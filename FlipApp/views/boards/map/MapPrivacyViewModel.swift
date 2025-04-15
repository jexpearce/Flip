import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// Enhanced MapPrivacyViewModel with selective friend options
class MapPrivacyViewModel: ObservableObject {
    @Published var visibilityLevel: LocationVisibilityLevel = .friendsOnly
    @Published var showSessionHistory: Bool = true
    @Published var selectedFriends: Set<String> = []
    @Published var excludedFriends: Set<String> = []
    @Published var allFriends: [FirebaseManager.FlipUser] = []
    @Published var isLoadingFriends: Bool = false
    private let db = Firestore.firestore()
    init() {
        loadSettings()
        loadFriends()
    }
    private func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoadingFriends = true
        // Get the current user's friends list
        db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    let friendIds = userData.friends
                    // Create a dispatch group to wait for all friend data to load
                    let dispatchGroup = DispatchGroup()
                    var loadedFriends: [FirebaseManager.FlipUser] = []
                    // Load each friend's details
                    for friendId in friendIds {
                        dispatchGroup.enter()
                        self.db.collection("users").document(friendId)
                            .getDocument { document, error in
                                defer { dispatchGroup.leave() }
                                if let friendData = try? document?
                                    .data(as: FirebaseManager.FlipUser.self)
                                {
                                    loadedFriends.append(friendData)
                                }
                            }
                    }
                    // When all friends are loaded, update the UI
                    dispatchGroup.notify(queue: .main) {
                        self.allFriends = loadedFriends
                        self.isLoadingFriends = false
                    }
                }
                else {
                    self.isLoadingFriends = false
                }
            }
    }
    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        // Load visibility setting
                        if let visibilityString = data["visibilityLevel"] as? String,
                            let level = LocationVisibilityLevel(rawValue: visibilityString)
                        {
                            self.visibilityLevel = level
                        }
                        // Load show history setting
                        if let showHistory = data["showSessionHistory"] as? Bool {
                            self.showSessionHistory = showHistory
                        }
                        // Load selected friends
                        if let selectedFriendsArray = data["selectedFriends"] as? [String] {
                            self.selectedFriends = Set(selectedFriendsArray)
                        }
                        // Load excluded friends
                        if let excludedFriendsArray = data["excludedFriends"] as? [String] {
                            self.excludedFriends = Set(excludedFriendsArray)
                        }
                    }
                }
                else {
                    // Create default settings if they don't exist
                    self.saveSettings()
                }
            }
    }

    func updateVisibilityLevel(_ level: LocationVisibilityLevel) {
        visibilityLevel = level
        saveSettings()
    }
    func toggleFriendSelection(_ friendId: String) {
        if visibilityLevel == .selectiveFriends {
            // Toggle selection for "Only These Friends" mode
            if selectedFriends.contains(friendId) {
                selectedFriends.remove(friendId)
            }
            else {
                selectedFriends.insert(friendId)
            }
        }
        else if visibilityLevel == .allExcept {
            // Toggle exclusion for "All Friends Except" mode
            if excludedFriends.contains(friendId) {
                excludedFriends.remove(friendId)
            }
            else {
                excludedFriends.insert(friendId)
            }
        }
        saveSettings()
    }
    func isFriendSelected(_ friendId: String) -> Bool {
        if visibilityLevel == .selectiveFriends {
            return selectedFriends.contains(friendId)
        }
        else if visibilityLevel == .allExcept {
            return !excludedFriends.contains(friendId)
        }
        return false
    }
    func toggleShowSessionHistory() {
        showSessionHistory.toggle()
        saveSettings()
    }

    func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        var settings: [String: Any] = [
            "visibilityLevel": visibilityLevel.rawValue, "showSessionHistory": showSessionHistory,
            "lastUpdated": FieldValue.serverTimestamp(),
        ]
        // Add selected or excluded friends based on mode
        if visibilityLevel == .selectiveFriends {
            settings["selectedFriends"] = Array(selectedFriends)
        }
        else if visibilityLevel == .allExcept {
            settings["excludedFriends"] = Array(excludedFriends)
        }

        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .setData(settings, merge: true) { error in
                if let error = error {
                    print("Error saving map privacy settings: \(error.localizedDescription)")
                }
            }
    }
}
