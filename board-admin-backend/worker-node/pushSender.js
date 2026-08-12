const admin = require('firebase-admin');

let initialized = false;
function init() {
  if (initialized) return;
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!serviceAccountPath) return;
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  initialized = true;
}

async function sendPush(token, title, body) {
  init();
  if (!initialized) {
    console.warn('Firebase not configured; skipping push');
    return;
  }
  const message = {
    token,
    notification: { title, body },
    data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' },
  };

  await admin.messaging().send(message);
}

module.exports = { sendPush };
