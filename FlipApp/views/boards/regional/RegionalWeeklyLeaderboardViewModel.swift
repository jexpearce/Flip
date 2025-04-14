import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class RegionalWeeklyLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var countyName: String = "Your Area"
    private let regionRadiusInMiles: Double = 15.0  // ~15 mile radius

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    func loadRegionalWeeklyLeaderboard() {
        isLoading = true
        Task { @MainActor in
            // Get the current user's location
            let location = LocationHandler.shared.lastLocation

            // Determine the county name for display
            determineCountyName(from: location) { [weak self] countyName in
                guard let self = self else { return }

                // Update the county name for display
                DispatchQueue.main.async { self.countyName = countyName }

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

                print("🗓️ Regional Weekly leaderboard from: \(weekStart)")

                // Convert miles to meters for geoqueries
                let regionRadiusInMeters = self.regionRadiusInMiles * 1609.34

                // First, fetch all sessions from this week in the region
                self.db.collection("session_locations")
                    .whereField("sessionStartTime", isGreaterThan: Timestamp(date: weekStart))
                    .whereField("includeInLeaderboards", isEqualTo: true)  // Only include sessions where user consented
                    .getDocuments(source: .default) { [weak self] snapshot, error in
                        guard let self = self else { return }

                        if let error = error {
                            print("Error fetching regional sessions: \(error.localizedDescription)")
                            DispatchQueue.main.async { self.isLoading = false }
                            return
                        }

                        guard let documents = snapshot?.documents else {
                            DispatchQueue.main.async { self.isLoading = false }
                            return
                        }

                        print("📊 Found \(documents.count) total sessions this week")

                        // Filter sessions by distance if location is available
                        var filteredDocuments = documents

                        // If we have valid location, filter by distance
                        if location.horizontalAccuracy > 0 {
                            filteredDocuments = documents.filter { document in
                                if let geoPoint = document.data()["location"] as? GeoPoint,
                                    let lastFlipWasSuccessful =
                                        document.data()["lastFlipWasSuccessful"] as? Bool,
                                    lastFlipWasSuccessful  // Only include successful sessions
                                {
                                    let sessionLocation = CLLocation(
                                        latitude: geoPoint.latitude,
                                        longitude: geoPoint.longitude
                                    )
                                    let distance = location.distance(from: sessionLocation)
                                    return distance <= regionRadiusInMeters
                                }
                                return false
                            }
                        }

                        print("📍 Found \(filteredDocuments.count) sessions in region")

                        // Process the filtered documents
                        var userData: [String: (userId: String, username: String, minutes: Int)] =
                            [:]
                        var userIdsToFetch = Set<String>()

                        for document in filteredDocuments {
                            if let userId = document.data()["userId"] as? String,
                                let username = document.data()["username"] as? String,
                                let actualDuration = document.data()["actualDuration"] as? Int
                            {
                                userIdsToFetch.insert(userId)
                                if let existing = userData[userId] {
                                    userData[userId] = (
                                        userId: userId, username: existing.username,
                                        minutes: existing.minutes + actualDuration
                                    )
                                }
                                else {
                                    userData[userId] = (
                                        userId: userId, username: username, minutes: actualDuration
                                    )
                                }
                            }
                        }

                        // Fetch privacy settings for all users
                        self.fetchUserPrivacySettings(userIds: Array(userIdsToFetch)) {
                            privacySettings in
                            // Filter out users who have opted out
                            let filteredUserData = userData.filter { userId, _ in
                                !(privacySettings[userId]?.optOut ?? false)
                            }

                            // Process users and create leaderboard entries
                            self.processUsers(userData: filteredUserData) { entries in
                                DispatchQueue.main.async {
                                    self.leaderboardEntries = entries
                                    self.isLoading = false
                                }
                            }
                        }
                    }
            }
        }
    }

    private func processUsers(
        userData: [String: (userId: String, username: String, minutes: Int)],
        completion: @escaping ([GlobalLeaderboardEntry]) -> Void
    ) {
        // No data found - update UI now
        if userData.isEmpty {
            DispatchQueue.main.async {
                self.leaderboardEntries = []
                self.isLoading = false
            }
            return
        }

        // Get the user IDs to check privacy settings
        let userIds = Array(userData.keys)

        // Check privacy settings for all users
        fetchUserPrivacySettings(userIds: userIds) { privacySettings in
            // Get scores and streaks
            self.fetchUserScoresAndStreaks(userIds) { scoresMap, streaksMap in
                // Now build final entries respecting privacy
                var entries: [GlobalLeaderboardEntry] = []

                for (userId, userInfo) in userData {
                    // Skip users who have opted out of leaderboards
                    if let userPrivacy = privacySettings[userId], userPrivacy.optOut { continue }

                    // Determine if user should be anonymous
                    let isAnonymous = privacySettings[userId]?.isAnonymous ?? false
                    let displayUsername = isAnonymous ? "Anonymous" : userInfo.username

                    let entry = GlobalLeaderboardEntry(
                        id: UUID().uuidString,  // Unique ID for SwiftUI
                        userId: userId,
                        username: displayUsername,
                        minutes: userInfo.minutes,
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

    // Helper method to determine county/region name
    private func determineCountyName(
        from location: CLLocation,
        completion: @escaping (String) -> Void
    ) {
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            var regionName = "Your Area"

            if let placemark = placemarks?.first {
                // Try to get the most specific name available
                if let locality = placemark.locality {
                    // City/town name
                    regionName = locality
                }
                else if let subAdministrativeArea = placemark.subAdministrativeArea {
                    // County/district name
                    regionName = subAdministrativeArea
                }
                else if let administrativeArea = placemark.administrativeArea {
                    // State/province name
                    regionName = administrativeArea
                }
            }

            completion(regionName)
        }
    }

    // Helper methods (same as GlobalLeaderboardViewModel)
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
