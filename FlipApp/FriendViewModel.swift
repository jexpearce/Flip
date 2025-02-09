//
//  FriendViewModel.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/9/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendViewModel: ObservableObject {
    @Published var isFriend = false
    private let firebaseManager = FirebaseManager.shared
    
    func addFriend(userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        firebaseManager.db.collection("users").document(currentUserId)
            .updateData([
                "friends": FieldValue.arrayUnion([userId])
            ]) { [weak self] error in
                if error == nil {
                    DispatchQueue.main.async {
                        self?.isFriend = true
                    }
                }
            }
    }
    
    func checkIfFriend(userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        firebaseManager.db.collection("users").document(currentUserId)
            .getDocument { [weak self] document, error in
                if let friends = document?.data()?["friends"] as? [String] {
                    DispatchQueue.main.async {
                        self?.isFriend = friends.contains(userId)
                    }
                }
            }
    }
}