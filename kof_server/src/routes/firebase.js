import express from "express";
import db from "../db.js";
import { requireAdmin } from "../adminAuth.js";
import { getFirestore, isReady } from "../firebase.js";

const router = express.Router();

function firestoreGuard(res) {
  if (!isReady()) {
    res.status(503).json({
      error:
        "Firestore not configured. Set FIREBASE_SERVICE_ACCOUNT_PATH in .env and restart.",
    });
    return false;
  }
  return true;
}

function getShopSetting(key) {
  return db.prepare(`SELECT value FROM shop_settings WHERE key = ?`).get(key)
    ?.value ?? null;
}

function setShopSetting(key, value) {
  db.prepare(
    `INSERT OR REPLACE INTO shop_settings (key, value) VALUES (?, ?)`
  ).run(key, value);
}

// GET /firebase/connectivity — check whether the server can reach the internet
router.get("/connectivity", requireAdmin("barista"), async (req, res) => {
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 4000);
    await fetch("https://firestore.googleapis.com/", {
      method: "HEAD",
      signal: ctrl.signal,
    });
    clearTimeout(timer);
    res.json({ online: true });
  } catch {
    res.json({ online: false });
  }
});

// GET /firebase/shop — return current Firestore registration state
router.get("/shop", requireAdmin("barista"), (req, res) => {
  const firestoreShopId = getShopSetting("firestore_shop_id");
  res.json({
    registered: !!firestoreShopId,
    firestore_shop_id: firestoreShopId,
    name: getShopSetting("shop_name") ?? "",
    description: getShopSetting("shop_description") ?? "",
    address: getShopSetting("firestore_address") ?? "",
    latitude: Number(getShopSetting("firestore_lat")) || null,
    longitude: Number(getShopSetting("firestore_lng")) || null,
    country: getShopSetting("firestore_country") ?? "",
    photo_url: getShopSetting("firestore_photo_url") ?? "",
    tags: (() => {
      try {
        return JSON.parse(getShopSetting("firestore_tags") ?? "[]");
      } catch {
        return [];
      }
    })(),
    phone: getShopSetting("firestore_phone") ?? "",
    rating: Number(getShopSetting("firestore_rating")) || null,
    server_url: getShopSetting("firestore_server_url") ?? "",
  });
});

// PATCH /firebase/shop/draft — save form data locally without publishing to Firestore
router.patch("/shop/draft", requireAdmin("manager"), (req, res) => {
  const {
    name = "",
    description = "",
    address = "",
    latitude,
    longitude,
    country = "",
    photo_url: photoUrl = "",
    tags = [],
    phone = "",
    server_url: serverUrl = "",
  } = req.body ?? {};

  const lat = Number(latitude);
  const lng = Number(longitude);

  if (name) setShopSetting("shop_name", String(name).trim());
  if (description !== undefined) setShopSetting("shop_description", String(description).trim());
  setShopSetting("firestore_address", String(address).trim());
  if (Number.isFinite(lat)) setShopSetting("firestore_lat", String(lat));
  if (Number.isFinite(lng)) setShopSetting("firestore_lng", String(lng));
  setShopSetting("firestore_country", String(country).trim().toUpperCase());
  setShopSetting("firestore_photo_url", String(photoUrl).trim());
  setShopSetting(
    "firestore_tags",
    JSON.stringify(
      Array.isArray(tags) ? tags.map((t) => String(t).trim()).filter(Boolean) : []
    )
  );
  setShopSetting("firestore_phone", String(phone).trim());
  setShopSetting("firestore_server_url", String(serverUrl).trim());

  res.json({ ok: true });
});

