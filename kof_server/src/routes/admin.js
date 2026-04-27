import express from "express";
import db from "../db.js";
import {
  ensureDefaultAdmin,
  requireAdmin,
  signToken,
  verifyPin,
  hashPin,
  revokeToken,
  getLoginLockoutSeconds,
  recordLoginAttempt,
} from "../adminAuth.js";
import { createIpRateLimiter } from "../rateLimit.js";
import { createTableToken } from "../utils/tableTokens.js";

const router = express.Router();

ensureDefaultAdmin();

// Rate limiter for the login endpoint — 10 attempts per 5 minutes per IP
const loginRateLimiter = createIpRateLimiter({
  windowMs: 5 * 60_000,
  max: 10,
  message: "Too many login attempts. Please wait a few minutes.",
});

// Write an audit log entry; errors are silently swallowed to never break the caller
function auditLog(adminUserId, action, targetType = null, targetId = null, detail = "") {
  try {
    db.prepare(`
      INSERT INTO audit_log (admin_user_id, action, target_type, target_id, detail)
      VALUES (?, ?, ?, ?, ?)
    `).run(adminUserId ?? null, action, targetType, targetId, detail);
  } catch {}
}

// Ensure a per-user settings row exists before any read or write
function ensureSettingsRow(adminUserId) {
  db.prepare(`
    INSERT OR IGNORE INTO admin_user_settings (admin_user_id, volume, dark_mode, language)
    VALUES (?, 0.5, 0, 'en')
  `).run(adminUserId);
}

function toNumberOrNull(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function toSqliteBoolean(value) {
  return value ? 1 : 0;
}

// Load all inventory ingredients with derived low/out-of-stock flags
function loadInventoryIngredients() {
  const rows = db.prepare(`
    SELECT id, name, unit, stock_qty, low_stock_threshold, is_active, created_at
    FROM ingredients
    ORDER BY is_active DESC, name COLLATE NOCASE ASC, id ASC
  `).all();

  return rows.map((row) => ({
    ...row,
    is_low: Number(row.stock_qty) <= Number(row.low_stock_threshold),
    is_out: Number(row.stock_qty) <= 0,
  }));
}

// Load menu items with recipe summaries and computed availability
function loadMenuRecipeSummary() {
  const menuItems = db.prepare(`
    SELECT id, name, description, price_cents, is_active
    FROM menu_items
    ORDER BY id ASC
  `).all();

  const recipeRowsForMenuItem = db.prepare(`
    SELECT
      mii.ingredient_id,
      mii.qty_per_item,
      ing.name AS ingredient_name,
      ing.unit AS ingredient_unit,
      ing.stock_qty,
      ing.low_stock_threshold,
      ing.is_active AS ingredient_is_active
    FROM menu_item_ingredients mii
    JOIN ingredients ing ON ing.id = mii.ingredient_id
    WHERE mii.menu_item_id = ?
    ORDER BY ing.name COLLATE NOCASE ASC, ing.id ASC
  `);

  return menuItems.map((item) => {
    const recipe = recipeRowsForMenuItem.all(item.id).map((row) => ({
      ingredient_id: row.ingredient_id,
      ingredient_name: row.ingredient_name,
      ingredient_unit: row.ingredient_unit,
      qty_per_item: Number(row.qty_per_item),
      stock_qty: Number(row.stock_qty),
      low_stock_threshold: Number(row.low_stock_threshold),
      ingredient_is_active: !!row.ingredient_is_active,
    }));

    let maxMakeable = null;
    let limitedBy = [];
    let hasLowIngredient = false;

    if (recipe.length > 0) {
      const counts = [];

      for (const recipeRow of recipe) {
        if (recipeRow.qty_per_item <= 0) continue;
        const units = Math.floor(recipeRow.stock_qty / recipeRow.qty_per_item);
        counts.push(units);
        if (recipeRow.stock_qty <= recipeRow.low_stock_threshold) {
          hasLowIngredient = true;
        }
        if (units <= 0) limitedBy.push(recipeRow.ingredient_name);
      }

      maxMakeable = counts.length ? Math.max(0, Math.min(...counts)) : null;
    }

    let availability = "no_recipe";

    if (recipe.length > 0) {
      if ((maxMakeable ?? 0) <= 0) {
        availability = "unavailable";
      } else if (hasLowIngredient) {
        availability = "low";
      } else {
        availability = "available";
      }
    }

    return {
      ...item,
      recipe,
      availability,
      max_makeable_units: maxMakeable,
      limited_by: limitedBy,
    };
  });
}

// GET /me — return the current authenticated admin user
router.get("/me", requireAdmin("barista"), (req, res) => {
  const currentUser = db.prepare(`
    SELECT id, username, role, is_active
    FROM admin_users
    WHERE id = ?
  `).get(req.admin.sub);

  if (!currentUser || currentUser.is_active !== 1) {
    return res.status(401).json({ error: "unauthorized" });
  }

  res.json({
    id: currentUser.id,
    username: currentUser.username,
    role: currentUser.role,
  });
});

// GET /me/settings — return persisted UI settings for the current user
router.get("/me/settings", requireAdmin("barista"), (req, res) => {
  const adminUserId = req.admin.sub;
  ensureSettingsRow(adminUserId);

  const settings = db.prepare(`
    SELECT volume, dark_mode, language
    FROM admin_user_settings
    WHERE admin_user_id = ?
  `).get(adminUserId);

  const language = ["en", "pt", "fi"].includes(settings?.language)
    ? settings.language
    : "en";

  res.json({
    volume: typeof settings?.volume === "number" ? settings.volume : 0.5,
    dark_mode: !!settings?.dark_mode,
    language,
  });
});

// PATCH /me/settings — update UI settings for the current user
router.patch("/me/settings", requireAdmin("barista"), (req, res) => {
  const adminUserId = req.admin.sub;
  ensureSettingsRow(adminUserId);

  const { volume, dark_mode: darkMode, language } = req.body ?? {};
  const fields = [];
  const values = [];

  if (typeof volume === "number" && Number.isFinite(volume)) {
    fields.push("volume = ?");
    values.push(Math.max(0, Math.min(1, volume)));
  }

  if (typeof darkMode === "boolean") {
    fields.push("dark_mode = ?");
    values.push(toSqliteBoolean(darkMode));
  }

  if (typeof language === "string") {
    const normalizedLanguage = language.trim();
    if (!["en", "pt", "fi"].includes(normalizedLanguage)) {
      return res.status(400).json({ error: "invalid language" });
    }
    fields.push("language = ?");
    values.push(normalizedLanguage);
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: "no fields to update" });
  }

  values.push(adminUserId);

  db.prepare(`
    UPDATE admin_user_settings SET ${fields.join(", ")} WHERE admin_user_id = ?
  `).run(...values);

  res.json({ ok: true });
});

