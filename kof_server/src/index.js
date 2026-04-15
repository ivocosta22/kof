import express from "express";
import cors from "cors";
import http from "http";
import path from "path";
import { fileURLToPath } from "url";
import "dotenv/config";

import db from "./db.js";
import adminRouter from "./routes/admin.js";
import menuRouter from "./routes/menu.js";
import createOrdersRouter from "./routes/orders.js";
import { createRealtimeServer } from "./realtime.js";

const app = express();
app.disable("x-powered-by");

// KOF_CORS_ORIGIN controls allowed web origins (default: * for local-network use).
// Set to a specific origin for production web deployments.
// Flutter native clients do not use CORS.
const corsOrigin = process.env.KOF_CORS_ORIGIN || "*";
app.use(cors({ origin: corsOrigin }));
app.use(express.json());

const server = http.createServer(app);
const realtime = await createRealtimeServer(server);
const { broadcast } = realtime;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const publicDir = path.join(__dirname, "../public");
const pagesDir = path.join(publicDir, "pages");
const cssDir = path.join(publicDir, "css");
const jsDir = path.join(publicDir, "js");
const audioDir = path.join(publicDir, "audio");
const vendorDir = path.join(__dirname, "../node_modules");

// Simple liveness check
app.get("/health", (req, res) => {
  res.json({ ok: true });
});

// Detailed health diagnostics: DB, uptime, memory, WebSocket client count
app.get("/api/health", (req, res) => {
  let dbOk = true;
  let dbMessage = "ok";

  try {
    db.prepare("SELECT 1").get();
  } catch (error) {
    dbOk = false;
    dbMessage = error?.message || String(error);
  }

  const memoryUsage = process.memoryUsage();

  res.json({
    ok: true,
    uptime_seconds: Math.floor(process.uptime()),
    db: dbOk ? "connected" : "error",
    db_message: dbMessage,
    websocket_clients:
      typeof realtime.getClientCount === "function"
        ? realtime.getClientCount()
        : null,
    memory_mb: {
      rss: Math.round(memoryUsage.rss / 1024 / 1024),
      heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
      heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
    },
  });
});

// Runtime maintenance status and retention settings
app.get("/api/status", (req, res) => {
  const maintenanceRows = db
    .prepare("SELECT job, last_run_at, ok, message FROM maintenance_runs")
    .all();

  const maintenanceByJob = Object.fromEntries(
    maintenanceRows.map((row) => [row.job, row])
  );

  res.json({
    ok: true,
    retention_days: Number(process.env.KOF_ORDER_RETENTION_DAYS || 0),
    backup_keep_days: Number(process.env.KOF_BACKUP_KEEP_DAYS || 0),
    maintenance: maintenanceByJob,
  });
});

// Frontend runtime config
app.get("/api/config", (req, res) => {
  res.json({
    public_base_url: String(process.env.KOF_PUBLIC_BASE_URL || "").trim(),
  });
});

// Service discovery endpoint for Flutter clients on the local network.
// Returns server identity and shop profile so clients can confirm they found the right Kof instance.
app.get("/api/info", (req, res) => {
  const rows = db
    .prepare(
      `SELECT key, value FROM shop_settings WHERE key IN ('shop_name', 'shop_description')`
    )
    .all();
  const s = Object.fromEntries(rows.map((r) => [r.key, r.value]));

  res.json({
    name: "Kof",
    version: "1.0.0",
    shop_name: s.shop_name || "",
    shop_description: s.shop_description || "",
  });
});

app.use("/api/admin", adminRouter);
app.use("/api/menu", menuRouter);
app.use("/api/orders", createOrdersRouter({ broadcast }));

app.use("/css", express.static(cssDir));
app.use("/js", express.static(jsDir));
app.use("/audio", express.static(audioDir));
app.use("/vendor", express.static(vendorDir));

const pageRoutes = {
  "/": "index.html",
  "/index.html": "index.html",
  "/item.html": "item.html",
  "/cart.html": "cart.html",
  "/orders.html": "orders.html",
  "/order.html": "order.html",
  "/login.html": "login.html",
  "/staff.html": "staff.html",
  "/admin.html": "admin.html",
  "/settings.html": "settings.html",
  "/inventory.html": "inventory.html",
  "/receipt.html": "receipt.html",
  "/history.html": "history.html",
};

for (const [routePath, fileName] of Object.entries(pageRoutes)) {
  app.get(routePath, (req, res) => {
    res.sendFile(path.join(pagesDir, fileName));
  });
}

app.use(express.static(publicDir));

const PORT = process.env.PORT || 3000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Kof server running on http://0.0.0.0:${PORT}`);
});

let isShuttingDown = false;

async function shutdown(signal) {
  if (isShuttingDown) return;
  isShuttingDown = true;
  console.log(`[shutdown] Received ${signal}. Closing...`);

  server.close(() => {
    console.log("[shutdown] HTTP server closed.");
  });

  try {
    if (typeof realtime.close === "function") {
      await realtime.close();
      console.log("[shutdown] WebSocket server closed.");
    }
  } catch (error) {
    console.log("[shutdown] Error closing WebSocket:", error?.message || error);
  }

  try {
    if (typeof db?.close === "function") {
      db.close();
      console.log("[shutdown] DB closed.");
    }
  } catch (error) {
    console.log("[shutdown] Error closing DB:", error?.message || error);
  }

  setTimeout(() => process.exit(0), 1500).unref();
}

process.on("SIGTERM", () => { shutdown("SIGTERM"); });
process.on("SIGINT", () => { shutdown("SIGINT"); });
