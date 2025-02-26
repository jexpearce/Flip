import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class SearchManager: ObservableObject {
    @Published var searchResults: [FirebaseManager.FlipUser] = []
    @Published var recommendations: [FirebaseManager.FlipUser] = []
    @Published var isSearching = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCancelRequestAlert = false
    @Published var userToCancelRequest: FirebaseManager.FlipUser?
    
    private let firebaseManager = FirebaseManager.shared
    private var currentUserData: FirebaseManager.FlipUser?

    init() {
        loadCurrentUser()
        loadAllUsers() // Changed this to load all users instead of recommendations
    }

    private func loadCurrentUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let userData = try? document?.data(
                    as: FirebaseManager.FlipUser.self)
                {
                    self?.currentUserData = userData
                }
            }
    }

    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        firebaseManager.db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self?.searchResults = documents.compactMap { document in
                            try? document.data(
                                as: FirebaseManager.FlipUser.self)
                        }.filter { $0.id != Auth.auth().currentUser?.uid }
                    }
                    self?.isSearching = false
                }
            }
    }

    // Simplified method to just load all users as recommendations
    private func loadAllUsers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Get all users except the current user
        firebaseManager.db.collection("users")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let documents = snapshot?.documents {
                    // Filter out only the current user
                    let users = documents.compactMap { document in
                        try? document.data(as: FirebaseManager.FlipUser.self)
                    }.filter { user in
                        return user.id != userId // Only filter out self
                    }
                    
                    DispatchQueue.main.async {
                        self.recommendations = users
                    }
                }
            }
    }

    func requestStatus(for userId: String) -> RequestStatus {
        guard let currentUser = currentUserData else { return .none }

        if currentUser.friends.contains(userId) {
            return .friends
        }
        if currentUser.sentRequests.contains(userId) {
            return .sent
        }
        return .none
    }

    func sendFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Add to recipient's friend requests
        firebaseManager.db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayUnion([currentUserId])
            ])

        // Add to sender's sent requests
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayUnion([userId])
            ])

        // Update local state
        loadCurrentUser()

        // Send notification
        sendFriendRequestNotification(to: userId)
    }
    
    func cancelFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Remove from recipient's friend requests
        firebaseManager.db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayRemove([currentUserId])
            ])
        
        // Remove from sender's sent requests
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayRemove([userId])
            ])
        
        // Update local state
        if var updatedUser = currentUserData {
            updatedUser.sentRequests.removeAll { $0 == userId }
            currentUserData = updatedUser
        }
        
        // Refresh UI after cancellation
        loadCurrentUser()
    }
    
    func promptCancelRequest(for user: FirebaseManager.FlipUser) {
        userToCancelRequest = user
        showCancelRequestAlert = true
    }

    private func sendFriendRequestNotification(to userId: String) {
        guard let currentUser = currentUserData else { return }

        let notification =
            [
                "title": "New Friend Request",
                "body": "\(currentUser.username) sent you a friend request!",
                "userId": userId,
            ] as [String: Any]

        firebaseManager.db.collection("notifications").addDocument(
            data: notification)
    }
}