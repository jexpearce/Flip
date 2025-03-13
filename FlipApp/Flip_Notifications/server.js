require("dotenv").config();
const express = require("express");
const admin = require("firebase-admin");
const cors = require("cors");

// Initialize Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://${process.env.FIREBASE_PROJECT_ID}.firebaseio.com`,
});

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Firestore references
const db = admin.firestore();

// Health check endpoint
app.get("/", (req, res) => {
  res.status(200).send("Push notification service is running");
});

// Endpoint to manually trigger notifications (for testing)
app.post("/send-notification", async (req, res) => {
  const { userId, message, type } = req.body;

  if (!userId || !message || !type) {
    return res.status(400).send("Missing required fields");
  }

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).send(`User ${userId} not found`);
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      return res.status(400).send(`No FCM token found for user ${userId}`);
    }

    const response = await sendPushNotification(
      fcmToken,
      {
        message,
        type,
      },
      "manual-test"
    );

    res.status(200).send({ success: true, response });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).send(`Error: ${error.message}`);
  }
});

// Function to get notification title based on type
function getNotificationTitle(type) {
  switch (type) {
    case "session_failure":
      return "Session Failed";
    case "comment":
      return "New Comment";
    case "friend_request":
      return "Friend Request";
    case "session_invitation":
      return "Session Invitation";
    default:
      return "Flip Notification";
  }
}

// Function to send push notification
async function sendPushNotification(token, notificationData, notificationId) {
  const message = {
    token: token,
    notification: {
      title: getNotificationTitle(notificationData.type),
      body: notificationData.message,
    },
    data: {
      type: notificationData.type,
      notificationId: notificationId,
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", response);
    return response;
  } catch (error) {
    console.error("Error sending notification:", error);
    throw error;
  }
}

// Set up Firestore listeners
function setupFirestoreListeners() {
  console.log("Setting up Firestore notification listeners...");

  // Listen for all users
  db.collection("users").onSnapshot(
    (snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === "added" || change.type === "modified") {
          const userId = change.doc.id;

          // Set up a listener for this user's notifications
          setupUserNotificationsListener(userId);
        }
      });
    },
    (error) => {
      console.error("Error listening to users collection:", error);
    }
  );
}

// Set up notifications listener for a specific user
function setupUserNotificationsListener(userId) {
  console.log(`Setting up notifications listener for user: ${userId}`);

  db.collection(`users/${userId}/notifications`)
    .orderBy("createdAt", "desc")
    .limit(10)
    .onSnapshot(
      (notifSnapshot) => {
        notifSnapshot.docChanges().forEach(async (notifChange) => {
          // Only process new notifications
          if (notifChange.type === "added") {
            const notificationId = notifChange.doc.id;
            const notificationData = notifChange.doc.data();

            console.log(
              `New notification for user ${userId}:`,
              notificationData
            );

            // Skip silent notifications
            if (notificationData.silent) {
              console.log("Silent notification, skipping push");
              return;
            }

            try {
              // Get user's FCM token
              const userDoc = await db.collection("users").doc(userId).get();
              if (!userDoc.exists) {
                console.log(`User ${userId} not found`);
                return;
              }

              const userData = userDoc.data();
              const fcmToken = userData.fcmToken;

              if (!fcmToken) {
                console.log(`No FCM token for user ${userId}`);
                return;
              }

              // Send push notification
              await sendPushNotification(
                fcmToken,
                notificationData,
                notificationId
              );
            } catch (error) {
              console.error("Error processing notification:", error);
            }
          }
        });
      },
      (error) => {
        console.error(
          `Error listening to notifications for user ${userId}:`,
          error
        );
      }
    );
}

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Notification server running on port ${PORT}`);

  // Set up Firestore listeners after server starts
  setupFirestoreListeners();
});
