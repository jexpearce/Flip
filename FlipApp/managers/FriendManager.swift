import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class FriendManager: ObservableObject {
    @Published var friends: [FirebaseManager.FlipUser] = []
    @Published var friendRequests: [FirebaseManager.FlipUser] = []
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

    func blockUser(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = firebaseManager.db
        let batch = db.batch()
        // Add to current user's blocked list
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(
            ["blockedUsers": FieldValue.arrayUnion([userId])],
            forDocument: currentUserRef
        )
        // Remove from friends list if they were friends
        batch.updateData(["friends": FieldValue.arrayRemove([userId])], forDocument: currentUserRef)
        // Remove current user from blocked user's friends list
        let blockedUserRef = db.collection("users").document(userId)
        batch.updateData(
            ["friends": FieldValue.arrayRemove([currentUserId])],
            forDocument: blockedUserRef
        )
        batch.commit { error in
            if let error = error {
                print("Error blocking user: \(error.localizedDescription)")
                completion(false)
            }
            else {
                // Refresh friends list
                self.loadFriends()
                completion(true)
            }
        }
    }
    func unblockUser(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let db = firebaseManager.db
        db.collection("users").document(currentUserId)
            .updateData(["blockedUsers": FieldValue.arrayRemove([userId])]) { error in
                if let error = error {
                    print("Error unblocking user: \(error.localizedDescription)")
                    completion(false)
                }
                else {
                    completion(true)
                }
            }
    }
    func isUserBlocked(userId: String) -> Bool {
        guard let currentUser = firebaseManager.currentUser else { return false }
        return currentUser.blockedUsers.contains(userId)
    }
}