// POST /change-pin — allow the current user to change their own PIN
router.post("/change-pin", requireAdmin("barista"), (req, res) => {
  const { old_pin: oldPin, new_pin: newPin } = req.body ?? {};

  if (!oldPin || !newPin) {
    return res.status(400).json({ error: "old_pin and new_pin required" });
  }

  if (String(newPin).length < 4) {
    return res.status(400).json({ error: "PIN too short (min 4)" });
  }

  const user = db.prepare(`
    SELECT id, pin_hash FROM admin_users WHERE id = ?
  `).get(req.admin.sub);

  if (!user) return res.status(404).json({ error: "not found" });

  if (!verifyPin(oldPin, user.pin_hash)) {
    return res.status(401).json({ error: "wrong PIN" });
  }

  db.prepare(`UPDATE admin_users SET pin_hash = ? WHERE id = ?`).run(
    hashPin(newPin),
    req.admin.sub
  );

  auditLog(req.admin.sub, "pin_changed");
  res.json({ ok: true });
});

// POST /login — authenticate and issue a token
router.post("/login", loginRateLimiter, (req, res) => {
  const { username, pin } = req.body ?? {};

  if (!username || !pin) {
    return res.status(400).json({ error: "username and pin required" });
  }

  const lockedSeconds = getLoginLockoutSeconds(username);
  if (lockedSeconds) {
    return res.status(429).json({
      error: `Account temporarily locked. Try again in ${lockedSeconds}s.`,
      retry_after_seconds: lockedSeconds,
    });
  }

  const user = db.prepare(`
    SELECT id, username, pin_hash, role, is_active
    FROM admin_users
    WHERE username = ?
  `).get(username);

  if (!user || user.is_active !== 1 || !verifyPin(pin, user.pin_hash)) {
    if (user) recordLoginAttempt(username, false);
    return res.status(401).json({ error: "invalid credentials" });
  }

  recordLoginAttempt(username, true);
  auditLog(user.id, "login");

  const token = signToken({
    sub: user.id,
    username: user.username,
    role: user.role,
    exp: Date.now() + 7 * 24 * 60 * 60 * 1000,
  });

  res.json({ token, username: user.username, role: user.role });
});

