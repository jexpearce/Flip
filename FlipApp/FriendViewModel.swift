//
//  FriendViewModel.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/9/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendsViewModel: ObservableObject {
    @Published var friends: [FirebaseManager.FlipUser] = []
    @Published var friendRequests: [FirebaseManager.FlipUser] = []
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        loadFriends()
        loadFriendRequests()
    }
    
    func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                      let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }
                
                // Clear existing friends before reloading
                DispatchQueue.main.async {
                    self?.friends = []
                }
                
                // Load friend details
                for friendId in userData.friends {
                    self?.loadFriendDetails(friendId: friendId)
                }
            }
    }
    
    private func loadFriendDetails(friendId: String) {
        firebaseManager.db.collection("users").document(friendId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                      let friendData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }
                
                DispatchQueue.main.async {
                    self?.friends.append(friendData)
                }
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
    
    private func loadRequestDetails(requestIds: [String]) {
        DispatchQueue.main.async {
            self.friendRequests = []
        }
        
        for requestId in requestIds {
            firebaseManager.db.collection("users").document(requestId)
                .getDocument { [weak self] document, error in
                    guard let document = document,
                          let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                    else { return }
                    
                    DispatchQueue.main.async {
                        self?.friendRequests.append(userData)
                    }
                }
        }
    }
    
    func acceptFriendRequest(from userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Update current user's friends and requests
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData([
                "friends": FieldValue.arrayUnion([userId]),
                "friendRequests": FieldValue.arrayRemove([userId])
            ])
        
        // Update requester's friends and sent requests
        firebaseManager.db.collection("users").document(userId)
            .updateData([
                "friends": FieldValue.arrayUnion([currentUserId]),
                "sentRequests": FieldValue.arrayRemove([currentUserId])
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
            .updateData([
                "friendRequests": FieldValue.arrayRemove([userId])
            ])
        
        // Remove sent request from requester
        firebaseManager.db.collection("users").document(userId)
            .updateData([
                "sentRequests": FieldValue.arrayRemove([currentUserId])
            ])
        
        // Remove from local friend requests
        DispatchQueue.main.async {
            self.friendRequests.removeAll { $0.id == userId }
        }
    }
}