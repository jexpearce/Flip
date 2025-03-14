const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

// v1 syntax
exports.sendPushNotification = functions
  .region("us-central1")
  .firestore.document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const userId = context.params.userId;

    // Skip if silent flag is true
    if (notificationData.silent === true) {
      console.log("Silent notification, skipping push for", userId);
      return null;
    }

    try {
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        console.log("User document not found for", userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log("No FCM token found for user", userId);
        return null;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: getNotificationTitle(notificationData.type),
          body: notificationData.message,
        },
        data: {
          type: notificationData.type,
          notificationId: context.params.notificationId,
        },
      };

      console.log("Sending push notification to user", userId);
      const response = await admin.messaging().send(message);
      console.log("Successfully sent notification:", response);
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });

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