// POST /logout — revoke the current token
router.post("/logout", requireAdmin("barista"), (req, res) => {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (token) revokeToken(token);
  auditLog(req.admin.sub, "logout");
  res.json({ ok: true });
});

// GET /shop — return shop profile settings
router.get("/shop", requireAdmin("barista"), (req, res) => {
  const rows = db.prepare(`SELECT key, value FROM shop_settings`).all();
  const s = Object.fromEntries(rows.map((r) => [r.key, r.value]));

  res.json({
    shop_name: s.shop_name || "",
    shop_description: s.shop_description || "",
    max_concurrent_orders: Number(s.max_concurrent_orders) || 0,
    wifi_ssid: s.wifi_ssid || "",
    wifi_password: s.wifi_password || "",
    wifi_security: s.wifi_security || "WPA",
  });
});

// PATCH /shop — update shop profile settings (manager only)
router.patch("/shop", requireAdmin("manager"), (req, res) => {
  const { shop_name, shop_description, max_concurrent_orders, wifi_ssid, wifi_password, wifi_security } = req.body ?? {};
  const upsert = db.prepare(
    `INSERT OR REPLACE INTO shop_settings (key, value) VALUES (?, ?)`
  );

  const VALID_SECURITY = ["WPA", "WEP", "nopass"];

  try {
    db.transaction(() => {
      if (typeof shop_name === "string") {
        upsert.run("shop_name", shop_name.trim().slice(0, 80));
      }
      if (typeof shop_description === "string") {
        upsert.run("shop_description", shop_description.trim().slice(0, 300));
      }
      if (max_concurrent_orders !== undefined) {
        const n = Number(max_concurrent_orders);
        if (!Number.isFinite(n) || n < 0) {
          throw Object.assign(new Error("invalid max_concurrent_orders"), {
            statusCode: 400,
          });
        }
        upsert.run("max_concurrent_orders", String(Math.floor(n)));
      }
      if (typeof wifi_ssid === "string") {
        upsert.run("wifi_ssid", wifi_ssid.trim().slice(0, 32));
      }
      if (typeof wifi_password === "string") {
        upsert.run("wifi_password", wifi_password.slice(0, 63));
      }
      if (typeof wifi_security === "string") {
        if (!VALID_SECURITY.includes(wifi_security)) {
          throw Object.assign(new Error("invalid wifi_security"), { statusCode: 400 });
        }
        upsert.run("wifi_security", wifi_security);
      }
    })();
  } catch (e) {
    return res.status(e.statusCode || 400).json({ error: e.message });
  }

  auditLog(req.admin.sub, "shop_settings_updated");
  res.json({ ok: true });
});

// GET /analytics/daily?date=YYYY-MM-DD — daily order and revenue summary
router.get("/analytics/daily", requireAdmin("barista"), (req, res) => {
  const rawDate = String(req.query.date || "").trim();
  const targetDate = /^\d{4}-\d{2}-\d{2}$/.test(rawDate) ? rawDate : null;
  const dateParam =
    targetDate ?? db.prepare(`SELECT date('now','localtime') AS d`).get().d;

  const stats = db.prepare(`
    SELECT
      COUNT(*) AS total_orders,
      SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
      SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
      SUM(CASE WHEN payment_status = 'paid' THEN 1 ELSE 0 END) AS paid_orders
    FROM orders
    WHERE created_date = ?
  `).get(dateParam);

  const revenueRow = db.prepare(`
    SELECT COALESCE(SUM(oi.line_total_cents), 0) AS total_revenue_cents
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.created_date = ? AND o.payment_status = 'paid'
  `).get(dateParam);

  const paidOrders = stats.paid_orders || 0;
  const totalRevenue = Number(revenueRow.total_revenue_cents) || 0;

  res.json({
    date: dateParam,
    total_orders: stats.total_orders || 0,
    completed_orders: stats.completed_orders || 0,
    cancelled_orders: stats.cancelled_orders || 0,
    paid_orders: paidOrders,
    total_revenue_cents: totalRevenue,
    avg_order_cents: paidOrders > 0 ? Math.round(totalRevenue / paidOrders) : 0,
  });
});

