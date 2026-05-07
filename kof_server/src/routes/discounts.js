import express from "express";
import db from "../db.js";
import { requireAdmin } from "../adminAuth.js";

const router = express.Router();

// Today's date in YYYY-MM-DD (local). Used to filter expired/upcoming
// discounts on the public endpoint.
function today() {
  return db.prepare(`SELECT date('now','localtime') AS d`).get().d;
}

function rowToJson(row) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    percentage_off: Number(row.percentage_off) || 0,
    amount_off_cents: Number(row.amount_off_cents) || 0,
    code: row.code,
    valid_from: row.valid_from,
    valid_until: row.valid_until,
    is_active: !!row.is_active,
    required_category: row.required_category || "",
    target_category: row.target_category || "",
    target_qty: Number(row.target_qty) || 0,
    created_at: row.created_at,
  };
}

// Validate a YYYY-MM-DD string (or empty). Returns the trimmed value or
// throws a 400-friendly error.
function validateIsoDate(value, fieldName) {
  const v = String(value ?? "").trim();
  if (v === "") return "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(v)) {
    const err = new Error(`${fieldName} must be in YYYY-MM-DD format`);
    err.statusCode = 400;
    throw err;
  }
  return v;
}

function validateDiscountFields(body, { partial = false } = {}) {
  const out = {};

  if (!partial || body.title !== undefined) {
    const title = String(body.title ?? "").trim();
    if (!title) {
      const err = new Error("title required");
      err.statusCode = 400;
      throw err;
    }
    if (title.length > 80) {
      const err = new Error("title too long (max 80)");
      err.statusCode = 400;
      throw err;
    }
    out.title = title;
  }

  if (!partial || body.description !== undefined) {
    out.description = String(body.description ?? "").trim().slice(0, 240);
  }

  if (!partial || body.percentage_off !== undefined) {
    const n = Math.max(0, Math.min(100, Math.floor(Number(body.percentage_off ?? 0))));
    out.percentage_off = Number.isFinite(n) ? n : 0;
  }

  if (!partial || body.amount_off_cents !== undefined) {
    const n = Math.max(0, Math.floor(Number(body.amount_off_cents ?? 0)));
    out.amount_off_cents = Number.isFinite(n) ? n : 0;
  }

  if (!partial || body.code !== undefined) {
    out.code = String(body.code ?? "").trim().toUpperCase().slice(0, 32);
  }

  if (!partial || body.valid_from !== undefined) {
    out.valid_from = validateIsoDate(body.valid_from, "valid_from");
  }

  if (!partial || body.valid_until !== undefined) {
    out.valid_until = validateIsoDate(body.valid_until, "valid_until");
  }

  if (!partial || body.is_active !== undefined) {
    out.is_active = body.is_active === false || body.is_active === 0 ? 0 : 1;
  }

  if (!partial || body.required_category !== undefined) {
    out.required_category = String(body.required_category ?? "").trim().slice(0, 200);
  }

  if (!partial || body.target_category !== undefined) {
    out.target_category = String(body.target_category ?? "").trim().slice(0, 200);
  }

  if (!partial || body.target_qty !== undefined) {
    const n = Math.max(0, Math.floor(Number(body.target_qty ?? 0)));
    out.target_qty = Number.isFinite(n) ? n : 0;
  }

  // Cross-field rule: at least one of percentage_off / amount_off_cents must
  // be > 0 on a full-write (POST). For PATCH we only enforce when both are
  // provided, since the existing row may already satisfy the rule.
  if (!partial) {
    if ((out.percentage_off || 0) === 0 && (out.amount_off_cents || 0) === 0) {
      const err = new Error("either percentage_off or amount_off_cents must be > 0");
      err.statusCode = 400;
      throw err;
    }
  }

  return out;
}

// GET / — list active discounts that are valid today (public, used by app).
router.get("/", (req, res) => {
  const t = today();
  const rows = db.prepare(`
    SELECT id, title, description, percentage_off, amount_off_cents, code,
           valid_from, valid_until, is_active,
           required_category, target_category, target_qty, created_at
    FROM discounts
    WHERE is_active = 1
      AND (valid_from = '' OR valid_from <= ?)
      AND (valid_until = '' OR valid_until >= ?)
    ORDER BY id DESC
  `).all(t, t);
  res.json({ discounts: rows.map(rowToJson) });
});

// GET /admin — list all discounts including inactive/expired (manager only).
router.get("/admin", requireAdmin("manager"), (req, res) => {
  const rows = db.prepare(`
    SELECT id, title, description, percentage_off, amount_off_cents, code,
           valid_from, valid_until, is_active,
           required_category, target_category, target_qty, created_at
    FROM discounts
    ORDER BY id DESC
  `).all();
  res.json({ discounts: rows.map(rowToJson) });
});

// POST /admin — create a discount (manager only).
router.post("/admin", requireAdmin("manager"), (req, res) => {
  let fields;
  try {
    fields = validateDiscountFields(req.body ?? {});
  } catch (e) {
    return res.status(e.statusCode || 400).json({ error: e.message });
  }

  const result = db.prepare(`
    INSERT INTO discounts
      (title, description, percentage_off, amount_off_cents, code,
       valid_from, valid_until, is_active,
       required_category, target_category, target_qty)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    fields.title,
    fields.description ?? "",
    fields.percentage_off ?? 0,
    fields.amount_off_cents ?? 0,
    fields.code ?? "",
    fields.valid_from ?? "",
    fields.valid_until ?? "",
    fields.is_active ?? 1,
    fields.required_category ?? "",
    fields.target_category ?? "",
    fields.target_qty ?? 0
  );

  res.status(201).json({ id: result.lastInsertRowid });
});

// PATCH /admin/:id — update a discount (manager only).
router.patch("/admin/:id", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }

  const existing = db.prepare(`SELECT id FROM discounts WHERE id = ?`).get(id);
  if (!existing) return res.status(404).json({ error: "not found" });

  let fields;
  try {
    fields = validateDiscountFields(req.body ?? {}, { partial: true });
  } catch (e) {
    return res.status(e.statusCode || 400).json({ error: e.message });
  }

  const sets = [];
  const values = [];
  for (const [key, value] of Object.entries(fields)) {
    sets.push(`${key} = ?`);
    values.push(value);
  }
  if (sets.length === 0) {
    return res.status(400).json({ error: "no fields to update" });
  }
  values.push(id);
  db.prepare(`UPDATE discounts SET ${sets.join(", ")} WHERE id = ?`).run(...values);
  res.json({ ok: true });
});

// DELETE /admin/:id — remove a discount (manager only).
router.delete("/admin/:id", requireAdmin("manager"), (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    return res.status(400).json({ error: "invalid id" });
  }
  const result = db.prepare(`DELETE FROM discounts WHERE id = ?`).run(id);
  if (result.changes === 0) return res.status(404).json({ error: "not found" });
  res.json({ ok: true });
});

export default router;
