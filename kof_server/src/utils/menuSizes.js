// Standard size options offered for items where has_sizes = 1.
// price_cents_delta is added on top of the menu item's base price_cents
// (which represents the Medium / default size).
export const SIZE_OPTIONS = [
  { name: "Small", price_cents_delta: -50 },
  { name: "Medium", price_cents_delta: 0 },
  { name: "Large", price_cents_delta: 50 },
  { name: "Xtra Large", price_cents_delta: 100 },
];

export const DEFAULT_SIZE_NAME = "Medium";

const sizeByName = new Map(SIZE_OPTIONS.map((size) => [size.name, size]));

export function getSizeOption(name) {
  return sizeByName.get(name) || null;
}

// Resolve the chosen size for a menu item line — returns the size delta to add
// to the base price. Throws if the requested size is invalid or if the item
// does not support sizes but a size was requested.
export function resolveLineSize(menuItem, requestedSizeName) {
  if (!menuItem.has_sizes) {
    if (requestedSizeName && requestedSizeName !== "") {
      const err = new Error(`size not supported for: ${menuItem.name}`);
      err.statusCode = 400;
      throw err;
    }
    return { name: "", delta: 0 };
  }

  const name = requestedSizeName || DEFAULT_SIZE_NAME;
  const size = getSizeOption(name);
  if (!size) {
    const err = new Error(`invalid size for: ${menuItem.name}`);
    err.statusCode = 400;
    throw err;
  }
  return { name: size.name, delta: size.price_cents_delta };
}

// Pull a size choice out of a chosen_modifiers array, looking for entries of
// the form "size:Large" (string). Returns the size name or null if none is
// present. Lets the legacy customer-page cart pass size info via modifiers
// instead of needing a dedicated `size` field on every order line.
export function extractSizeFromModifiers(modifiers) {
  if (!Array.isArray(modifiers)) return null;
  for (const m of modifiers) {
    if (typeof m !== "string") continue;
    if (m.startsWith("size:")) return m.slice(5);
  }
  return null;
}
