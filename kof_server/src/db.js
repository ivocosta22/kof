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

if (!hasColumn("menu_items", "category")) {
  db.exec(`ALTER TABLE menu_items ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'`);
}

if (!hasColumn("menu_items", "has_sizes")) {
  db.exec(`ALTER TABLE menu_items ADD COLUMN has_sizes INTEGER NOT NULL DEFAULT 0`);
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
    INSERT INTO menu_items (name, description, price_cents, category, has_sizes)
    VALUES (?, ?, ?, ?, ?)
  `);

  // Espresso-based hot drinks (sizes available)
  insertMenuItem.run("Espresso", "Single shot, bold and intense", 150, "Espresso", 1);
  insertMenuItem.run("Americano", "Espresso topped up with hot water", 220, "Espresso", 1);
  insertMenuItem.run("Cappuccino", "Espresso, steamed milk and foam", 300, "Hot Drinks", 1);
  insertMenuItem.run("Latte", "Espresso with silky steamed milk", 320, "Hot Drinks", 1);
  insertMenuItem.run("Mocha", "Espresso, chocolate and steamed milk", 360, "Hot Drinks", 1);
  insertMenuItem.run("Hot Chocolate", "Rich melted chocolate with milk", 320, "Hot Drinks", 1);
  insertMenuItem.run("Tea", "Choice of black, green or herbal", 220, "Hot Drinks", 1);

  // Cold drinks (sizes available)
  insertMenuItem.run("Iced Latte", "Cold milk + espresso over ice", 350, "Cold Drinks", 1);
  insertMenuItem.run("Iced Coffee", "Chilled brewed coffee over ice", 300, "Cold Drinks", 1);
  insertMenuItem.run("Cold Brew", "Slow-steeped, smooth and bold", 380, "Cold Drinks", 1);

  // Pastries (no sizes)
  insertMenuItem.run("Butter Croissant", "Flaky French-style croissant", 220, "Pastries", 0);
  insertMenuItem.run("Chocolate Muffin", "Double chocolate, baked daily", 250, "Pastries", 0);
  insertMenuItem.run("Blueberry Muffin", "Bursting with real blueberries", 250, "Pastries", 0);
  insertMenuItem.run("Cinnamon Roll", "Warm, glazed and gooey", 280, "Pastries", 0);

  // Food (no sizes)
  insertMenuItem.run("Ham & Cheese Toastie", "Toasted sourdough sandwich", 480, "Food", 0);
  insertMenuItem.run("Avocado Toast", "Sourdough, avocado, sea salt", 520, "Food", 0);
}

export default db;
