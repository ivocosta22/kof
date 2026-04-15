import express from "express";
import db from "../db.js";
import { createIpRateLimiter } from "../rateLimit.js";
import { requireAdmin } from "../adminAuth.js";
import { getMenuItemAvailability } from "../utils/menuAvailability.js";
import { validateOrderContext } from "../utils/orderContext.js";
import { verifyTableToken } from "../utils/tableTokens.js";

export default function createOrdersRouter({ broadcast }) {
  const router = express.Router();

  const allowedOrderStatuses = new Set([
    "new", "making", "ready", "completed", "cancelled",
  ]);
  const allowedPaymentStatuses = new Set(["unpaid", "paid"]);

  // IP rate limiter for order creation — prevents accidental or intentional spam
  const limitCreateOrder = createIpRateLimiter({
    windowMs: 60_000,
    max: 10,
    message: "Too many orders from this device. Please wait 1 minute.",
  });

  // Next daily order number — resets each local calendar day
  function nextOrderNumber() {
    const row = db.prepare(`
      SELECT COALESCE(MAX(order_number), 0) AS m
      FROM orders
      WHERE created_date = date('now','localtime')
    `).get();
    return row.m + 1;
  }

  // Return ingredient warnings for an order when it moves to "making"
  function getLowInventoryWarningsForOrder(orderId) {
    const rows = db.prepare(`
      SELECT
        ing.id, ing.name, ing.unit, ing.stock_qty, ing.low_stock_threshold,
        SUM(oi.qty * mii.qty_per_item) AS required_qty
      FROM order_items oi
      JOIN menu_item_ingredients mii ON mii.menu_item_id = oi.menu_item_id
      JOIN ingredients ing ON ing.id = mii.ingredient_id
      WHERE oi.order_id = ?
      GROUP BY ing.id, ing.name, ing.unit, ing.stock_qty, ing.low_stock_threshold
      ORDER BY ing.name COLLATE NOCASE ASC
    `).all(orderId);

    return rows
      .filter(
        (row) =>
          Number(row.stock_qty) <= Number(row.low_stock_threshold) ||
          Number(row.stock_qty) < Number(row.required_qty)
      )
      .map((row) => {
        const stockQty = Number(row.stock_qty);
        const requiredQty = Number(row.required_qty);
        const lowThreshold = Number(row.low_stock_threshold);
        let message = `${row.name}: ${stockQty} ${row.unit} left`;
        if (stockQty < requiredQty) {
          message += `, order needs ${requiredQty} ${row.unit}`;
        } else if (stockQty <= lowThreshold) {
          message += `, at/below low-stock threshold (${lowThreshold} ${row.unit})`;
        }
        return {
          ingredient_id: row.id,
          ingredient_name: row.name,
          unit: row.unit,
          stock_qty: stockQty,
          low_stock_threshold: lowThreshold,
          required_qty_for_order: requiredQty,
          message,
        };
      });
  }

  // Return ingredients from a given set of IDs that are now at or below threshold
  function getLowStockIngredients(ingredientIds) {
    if (!ingredientIds.length) return [];
    const placeholders = ingredientIds.map(() => "?").join(",");
    return db.prepare(`
      SELECT id, name, unit, stock_qty, low_stock_threshold
      FROM ingredients
      WHERE id IN (${placeholders})
        AND low_stock_threshold > 0
        AND stock_qty <= low_stock_threshold
    `).all(...ingredientIds);
  }

  // Atomically deduct inventory when an order completes.
  // Uses a conditional UPDATE to claim the deduction so concurrent calls are safe.
  // Returns { deducted: bool, ingredientIds: number[] }
  function deductInventoryForCompletedOrder(orderId, adminUserId) {
    const orderExists = db.prepare(`SELECT id FROM orders WHERE id = ?`).get(orderId);
    if (!orderExists) {
      const err = new Error("not found");
      err.statusCode = 404;
      throw err;
    }

    const ingredientRows = db.prepare(`
      SELECT
        ing.id AS ingredient_id,
        ing.name AS ingredient_name,
        SUM(oi.qty * mii.qty_per_item) AS total_qty
      FROM order_items oi
      JOIN menu_item_ingredients mii ON mii.menu_item_id = oi.menu_item_id
      JOIN ingredients ing ON ing.id = mii.ingredient_id
      WHERE oi.order_id = ?
      GROUP BY ing.id, ing.name
      ORDER BY ing.id ASC
    `).all(orderId);

    const doDeduct = db.transaction(() => {
      // Atomic claim: only proceeds if inventory has not been deducted yet
      const claimed = db.prepare(`
        UPDATE orders
        SET inventory_deducted_at = datetime('now','localtime')
        WHERE id = ? AND inventory_deducted_at IS NULL
      `).run(orderId);

      if (claimed.changes === 0) return { deducted: false, ingredientIds: [] };

      const order = db.prepare(`SELECT order_number FROM orders WHERE id = ?`).get(orderId);
      const updateIngredient = db.prepare(`
        UPDATE ingredients SET stock_qty = stock_qty - ? WHERE id = ?
      `);
      const insertAdjustment = db.prepare(`
        INSERT INTO inventory_adjustments
        (ingredient_id, delta_qty, reason, note, order_id, admin_user_id)
        VALUES (?, ?, 'order_completion', ?, ?, ?)
      `);

      const affectedIds = [];

      for (const row of ingredientRows) {
        const qty = Number(row.total_qty);
        if (!Number.isFinite(qty) || qty === 0) continue;
        updateIngredient.run(qty, row.ingredient_id);
        insertAdjustment.run(
          row.ingredient_id,
          -qty,
          `Order #${order.order_number}`,
          orderId,
          adminUserId
        );
        affectedIds.push(row.ingredient_id);
      }

      return { deducted: true, ingredientIds: affectedIds };
    });

    return doDeduct();
  }

  // Attach enriched item details to order response objects
  function enrichOrderItems(orderId) {
    const rows = db.prepare(`
      SELECT
        oi.menu_item_id, oi.qty, oi.chosen_modifiers_json, oi.line_total_cents,
        mi.name AS item_name
      FROM order_items oi
      JOIN menu_items mi ON mi.id = oi.menu_item_id
      WHERE oi.order_id = ?
    `).all(orderId);

    const requestedQtyByMenuItemId = rows.reduce((totals, item) => {
      const current = totals.get(item.menu_item_id) || 0;
      totals.set(item.menu_item_id, current + Number(item.qty || 0));
      return totals;
    }, new Map());

    return rows.map((item) => {
      const availabilityInfo = getMenuItemAvailability(item.menu_item_id, {
        requestedQty: requestedQtyByMenuItemId.get(item.menu_item_id) || item.qty,
      });
      return {
        menu_item_id: item.menu_item_id,
        qty: item.qty,
        item_name: item.item_name,
        chosen_modifiers: JSON.parse(item.chosen_modifiers_json),
        line_total_cents: item.line_total_cents,
        item_availability: availabilityInfo.availability,
      };
    });
  }

  // Load receipt payload — only available for paid orders
  function loadReceipt(orderId) {
    const order = db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at
      FROM orders WHERE id = ?
    `).get(orderId);

    if (!order) {
      const err = new Error("not found");
      err.statusCode = 404;
      throw err;
    }

    if (order.payment_status !== "paid") {
      const err = new Error("Receipt available only for paid orders");
      err.statusCode = 400;
      throw err;
    }

    const items = db.prepare(`
      SELECT oi.qty, oi.chosen_modifiers_json, oi.line_total_cents, mi.name AS item_name
      FROM order_items oi
      JOIN menu_items mi ON mi.id = oi.menu_item_id
      WHERE oi.order_id = ?
      ORDER BY oi.id ASC
    `).all(orderId).map((row) => ({
      qty: row.qty,
      item_name: row.item_name,
      chosen_modifiers: JSON.parse(row.chosen_modifiers_json),
      line_total_cents: row.line_total_cents,
    }));

    const totalCents = items.reduce(
      (sum, item) => sum + Number(item.line_total_cents || 0),
      0
    );

    return { order: { ...order, items, total_cents: totalCents } };
  }

  // Load core order fields for staff/admin responses
  function loadOrderSummary(orderId) {
    return db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at
      FROM orders WHERE id = ?
    `).get(orderId);
  }

  // PATCH /:id/status — update order status and emit realtime events
  router.patch("/:id/status", requireAdmin("barista"), (req, res) => {
    const id = Number(req.params.id);
    const status = String(req.body?.status || "").trim();

    if (!Number.isFinite(id)) {
      return res.status(400).json({ error: "invalid id" });
    }

    if (!allowedOrderStatuses.has(status)) {
      return res.status(400).json({ error: "invalid status" });
    }

    const existingOrder = loadOrderSummary(id);
    if (!existingOrder) return res.status(404).json({ error: "not found" });

    try {
      db.prepare(`UPDATE orders SET status = ? WHERE id = ?`).run(status, id);

      // Record status transition
      db.prepare(`
        INSERT INTO order_status_history (order_id, from_status, to_status, changed_by)
        VALUES (?, ?, ?, ?)
      `).run(id, existingOrder.status, status, req.admin?.sub || null);

      let warnings = [];

      if (status === "making") {
        warnings = getLowInventoryWarningsForOrder(id);
      }

      if (status === "completed") {
        const deductResult = deductInventoryForCompletedOrder(id, req.admin?.sub || null);
        if (deductResult.deducted && deductResult.ingredientIds.length > 0) {
          const lowStock = getLowStockIngredients(deductResult.ingredientIds);
          if (lowStock.length > 0) {
            broadcast("low_stock", { ingredients: lowStock }, { staffOnly: true });
          }
        }
      }

      const order = loadOrderSummary(id);

      broadcast("order_status_changed", {
        id: order.id,
        order_number: order.order_number,
        previous_status: existingOrder.status,
        status: order.status,
      });

      res.json({ order, warnings });
    } catch (e) {
      res.status(e?.statusCode || 400).json({
        error: e.message || "status update failed",
      });
    }
  });

  // PATCH /:id/payment — update payment status and notify clients
  router.patch("/:id/payment", requireAdmin("barista"), (req, res) => {
    const id = Number(req.params.id);
    const paymentStatus = String(req.body?.payment_status || "").trim();

    if (!Number.isFinite(id)) {
      return res.status(400).json({ error: "invalid id" });
    }

    if (!allowedPaymentStatuses.has(paymentStatus)) {
      return res.status(400).json({ error: "invalid payment_status" });
    }

    const existingOrder = loadOrderSummary(id);
    if (!existingOrder) return res.status(404).json({ error: "not found" });

    try {
      db.prepare(`UPDATE orders SET payment_status = ? WHERE id = ?`).run(paymentStatus, id);
      const order = loadOrderSummary(id);

      broadcast("order_payment_changed", {
        id: order.id,
        order_number: order.order_number,
        previous_payment_status: existingOrder.payment_status,
        payment_status: order.payment_status,
      });

      res.json({ order });
    } catch (e) {
      res.status(e?.statusCode || 400).json({
        error: e.message || "payment update failed",
      });
    }
  });

  // GET /board — active orders plus today's completed/cancelled for the staff board
  router.get("/board", requireAdmin("barista"), (req, res) => {
    const orders = db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at
      FROM orders
      WHERE status NOT IN ('completed', 'cancelled')
         OR created_date = date('now', 'localtime')
      ORDER BY id DESC
      LIMIT 200
    `).all();

    const enriched = orders.map((order) => ({
      ...order,
      items: enrichOrderItems(order.id),
    }));

    res.json({ orders: enriched });
  });

  // GET /history — completed/cancelled orders from previous days, single JOIN query
  router.get("/history", requireAdmin("barista"), (req, res) => {
    const orders = db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at, created_date
      FROM orders
      WHERE status IN ('completed', 'cancelled')
        AND created_date < date('now', 'localtime')
      ORDER BY id DESC
      LIMIT 1000
    `).all();

    if (!orders.length) return res.json({ orders: [] });

    // Single JOIN query for all items — avoids N+1
    const ids = orders.map((o) => o.id);
    const placeholders = ids.map(() => "?").join(",");
    const itemRows = db.prepare(`
      SELECT oi.order_id, oi.qty, oi.chosen_modifiers_json, oi.line_total_cents,
             mi.name AS item_name
      FROM order_items oi
      JOIN menu_items mi ON mi.id = oi.menu_item_id
      WHERE oi.order_id IN (${placeholders})
      ORDER BY oi.order_id ASC, oi.id ASC
    `).all(...ids);

    const itemsByOrderId = new Map();
    for (const row of itemRows) {
      if (!itemsByOrderId.has(row.order_id)) itemsByOrderId.set(row.order_id, []);
      itemsByOrderId.get(row.order_id).push({
        qty: row.qty,
        item_name: row.item_name,
        chosen_modifiers: JSON.parse(row.chosen_modifiers_json),
        line_total_cents: row.line_total_cents,
      });
    }

    const enriched = orders.map((order) => {
      const items = itemsByOrderId.get(order.id) || [];
      const total_cents = items.reduce(
        (sum, item) => sum + Number(item.line_total_cents || 0),
        0
      );
      return { ...order, items, total_cents };
    });

    res.json({ orders: enriched });
  });

  // GET /:id/receipt — load receipt for a paid order (public, no auth)
  router.get("/:id/receipt", (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) {
      return res.status(400).json({ error: "invalid id" });
    }
    try {
      res.json(loadReceipt(id));
    } catch (e) {
      res.status(e?.statusCode || 400).json({
        error: e.message || "receipt load failed",
      });
    }
  });

  // GET /:id — load a single order (public, used for order tracking)
  router.get("/:id", (req, res) => {
    const id = Number(req.params.id);

    const order = db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at
      FROM orders WHERE id = ?
    `).get(id);

    if (!order) return res.status(404).json({ error: "not found" });

    res.json({ order: { ...order, items: enrichOrderItems(id) } });
  });

  // POST / — create a new order
  router.post("/", limitCreateOrder, (req, res) => {
    const {
      fulfillment_type = "",
      customer_label = "",
      table_label = "",
      table_token = "",
      note = "",
      items = [],
    } = req.body ?? {};

    let orderContext;

    try {
      orderContext = validateOrderContext({
        fulfillment_type,
        customer_label,
        table_label,
        note,
      });
    } catch (e) {
      return res.status(e?.statusCode || 400).json({
        error: e.message || "invalid order context",
      });
    }

    if (orderContext.fulfillment_type === "table") {
      if (!table_token) {
        return res.status(400).json({
          error: "Valid table QR is required for table orders",
        });
      }
      if (!verifyTableToken(orderContext.table_label, table_token)) {
        return res.status(400).json({
          error: "Table QR does not match selected table",
        });
      }
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: "items required" });
    }

    // Capacity check — respect max_concurrent_orders shop setting
    const capacityRow = db.prepare(
      `SELECT value FROM shop_settings WHERE key = 'max_concurrent_orders'`
    ).get();
    const maxConcurrent = capacityRow ? Number(capacityRow.value) : 0;

    if (maxConcurrent > 0) {
      const activeRow = db.prepare(`
        SELECT COUNT(*) AS count FROM orders
        WHERE status NOT IN ('completed', 'cancelled')
      `).get();
      if (activeRow.count >= maxConcurrent) {
        return res.status(503).json({
          error: "Shop is at capacity. Please try again shortly.",
        });
      }
    }

    const menuById = db.prepare(`
      SELECT id, price_cents, name FROM menu_items WHERE id = ? AND is_active = 1
    `);
    const requestedQtyByMenuItemId = new Map();

    for (const item of items) {
      const qty = Math.max(1, Number(item.qty ?? 1));
      const menuId = Number(item.menu_item_id);
      requestedQtyByMenuItemId.set(menuId, (requestedQtyByMenuItemId.get(menuId) || 0) + qty);
    }

    for (const [menuId, requestedQty] of requestedQtyByMenuItemId.entries()) {
      const menu = menuById.get(menuId);
      if (!menu) {
        return res.status(400).json({ error: `invalid menu_item_id: ${menuId}` });
      }
      const availabilityInfo = getMenuItemAvailability(menuId, { requestedQty });
      if (availabilityInfo.availability === "unavailable") {
        return res.status(400).json({
          error: `requested quantity unavailable for: ${menu.name}`,
        });
      }
    }

    const orderNumber = nextOrderNumber();

    const tx = db.transaction(() => {
      const result = db.prepare(`
        INSERT INTO orders
        (order_number, status, fulfillment_type, customer_label, table_label, note)
        VALUES (?, 'new', ?, ?, ?, ?)
      `).run(
        orderNumber,
        orderContext.fulfillment_type,
        orderContext.customer_label,
        orderContext.table_label,
        orderContext.note
      );

      const orderId = result.lastInsertRowid;

      const itemIns = db.prepare(`
        INSERT INTO order_items
        (order_id, menu_item_id, qty, chosen_modifiers_json, line_total_cents)
        VALUES (?, ?, ?, ?, ?)
      `);

      for (const item of items) {
        const qty = Math.max(1, Number(item.qty ?? 1));
        const menuId = Number(item.menu_item_id);
        const menu = menuById.get(menuId);
        if (!menu) throw new Error(`invalid menu_item_id: ${menuId}`);
        const chosenModifiers = Array.isArray(item.chosen_modifiers)
          ? item.chosen_modifiers
          : [];
        itemIns.run(orderId, menuId, qty, JSON.stringify(chosenModifiers), menu.price_cents * qty);
      }

      return orderId;
    });

    let orderId;
    try {
      orderId = tx();
    } catch (e) {
      return res.status(400).json({ error: e.message });
    }

    const order = db.prepare(`
      SELECT id, order_number, status, payment_status, fulfillment_type,
             customer_label, table_label, note, created_at
      FROM orders WHERE id = ?
    `).get(orderId);

    // order_created is staff-only — customers don't need to see new orders arrive
    broadcast("order_created", order, { staffOnly: true });

    res.status(201).json({ order });
  });

  return router;
}