// GET /analytics/items?date=YYYY-MM-DD — item popularity and revenue for a day
router.get("/analytics/items", requireAdmin("barista"), (req, res) => {
  const rawDate = String(req.query.date || "").trim();
  const targetDate = /^\d{4}-\d{2}-\d{2}$/.test(rawDate) ? rawDate : null;
  const dateParam =
    targetDate ?? db.prepare(`SELECT date('now','localtime') AS d`).get().d;

  const items = db.prepare(`
    SELECT
      mi.id AS menu_item_id,
      mi.name AS item_name,
      SUM(oi.qty) AS total_qty,
      SUM(oi.line_total_cents) AS total_revenue_cents
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    JOIN menu_items mi ON mi.id = oi.menu_item_id
    WHERE o.created_date = ?
    GROUP BY mi.id, mi.name
    ORDER BY total_qty DESC, total_revenue_cents DESC
  `).all(dateParam);

  res.json({ date: dateParam, items });
});

// POST /users — create a new admin user (manager only)
router.post("/users", requireAdmin("manager"), (req, res) => {
  const { username, pin, role = "barista" } = req.body ?? {};

  if (!username || !pin) {
    return res.status(400).json({ error: "username and pin required" });
  }

  if (!["manager", "barista"].includes(role)) {
    return res.status(400).json({ error: "invalid role" });
  }

  if (String(pin).length < 4) {
    return res.status(400).json({ error: "PIN too short (min 4)" });
  }

  try {
    const result = db.prepare(`
      INSERT INTO admin_users (username, pin_hash, role, is_active)
      VALUES (?, ?, ?, 1)
    `).run(username, hashPin(pin), role);

    ensureSettingsRow(Number(result.lastInsertRowid));
    auditLog(req.admin.sub, "user_created", "admin_user", Number(result.lastInsertRowid));
    res.status(201).json({ id: result.lastInsertRowid });
  } catch {
    res.status(400).json({ error: "username already exists" });
  }
});

// GET /users — list admin users (manager only)
router.get("/users", requireAdmin("manager"), (req, res) => {
  const users = db.prepare(`
    SELECT id, username, role, is_active
    FROM admin_users
    ORDER BY role DESC, username ASC
  `).all();

  res.json({ users });
});

// PATCH /users/:id — enable or disable an admin user (manager only)
router.patch("/users/:id", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);
  const { is_active: isActive } = req.body ?? {};

  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }

  if (typeof isActive !== "boolean" && typeof isActive !== "number") {
    return res.status(400).json({ error: "is_active required" });
  }

  const nextActive = toSqliteBoolean(isActive);

  if (id === req.admin.sub && nextActive === 0) {
    return res.status(400).json({ error: "cannot disable yourself" });
  }

  const targetUser = db.prepare(`
    SELECT id, username, role, is_active FROM admin_users WHERE id = ?
  `).get(id);

  if (!targetUser) return res.status(404).json({ error: "not found" });

  if (targetUser.username === "admin" && nextActive === 0) {
    return res.status(400).json({ error: "cannot disable root admin user" });
  }

  if (targetUser.role === "manager" && nextActive === 0) {
    const managerCountRow = db.prepare(`
      SELECT COUNT(*) AS count FROM admin_users
      WHERE role = 'manager' AND is_active = 1
    `).get();

    if ((managerCountRow?.count || 0) <= 1) {
      return res.status(400).json({ error: "cannot disable the last active manager" });
    }
  }

  const result = db.prepare(`
    UPDATE admin_users SET is_active = ? WHERE id = ?
  `).run(nextActive, id);

  if (result.changes === 0) return res.status(404).json({ error: "not found" });

  auditLog(
    req.admin.sub,
    nextActive ? "user_enabled" : "user_disabled",
    "admin_user",
    id
  );
  res.json({ ok: true });
});

