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
    // Add this to FirebaseManager.swift
    func inspectUserData() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("⚠️ USER INSPECTION: No current user")
            return
        }
        
        print("🔍 STARTING USER DATA INSPECTION")
        
        // First check current user data
        db.collection("users").document(currentUserId).getDocument { document, error in
            if let error = error {
                print("❌ USER INSPECTION ERROR: \(error.localizedDescription)")
                return
            }
            
            if let data = document?.data() {
                print("👤 CURRENT USER (\(currentUserId)) RAW DATA: \(data)")
                
                // Check username field specifically
                if let username = data["username"] as? String {
                    print("✅ Current user username exists: '\(username)'")
                    
                    // Check if username is empty
                    if username.isEmpty {
                        print("⚠️ Current user username is EMPTY")
                    }
                    
                    // Try to update current user's username in FirebaseManager
                    if self.currentUser?.username.isEmpty ?? true {
                        print("⚠️ Current user object has empty username, updating it to: \(username)")
                        
                        // Create a new FlipUser with the correct username
                        let updatedUser = FirebaseManager.FlipUser(
                            id: currentUserId,
                            username: username,
                            totalFocusTime: self.currentUser?.totalFocusTime ?? 0,
                            totalSessions: self.currentUser?.totalSessions ?? 0,
                            longestSession: self.currentUser?.longestSession ?? 0,
                            friends: self.currentUser?.friends ?? [],
                            friendRequests: self.currentUser?.friendRequests ?? [],
                            sentRequests: self.currentUser?.sentRequests ?? [],
                            profileImageURL: self.currentUser?.profileImageURL
                        )
                        
                        // Update the current user
                        DispatchQueue.main.async {
                            self.currentUser = updatedUser
                        }
                    }
                } else {
                    print("❌ Current user is missing username field!")
                    
                    // Check if there's a displayName in Auth that we can use
                    if let displayName = Auth.auth().currentUser?.displayName, !displayName.isEmpty {
                        print("🔄 Found displayName in Auth: \(displayName), updating Firestore...")
                        
                        // Update Firestore with the displayName as username
                        self.db.collection("users").document(currentUserId).updateData([
                            "username": displayName
                        ]) { error in
                            if let error = error {
                                print("❌ Failed to update missing username: \(error.localizedDescription)")
                            } else {
                                print("✅ Successfully repaired missing username field")
                                
                                // Also update local user object
                                if let currentUser = self.currentUser {
                                    let updatedUser = FirebaseManager.FlipUser(
                                        id: currentUser.id,
                                        username: displayName,
                                        totalFocusTime: currentUser.totalFocusTime,
                                        totalSessions: currentUser.totalSessions,
                                        longestSession: currentUser.longestSession,
                                        friends: currentUser.friends,
                                        friendRequests: currentUser.friendRequests,
                                        sentRequests: currentUser.sentRequests,
                                        profileImageURL: currentUser.profileImageURL
                                    )
                                    
                                    DispatchQueue.main.async {
                                        self.currentUser = updatedUser
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                print("❌ No user document found for current user!")
            }
            
            // Then check friend data
            self.db.collection("users").document(currentUserId).getDocument { document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    print("👥 Checking \(userData.friends.count) friends...")
                    
                    for friendId in userData.friends {
                        self.db.collection("users").document(friendId).getDocument { friendDoc, friendError in
                            if let friendError = friendError {
                                print("❌ Error getting friend data for \(friendId): \(friendError.localizedDescription)")
                                return
                            }
                            
                            if let friendData = friendDoc?.data() {
                                if let friendUsername = friendData["username"] as? String {
                                    print("👤 Friend \(friendId): username = '\(friendUsername)'")
                                    
                                    if friendUsername.isEmpty {
                                        print("⚠️ Friend \(friendId) has EMPTY username")
                                    }
                                } else {
                                    print("❌ Friend \(friendId) is MISSING username field")
                                }
                            } else {
                                print("❌ No document found for friend \(friendId)")
                            }
                        }
                    }
                }
            }
            
            // Check recent sessions to ensure they have usernames
            self.db.collection("sessions")
                .whereField("userId", isEqualTo: currentUserId)
                .order(by: "startTime", descending: true)
                .limit(to: 5)
                .getDocuments { snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No recent sessions found")
                        return
                    }
                    
                    print("📋 Checking \(documents.count) recent sessions...")
                    
                    for document in documents {
                        let data = document.data()
                        let sessionId = document.documentID
                        
                        if let username = data["username"] as? String {
                            print("📝 Session \(sessionId): username = '\(username)'")
                            
                            if username.isEmpty {
                                print("⚠️ Session \(sessionId) has EMPTY username")
                                
                                // Try to repair this session
                                if let currentUsername = self.currentUser?.username, !currentUsername.isEmpty {
                                    print("🔄 Repairing session \(sessionId) with username: \(currentUsername)")
                                    
                                    self.db.collection("sessions").document(sessionId).updateData([
                                        "username": currentUsername
                                    ]) { error in
                                        if let error = error {
                                            print("❌ Failed to repair session: \(error.localizedDescription)")
                                        } else {
                                            print("✅ Successfully repaired session \(sessionId)")
                                        }
                                    }
                                }
                            }
                        } else {
                            print("❌ Session \(sessionId) is MISSING username field")
                        }
                    }
                }
        }
    }
    // Add this to FirebaseManager.swift
    func pruneOldSessions(forUserId userId: String) {
        // Get a timestamp for 30 days ago
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        
        // First, delete any very old sessions (more than 30 days old)
        db.collection("session_locations")
            .whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isLessThan: Timestamp(date: thirtyDaysAgo))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, !documents.isEmpty else {
                    return
                }
                
                let batch = self.db.batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting old sessions: \(error)")
                    } else {
                        print("Deleted \(documents.count) sessions older than 10 days")
                    }
                }
            }
        
        // Next, make sure we only keep the 10 most recent sessions within the last 30 days
        db.collection("session_locations")
            .whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: thirtyDaysAgo))
            .order(by: "sessionEndTime", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents,
                      documents.count > 10 else {
                    return
                }
                
                // Keep the 10 most recent, delete the rest
                let docsToDelete = documents.suffix(from: 10)
                
                let batch = self.db.batch()
                for doc in docsToDelete {
                    batch.deleteDocument(doc.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error pruning excess sessions: \(error)")
                    } else {
                        print("Pruned \(docsToDelete.count) excess sessions for map display")
                    }
                }
            }
    }

    
    func saveSessionLocation(session: CompletedSession) {
        let sessionId = "\(session.userId)_\(Int(Date().timeIntervalSince1970))"
        
        // Debug logging for duration
        print("💾 Saving session duration: \(session.duration) minutes, actual duration: \(session.actualDuration) minutes")
        
        // Ensure we have a valid actual duration - but don't cap it unnecessarily
        let validActualDuration = max(1, session.actualDuration) // Ensure at least 1 minute
        
        // Add warning if duration calculation seems wrong
        if validActualDuration <= 1 && session.duration > 5 {
            print("⚠️ WARNING: Duration calculation may be incorrect! Target: \(session.duration)m, Actual: \(validActualDuration)m")
        }
        
        var sessionData: [String: Any] = [
            "userId": session.userId,
            "username": session.username,
            "location": GeoPoint(latitude: session.location.latitude, longitude: session.location.longitude),
            "isCurrentlyFlipped": false,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": session.wasSuccessful,
            "sessionDuration": session.duration,
            "actualDuration": validActualDuration, // Ensure we have a valid value
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
        
        print("💾 Saving session: \(sessionId)")
        print("📍 Location: \(session.location.latitude), \(session.location.longitude)")
        print("⏱️ Duration: \(session.duration)m / Actual: \(validActualDuration)m")
        
        if let building = session.building {
            print("🏢 Building: \(building.name) [ID: \(building.id)]")
        }
        
        // Save to Firestore
        db.collection("session_locations").document(sessionId).setData(sessionData) { [weak self] error in
            if let error = error {
                print("❌ SAVE ERROR: \(error.localizedDescription)")
            } else {
                print("✅ SESSION SAVED SUCCESSFULLY: \(sessionId) with duration \(validActualDuration) minutes")
                
                // Prune old sessions to keep the map clean
                self?.pruneOldSessions(forUserId: session.userId)
                
                // Force refresh building leaderboard if needed
                if let building = session.building {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        RegionalViewModel.shared.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                    }
                }
                
                // Clean up stale location data
                if session.wasSuccessful {
                    // Only remove from active locations when session completed successfully
                    // to ensure failed sessions still show up properly
                    self?.db.collection("locations").document(session.userId).delete()
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
