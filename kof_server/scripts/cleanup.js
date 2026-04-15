import "dotenv/config";
import fs from "fs";
import Database from "better-sqlite3";
import { recordRun } from "../src/maintenance.js";

// Configuration for retention cleanup. Deletes old orders according to the
// configured retention period and records the maintenance result.
const DB_PATH = process.env.KOF_DB_PATH || "kof.sqlite";
const RETENTION_DAYS = Number(process.env.KOF_ORDER_RETENTION_DAYS || 30);

// Finish the script with a recorded maintenance result and explicit process
// exit code.
function finish(ok, message) {
  try {
    recordRun({ dbPath: DB_PATH, job: "cleanup", ok, message });
  } catch {}

  console.log(message);
  process.exit(ok ? 0 : 1);
}

// Skip cleanup entirely when retention is disabled.
if (!RETENTION_DAYS || RETENTION_DAYS <= 0) {
  finish(true, "Order retention disabled (KOF_ORDER_RETENTION_DAYS <= 0).");
}

// Fail fast when the configured database file does not exist.
if (!fs.existsSync(DB_PATH)) {
  finish(false, `Database file not found: ${DB_PATH}`);
}

// Enable foreign key enforcement on this connection so cascading deletes and
// ON DELETE SET NULL rules are actually applied by SQLite.
const db = new Database(DB_PATH);

try {
  db.pragma("foreign_keys = ON");

// Delete orders older than the configured retention window. With foreign keys
// enabled, related order_items cascade and inventory_adjustments.order_id is
// set to NULL according to schema rules.
  const deleteOldOrders = db.prepare(`
    DELETE FROM orders
    WHERE created_at < datetime('now', 'localtime', ?)
  `);

  const runCleanup = db.transaction(() => {
    return deleteOldOrders.run(`-${RETENTION_DAYS} days`);
  });

  const result = runCleanup();

  db.close();

  finish(
    true,
    `Deleted ${result.changes} old orders (older than ${RETENTION_DAYS} days).`
  );
} catch (error) {
  try {
    db.close();
  } catch {}

  finish(false, `Cleanup failed: ${error.message}`);
}
