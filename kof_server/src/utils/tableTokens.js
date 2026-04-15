import crypto from "crypto";
import { normalizeTableLabel } from "./orderContext.js";

const TABLE_TOKEN_SECRET =
  process.env.KOF_TABLE_TOKEN_SECRET ||
  process.env.KOF_TOKEN_SECRET ||
  "dev-table-token-secret";

// Create a deterministic HMAC token for a table label — embedded in QR code URLs
export function createTableToken(tableLabel) {
  const normalized = normalizeTableLabel(tableLabel);
  if (!normalized) return "";
  return crypto
    .createHmac("sha256", TABLE_TOKEN_SECRET)
    .update(normalized)
    .digest("hex");
}

// Verify that a submitted table token matches the expected label
export function verifyTableToken(tableLabel, token) {
  const normalized = normalizeTableLabel(tableLabel);
  const submitted = String(token || "").trim();

  if (!normalized || !submitted) return false;

  const expected = createTableToken(normalized);

  if (!expected || expected.length !== submitted.length) return false;

  try {
    return crypto.timingSafeEqual(
      Buffer.from(expected, "utf8"),
      Buffer.from(submitted, "utf8")
    );
  } catch {
    return false;
  }
}
