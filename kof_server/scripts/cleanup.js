import "dotenv/config";
import fs from "fs";
import Database from "better-sqlite3";
import { recordRun } from "../src/maintenance.js";

const DB_PATH = process.env.KOF_DB_PATH || "kof.sqlite";
const ORDER_DAYS = Number(process.env.KOF_ORDER_RETENTION_DAYS || 30);
const AUDIT_DAYS = Number(process.env.KOF_AUDIT_RETENTION_DAYS || ORDER_DAYS);
const INVENTORY_DAYS = Number(process.env.KOF_INVENTORY_RETENTION_DAYS || ORDER_DAYS);

function finish(ok, message) {
  try {
    recordRun({ dbPath: DB_PATH, job: "cleanup", ok, message });
  } catch {}
  console.log(message);
  process.exit(ok ? 0 : 1);
}

if (!ORDER_DAYS || ORDER_DAYS <= 0) {
  finish(true, "Order retention disabled (KOF_ORDER_RETENTION_DAYS <= 0).");
}

if (!fs.existsSync(DB_PATH)) {
  finish(false, `Database file not found: ${DB_PATH}`);
}

// Foreign keys must be ON for ON DELETE CASCADE / SET NULL on order_items,
// inventory_adjustments, and order_status_history to apply.
const db = new Database(DB_PATH);

try {
  db.pragma("foreign_keys = ON");

  const deleteOldOrders = db.prepare(`
    DELETE FROM orders
    WHERE created_at < datetime('now', 'localtime', ?)
  `);

  // Drop audit-log entries older than the configured window. These accumulate
  // forever otherwise — admin_user_id is already SET NULL on user delete.
  const deleteOldAuditLog = db.prepare(`
    DELETE FROM audit_log
    WHERE created_at < datetime('now', 'localtime', ?)
  `);

  // Drop stale inventory adjustments. Deleting an order sets the adjustment's
  // order_id to NULL, leaving a detached order-completion row — those are the
  // primary growth source. We also prune restock/manual/waste rows older than
  // the window so non-order adjustments don't grow unbounded.
  const deleteOldInventoryAdjustments = db.prepare(`
    DELETE FROM inventory_adjustments
    WHERE created_at < datetime('now', 'localtime', ?)
  `);

  const result = db.transaction(() => {
    const orders = deleteOldOrders.run(`-${ORDER_DAYS} days`);
    const auditDays = AUDIT_DAYS > 0 ? AUDIT_DAYS : ORDER_DAYS;
    const audit = deleteOldAuditLog.run(`-${auditDays} days`);
    const inventoryDays = INVENTORY_DAYS > 0 ? INVENTORY_DAYS : ORDER_DAYS;
    const inventory = deleteOldInventoryAdjustments.run(`-${inventoryDays} days`);
    return { orders: orders.changes, audit: audit.changes, inventory: inventory.changes };
  })();

  db.close();
  finish(
    true,
    `Pruned: orders=${result.orders} (>${ORDER_DAYS}d), audit_log=${result.audit} (>${AUDIT_DAYS}d), inventory_adjustments=${result.inventory} (>${INVENTORY_DAYS}d).`
  );
} catch (error) {
  try {
    db.close();
  } catch {}
  finish(false, `Cleanup failed: ${error.message}`);
}
