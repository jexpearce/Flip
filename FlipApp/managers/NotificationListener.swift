import FirebaseAuth
import FirebaseFirestore
import Foundation

class NotificationListener {
    static let shared = NotificationListener()
    private var db = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    private var lastNotificationTimestamp: Timestamp?

    func resetAllNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        print("Resetting all notifications for user: \(currentUserId)")

        // First reset the badge count immediately
        DispatchQueue.main.async { UIApplication.shared.applicationIconBadgeNumber = 0 }

        // Then mark all existing notifications as read
        db.collection("users").document(currentUserId).collection("notifications")
            .whereField("read", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error getting notifications: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No unread notifications to reset")
                    return
                }

                print("Marking \(documents.count) notifications as read")

                // Create a batch to update all notifications
                let batch = self?.db.batch()

                for document in documents {
                    let docRef = self?.db.collection("users").document(currentUserId)
                        .collection("notifications").document(document.documentID)

                    if let docRef = docRef {
                        batch?.updateData(["read": true], forDocument: docRef)
                    }
                }

                // Commit the batch
                batch?
                    .commit { error in
                        if let error = error {
                            print(
                                "Error marking notifications as read: \(error.localizedDescription)"
                            )
                        }
                        else {
                            print("Successfully marked all notifications as read")
                        }
                    }
            }
    }

    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("Cannot start notification listener: No user logged in")
            return
        }

        // Only request permission if not locked in permission flow
        if !PermissionManager.shared.isPermissionLocked() {
            // Request notification permission if needed
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        print("Notification permission granted")
                    }
                    else if let error = error {
                        print(
                            "Error requesting notification permission: \(error.localizedDescription)"
                        )
                    }
                }
        }
        else {
            print("⏸️ Notification permission request deferred - permission flow in progress")
        }

        // Stop any existing listener
        stopListening()

        // IMPORTANT: Use current time as the cutoff for notifications
        // This ensures we only listen for new notifications from now on
        lastNotificationTimestamp = Timestamp(date: Date())
        UserDefaults.standard.set(
            lastNotificationTimestamp!.seconds,
            forKey: "lastNotificationTimestamp"
        )

        print("Starting notification listener for user: \(currentUserId)")
        print("Will only listen for notifications after: \(lastNotificationTimestamp!.dateValue())")

        // Reset badge count on start
        DispatchQueue.main.async { UIApplication.shared.applicationIconBadgeNumber = 0 }

        // Listen for new notifications
        notificationListener = db.collection("users").document(currentUserId)
            .collection("notifications")
            .whereField("timestamp", isGreaterThan: lastNotificationTimestamp!)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    print(
                        "Error listening for notifications: \(error?.localizedDescription ?? "unknown error")"
                    )
                    return
                }

                var newestTimestamp: Timestamp?

                // Process each new notification
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        let data = change.document.data()
                        print("New notification received: \(data)")

                        // Process new notification
                        self?.processNewNotification(data)

                        // Track newest timestamp
                        if let timestamp = data["timestamp"] as? Timestamp {
                            if newestTimestamp == nil
                                || timestamp.seconds > newestTimestamp!.seconds
                            {
                                newestTimestamp = timestamp
                            }
                        }
                    }
                }

                // Update last seen timestamp
                if let timestamp = newestTimestamp {
                    self?.lastNotificationTimestamp = timestamp
                    UserDefaults.standard.set(
                        timestamp.seconds,
                        forKey: "lastNotificationTimestamp"
                    )
                    print("Updated last notification timestamp to: \(timestamp.dateValue())")

                    // Update badge count
                    self?.updateBadgeCount()
                }
            }
    }

    private func processNewNotification(_ data: [String: Any]) {
        // Extract notification data
        guard let type = data["type"] as? String else { return }

        switch type {
        case "session_failure":
            // Check if friend failure notifications are enabled in settings
            if UserSettingsManager.shared.areFriendFailureNotificationsEnabled {
                if let message = data["message"] as? String, let silent = data["silent"] as? Bool,
                    !silent
                {
                    // Show local notification only if not silent and enabled in settings
                    NotificationManager.shared.display(
                        title: "Friend Alert",
                        body: message,
                        categoryIdentifier: "FRIEND_ALERT",
                        silent: true
                    )
                    print("Displayed session failure notification: \(message)")
                }
            }
            else {
                print("Friend failure notification suppressed - disabled in settings")
            }
        case "comment":
            // Check if comment notifications are enabled in settings
            if UserSettingsManager.shared.areCommentNotificationsEnabled {
                if let fromUsername = data["fromUsername"] as? String,
                    let comment = data["comment"] as? String
                {
                    NotificationManager.shared.display(
                        title: "New Comment",
                        body: "\(fromUsername): \(comment)",
                        categoryIdentifier: "COMMENT",
                        silent: true
                    )
                    print("Displayed comment notification from: \(fromUsername)")
                }
            }
            else {
                print("Comment notification suppressed - disabled in settings")
            }

        case "friend_request":
            if let fromUsername = data["fromUsername"] as? String {
                // Friend requests are always shown regardless of settings
                NotificationManager.shared.display(
                    title: "Friend Request",
                    body: "\(fromUsername) wants to add you as a friend",
                    categoryIdentifier: "FRIEND_REQUEST",
                    silent: true
                )
                print("Displayed friend request notification from: \(fromUsername)")
            }

        default:
            print("Unknown notification type: \(type)")
            break
        }
    }

    func stopListening() {
        notificationListener?.remove()
        notificationListener = nil
        print("Stopped notification listener")
    }

    // Helper method to check and update notification badge count
    func updateBadgeCount() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Use a more specific query that excludes session_failure notifications
        db.collection("users").document(currentUserId).collection("notifications")
            .whereField("read", isEqualTo: false).whereField("type", notIn: ["session_failure"])  // Exclude session failure notifications
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting unread notifications: \(error.localizedDescription)")
                    return
                }

                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async { UIApplication.shared.applicationIconBadgeNumber = count }
                print("Updated badge count: \(count) (excluding session failure notifications)")
            }
    }
}
