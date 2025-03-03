import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreLocation  // Add this import for CLLocationCoordinate2D

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
extension FirebaseManager {
    // Function to create a test session to ensure the collection exists
    @MainActor func createTestSessionLocation() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let sessionId = "\(userId)_test_\(Int(Date().timeIntervalSince1970))"
        let currentCoordinates = LocationHandler.shared.lastLocation.coordinate
        
        // Create basic test session data
        let sessionData: [String: Any] = [
            "userId": userId,
            "username": FirebaseManager.shared.currentUser?.username ?? "User",
            "location": GeoPoint(latitude: currentCoordinates.latitude, longitude: currentCoordinates.longitude),
            "isCurrentlyFlipped": false,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": true,
            "sessionDuration": 1,
            "actualDuration": 1,
            "sessionStartTime": Timestamp(date: Date().addingTimeInterval(-60)),
            "sessionEndTime": Timestamp(date: Date()),
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Directly save to Firestore to create the collection
        db.collection("session_locations").document(sessionId).setData(sessionData) { error in
            if let error = error {
                print("❌ TEST SESSION ERROR: \(error.localizedDescription)")
            } else {
                print("✅ TEST SESSION CREATED SUCCESSFULLY: \(sessionId)")
            }
        }
    }
    
    // Add this version of updateLocationDuringSession to use in AppManager
    func saveSessionLocation(session: CompletedSession) {
        let sessionId = "\(session.userId)_\(Int(Date().timeIntervalSince1970))"
        
        var sessionData: [String: Any] = [
            "userId": session.userId,
            "username": session.username,
            "location": GeoPoint(latitude: session.location.latitude, longitude: session.location.longitude),
            "isCurrentlyFlipped": false,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": session.wasSuccessful,
            "sessionDuration": session.duration,
            "actualDuration": session.actualDuration,
            "sessionStartTime": Timestamp(date: session.startTime),
            "sessionEndTime": Timestamp(date: Date()),
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Add building information if available
        if let building = session.building {
            sessionData["buildingId"] = building.id
            sessionData["buildingName"] = building.name
            sessionData["buildingLatitude"] = building.coordinate.latitude
            sessionData["buildingLongitude"] = building.coordinate.longitude
        }
        
        print("💾 Attempting to save session: \(sessionId)")
        print("📍 Location: \(session.location.latitude), \(session.location.longitude)")
        if let building = session.building {
            print("🏢 Building: \(building.name) [ID: \(building.id)]")
        }
        
        // Save to Firestore
        db.collection("session_locations").document(sessionId).setData(sessionData) { error in
            if let error = error {
                print("❌ SAVE ERROR: \(error.localizedDescription)")
            } else {
                print("✅ SESSION SAVED SUCCESSFULLY: \(sessionId)")
                
                // Force refresh building leaderboard
                if let building = session.building {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        RegionalViewModel.shared.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                    }
                }
            }
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

struct CompletedSession {
    let userId: String
    let username: String
    let location: CLLocationCoordinate2D
    let duration: Int
    let actualDuration: Int
    let wasSuccessful: Bool
    let startTime: Date
    let building: BuildingInfo?
}