// PUT /firebase/shop — create or update this shop's Firestore document (manager only)
router.put("/shop", requireAdmin("manager"), async (req, res) => {
  if (!firestoreGuard(res)) return;

  const {
    name: bodyName,
    description: bodyDescription = "",
    address,
    latitude,
    longitude,
    country,
    photo_url: photoUrl = "",
    tags = [],
    phone = "",
    server_url: bodyServerUrl = "",
  } = req.body ?? {};

  if (!address || !country) {
    return res.status(400).json({ error: "address and country are required" });
  }

  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return res.status(400).json({ error: "valid latitude and longitude are required" });
  }

  const name = (bodyName ? String(bodyName).trim() : null) || getShopSetting("shop_name") || "Unnamed Shop";
  const description = bodyDescription !== undefined ? String(bodyDescription).trim() : (getShopSetting("shop_description") || "");

  const firestore = getFirestore();
  const { FieldValue, GeoPoint } = await import("firebase-admin/firestore");
  const serverUrl = String(bodyServerUrl).trim() || getShopSetting("firestore_server_url") || null;
  const rawShopData = {
    name,
    description: description || null,
    address: String(address).trim(),
    location: new GeoPoint(lat, lng),
    country: String(country).trim().toUpperCase(),
    photoUrl: String(photoUrl).trim() || null,
    tags: Array.isArray(tags)
      ? tags.map((t) => String(t).trim()).filter(Boolean)
      : [],
    phone: String(phone).trim() || null,
    serverUrl: serverUrl,
    updatedAt: FieldValue.serverTimestamp(),
  };
  // Strip null/undefined so empty optional fields don't appear in Firestore
  const shopData = Object.fromEntries(
    Object.entries(rawShopData).filter(([, v]) => v !== null && v !== undefined)
  );

  try {
    let shopId = getShopSetting("firestore_shop_id");
    if (shopId) {
      await firestore.collection("shops").doc(shopId).update(shopData);
    } else {
      const ref = await firestore.collection("shops").add({
        ...shopData,
        createdAt: FieldValue.serverTimestamp(),
      });
      shopId = ref.id;
      setShopSetting("firestore_shop_id", shopId);
    }

    // Persist values locally for the GET endpoint
    setShopSetting("shop_name", name);
    setShopSetting("shop_description", description);
    setShopSetting("firestore_address", address);
    setShopSetting("firestore_lat", String(lat));
    setShopSetting("firestore_lng", String(lng));
    setShopSetting("firestore_country", String(country).trim().toUpperCase());
    setShopSetting("firestore_photo_url", photoUrl);
    setShopSetting("firestore_tags", JSON.stringify(shopData.tags));
    setShopSetting("firestore_phone", phone);
    if (serverUrl) setShopSetting("firestore_server_url", serverUrl);

    res.json({ ok: true, firestore_shop_id: shopId });
  } catch (err) {
    console.error("[firebase] shop upsert failed:", err);
    res.status(500).json({ error: "Firestore write failed: " + err.message });
  }
});

// GET /firebase/broadcasts — list this shop's recent broadcasts (manager only)
// Reads from shops/{shopId}/broadcasts ordered by createdAt desc.
router.get("/broadcasts", requireAdmin("manager"), async (req, res) => {
  if (!firestoreGuard(res)) return;
  const shopId = getShopSetting("firestore_shop_id");
  if (!shopId) {
    return res.status(404).json({
      error: "shop not registered on Firestore — publish from the platform panel first",
    });
  }

  try {
    const snap = await getFirestore()
      .collection("shops")
      .doc(shopId)
      .collection("broadcasts")
      .orderBy("createdAt", "desc")
      .limit(20)
      .get();

    const broadcasts = snap.docs.map((doc) => {
      const data = doc.data() || {};
      const createdAt = data.createdAt?.toDate?.() ?? null;
      return {
        id: doc.id,
        title: data.title || "",
        body: data.body || "",
        created_at: createdAt ? createdAt.toISOString() : null,
      };
    });

    res.json({ broadcasts });
  } catch (err) {
    console.error("[firebase] broadcasts list failed:", err);
    res.status(500).json({ error: "Firestore read failed: " + err.message });
  }
});

// POST /firebase/broadcast — send a push notification to followers (manager only)
// Writes a doc at shops/{shopId}/broadcasts; the notifyFollowersOnBroadcast
// Cloud Function picks it up and fans out FCM messages.
router.post("/broadcast", requireAdmin("manager"), async (req, res) => {
  if (!firestoreGuard(res)) return;
  const shopId = getShopSetting("firestore_shop_id");
  if (!shopId) {
    return res.status(404).json({
      error: "shop not registered on Firestore — publish from the platform panel first",
    });
  }

  const title = String(req.body?.title || "").trim();
  const body = String(req.body?.body || "").trim();

  if (!title) return res.status(400).json({ error: "title is required" });
  if (!body) return res.status(400).json({ error: "body is required" });
  if (title.length > 80) {
    return res.status(400).json({ error: "title too long (max 80 chars)" });
  }
  if (body.length > 240) {
    return res.status(400).json({ error: "body too long (max 240 chars)" });
  }

  try {
    const { FieldValue } = await import("firebase-admin/firestore");
    const ref = await getFirestore()
      .collection("shops")
      .doc(shopId)
      .collection("broadcasts")
      .add({
        title,
        body,
        createdAt: FieldValue.serverTimestamp(),
      });

    res.json({ ok: true, id: ref.id });
  } catch (err) {
    console.error("[firebase] broadcast send failed:", err);
    res.status(500).json({ error: "Firestore write failed: " + err.message });
  }
});

// DELETE /firebase/shop — remove this shop from Firestore (manager only)
router.delete("/shop", requireAdmin("manager"), async (req, res) => {
  if (!firestoreGuard(res)) return;

  const shopId = getShopSetting("firestore_shop_id");
  if (!shopId) {
    return res.status(404).json({ error: "shop not registered on Firestore" });
  }

  try {
    await getFirestore().collection("shops").doc(shopId).delete();
    setShopSetting("firestore_shop_id", "");
    res.json({ ok: true });
  } catch (err) {
    console.error("[firebase] shop delete failed:", err);
    res.status(500).json({ error: "Firestore delete failed: " + err.message });
  }
});

export default router;
