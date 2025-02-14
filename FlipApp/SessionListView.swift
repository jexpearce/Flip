import FirebaseFirestore
//
//  SessionListView.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/11/25.
//
import Foundation

class SessionListViewModel: ObservableObject {
  @Published var sessions: [Session] = []
  private let firebaseManager = FirebaseManager.shared

  func loadSessions(for userId: String) {
    firebaseManager.db.collection("sessions")
      .whereField("userId", isEqualTo: userId)
      .order(by: "startTime", descending: true)
      .limit(to: 10)  // Show last 10 sessions
      .addSnapshotListener { [weak self] snapshot, error in
        guard let documents = snapshot?.documents else { return }

        DispatchQueue.main.async {
          self?.sessions = documents.compactMap { document in
            try? document.data(as: Session.self)
          }
        }
      }
  }
}
