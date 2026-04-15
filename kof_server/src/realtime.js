import { verifyToken } from "./adminAuth.js";

export async function createRealtimeServer(httpServer) {
  const { WebSocketServer } = await import("ws");
  const wss = new WebSocketServer({ server: httpServer });

  // Broadcast a realtime event to connected clients.
  // staffOnly=true restricts delivery to authenticated (staff) connections.
  function broadcast(typeOrMessage, payload, { staffOnly = false } = {}) {
    const message =
      typeof typeOrMessage === "string"
        ? { type: typeOrMessage, payload }
        : typeOrMessage;

    const data = JSON.stringify(message);

    for (const client of wss.clients) {
      if (client.readyState === 1) {
        if (!staffOnly || client.isAuthenticated) {
          client.send(data);
        }
      }
    }
  }

  // Count currently open realtime connections
  function getClientCount() {
    let count = 0;
    for (const client of wss.clients) {
      if (client.readyState === 1) count += 1;
    }
    return count;
  }

  // Close all clients then shut down the WebSocket server
  function close() {
    for (const client of wss.clients) {
      try {
        client.close(1001, "Server shutting down");
      } catch {}
    }
    return new Promise((resolve) => {
      wss.close(() => resolve());
    });
  }

  // Authenticate connections on upgrade.
  // Staff clients pass ?token=... in the URL; customer clients connect anonymously.
  // staffOnly broadcasts (e.g. order_created) are withheld from anonymous clients.
  wss.on("connection", (ws, req) => {
    const url = new URL(req.url, "http://localhost");
    const token = url.searchParams.get("token");
    const payload = verifyToken(token);
    ws.isAuthenticated = !!payload;

    ws.send(
      JSON.stringify({
        type: "realtime_connected",
        payload: { ok: true },
      })
    );
  });

  return { wss, broadcast, getClientCount, close };
}
