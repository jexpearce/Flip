// Create a new file: FirebaseManager.swift
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    
    @Published var currentUser: FlipUser?
    @Published var friends: [FlipUser] = []
    @Published var friendSessions: [Session] = []
    
    struct FlipUser: Codable, Identifiable {
        let id: String
        var username: String
        var totalFocusTime: Int
        var totalSessions: Int
        var longestSession: Int
        var friends: [String] // User IDs
    }
  
  func searchUsers(query: String, completion: @escaping ([FlipUser]) -> Void) {
          guard !query.isEmpty else {
              completion([])
              return
          }
          
          db.collection("users")
              .whereField("username", isGreaterThanOrEqualTo: query)
              .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
              .getDocuments { snapshot, error in
                  guard let documents = snapshot?.documents else {
                      completion([])
                      return
                  }
                  
                  let users = documents.compactMap { document -> FlipUser? in
                      try? document.data(as: FlipUser.self)
                  }
                  completion(users)
              }
      }
  
}