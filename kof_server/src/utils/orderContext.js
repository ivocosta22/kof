// Normalize short text: trim, collapse whitespace, limit length
export function normalizeShortText(value, maxLen = 32) {
  return String(value ?? "")
    .trim()
    .replace(/\s+/g, " ")
    .slice(0, maxLen);
}

// Normalize a table label: allow letters, digits, hyphens, and spaces.
// Strips everything else and limits to 10 characters.
export function normalizeTableLabel(value) {
  return String(value ?? "")
    .trim()
    .replace(/[^A-Za-z0-9 \-]/g, "")
    .replace(/\s+/g, " ")
    .slice(0, 10)
    .trim();
}

// Validate fulfillment context. Throws a 400 error for any invalid state.
export function validateOrderContext(input) {
  const fulfillmentType = String(input?.fulfillment_type ?? "").trim();
  const customerLabel = normalizeShortText(input?.customer_label ?? "", 32);
  const tableLabel = normalizeTableLabel(input?.table_label ?? "");

  // Reject notes that exceed the limit rather than silently truncating
  const rawNote = String(input?.note ?? "");
  if (rawNote.length > 200) {
    const err = new Error("Note too long (max 200 characters)");
    err.statusCode = 400;
    throw err;
  }
  const note = normalizeShortText(rawNote, 200);

  if (!["counter_pickup", "table"].includes(fulfillmentType)) {
    const err = new Error("fulfillment_type must be counter_pickup or table");
    err.statusCode = 400;
    throw err;
  }

  if (fulfillmentType === "counter_pickup") {
    if (!customerLabel) {
      const err = new Error("Pickup name is required for counter pickup");
      err.statusCode = 400;
      throw err;
    }
    if (tableLabel) {
      const err = new Error("Table must be empty for counter pickup");
      err.statusCode = 400;
      throw err;
    }
  }

  if (fulfillmentType === "table") {
    if (!tableLabel) {
      const err = new Error("Table number is required for table orders");
      err.statusCode = 400;
      throw err;
    }
    if (customerLabel) {
      const err = new Error("Pickup name must be empty for table orders");
      err.statusCode = 400;
      throw err;
    }
  }

  return {
    fulfillment_type: fulfillmentType,
    customer_label: customerLabel,
    table_label: tableLabel,
    note,
  };
}
