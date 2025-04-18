import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()

    @Published var currentUser: FlipUser?
    @Published var friends: [FlipUser] = []

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
        var blockedUsers: [String]  // New: list of blocked user IDs
    }

    func updateExistingUsersWithBlockedUsers(completion: @escaping (Error?) -> Void) {
        db.collection("users")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }
                let batch = self.db.batch()
                var count = 0
                for document in snapshot?.documents ?? [] {
                    if document.data()["blockedUsers"] == nil {
                        batch.updateData(["blockedUsers": []], forDocument: document.reference)
                        count += 1
                    }
                }
                if count > 0 {
                    batch.commit { error in completion(error) }
                }
                else {
                    completion(nil)
                }
            }
    }
}
extension FirebaseManager {
    // Function to create a test session to ensure the collection exists
    @MainActor func createTestSessionLocation() {
        //        guard let userId = Auth.auth().currentUser?.uid else { return }
        //
        //        let sessionId = "\(userId)_test_\(Int(Date().timeIntervalSince1970))"
        //        let currentCoordinates = LocationHandler.shared.lastLocation.coordinate
        //
        //        // Create basic test session data
        //        let sessionData: [String: Any] = [
        //            "userId": userId, "username": FirebaseManager.shared.currentUser?.username ?? "User",
        //            "location": GeoPoint(
        //                latitude: currentCoordinates.latitude,
        //                longitude: currentCoordinates.longitude
        //            ), "isCurrentlyFlipped": false, "lastFlipTime": Timestamp(date: Date()),
        //            "lastFlipWasSuccessful": true, "sessionDuration": 1, "actualDuration": 1,
        //            "sessionStartTime": Timestamp(date: Date().addingTimeInterval(-60)),
        //            "sessionEndTime": Timestamp(date: Date()), "createdAt": FieldValue.serverTimestamp(),
        //        ]
        //
        //        // Directly save to Firestore to create the collection
        //        db.collection("session_locations").document(sessionId)
        //            .setData(sessionData) { error in
        //                if let error = error {
        //                    print("❌ TEST SESSION ERROR: \(error.localizedDescription)")
        //                }
        //                else {
        //                    print("✅ TEST SESSION CREATED SUCCESSFULLY: \(sessionId)")
        //                }
        //            }
    }
    // Add this to FirebaseManager.swift
    func inspectUserData() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("⚠️ USER INSPECTION: No current user")
            return
        }

        print("🔍 STARTING USER DATA INSPECTION")

        // First check current user data
        db.collection("users").document(currentUserId)
            .getDocument { document, error in
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
                        if username.isEmpty { print("⚠️ Current user username is EMPTY") }

                        // Try to update current user's username in FirebaseManager
                        if self.currentUser?.username.isEmpty ?? true {
                            print(
                                "⚠️ Current user object has empty username, updating it to: \(username)"
                            )

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
                                profileImageURL: self.currentUser?.profileImageURL,
                                blockedUsers: self.currentUser?.blockedUsers ?? []
                            )

                            // Update the current user
                            DispatchQueue.main.async { self.currentUser = updatedUser }
                        }
                    }
                    else {
                        print("❌ Current user is missing username field!")

                        // Check if there's a displayName in Auth that we can use
                        if let displayName = Auth.auth().currentUser?.displayName,
                            !displayName.isEmpty
                        {
                            print(
                                "🔄 Found displayName in Auth: \(displayName), updating Firestore..."
                            )

                            // Update Firestore with the displayName as username
                            self.db.collection("users").document(currentUserId)
                                .updateData(["username": displayName]) { error in
                                    if let error = error {
                                        print(
                                            "❌ Failed to update missing username: \(error.localizedDescription)"
                                        )
                                    }
                                    else {
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
                                                profileImageURL: currentUser.profileImageURL,
                                                blockedUsers: currentUser.blockedUsers
                                            )

                                            DispatchQueue.main.async {
                                                self.currentUser = updatedUser
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
                else {
                    print("❌ No user document found for current user!")
                }

                // Then check friend data
                self.db.collection("users").document(currentUserId)
                    .getDocument { document, error in
                        if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                            print("👥 Checking \(userData.friends.count) friends...")

                            for friendId in userData.friends {
                                self.db.collection("users").document(friendId)
                                    .getDocument { friendDoc, friendError in
                                        if let friendError = friendError {
                                            print(
                                                "❌ Error getting friend data for \(friendId): \(friendError.localizedDescription)"
                                            )
                                            return
                                        }

                                        if let friendData = friendDoc?.data() {
                                            if let friendUsername = friendData["username"]
                                                as? String
                                            {
                                                print(
                                                    "👤 Friend \(friendId): username = '\(friendUsername)'"
                                                )

                                                if friendUsername.isEmpty {
                                                    print("⚠️ Friend \(friendId) has EMPTY username")
                                                }
                                            }
                                            else {
                                                print(
                                                    "❌ Friend \(friendId) is MISSING username field"
                                                )
                                            }
                                        }
                                        else {
                                            print("❌ No document found for friend \(friendId)")
                                        }
                                    }
                            }
                        }
                    }

                // Check recent sessions to ensure they have usernames
                self.db.collection("sessions").whereField("userId", isEqualTo: currentUserId)
                    .order(by: "startTime", descending: true).limit(to: 5)
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
                                    if let currentUsername = self.currentUser?.username,
                                        !currentUsername.isEmpty
                                    {
                                        print(
                                            "🔄 Repairing session \(sessionId) with username: \(currentUsername)"
                                        )

                                        self.db.collection("sessions").document(sessionId)
                                            .updateData(["username": currentUsername]) { error in
                                                if let error = error {
                                                    print(
                                                        "❌ Failed to repair session: \(error.localizedDescription)"
                                                    )
                                                }
                                                else {
                                                    print(
                                                        "✅ Successfully repaired session \(sessionId)"
                                                    )
                                                }
                                            }
                                    }
                                }
                            }
                            else {
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
        db.collection("session_locations").whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isLessThan: Timestamp(date: thirtyDaysAgo))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, !documents.isEmpty
                else { return }

                let batch = self.db.batch()
                for doc in documents { batch.deleteDocument(doc.reference) }

                batch.commit { error in
                    if let error = error {
                        print("Error deleting old sessions: \(error)")
                    }
                    else {
                        print("Deleted \(documents.count) sessions older than 10 days")
                    }
                }
            }

        // Next, make sure we only keep the 10 most recent sessions within the last 30 days
        db.collection("session_locations").whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: thirtyDaysAgo))
            .order(by: "sessionEndTime", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, documents.count > 10
                else { return }

                // Keep the 10 most recent, delete the rest
                let docsToDelete = documents.suffix(from: 10)

                let batch = self.db.batch()
                for doc in docsToDelete { batch.deleteDocument(doc.reference) }

                batch.commit { error in
                    if let error = error {
                        print("Error pruning excess sessions: \(error)")
                    }
                    else {
                        print("Pruned \(docsToDelete.count) excess sessions for map display")
                    }
                }
            }
    }
    func saveSessionLocation(session: CompletedSession) {
        // First check if user has consented to map sharing AND manually enabled posting
        let shouldPostToMap = MapConsentManager.shared.shouldPostToMap()
        // Create a session ID
        let sessionId = "\(session.userId)_\(Int(Date().timeIntervalSince1970))"

        // Check if user has consented to leaderboards (for leaderboard functionality)
        let hasLeaderboardConsent = LeaderboardConsentManager.shared.canAddToLeaderboard()
        // Use consistent format for actual duration
        let validActualDuration = max(1, session.actualDuration)  // Ensure at least 1 minute is recorded

        // Calculate the real session end time
        let sessionEndTime = session.startTime.addingTimeInterval(Double(validActualDuration * 60))

        // Start with basic session data
        var sessionData: [String: Any] = [
            "userId": session.userId, "username": session.username,
            "location": GeoPoint(
                latitude: session.location.latitude,
                longitude: session.location.longitude
            ), "isCurrentlyFlipped": false, "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": session.wasSuccessful, "sessionDuration": session.duration,
            "actualDuration": validActualDuration,
            "sessionStartTime": Timestamp(date: session.startTime),
            "sessionEndTime": Timestamp(date: sessionEndTime),
            "createdAt": FieldValue.serverTimestamp(),
            "includeInLeaderboards": hasLeaderboardConsent,
        ]

        // Add building information if available - IMPORTANT: Use standardized building ID
        if let building = session.building {
            // Generate standardized building ID regardless of what's passed in
            let standardizedBuildingId = String(
                format: "building-%.6f-%.6f",
                building.coordinate.latitude,
                building.coordinate.longitude
            )
            sessionData["buildingId"] = standardizedBuildingId
            sessionData["buildingName"] = building.name
            sessionData["buildingLatitude"] = building.coordinate.latitude
            sessionData["buildingLongitude"] = building.coordinate.longitude
            print(
                "📍 Adding session to building: \(building.name) with ID: \(standardizedBuildingId)"
            )
        }
        else {
            print("⚠️ No building information available for this session")
        }

        // Check if this session should be saved to the map
        if !shouldPostToMap {
            print("🚫 Session not saved to map - user has not enabled 'Post to Map' feature")
            // Still save to leaderboards if user has given leaderboard consent
            if hasLeaderboardConsent {
                // Save only to leaderboards collection, not to session_locations
                db.collection("leaderboard_sessions").document(sessionId)
                    .setData(sessionData) { error in
                        if let error = error {
                            print("❌ Error saving to leaderboard: \(error.localizedDescription)")
                        }
                        else {
                            print("✅ Session saved to leaderboards only (not to map)")
                        }
                    }
            }
            return
        }

        // If we reach here, user has explicitly enabled map posting
        // Save to Firestore session_locations (which powers the map)
        db.collection("session_locations").document(sessionId)
            .setData(sessionData) { [weak self] error in
                if let error = error {
                    print("❌ SAVE ERROR: \(error.localizedDescription)")
                }
                else {
                    print(
                        "✅ SESSION SAVED TO MAP: \(sessionId) with duration \(validActualDuration) minutes"
                    )
                    // Debug output to verify data was saved correctly
                    print(
                        "🔍 Session saved with building data: \(sessionData["buildingId"] as? String ?? "none")"
                    )

                    // Prune old sessions to keep the map clean
                    self?.pruneOldSessions(forUserId: session.userId)

                    // Force refresh building leaderboard if building info exists and consent is given
                    if let building = session.building, hasLeaderboardConsent {
                        print("🔄 Triggering leaderboard refresh for building: \(building.name)")
                        // Add a short delay to ensure Firestore has time to process the write
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            RegionalViewModel.shared.leaderboardViewModel.loadBuildingLeaderboard(
                                building: building
                            )
                        }
                    }

                    // Clean up stale location data
                    if session.wasSuccessful {
                        // Only remove from active locations when session completed successfully
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
            .whereField("sessionEndTime", isLessThan: Timestamp(date: oneWeekAgo)).limit(to: 500)  // Process in batches to avoid timeout
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

                for document in documents { batch.deleteDocument(document.reference) }

                batch.commit { error in
                    if let error = error {
                        print("Error deleting old sessions: \(error.localizedDescription)")
                    }
                    else {
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
// Add this extension to FirebaseManager.swift

extension FirebaseManager {
    // Check if the user has already completed their first session
    func hasCompletedFirstSession(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "isPotentialFirstTimeUser") {
            print(
                "🏆 FIRST SESSION OVERRIDE: Fresh install with new account, forcing first-time experience"
            )
            completion(false)
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        // Check first_sessions collection first
        db.collection("first_sessions").document(userId)
            .getDocument { document, error in
                if let error = error {
                    print("Error checking first session: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if let document = document, document.exists {
                    // User already has a first session record
                    completion(true)
                    return
                }

                // Also check sessions collection as a backup
                self.db.collection("sessions").whereField("userId", isEqualTo: userId).limit(to: 1)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error checking regular sessions: \(error.localizedDescription)")
                            completion(false)
                            return
                        }

                        // If there are any documents, the user has completed at least one session
                        completion(!(snapshot?.documents.isEmpty ?? true))
                    }
            }
    }

    // Create a first session entry in the leaderboard
    func recordFirstSession(
        duration: Int,
        wasSuccessful: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let username = self.currentUser?.username ?? "User"

        // Create first session document
        let firstSessionData: [String: Any] = [
            "userId": userId, "username": username, "duration": duration,
            "wasSuccessful": wasSuccessful, "timestamp": FieldValue.serverTimestamp(),
        ]

        // Save to first_sessions collection
        db.collection("first_sessions").document(userId)
            .setData(firstSessionData) { error in
                if let error = error {
                    print("Error saving first session: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                print("First session recorded successfully")
                completion(true)
            }
        UserDefaults.standard.set(false, forKey: "isPotentialFirstTimeUser")
    }
    // For a truly fresh install, ensure first time experience
    func ensureFirstTimeExperience() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "isPotentialFirstTimeUser") {

            guard let userId = Auth.auth().currentUser?.uid else { return }

            // ONLY clear first_sessions entry to ensure proper first-time experience
            print("🧹 FRESH INSTALL: Clearing first_sessions record if it exists")

            db.collection("first_sessions").document(userId)
                .delete { error in
                    if let error = error {
                        print("⚠️ Error clearing first session: \(error.localizedDescription)")
                    }
                    else {
                        print("✅ Successfully cleared first_sessions record")
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
    let endTime: Date
    let building: BuildingInfo?
}
