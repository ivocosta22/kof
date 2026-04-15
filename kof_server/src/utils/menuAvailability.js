import db from "../db.js";

// Calculate menu item availability from its recipe and current ingredient stock
export function getMenuItemAvailability(menuItemId, options = {}) {
  const requestedQty = Math.max(1, Number(options.requestedQty || 1));
  const recipeRows = db.prepare(`
    SELECT
      mii.qty_per_item,
      ing.name AS ingredient_name,
      ing.stock_qty,
      ing.low_stock_threshold,
      ing.is_active AS ingredient_is_active
    FROM menu_item_ingredients mii
    JOIN ingredients ing ON ing.id = mii.ingredient_id
    WHERE mii.menu_item_id = ?
    ORDER BY ing.name COLLATE NOCASE ASC, ing.id ASC
  `).all(menuItemId);

  if (!recipeRows.length) {
    return {
      availability: "no_recipe",
      limited_by: [],
      max_makeable_units: null
    };
  }

  let hasLowIngredient = false;
  const limitedBy = [];
  const counts = [];

  for (const row of recipeRows) {
    const qtyPerItem = Number(row.qty_per_item);
    const stockQty = Number(row.stock_qty);
    const lowStockThreshold = Number(row.low_stock_threshold);

    if (!row.ingredient_is_active) {
      limitedBy.push(row.ingredient_name);
      counts.push(0);
      continue;
    }

    if (qtyPerItem <= 0) {
      continue;
    }

    const units = Math.floor(stockQty / qtyPerItem);
    counts.push(units);

    if (stockQty <= lowStockThreshold) {
      hasLowIngredient = true;
    }

    if (units <= 0) {
      limitedBy.push(row.ingredient_name);
    }
  }

  const maxMakeable = counts.length ? Math.max(0, Math.min(...counts)) : null;
  const isUnavailableForRequest =
    maxMakeable !== null && maxMakeable < requestedQty;
  const isLowForRequest =
    maxMakeable !== null &&
    maxMakeable > 0 &&
    (maxMakeable <= requestedQty || maxMakeable === 1);

  let availability = "no_recipe";

  if ((maxMakeable ?? 0) <= 0 || isUnavailableForRequest) {
    availability = "unavailable";
  } else if (hasLowIngredient || isLowForRequest) {
    availability = "low";
  } else {
    availability = "available";
  }

  return {
    availability,
    limited_by: limitedBy,
    max_makeable_units: maxMakeable
  };
}
