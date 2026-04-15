import Database from "better-sqlite3";
import fs from "fs";

const dbPath = process.env.KOF_DB_PATH || "kof.sqlite";
const db = new Database(dbPath);
db.pragma("foreign_keys = ON");

// Apply the schema on startup — schema.sql is the source of truth for base tables and indexes
const schema = fs.readFileSync(
  new URL("./schema.sql", import.meta.url),
  "utf8"
);

db.exec(schema);

// Check whether a table already contains a column (used for backwards-safe migrations)
function hasColumn(tableName, columnName) {
  const columns = db.prepare(`PRAGMA table_info(${tableName})`).all();
  return columns.some((column) => column.name === columnName);
}

// Backwards-safe column additions for databases created before these fields existed
if (!hasColumn("orders", "inventory_deducted_at")) {
  db.exec(`ALTER TABLE orders ADD COLUMN inventory_deducted_at TEXT DEFAULT NULL`);
}

if (!hasColumn("orders", "fulfillment_type")) {
  db.exec(`ALTER TABLE orders ADD COLUMN fulfillment_type TEXT NOT NULL DEFAULT 'counter_pickup'`);
}

if (!hasColumn("orders", "table_label")) {
  db.exec(`ALTER TABLE orders ADD COLUMN table_label TEXT DEFAULT ''`);
}

// Normalize legacy order rows after migrations so fulfillment fields are always consistent
db.exec(`
  UPDATE orders
  SET fulfillment_type = CASE
    WHEN trim(COALESCE(table_label, '')) <> '' THEN 'table'
    ELSE 'counter_pickup'
  END
  WHERE fulfillment_type IS NULL
     OR fulfillment_type NOT IN ('counter_pickup', 'table')
`);

db.exec(`UPDATE orders SET table_label = '' WHERE table_label IS NULL`);
db.exec(`UPDATE orders SET customer_label = '' WHERE customer_label IS NULL`);

// Clean up expired revoked tokens on each startup
db.prepare(`DELETE FROM revoked_tokens WHERE expires_at < ?`).run(Date.now());

// Seed initial menu items only when the menu is empty
const menuItemCountRow = db.prepare("SELECT COUNT(*) AS count FROM menu_items").get();

if (menuItemCountRow.count === 0) {
  const insertMenuItem = db.prepare(`
    INSERT INTO menu_items (name, description, price_cents)
    VALUES (?, ?, ?)
  `);

  insertMenuItem.run("Espresso", "Single shot", 150);
  insertMenuItem.run("Cappuccino", "Espresso + milk foam", 300);
  insertMenuItem.run("Iced Latte", "Cold milk + espresso", 350);
}

export default db;
