const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

/**
 * ============================================================
 * 1) INGEST ENDPOINT — the ESP32 posts readings here.
 *    Replaces the old ThingSpeak GET request.
 *
 * POST body (JSON):
 * {
 *   "deviceId": "SHV-ESP-0142",
 *   "apiKey": "the-secret-key-issued-at-pairing",
 *   "vll_avg": 413.3, "vll_ry": 412.9, "vll_yb": 413.1, "vll_br": 413.9,
 *   "cur_avg": 12.4,  "cur_r": 12.1,   "cur_y": 12.6,   "cur_b": 12.5
 * }
 * ============================================================
 */
exports.ingest = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Use POST");
  }

  const {
    deviceId, apiKey,
    vll_avg, vll_ry, vll_yb, vll_br,
    cur_avg, cur_r, cur_y, cur_b
  } = req.body || {};

  if (!deviceId || !apiKey) {
    return res.status(400).json({ error: "deviceId and apiKey are required" });
  }

  const deviceRef = db.collection("devices").doc(deviceId);
  const deviceSnap = await deviceRef.get();

  if (!deviceSnap.exists) {
    return res.status(404).json({ error: "Unknown device" });
  }

  const device = deviceSnap.data();
  if (device.apiKey !== apiKey) {
    return res.status(401).json({ error: "Invalid API key" });
  }

  const reading = {
    vll_avg, vll_ry, vll_yb, vll_br,
    cur_avg, cur_r, cur_y, cur_b,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  };

  const batch = db.batch();
  // full history record, for graphs
  batch.set(deviceRef.collection("readings").doc(), reading);
  // fast lookup fields on the device doc itself, for the "latest reading" screen
  batch.update(deviceRef, {
    lastReading: reading,
    lastSeen: admin.firestore.FieldValue.serverTimestamp()
  });
  await batch.commit();

  return res.status(200).json({ ok: true });
});

/**
 * ============================================================
 * 2) PAIR A METER — called from the app when a user adds a device.
 *    Generates the device's permanent API key (shown once, then
 *    burned into the ESP32 firmware).
 * ============================================================
 */
exports.createDevice = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in first.");
  }

  const { deviceId, meterSerial } = data;
  if (!deviceId || !meterSerial) {
    throw new functions.https.HttpsError("invalid-argument", "deviceId and meterSerial are required.");
  }

  const deviceRef = db.collection("devices").doc(deviceId);
  const existing = await deviceRef.get();
  if (existing.exists) {
    throw new functions.https.HttpsError("already-exists", "This device ID is already paired.");
  }

  const apiKey = crypto.randomBytes(24).toString("hex");

  await deviceRef.set({
    ownerId: context.auth.uid,
    meterSerial,
    apiKey,
    visibility: "private",     // 'private' | 'public' | 'shared'
    sharedEmails: [],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSeen: null,
    lastReading: null
  });

  // Returned once — the app should show/copy this into the ESP32 sketch.
  return { deviceId, apiKey };
});

/**
 * ============================================================
 * 3) UPDATE SHARING — owner sets visibility / who can see the device.
 * ============================================================
 */
exports.updateSharing = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in first.");
  }

  const { deviceId, visibility, sharedEmails } = data;
  const deviceRef = db.collection("devices").doc(deviceId);
  const snap = await deviceRef.get();

  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "Device not found.");
  }
  if (snap.data().ownerId !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "Only the owner can change sharing.");
  }
  if (!["private", "public", "shared"].includes(visibility)) {
    throw new functions.https.HttpsError("invalid-argument", "visibility must be private, public, or shared.");
  }

  await deviceRef.update({
    visibility,
    sharedEmails: visibility === "shared" ? (sharedEmails || []) : []
  });

  return { ok: true };
});
