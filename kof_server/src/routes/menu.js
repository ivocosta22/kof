import express from "express";
import db from "../db.js";
import { getMenuItemAvailability } from "../utils/menuAvailability.js";
import { SIZE_OPTIONS } from "../utils/menuSizes.js";

const router = express.Router();

// GET / — return active menu items with computed availability metadata
router.get("/", (req, res) => {
  const items = db.prepare(`
    SELECT id, name, description, price_cents, is_active, category, has_sizes
    FROM menu_items
    WHERE is_active = 1
    ORDER BY id ASC
  `).all();

  const enrichedItems = items.map((item) => {
    const availabilityInfo = getMenuItemAvailability(item.id);

    return {
      ...item,
      has_sizes: !!item.has_sizes,
      sizes: item.has_sizes ? SIZE_OPTIONS : [],
      availability: availabilityInfo.availability,
      limited_by: availabilityInfo.limited_by,
      max_makeable_units: availabilityInfo.max_makeable_units,
    };
  });

  res.json({ items: enrichedItems, size_options: SIZE_OPTIONS });
});

export default router;