// POST /users/:id/reset-pin — reset a user's PIN to a random value (manager only)
router.post("/users/:id/reset-pin", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);

  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }

  const newPin = String(Math.floor(1000 + Math.random() * 9000));
  const result = db.prepare(`
    UPDATE admin_users SET pin_hash = ? WHERE id = ?
  `).run(hashPin(newPin), id);

  if (result.changes === 0) return res.status(404).json({ error: "not found" });

  auditLog(req.admin.sub, "pin_reset", "admin_user", id);
  res.json({ ok: true, new_pin: newPin });
});

// GET /table-links — generate signed table QR URLs (manager only)
router.get("/table-links", requireAdmin("manager"), (req, res) => {
  const count = Math.max(1, Math.min(200, Number(req.query.count || 10)));
  let baseUrl = String(
    req.query.base_url || `${req.protocol}://${req.get("host")}`
  )
    .trim()
    .replace(/\/+$/, "");

  if (baseUrl && !/^[a-zA-Z][a-zA-Z\d+\-.]*:\/\//.test(baseUrl)) {
    baseUrl = `http://${baseUrl}`;
  }

  const tables = Array.from({ length: count }, (_, index) => {
    const tableLabel = String(index + 1);
    const tableToken = createTableToken(tableLabel);
    const params = new URLSearchParams({ table: tableLabel, table_token: tableToken });
    return {
      table_label: tableLabel,
      table_token: tableToken,
      url: `${baseUrl}/?${params.toString()}`,
    };
  });

  res.json({ tables });
});

const ALLOWED_CATEGORIES = ["Espresso", "Hot Drinks", "Cold Drinks", "Pastries", "Food", "Other"];

// GET /menu — admin-facing menu list
router.get("/menu", requireAdmin("barista"), (req, res) => {
  const items = db.prepare(`
    SELECT id, name, description, price_cents, is_active, category, has_sizes
    FROM menu_items
    ORDER BY id ASC
  `).all().map((item) => ({ ...item, has_sizes: !!item.has_sizes }));

  res.json({ items, categories: ALLOWED_CATEGORIES });
});

// POST /menu — create a new menu item (manager only)
router.post("/menu", requireAdmin("manager"), (req, res) => {
  const {
    name,
    description = "",
    price_cents: priceCents,
    category = "Other",
    has_sizes: hasSizes = false,
  } = req.body ?? {};

  if (!name || !Number.isFinite(Number(priceCents))) {
    return res.status(400).json({ error: "name and price_cents required" });
  }

  const safeCategory = ALLOWED_CATEGORIES.includes(category) ? category : "Other";

  const result = db.prepare(`
    INSERT INTO menu_items (name, description, price_cents, is_active, category, has_sizes)
    VALUES (?, ?, ?, 1, ?, ?)
  `).run(name, description, Number(priceCents), safeCategory, toSqliteBoolean(hasSizes));

  res.status(201).json({ id: result.lastInsertRowid });
});

// PATCH /menu/:id — update a menu item (manager only)
router.patch("/menu/:id", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);
  const {
    name,
    description,
    price_cents: priceCents,
    is_active: isActive,
    category,
    has_sizes: hasSizes,
  } = req.body ?? {};

  const existing = db.prepare(`SELECT id FROM menu_items WHERE id = ?`).get(id);
  if (!existing) return res.status(404).json({ error: "not found" });

  const fields = [];
  const values = [];

  if (typeof name === "string") { fields.push("name = ?"); values.push(name); }
  if (typeof description === "string") { fields.push("description = ?"); values.push(description); }
  if (Number.isFinite(Number(priceCents))) { fields.push("price_cents = ?"); values.push(Number(priceCents)); }
  if (typeof isActive === "number" || typeof isActive === "boolean") {
    fields.push("is_active = ?");
    values.push(toSqliteBoolean(isActive));
  }
  if (typeof category === "string" && ALLOWED_CATEGORIES.includes(category)) {
    fields.push("category = ?");
    values.push(category);
  }
  if (typeof hasSizes === "boolean" || typeof hasSizes === "number") {
    fields.push("has_sizes = ?");
    values.push(toSqliteBoolean(hasSizes));
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: "no fields to update" });
  }

  values.push(id);
  db.prepare(`UPDATE menu_items SET ${fields.join(", ")} WHERE id = ?`).run(...values);
  res.json({ ok: true });
});

