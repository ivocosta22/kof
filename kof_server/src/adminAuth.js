import crypto from "crypto";
import db from "./db.js";

const TOKEN_SECRET = process.env.KOF_TOKEN_SECRET;
const effectiveSecret = TOKEN_SECRET || "dev-unsafe-secret";

if (!TOKEN_SECRET) {
  console.warn("WARNING: KOF_TOKEN_SECRET is not set. Set it for security.");
}

// In-memory login attempt tracking (resets on restart)
const loginAttempts = new Map();
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;

// Hash admin PIN using scrypt with a random salt
export function hashPin(pin) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(String(pin), salt, 32);
  return `scrypt$${salt.toString("base64")}$${hash.toString("base64")}`;
}

// Verify a plaintext PIN against a stored scrypt hash
export function verifyPin(pin, stored) {
  try {
    const [algorithm, saltBase64, hashBase64] = stored.split("$");
    if (algorithm !== "scrypt") return false;
    const salt = Buffer.from(saltBase64, "base64");
    const expectedHash = Buffer.from(hashBase64, "base64");
    const actualHash = crypto.scryptSync(String(pin), salt, expectedHash.length);
    return crypto.timingSafeEqual(actualHash, expectedHash);
  } catch {
    return false;
  }
}

// Sign a token — payload is HMAC-signed, includes a unique jti for revocation
export function signToken(payload) {
  const jti = crypto.randomBytes(16).toString("hex");
  const body = Buffer.from(
    JSON.stringify({ ...payload, jti }),
    "utf8"
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", effectiveSecret)
    .update(body)
    .digest("hex");
  return `${body}.${signature}`;
}

// Verify a token and return its payload, or null on any failure
export function verifyToken(token) {
  if (!token || typeof token !== "string") return null;
  const parts = token.split(".");
  if (parts.length !== 2) return null;
  const [body, signature] = parts;
  const expectedSignature = crypto
    .createHmac("sha256", effectiveSecret)
    .update(body)
    .digest("hex");
  if (signature !== expectedSignature) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
    if (payload.exp && Date.now() > payload.exp) return null;
    return payload;
  } catch {
    return null;
  }
}

// Add a token's jti to the revoked_tokens table so it can no longer be used
export function revokeToken(token) {
  const payload = verifyToken(token);
  if (!payload?.jti) return false;
  db.prepare(`
    INSERT OR IGNORE INTO revoked_tokens (jti, expires_at)
    VALUES (?, ?)
  `).run(payload.jti, payload.exp ?? (Date.now() + 7 * 24 * 60 * 60 * 1000));
  return true;
}

// Return seconds remaining in lockout, or null if not locked out
export function getLoginLockoutSeconds(username) {
  const entry = loginAttempts.get(username);
  if (!entry?.lockedUntil) return null;
  const remaining = entry.lockedUntil - Date.now();
  return remaining > 0 ? Math.ceil(remaining / 1000) : null;
}

// Record a login attempt; on success clears the counter, on failure increments and potentially locks
export function recordLoginAttempt(username, success) {
  if (success) {
    loginAttempts.delete(username);
    return;
  }
  const entry = loginAttempts.get(username) ?? { count: 0, lockedUntil: null };
  if (entry.lockedUntil && Date.now() >= entry.lockedUntil) {
    entry.count = 0;
    entry.lockedUntil = null;
  }
  entry.count += 1;
  if (entry.count >= MAX_LOGIN_ATTEMPTS) {
    entry.lockedUntil = Date.now() + LOCKOUT_MS;
  }
  loginAttempts.set(username, entry);
}

// Middleware: require a valid, non-revoked token from an active user
export function requireAdmin(role = "manager") {
  return (req, res, next) => {
    const authorizationHeader = req.headers.authorization || "";
    const token = authorizationHeader.startsWith("Bearer ")
      ? authorizationHeader.slice(7)
      : null;

    const payload = verifyToken(token);
    if (!payload) {
      return res.status(401).json({ error: "unauthorized" });
    }

    // Check token not revoked
    if (payload.jti) {
      const revoked = db.prepare(
        `SELECT 1 FROM revoked_tokens WHERE jti = ?`
      ).get(payload.jti);
      if (revoked) return res.status(401).json({ error: "unauthorized" });
    }

    // Check user still active in DB on every request
    const user = db.prepare(
      `SELECT id, role, is_active FROM admin_users WHERE id = ?`
    ).get(payload.sub);

    if (!user || user.is_active !== 1) {
      return res.status(401).json({ error: "unauthorized" });
    }

    const isAllowed =
      role === "barista"
        ? user.role === "barista" || user.role === "manager"
        : user.role === "manager";

    if (!isAllowed) {
      return res.status(403).json({ error: "forbidden" });
    }

    req.admin = { ...payload, role: user.role };
    next();
  };
}

// Seed the default admin account on first boot with a random 6-digit PIN
export function ensureDefaultAdmin() {
  const row = db.prepare("SELECT COUNT(*) AS count FROM admin_users").get();
  if (row.count === 0) {
    const pin = String(Math.floor(100000 + Math.random() * 900000));
    const pinHash = hashPin(pin);
    db.prepare(`
      INSERT INTO admin_users (username, pin_hash, role)
      VALUES (?, ?, ?)
    `).run("admin", pinHash, "manager");
    console.log("\n================================================");
    console.log("  Default admin account created");
    console.log("  Username : admin");
    console.log(`  PIN      : ${pin}`);
    console.log("  Change this PIN immediately via Settings.");
    console.log("================================================\n");
  }
}
