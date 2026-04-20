import { readFileSync } from "fs";
import { resolve } from "path";
import admin from "firebase-admin";

let _db = null;
let _ready = false;

function init() {
  if (_ready) return;

  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!keyPath) {
    console.warn(
      "[firebase] FIREBASE_SERVICE_ACCOUNT_PATH not set — " +
        "Firestore integration disabled."
    );
    return;
  }

  try {
    const absPath = resolve(keyPath);
    const serviceAccount = JSON.parse(readFileSync(absPath, "utf8"));

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    _db = admin.firestore();
    _ready = true;
    console.log("[firebase] Firestore ready.");
  } catch (err) {
    console.error("[firebase] Failed to initialise:", err.message);
  }
}

init();

export function getFirestore() {
  return _db;
}

export function isReady() {
  return _ready;
}