// GET /inventory/ingredients — ingredient list with stock state flags
router.get("/inventory/ingredients", requireAdmin("barista"), (req, res) => {
  res.json({ ingredients: loadInventoryIngredients() });
});

// POST /inventory/ingredients — create a new ingredient (manager only)
router.post("/inventory/ingredients", requireAdmin("manager"), (req, res) => {
  const {
    name,
    unit = "g",
    stock_qty: stockQty = 0,
    low_stock_threshold: lowStockThreshold = 0,
  } = req.body ?? {};

  const parsedStockQty = toNumberOrNull(stockQty);
  const parsedLowStockThreshold = toNumberOrNull(lowStockThreshold);

  if (!String(name || "").trim()) {
    return res.status(400).json({ error: "name required" });
  }

  if (!String(unit || "").trim()) {
    return res.status(400).json({ error: "unit required" });
  }

  if (parsedStockQty === null || parsedLowStockThreshold === null) {
    return res.status(400).json({
      error: "stock_qty and low_stock_threshold must be numbers",
    });
  }

  try {
    const result = db.prepare(`
      INSERT INTO ingredients (name, unit, stock_qty, low_stock_threshold, is_active)
      VALUES (?, ?, ?, ?, 1)
    `).run(String(name).trim(), String(unit).trim(), parsedStockQty, parsedLowStockThreshold);

    res.status(201).json({ id: result.lastInsertRowid });
  } catch {
    res.status(400).json({ error: "ingredient already exists" });
  }
});

// PATCH /inventory/ingredients/:id — update an ingredient (manager only)
router.patch("/inventory/ingredients/:id", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);

  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }

  const existing = db.prepare(`SELECT id FROM ingredients WHERE id = ?`).get(id);
  if (!existing) return res.status(404).json({ error: "not found" });

  const {
    name,
    unit,
    stock_qty: stockQty,
    low_stock_threshold: lowStockThreshold,
    is_active: isActive,
  } = req.body ?? {};

  const fields = [];
  const values = [];

  if (typeof name === "string") {
    const trimmed = name.trim();
    if (!trimmed) return res.status(400).json({ error: "name cannot be empty" });
    fields.push("name = ?");
    values.push(trimmed);
  }

  if (typeof unit === "string") {
    const trimmed = unit.trim();
    if (!trimmed) return res.status(400).json({ error: "unit cannot be empty" });
    fields.push("unit = ?");
    values.push(trimmed);
  }

  if (stockQty !== undefined) {
    const parsed = toNumberOrNull(stockQty);
    if (parsed === null) return res.status(400).json({ error: "invalid stock_qty" });
    fields.push("stock_qty = ?");
    values.push(parsed);
  }

  if (lowStockThreshold !== undefined) {
    const parsed = toNumberOrNull(lowStockThreshold);
    if (parsed === null) return res.status(400).json({ error: "invalid low_stock_threshold" });
    fields.push("low_stock_threshold = ?");
    values.push(parsed);
  }

  if (typeof isActive === "boolean" || typeof isActive === "number") {
    fields.push("is_active = ?");
    values.push(toSqliteBoolean(isActive));
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: "no fields to update" });
  }

  try {
    values.push(id);
    db.prepare(`UPDATE ingredients SET ${fields.join(", ")} WHERE id = ?`).run(...values);
    res.json({ ok: true });
  } catch {
    res.status(400).json({ error: "ingredient update failed" });
  }
});

