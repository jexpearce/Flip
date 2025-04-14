import CoreLocation
import FirebaseFirestore
import SwiftUI

class GlobalWeeklyLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    func loadGlobalWeeklyLeaderboard() {
        isLoading = true

        // Calculate the current week's start date
        let calendar = Calendar.current
        let currentDate = Date()
        var components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: currentDate
        )
        components.weekday = 2  // Monday
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let weekStart = calendar.date(from: components) else {
            self.isLoading = false
            return
        }

        print("🗓️ Global Weekly leaderboard from: \(weekStart)")

        // First, fetch all sessions from this week
        db.collection("sessions").whereField("wasSuccessful", isEqualTo: true)
            .whereField("startTime", isGreaterThan: Timestamp(date: weekStart))
            .getDocuments(source: .default) { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching global sessions: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }

                print("📊 Found \(documents.count) total global sessions this week")

                // Dictionary to track each user's total time
                var userWeeklyData: [String: (userId: String, username: String, minutes: Int)] = [:]

                // Collection of user IDs we need to fetch privacy settings for
                var userIdsToCheck = Set<String>()

                // Process each session document
                for document in documents {
                    let data = document.data()

                    // Extract basic session info
                    guard let userId = data["userId"] as? String,
                        let actualDuration = data["actualDuration"] as? Int
                    else { continue }

                    // Add this user ID to the list we need to check privacy for
                    userIdsToCheck.insert(userId)

                    // Get temp username (will be updated later if needed)
                    let tempUsername = data["username"] as? String ?? "User"

                    // Update the user's total time
                    if let existingData = userWeeklyData[userId] {
                        userWeeklyData[userId] = (
                            userId: userId, username: existingData.username,
                            minutes: existingData.minutes + actualDuration
                        )
                    }
                    else {
                        userWeeklyData[userId] = (
                            userId: userId, username: tempUsername, minutes: actualDuration
                        )
                    }
                }

                // No data found - update UI now
                if userWeeklyData.isEmpty {
                    DispatchQueue.main.async {
                        self.leaderboardEntries = []
                        self.isLoading = false
                    }
                    return
                }

                // Now check privacy settings for all users
                self.fetchUserPrivacySettings(userIds: Array(userIdsToCheck)) { privacySettings in
                    // Get all usernames respecting privacy
                    self.fetchUsernamesRespectingPrivacy(
                        Array(userIdsToCheck),
                        privacySettings: privacySettings
                    ) { usernameMap in
                        // Get scores and streaks
                        self.fetchUserScoresAndStreaks(Array(userIdsToCheck)) {
                            scoresMap,
                            streaksMap in
                            // Now build final entries respecting privacy
                            var entries: [GlobalLeaderboardEntry] = []

                            for (userId, userData) in userWeeklyData {
                                // Skip users who have opted out of leaderboards
                                if let userPrivacy = privacySettings[userId], userPrivacy.optOut {
                                    continue
                                }

                                // Determine if user should be anonymous
                                let isAnonymous = privacySettings[userId]?.isAnonymous ?? false
                                let displayUsername =
                                    isAnonymous
                                    ? "Anonymous" : (usernameMap[userId] ?? userData.username)

                                let entry = GlobalLeaderboardEntry(
                                    id: UUID().uuidString,  // Unique ID for SwiftUI
                                    userId: userId,
                                    username: displayUsername,
                                    minutes: userData.minutes,
                                    score: scoresMap[userId],
                                    streakStatus: streaksMap[userId] ?? .none,
                                    isAnonymous: isAnonymous
                                )

                                entries.append(entry)
                            }

                            // Sort by minutes
                            entries.sort { $0.minutes > $1.minutes }

                            DispatchQueue.main.async {
                                self.leaderboardEntries = entries
                                self.isLoading = false
                            }
                        }
                    }
                }
            }
    }

    // Helper methods for fetching user data (same as RegionalLeaderboardViewModel)
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) -> Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId)
                .getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data() {
                        // Get opt-out setting (default to false)
                        let optOut = data["regionalOptOut"] as? Bool ?? false

                        // Get display mode (default to normal)
                        let displayModeString = data["regionalDisplayMode"] as? String ?? "normal"
                        let isAnonymous = displayModeString == "anonymous"

                        result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                    }
                    else {
                        // Use defaults if no settings document
                        result[userId] = (optOut: false, isAnonymous: false)
                    }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(result) }
    }

    private func fetchUsernamesRespectingPrivacy(
        _ userIds: [String],
        privacySettings: [String: (optOut: Bool, isAnonymous: Bool)],
        completion: @escaping ([String: String]) -> Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        // First check our cache
        var result: [String: String] = [:]
        var idsToFetch: [String] = []

        for userId in userIds {
            // Check if user is anonymous based on privacy settings
            if let privacySetting = privacySettings[userId], privacySetting.isAnonymous {
                result[userId] = "Anonymous"
                continue
            }

            if let cachedUser = userCache[userId],
                !cachedUser.username.isEmpty && cachedUser.username != "User"
            {
                result[userId] = cachedUser.username
            }
            else if let currentUser = FirebaseManager.shared.currentUser, currentUser.id == userId,
                !currentUser.username.isEmpty
            {
                result[userId] = currentUser.username
                // Update cache
                userCache[userId] = UserCacheItem(
                    userId: userId,
                    username: currentUser.username,
                    profileImageURL: currentUser.profileImageURL
                )
            }
            else {
                idsToFetch.append(userId)
            }
        }

        // If we have all usernames already, return
        if idsToFetch.isEmpty {
            completion(result)
            return
        }

        // Fetch in batches of 10 to avoid Firestore limitations
        let batchSize = 10
        let dispatchGroup = DispatchGroup()

        for i in stride(from: 0, to: idsToFetch.count, by: batchSize) {
            let end = min(i + batchSize, idsToFetch.count)
            let batch = Array(idsToFetch[i..<end])

            dispatchGroup.enter()
            fetchUserBatch(batch) { batchResult in
                // Add this batch to our results
                for (id, username) in batchResult {
                    // Apply privacy settings - override with "Anonymous" if needed
                    if let privacySetting = privacySettings[id], privacySetting.isAnonymous {
                        result[id] = "Anonymous"
                    }
                    else {
                        result[id] = username
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { completion(result) }
    }

    private func fetchUserBatch(
        _ userIds: [String],
        completion: @escaping ([String: String]) -> Void
    ) {
        let db = Firestore.firestore()
        var batchResult: [String: String] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("users").document(userId)
                .getDocument(source: .default) { document, error in
                    defer { dispatchGroup.leave() }

                    // Try to get username from document
                    if let data = document?.data(), let username = data["username"] as? String,
                        !username.isEmpty
                    {
                        batchResult[userId] = username

                        // Update our cache
                        self.userCache[userId] = UserCacheItem(
                            userId: userId,
                            username: username,
                            profileImageURL: data["profileImageURL"] as? String
                        )
                    }
                    else {
                        batchResult[userId] = "User"
                    }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(batchResult) }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId)
                .getDocument(source: .default) { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data() {
                        if let score = data["score"] as? Double { scores[userId] = score }
                    }
                }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak").document("current")
                .getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] = StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(scores, streaks) }
    }
}
