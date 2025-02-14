import FirebaseAuth
import FirebaseFirestore
import Foundation
//
//  SearchViewModel.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/11/25.
//
import SwiftUI

class SearchViewModel: ObservableObject {
  @Published var searchResults: [FirebaseManager.FlipUser] = []
  @Published var recommendations: [FirebaseManager.FlipUser] = []
  @Published var isSearching = false
  @Published var showError = false
  @Published var errorMessage = ""
  private let firebaseManager = FirebaseManager.shared
  private var currentUserData: FirebaseManager.FlipUser?

  init() {
    loadCurrentUser()
    loadRecommendations()
  }

  private func loadCurrentUser() {
    guard let userId = Auth.auth().currentUser?.uid else { return }

    firebaseManager.db.collection("users").document(userId)
      .getDocument { [weak self] document, error in
        if let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
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
              try? document.data(as: FirebaseManager.FlipUser.self)
            }.filter { $0.id != Auth.auth().currentUser?.uid }
          }
          self?.isSearching = false
        }
      }
  }

  private func loadRecommendations() {
    guard let userId = Auth.auth().currentUser?.uid else { return }

    // Get 10 most active users
    firebaseManager.db.collection("users")
      .order(by: "totalSessions", descending: true)
      .limit(to: 10)
      .getDocuments { [weak self] snapshot, error in
        if let documents = snapshot?.documents {
          let users = documents.compactMap { document in
            try? document.data(as: FirebaseManager.FlipUser.self)
          }.filter { $0.id != userId }

          DispatchQueue.main.async {
            self?.recommendations = users
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
