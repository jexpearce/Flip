import CoreLocation
import FirebaseFirestore
import SwiftUI

class RegionalAllTimeLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var countyName: String = "Your Area"
    private let regionRadiusInMiles: Double = 15.0  // ~15 mile radius

    private let db = Firestore.firestore()

    @MainActor func loadRegionalAllTimeLeaderboard() {
        isLoading = true

        // Get the current user's location
        let location = LocationHandler.shared.lastLocation

        // Determine the county name for display
        determineCountyName(from: location) { [weak self] countyName in
            guard let self = self else { return }

            // Update the county name for display
            DispatchQueue.main.async { self.countyName = countyName }

            // Convert miles to meters for geoqueries
            let regionRadiusInMeters = self.regionRadiusInMiles * 1609.34

            // Directly query the users collection to get all users
            self.db.collection("users")
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }

                    if let error = error {
                        print("Error fetching users: \(error.localizedDescription)")
                        DispatchQueue.main.async { self.isLoading = false }
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        DispatchQueue.main.async { self.isLoading = false }
                        return
                    }

                    print("👥 Found \(documents.count) total users")

                    // Extract user IDs and initial data
                    var userIds: [String] = []
                    var userData: [String: (userId: String, username: String, minutes: Int)] = [:]

                    for document in documents {
                        let data = document.data()
                        let userId = document.documentID
                        let totalFocusTime = data["totalFocusTime"] as? Int ?? 0
                        let username = data["username"] as? String ?? "User"

                        // Skip users with zero time
                        if totalFocusTime > 0 {
                            userIds.append(userId)
                            userData[userId] = (
                                userId: userId, username: username, minutes: totalFocusTime
                            )
                        }
                    }

                    // Now filter by location - check if each user has sessions in the region
                    if location.horizontalAccuracy > 0 {
                        self.filterUsersByRegion(
                            userIds: userIds,
                            location: location,
                            regionRadius: regionRadiusInMeters
                        ) { usersInRegion in
                            // Filter the user data to only those in region
                            let filteredUserData = userData.filter {
                                usersInRegion.contains($0.key)
                            }
                            print(
                                "📍 Found \(filteredUserData.count) users with sessions in \(self.regionRadiusInMiles) mile radius"
                            )

                            // Process the filtered users
                            self.processUsers(userData: filteredUserData)
                        }
                    }
                    else {
                        // If location is not available, use all users
                        self.processUsers(userData: userData)
                    }
                }
        }
    }

    private func filterUsersByRegion(
        userIds: [String],
        location: CLLocation,
        regionRadius: Double,
        completion: @escaping (Set<String>) -> Void
    ) {
        var usersInRegion = Set<String>()
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Check session_locations for this user to see if any are in our region
            db.collection("session_locations").whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }

                    var userHasSessionInRegion = false

                    if let documents = snapshot?.documents {
                        for document in documents {
                            if let geoPoint = document.data()["location"] as? GeoPoint {
                                let sessionLocation = CLLocation(
                                    latitude: geoPoint.latitude,
                                    longitude: geoPoint.longitude
                                )

                                // Check if within region radius
                                let distance = location.distance(from: sessionLocation)
                                if distance <= regionRadius {
                                    userHasSessionInRegion = true
                                    break
                                }
                            }
                        }
                    }

                    if userHasSessionInRegion { usersInRegion.insert(userId) }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(usersInRegion) }
    }

    private func processUsers(userData: [String: (userId: String, username: String, minutes: Int)])
    {
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
