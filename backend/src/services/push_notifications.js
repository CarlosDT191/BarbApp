const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const User = require("../models/user.model");

let firebaseApp;

function loadServiceAccount() {
  const accountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (accountPath) {
    try {
      const resolvedPath = path.resolve(process.cwd(), accountPath);
      const rawFile = fs.readFileSync(resolvedPath, "utf8");
      return JSON.parse(rawFile);
    } catch (err) {
      console.error("FIREBASE_SERVICE_ACCOUNT_PATH invalid:", err);
      return null;
    }
  }

  return null;
}

function getFirebaseApp() {
  if (firebaseApp) {
    return firebaseApp;
  }

  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    return null;
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  return firebaseApp;
}

function normalizeDataPayload(data) {
  if (!data) {
    return undefined;
  }

  const normalized = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) {
      continue;
    }
    normalized[key] = String(value);
  }

  return Object.keys(normalized).length > 0 ? normalized : undefined;
}

async function sendPushToUser(userId, payload) {
  const app = getFirebaseApp();
  if (!app) {
    return { skipped: true };
  }

  const user = await User.findById(userId, { deviceTokens: 1 }).lean();
  const tokens = (user?.deviceTokens || [])
    .map((token) => token?.trim())
    .filter((token) => token);

  if (!tokens.length) {
    return { skipped: true };
  }

  const data = normalizeDataPayload(payload?.data);
  const message = {
    tokens,
    notification: {
      title: payload?.title || "BarbApp",
      body: payload?.body || "",
    },
    data,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    const invalidTokens = [];

    response.responses.forEach((result, index) => {
      if (!result.success) {
        const code = result.error?.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(tokens[index]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await User.updateOne(
        { _id: userId },
        { $pull: { deviceTokens: { $in: invalidTokens } } }
      );
    }

    return {
      sent: response.successCount,
      failed: response.failureCount,
    };
  } catch (err) {
    console.error("Push notification error:", err);
    return { error: err?.message || "unknown" };
  }
}

module.exports = {
  sendPushToUser,
};
