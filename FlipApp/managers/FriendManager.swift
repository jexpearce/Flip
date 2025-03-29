import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class FriendManager: ObservableObject {
    @Published var friends: [FirebaseManager.FlipUser] = []
    @Published var friendRequests: [FirebaseManager.FlipUser] = []
    @Published var showError = false
    @Published var errorMessage = ""
    private let firebaseManager = FirebaseManager.shared

    init() {
        loadFriends()
        loadFriendRequests()
    }

    func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Clear existing friends before reloading to avoid duplicates
        DispatchQueue.main.async { self.friends = [] }

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                    let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }

                // Load friend details
                for friendId in userData.friends { self?.loadFriendDetails(friendId: friendId) }

                // Also force refresh live sessions to keep everything in sync
                LiveSessionManager.shared.refreshLiveSessions()
            }
    }

    private func loadFriendDetails(friendId: String) {
        firebaseManager.db.collection("users").document(friendId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                    let friendData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }

                DispatchQueue.main.async { self?.friends.append(friendData) }
            }
    }

    func loadFriendRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        firebaseManager.db.collection("users").document(userId)
            .addSnapshotListener { [weak self] document, error in
                guard let document = document,
                    let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }

                // Load request details
                self?.loadRequestDetails(requestIds: userData.friendRequests)
            }
    }
    // Add to your FriendManager class

    func joinFriendSession(friendId: String, friendName: String, sessionId: String) {
        // Check if the user is already in a session
        if AppManager.shared.currentState != .initial {
            showError = true
            errorMessage =
                "You're already in a session. Please complete or cancel it before joining another."
            return
        }

        // Use the coordinator to pass session information
        SessionJoinCoordinator.shared.setJoinSession(id: sessionId, name: friendName)

        // Use the view router to switch to home tab
        // Note: This approach doesn't use UIHostingController directly
        NotificationCenter.default.post(name: Notification.Name("SwitchToHomeTab"), object: nil)
    }

    private func loadRequestDetails(requestIds: [String]) {
        DispatchQueue.main.async { self.friendRequests = [] }

        for requestId in requestIds {
            firebaseManager.db.collection("users").document(requestId)
                .getDocument { [weak self] document, error in
                    guard let document = document,
                        let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                    else { return }

                    DispatchQueue.main.async { self?.friendRequests.append(userData) }
                }
        }
    }

    func acceptFriendRequest(from userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Update current user's friends and requests
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData([
                "friends": FieldValue.arrayUnion([userId]),
                "friendRequests": FieldValue.arrayRemove([userId]),
            ])

        // Update requester's friends and sent requests
        firebaseManager.db.collection("users").document(userId)
            .updateData([
                "friends": FieldValue.arrayUnion([currentUserId]),
                "sentRequests": FieldValue.arrayRemove([currentUserId]),
            ])

        // Remove from local friend requests
        DispatchQueue.main.async {
            self.friendRequests.removeAll { $0.id == userId }
            self.loadFriends()  // Reload friends list
        }
    }

    func declineFriendRequest(from userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Remove request from current user
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData(["friendRequests": FieldValue.arrayRemove([userId])])

        // Remove sent request from requester
        firebaseManager.db.collection("users").document(userId)
            .updateData(["sentRequests": FieldValue.arrayRemove([currentUserId])])

        // Remove from local friend requests
        DispatchQueue.main.async { self.friendRequests.removeAll { $0.id == userId } }
    }

    func removeFriend(friendId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Remove from current user's friends list
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData(["friends": FieldValue.arrayRemove([friendId])])

        // Remove current user from friend's friends list
        firebaseManager.db.collection("users").document(friendId)
            .updateData(["friends": FieldValue.arrayRemove([currentUserId])])

        // Update local state
        DispatchQueue.main.async { self.friends.removeAll { $0.id == friendId } }
    }
}
