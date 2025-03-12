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
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  let currentUsername = FirebaseManager.shared.currentUser?.username else { return }
            
            print("Sending friend request from \(currentUsername) to \(userId)")
            
            // Update current user's "sentRequests" array
            FirebaseManager.shared.db.collection("users").document(currentUserId)
                .updateData([
                    "sentRequests": FieldValue.arrayUnion([userId])
                ])
            
            // Update target user's "friendRequests" array
            FirebaseManager.shared.db.collection("users").document(userId)
                .updateData([
                    "friendRequests": FieldValue.arrayUnion([currentUserId])
                ])
            
            // Create a notification document for the friend request
            let notificationData: [String: Any] = [
                "type": "friend_request",
                "fromUserId": currentUserId,
                "fromUsername": currentUsername,
                "timestamp": FieldValue.serverTimestamp(),
                "message": "\(currentUsername) wants to add you as a friend",
                "read": false,
                "silent": false
            ]
            
            // Add to the target user's notifications collection
            FirebaseManager.shared.db.collection("users").document(userId)
                .collection("notifications")
                .document()
                .setData(notificationData) { error in
                    if let error = error {
                        print("Error creating friend request notification: \(error.localizedDescription)")
                    } else {
                        print("Friend request notification created successfully")
                    }
                }
            
            // Update local state
            DispatchQueue.main.async {
                self.updateRequestStatus(for: userId, to: .sent)
            }
        }
    // Add this method to your SearchManager class:

    func updateRequestStatus(for userId: String, to status: RequestStatus) {
        // This updates our local cache to reflect the new status
        // without requiring a server round-trip
        loadCurrentUser()
        
        // Force UI update
        DispatchQueue.main.async {
            // If we have search results, update the status in those
            if let index = self.searchResults.firstIndex(where: { $0.id == userId }) {
                self.objectWillChange.send()
            }
            
            // If we have recommendations, update the status in those
            if let index = self.recommendations.firstIndex(where: { $0.id == userId }) {
                self.objectWillChange.send()
            }
        }
        
        // Prompt to cancel the request if needed
        if status == .sent {
            print("Request sent to user \(userId)")
        }
    }
    func promptCancelRequest(for user: FirebaseManager.FlipUser) {
            userToCancelRequest = user
            showCancelRequestAlert = true
        }
    
    func cancelFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Update current user's "sentRequests" array
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayRemove([userId])
            ])
        
        // Update target user's "friendRequests" array
        FirebaseManager.shared.db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayRemove([currentUserId])
            ])
        
        // Remove any pending friend request notifications
        FirebaseManager.shared.db.collection("users").document(userId)
            .collection("notifications")
            .whereField("type", isEqualTo: "friend_request")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let batch = FirebaseManager.shared.db.batch()
                    
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            print("Error removing friend request notifications: \(error.localizedDescription)")
                        } else {
                            print("Friend request notifications removed successfully")
                        }
                    }
                }
            }
        
        // Update local state
        DispatchQueue.main.async {
            self.updateRequestStatus(for: userId, to: .none)
            // Clear any UI state
            self.showCancelRequestAlert = false
            self.userToCancelRequest = nil
        }
    }
}

