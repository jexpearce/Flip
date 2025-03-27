import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class SearchManager: ObservableObject {
    @Published var searchResults: [FirebaseManager.FlipUser] = []
    @Published var recommendations: [FirebaseManager.FlipUser] = []
    @Published var isSearching = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCancelRequestAlert = false
    @Published var userToCancelRequest: FirebaseManager.FlipUser?
    @Published var showMoreRecommendations = false

    // New properties for mutual friends functionality
    @Published var mutualFriendCounts: [String: Int] = [:]

    private let firebaseManager = FirebaseManager.shared
    private var currentUserData: FirebaseManager.FlipUser?
    private var allUsers: [FirebaseManager.FlipUser] = []

    init() {
        loadCurrentUser()
        loadAllUsers()
    }

    private func loadCurrentUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let userData = try? document?.data(
                    as: FirebaseManager.FlipUser.self)
                {
                    self?.currentUserData = userData
                    // After loading current user, calculate mutual friends
                    self?.calculateMutualFriends()
                }
            }
    }

    // Calculate mutual friends for all users
    private func calculateMutualFriends() {
        guard let currentUser = currentUserData else { return }

        // Reset counts
        mutualFriendCounts = [:]

        for user in allUsers {
            // Skip calculating for self
            if user.id == currentUser.id {
                continue
            }

            // Find mutual friends (intersection of friends arrays)
            let mutualCount = Set(currentUser.friends).intersection(
                Set(user.friends)
            ).count
            mutualFriendCounts[user.id] = mutualCount
        }

        // Sort recommendations based on mutual friends count
        sortRecommendations()
    }

    private func sortRecommendations() {
        // Sort recommendations by mutual friend count (descending)
        recommendations.sort { userA, userB in
            let mutualCountA = mutualFriendCounts[userA.id] ?? 0
            let mutualCountB = mutualFriendCounts[userB.id] ?? 0

            // If mutual counts are the same, sort alphabetically
            if mutualCountA == mutualCountB {
                return userA.username.lowercased() < userB.username.lowercased()
            }

            return mutualCountA > mutualCountB
        }

        // Force UI update
        objectWillChange.send()
    }

    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        // First, check for exact matches
        firebaseManager.db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: query)
            .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                        self.isSearching = false
                    }
                    return
                }

                var exactMatches = [FirebaseManager.FlipUser]()

                if let documents = snapshot?.documents {
                    exactMatches = documents.compactMap { document in
                        try? document.data(as: FirebaseManager.FlipUser.self)
                    }.filter { $0.id != Auth.auth().currentUser?.uid }
                }

                // Now handle fuzzy search for users with mutual friends
                let fuzzyMatches = self.performFuzzySearch(query: query)

                // Combine results, removing duplicates
                let combinedResults = self.combinedUniqueResults(
                    exact: exactMatches, fuzzy: fuzzyMatches)

                DispatchQueue.main.async {
                    self.searchResults = combinedResults
                    self.isSearching = false
                }
            }
    }

    // Perform fuzzy search (with tolerance for typos) on users with mutual friends
    private func performFuzzySearch(query: String) -> [FirebaseManager.FlipUser]
    {
        let lowercaseQuery = query.lowercased()

        // Only apply fuzzy search to users with mutual friends
        return allUsers.filter { user in
            // Skip current user
            if user.id == Auth.auth().currentUser?.uid {
                return false
            }

            // Get mutual count
            let mutualCount = mutualFriendCounts[user.id] ?? 0

            // Only apply fuzzy matching for users with mutual friends
            if mutualCount > 0 {
                let username = user.username.lowercased()

                // Simple fuzzy matching - calculate the edit distance
                let distance = calculateLevenshteinDistance(
                    username, lowercaseQuery)

                // The more mutual friends, the more typo tolerance we allow
                let maxAllowedDistance = min(2 + (mutualCount / 2), 4)

                // If the distance is within our tolerance
                if distance <= maxAllowedDistance {
                    return true
                }

                // Also check if query is contained within username
                return username.contains(lowercaseQuery)
            }

            // No fuzzy match for users without mutual friends
            return false
        }
    }

    // Combine exact and fuzzy search results, removing duplicates
    private func combinedUniqueResults(
        exact: [FirebaseManager.FlipUser], fuzzy: [FirebaseManager.FlipUser]
    ) -> [FirebaseManager.FlipUser] {
        var combinedResults = exact
        let exactIds = Set(exact.map { $0.id })

        // Add fuzzy matches that aren't already in exact matches
        for user in fuzzy {
            if !exactIds.contains(user.id) {
                combinedResults.append(user)
            }
        }

        // Sort by mutual friend count (descending)
        combinedResults.sort { userA, userB in
            let mutualCountA = mutualFriendCounts[userA.id] ?? 0
            let mutualCountB = mutualFriendCounts[userB.id] ?? 0

            // If mutual counts are equal, sort by username
            if mutualCountA == mutualCountB {
                return userA.username.lowercased() < userB.username.lowercased()
            }

            return mutualCountA > mutualCountB
        }

        return combinedResults
    }

    // Calculate Levenshtein distance for fuzzy matching
    private func calculateLevenshteinDistance(_ a: String, _ b: String) -> Int {
        let aCount = a.count
        let bCount = b.count

        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }

        var matrix = Array(
            repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1
        )

        for i in 0...aCount {
            matrix[i][0] = i
        }

        for j in 0...bCount {
            matrix[0][j] = j
        }

        let aChars = Array(a)
        let bChars = Array(b)

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,  // Deletion
                    matrix[i][j - 1] + 1,  // Insertion
                    matrix[i - 1][j - 1] + cost  // Substitution
                )
            }
        }

        return matrix[aCount][bCount]
    }

    // Simplified method to load all users
    private func loadAllUsers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Get all users except the current user
        firebaseManager.db.collection("users")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let documents = snapshot?.documents {
                    // Filter out only the current user
                    self.allUsers = documents.compactMap { document in
                        try? document.data(as: FirebaseManager.FlipUser.self)
                    }.filter { user in
                        return user.id != userId  // Only filter out self
                    }

                    // Calculate mutual friends
                    self.calculateMutualFriends()

                    DispatchQueue.main.async {
                        self.recommendations = self.allUsers
                    }
                }
            }
    }

    func requestStatus(for userId: String) -> RequestStatus {
        guard let currentUser = currentUserData else { return .none }

        if currentUser.friends.contains(userId) {
            return .friends
        }
        if currentUser.sentRequests.contains(userId) {
            return .sent
        }
        return .none
    }

    // Get mutual friend count for a user
    func mutualFriendCount(for userId: String) -> Int {
        return mutualFriendCounts[userId] ?? 0
    }

    func sendFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
            let currentUsername = FirebaseManager.shared.currentUser?.username
        else { return }

        print("Sending friend request from \(currentUsername) to \(userId)")

        // Update current user's "sentRequests" array
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayUnion([userId])
            ])

        // Update target user's "friendRequests" array
        FirebaseManager.shared.db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayUnion([currentUserId])
            ])

        // Create a notification document for the friend request
        let notificationData: [String: Any] = [
            "type": "friend_request",
            "fromUserId": currentUserId,
            "fromUsername": currentUsername,
            "timestamp": FieldValue.serverTimestamp(),
            "message": "\(currentUsername) wants to add you as a friend",
            "read": false,
            "silent": false,
        ]

        // Add to the target user's notifications collection
        FirebaseManager.shared.db.collection("users").document(userId)
            .collection("notifications")
            .document()
            .setData(notificationData) { error in
                if let error = error {
                    print(
                        "Error creating friend request notification: \(error.localizedDescription)"
                    )
                } else {
                    print("Friend request notification created successfully")
                }
            }

        // Update local state
        DispatchQueue.main.async {
            self.updateRequestStatus(for: userId, to: .sent)
        }
    }

    func updateRequestStatus(for userId: String, to status: RequestStatus) {
        // This updates our local cache to reflect the new status
        // without requiring a server round-trip
        loadCurrentUser()

        // Force UI update
        DispatchQueue.main.async {
            // If we have search results, update the status in those
            if let index = self.searchResults.firstIndex(where: {
                $0.id == userId
            }) {
                self.objectWillChange.send()
            }

            // If we have recommendations, update the status in those
            if let index = self.recommendations.firstIndex(where: {
                $0.id == userId
            }) {
                self.objectWillChange.send()
            }
        }

        // Prompt to cancel the request if needed
        if status == .sent {
            print("Request sent to user \(userId)")
        }
    }

    func promptCancelRequest(for user: FirebaseManager.FlipUser) {
        userToCancelRequest = user
        showCancelRequestAlert = true
    }

    func cancelFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Update current user's "sentRequests" array
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayRemove([userId])
            ])

        // Update target user's "friendRequests" array
        FirebaseManager.shared.db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayRemove([currentUserId])
            ])

        // Remove any pending friend request notifications
        FirebaseManager.shared.db.collection("users").document(userId)
            .collection("notifications")
            .whereField("type", isEqualTo: "friend_request")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let batch = FirebaseManager.shared.db.batch()

                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }

                    batch.commit { error in
                        if let error = error {
                            print(
                                "Error removing friend request notifications: \(error.localizedDescription)"
                            )
                        } else {
                            print(
                                "Friend request notifications removed successfully"
                            )
                        }
                    }
                }
            }

        // Update local state
        DispatchQueue.main.async {
            self.updateRequestStatus(for: userId, to: .none)
            // Clear any UI state
            self.showCancelRequestAlert = false
            self.userToCancelRequest = nil
        }
    }

    // Toggle show more recommendations
    func toggleShowMoreRecommendations() {
        showMoreRecommendations.toggle()
    }
}

// MARK: - SearchManager Extensions

// Extension for filtered recommendations
extension SearchManager {
    // Get users with mutual friends
    var usersWithMutuals: [FirebaseManager.FlipUser] {
        return recommendations.filter { user in
            let status = requestStatus(for: user.id)
            return status != .friends && (mutualFriendCounts[user.id] ?? 0) > 0
        }
    }

    // Get other users (without mutual friends)
    var otherUsers: [FirebaseManager.FlipUser] {
        return recommendations.filter { user in
            let status = requestStatus(for: user.id)
            return status != .friends && (mutualFriendCounts[user.id] ?? 0) == 0
        }
    }

    // Get number of recommendations to show
    var otherUsersToShow: [FirebaseManager.FlipUser] {
        if showMoreRecommendations {
            return otherUsers
        } else {
            // Show first 5 users when not expanded
            return Array(otherUsers.prefix(5))
        }
    }

    // Has more recommendations to show
    var hasMoreOtherUsers: Bool {
        return otherUsers.count > 5
    }

    // Filter out users who are already friends from search results
    var filteredSearchResults: [FirebaseManager.FlipUser] {
        searchResults.filter { user in
            let status = requestStatus(for: user.id)
            return status != .friends
        }
    }
}
