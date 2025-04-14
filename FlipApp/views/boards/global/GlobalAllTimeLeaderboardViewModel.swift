import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class GlobalAllTimeLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()

    func loadGlobalAllTimeLeaderboard() {
        isLoading = true

        // Directly query the users collection to get all users sorted by total focus time
        db.collection("users").order(by: "totalFocusTime", descending: true).limit(to: 100)  // Fetch more than we need in case some users opt out
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching global users: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { self.isLoading = false }
                    return
                }

                print("📊 Found \(documents.count) total users for all time leaderboard")

                // Dictionary to store user data with total focus time
                var userData: [(userId: String, username: String, minutes: Int)] = []

                // Collection of user IDs we need to fetch privacy settings for
                var userIdsToCheck = [String]()

                // Process each user document
                for document in documents {
                    let data = document.data()

                    // Skip users with zero totalFocusTime
                    guard let totalFocusTime = data["totalFocusTime"] as? Int, totalFocusTime > 0
                    else { continue }

                    let userId = document.documentID
                    let username = data["username"] as? String ?? "User"

                    userIdsToCheck.append(userId)
                    userData.append((userId: userId, username: username, minutes: totalFocusTime))
                }

                // No data found - update UI now
                if userData.isEmpty {
                    DispatchQueue.main.async {
                        self.leaderboardEntries = []
                        self.isLoading = false
                    }
                    return
                }

                // Now check privacy settings for all users
                self.fetchUserPrivacySettings(userIds: userIdsToCheck) { privacySettings in
                    // Get scores and streaks
                    self.fetchUserScoresAndStreaks(userIdsToCheck) { scoresMap, streaksMap in
                        // Now build final entries respecting privacy
                        var entries: [GlobalLeaderboardEntry] = []

                        for userInfo in userData {
                            // Skip users who have opted out of leaderboards
                            if let userPrivacy = privacySettings[userInfo.userId],
                                userPrivacy.optOut
                            {
                                continue
                            }

                            // Determine if user should be anonymous
                            let isAnonymous = privacySettings[userInfo.userId]?.isAnonymous ?? false
                            let displayUsername = isAnonymous ? "Anonymous" : userInfo.username

                            let entry = GlobalLeaderboardEntry(
                                id: UUID().uuidString,  // Unique ID for SwiftUI
                                userId: userInfo.userId,
                                username: displayUsername,
                                minutes: userInfo.minutes,
                                score: scoresMap[userInfo.userId],
                                streakStatus: streaksMap[userInfo.userId] ?? .none,
                                isAnonymous: isAnonymous
                            )

                            entries.append(entry)
                        }

                        // Sort by minutes (already pre-sorted from Firestore, but just in case)
                        entries.sort { $0.minutes > $1.minutes }

                        DispatchQueue.main.async {
                            self.leaderboardEntries = entries
                            self.isLoading = false
                        }
                    }
                }
            }
    }

    // Helper methods for fetching user data (same implementations as GlobalWeeklyLeaderboardViewModel)
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