// POST /inventory/ingredients/:id/adjust — apply a manual stock adjustment (manager only)
router.post(
  "/inventory/ingredients/:id/adjust",
  requireAdmin("manager"),
  (req, res) => {
    const id = Number(req.params.id);
    const { delta_qty: deltaQty, reason = "manual", note = "" } = req.body ?? {};

    const delta = toNumberOrNull(deltaQty);

    if (!Number.isFinite(id)) {
      return res.status(400).json({ error: "invalid id" });
    }

    if (delta === null || delta === 0) {
      return res.status(400).json({ error: "delta_qty must be a non-zero number" });
    }

    if (!["restock", "waste", "manual"].includes(reason)) {
      return res.status(400).json({ error: "invalid reason" });
    }

    const ingredient = db.prepare(`SELECT id, name FROM ingredients WHERE id = ?`).get(id);
    if (!ingredient) return res.status(404).json({ error: "not found" });

    db.transaction(() => {
      db.prepare(`UPDATE ingredients SET stock_qty = stock_qty + ? WHERE id = ?`).run(delta, id);
      db.prepare(`
        INSERT INTO inventory_adjustments
        (ingredient_id, delta_qty, reason, note, admin_user_id)
        VALUES (?, ?, ?, ?, ?)
      `).run(id, delta, reason, String(note || "").trim(), req.admin.sub);
    })();

    const updated = db.prepare(`
      SELECT id, name, unit, stock_qty, low_stock_threshold, is_active, created_at
      FROM ingredients WHERE id = ?
    `).get(id);

    res.json({
      ok: true,
      ingredient: {
        ...updated,
        is_low: Number(updated.stock_qty) <= Number(updated.low_stock_threshold),
        is_out: Number(updated.stock_qty) <= 0,
      },
    });
  }
);

// GET /inventory/menu-recipes — menu items with recipe and availability info
router.get("/inventory/menu-recipes", requireAdmin("barista"), (req, res) => {
  res.json({ items: loadMenuRecipeSummary() });
});

// PUT /inventory/menu/:id/recipe — replace a menu item's full recipe (manager only)
router.put("/inventory/menu/:id/recipe", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);
  const recipe = Array.isArray(req.body?.recipe) ? req.body.recipe : null;

  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }

  if (!recipe) {
    return res.status(400).json({ error: "recipe array required" });
  }

  const item = db.prepare(`SELECT id FROM menu_items WHERE id = ?`).get(id);
  if (!item) return res.status(404).json({ error: "menu item not found" });

  const cleanedRecipe = [];
  const seenIngredientIds = new Set();

  for (const recipeRow of recipe) {
    const ingredientId = Number(recipeRow?.ingredient_id);
    const qtyPerItem = toNumberOrNull(recipeRow?.qty_per_item);

    if (!Number.isFinite(ingredientId)) {
      return res.status(400).json({ error: "invalid ingredient_id in recipe" });
    }

    if (qtyPerItem === null || qtyPerItem <= 0) {
      return res.status(400).json({ error: "qty_per_item must be greater than 0" });
    }

    if (seenIngredientIds.has(ingredientId)) {
      return res.status(400).json({ error: "duplicate ingredient in recipe" });
    }

    const ingredient = db.prepare(`SELECT id FROM ingredients WHERE id = ?`).get(ingredientId);
    if (!ingredient) {
      return res.status(400).json({ error: `ingredient not found: ${ingredientId}` });
    }

    seenIngredientIds.add(ingredientId);
    cleanedRecipe.push({ ingredient_id: ingredientId, qty_per_item: qtyPerItem });
  }

  db.transaction(() => {
    db.prepare(`DELETE FROM menu_item_ingredients WHERE menu_item_id = ?`).run(id);
    const insertRow = db.prepare(`
      INSERT INTO menu_item_ingredients (menu_item_id, ingredient_id, qty_per_item)
      VALUES (?, ?, ?)
    `);
    for (const row of cleanedRecipe) {
      insertRow.run(id, row.ingredient_id, row.qty_per_item);
    }
  })();

  res.json({ ok: true });
});

// GET /inventory/adjustments — recent stock adjustment history
router.get("/inventory/adjustments", requireAdmin("barista"), (req, res) => {
  const adjustments = db.prepare(`
    SELECT
      ia.id, ia.ingredient_id, ia.delta_qty, ia.reason, ia.note,
      ia.order_id, ia.admin_user_id, ia.created_at,
      ing.name AS ingredient_name,
      ing.unit AS ingredient_unit,
      au.username AS admin_username
    FROM inventory_adjustments ia
    JOIN ingredients ing ON ing.id = ia.ingredient_id
    LEFT JOIN admin_users au ON au.id = ia.admin_user_id
    ORDER BY ia.id DESC
    LIMIT 200
  `).all();

  res.json({ adjustments });
});

export default router;
