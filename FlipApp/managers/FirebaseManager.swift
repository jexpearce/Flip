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
        var friends: [String]  // User IDs
        var friendRequests: [String]  // New: incoming friend requests
        var sentRequests: [String]  // New: outgoing friend requests
        var profileImageURL: String?  // New: URL to profile image
        
    }

    func searchUsers(query: String, completion: @escaping ([FlipUser]) -> Void)
    {
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
// Add this extension to FirebaseManager.swift

extension FirebaseManager {
    func cleanupOldLocationData() {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        let db = Firestore.firestore()
        
        // Query for session_locations older than one week
        db.collection("session_locations")
            .whereField("sessionEndTime", isLessThan: Timestamp(date: oneWeekAgo))
            .limit(to: 500)  // Process in batches to avoid timeout
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error querying old sessions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No old sessions to clean up")
                    return
                }
                
                let batch = db.batch()
                
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting old sessions: \(error.localizedDescription)")
                    } else {
                        print("Successfully deleted \(documents.count) old sessions")
                        
                        // If there are likely more documents to delete, call this function again
                        if documents.count == 500 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.cleanupOldLocationData()
                            }
                        }
                    }
                }
            }
    }
}