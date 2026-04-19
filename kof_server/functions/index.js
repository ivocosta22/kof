const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

/**
 * When a shop creates a broadcast at shops/{shopId}/broadcasts/{broadcastId},
 * send an FCM push to every device registered by any user in
 * shops/{shopId}/followers.
 *
 * Broadcast document shape:
 *   { title: string, body: string, createdAt: Timestamp }
 */
exports.notifyFollowersOnBroadcast = onDocumentCreated(
  "shops/{shopId}/broadcasts/{broadcastId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const broadcast = snap.data() || {};
    const shopId = event.params.shopId;
    const broadcastId = event.params.broadcastId;

    const db = getFirestore();
    const messaging = getMessaging();

    const shopDoc = await db.collection("shops").doc(shopId).get();
    const shopName = (shopDoc.exists && shopDoc.data().name) || "Kof";

    const followersSnap = await db
        .collection("shops")
        .doc(shopId)
        .collection("followers")
        .get();

    if (followersSnap.empty) {
      logger.info(`Broadcast ${broadcastId}: no followers for ${shopId}`);
      return;
    }

    const tokens = [];
    await Promise.all(
        followersSnap.docs.map(async (f) => {
          const devicesSnap = await db
              .collection("users")
              .doc(f.id)
              .collection("devices")
              .get();
          for (const d of devicesSnap.docs) tokens.push(d.id);
        }),
    );

    if (tokens.length === 0) {
      logger.info(
          `Broadcast ${broadcastId}: ${followersSnap.size} followers but no ` +
        `device tokens`,
      );
      return;
    }

    const title = broadcast.title || shopName;
    const body = broadcast.body || "";

    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: {
        shopId,
        broadcastId,
        type: "shop_broadcast",
      },
    });

    logger.info(
        `Broadcast ${broadcastId}: sent to ${response.successCount}/` +
      `${tokens.length} devices`,
    );

    const invalid = [];
    response.responses.forEach((r, idx) => {
      if (!r.success) {
        const code = (r.error && r.error.code) || "";
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalid.push(tokens[idx]);
        }
      }
    });
    if (invalid.length) {
      logger.warn(
          `Broadcast ${broadcastId}: ${invalid.length} invalid token(s) ` +
        `(cleanup not implemented)`,
      );
    }
  },
);
