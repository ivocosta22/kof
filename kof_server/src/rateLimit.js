// Create a simple in-memory IP rate limiter for local LAN use
export function createIpRateLimiter({
  windowMs = 60_000,
  max = 10,
  message = "Too many orders. Please wait a moment and try again.",
} = {}) {
  const buckets = new Map();

  // Periodically remove expired buckets to keep memory bounded
  setInterval(() => {
    const now = Date.now();
    for (const [ip, bucket] of buckets.entries()) {
      if (bucket.resetAt <= now) buckets.delete(ip);
    }
  }, Math.max(10_000, windowMs)).unref?.();

  return function rateLimitMiddleware(req, res, next) {
    const ip = req.ip || req.socket?.remoteAddress || "unknown";
    const now = Date.now();

    let bucket = buckets.get(ip);

    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + windowMs };
      buckets.set(ip, bucket);
    }

    bucket.count += 1;

    if (bucket.count > max) {
      const retryAfterSeconds = Math.ceil((bucket.resetAt - now) / 1000);
      res.setHeader("Retry-After", String(retryAfterSeconds));
      return res.status(429).json({
        error: message,
        retry_after_seconds: retryAfterSeconds,
      });
    }

    next();
  };
}
