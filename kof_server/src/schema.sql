PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS menu_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  price_cents INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  category TEXT NOT NULL DEFAULT 'Other',
  has_sizes INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number INTEGER NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('new','making','ready','completed','cancelled')) DEFAULT 'new',
  payment_status TEXT NOT NULL CHECK(payment_status IN ('unpaid','paid')) DEFAULT 'unpaid',
  fulfillment_type TEXT NOT NULL CHECK(fulfillment_type IN ('counter_pickup','table')) DEFAULT 'counter_pickup',
  customer_label TEXT DEFAULT '',
  table_label TEXT DEFAULT '',
  note TEXT DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  created_date TEXT NOT NULL DEFAULT (date('now','localtime')),
  inventory_deducted_at TEXT DEFAULT NULL,
  CHECK (
    (fulfillment_type = 'counter_pickup' AND trim(customer_label) <> '' AND trim(table_label) = '')
    OR
    (fulfillment_type = 'table' AND trim(table_label) <> '' AND trim(customer_label) = '')
  )
);

CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  menu_item_id INTEGER NOT NULL,
  qty INTEGER NOT NULL,
  chosen_modifiers_json TEXT NOT NULL DEFAULT '[]',
  line_total_cents INTEGER NOT NULL,
  FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS admin_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  pin_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('manager','barista')) DEFAULT 'manager',
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS admin_user_settings (
  admin_user_id INTEGER PRIMARY KEY,
  volume REAL NOT NULL DEFAULT 0.5,
  dark_mode INTEGER NOT NULL DEFAULT 0,
  language TEXT NOT NULL DEFAULT 'en' CHECK(language IN ('en','pt','fi')),
  FOREIGN KEY(admin_user_id) REFERENCES admin_users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS maintenance_runs (
  job TEXT PRIMARY KEY,
  last_run_at TEXT NOT NULL,
  ok INTEGER NOT NULL,
  message TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  unit TEXT NOT NULL DEFAULT 'g',
  stock_qty REAL NOT NULL DEFAULT 0,
  low_stock_threshold REAL NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
);

CREATE TABLE IF NOT EXISTS menu_item_ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  menu_item_id INTEGER NOT NULL,
  ingredient_id INTEGER NOT NULL,
  qty_per_item REAL NOT NULL,
  UNIQUE(menu_item_id, ingredient_id),
  FOREIGN KEY(menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,
  FOREIGN KEY(ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inventory_adjustments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ingredient_id INTEGER NOT NULL,
  delta_qty REAL NOT NULL,
  reason TEXT NOT NULL CHECK(reason IN ('restock','waste','manual','order_completion')),
  note TEXT DEFAULT '',
  order_id INTEGER,
  admin_user_id INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  FOREIGN KEY(ingredient_id) REFERENCES ingredients(id) ON DELETE CASCADE,
  FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE SET NULL,
  FOREIGN KEY(admin_user_id) REFERENCES admin_users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_created_date_order_number
ON orders(created_date, order_number);

CREATE INDEX IF NOT EXISTS idx_orders_status_created_at
ON orders(status, created_at);

CREATE INDEX IF NOT EXISTS idx_menu_item_ingredients_menu_item
ON menu_item_ingredients(menu_item_id);

CREATE INDEX IF NOT EXISTS idx_menu_item_ingredients_ingredient
ON menu_item_ingredients(ingredient_id);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustments_ingredient_created_at
ON inventory_adjustments(ingredient_id, created_at);

CREATE TABLE IF NOT EXISTS shop_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS revoked_tokens (
  jti TEXT PRIMARY KEY,
  expires_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  admin_user_id INTEGER,
  action TEXT NOT NULL,
  target_type TEXT,
  target_id INTEGER,
  detail TEXT DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  FOREIGN KEY(admin_user_id) REFERENCES admin_users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS order_status_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by INTEGER,
  changed_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
  FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY(changed_by) REFERENCES admin_users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_log_created_at
ON audit_log(admin_user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at
ON revoked_tokens(expires_at);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id
ON order_status_history(order_id);
