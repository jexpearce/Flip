import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var friendFailureNotifications = true
    @Published var visibilityLevel: LocationVisibilityLevel = .friendsOnly
    @Published var showSessionHistory = true
    @Published var commentNotifications = true
    @Published var regionalDisplayMode: RegionalDisplayMode = .normal
    @Published var regionalOptOut = false

    private let db = Firestore.firestore()

    init() { loadSettings() }

    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Load notification and privacy settings
        db.collection("user_settings").document(userId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists, let data = document.data() {
                    // Load friend failure notification setting (default to ON if not set)
                    self.friendFailureNotifications =
                        data["friendFailureNotifications"] as? Bool ?? true

                    // Load comment notifications setting (default to ON if not set)
                    self.commentNotifications = data["commentNotifications"] as? Bool ?? true

                    // Load visibility level (default to friendsOnly if not set)
                    if let visibilityString = data["visibilityLevel"] as? String,
                        let visibility = LocationVisibilityLevel(rawValue: visibilityString)
                    {
                        self.visibilityLevel = visibility
                    }

                    // Load session history setting (default to ON if not set)
                    self.showSessionHistory = data["showSessionHistory"] as? Bool ?? true

                    // Load regional display mode (default to normal if not set)
                    if let modeString = data["regionalDisplayMode"] as? String,
                        let mode = RegionalDisplayMode(rawValue: modeString)
                    {
                        self.regionalDisplayMode = mode
                    }

                    // Load regional opt out setting (default to OFF if not set)
                    self.regionalOptOut = data["regionalOptOut"] as? Bool ?? false
                }
                else {
                    // Set defaults and save them
                    self.friendFailureNotifications = true
                    self.commentNotifications = true
                    self.visibilityLevel = .friendsOnly
                    self.showSessionHistory = true
                    self.regionalDisplayMode = .normal
                    self.regionalOptOut = false
                    self.saveSettings()
                }
            }
    }

    func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let settings: [String: Any] = [
            "friendFailureNotifications": friendFailureNotifications,
            "commentNotifications": commentNotifications,
            "visibilityLevel": visibilityLevel.rawValue, "showSessionHistory": showSessionHistory,
            "regionalDisplayMode": regionalDisplayMode.rawValue, "regionalOptOut": regionalOptOut,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        db.collection("user_settings").document(userId)
            .setData(settings, merge: true) { error in
                if let error = error {
                    print("Error saving settings: \(error.localizedDescription)")
                }
            }
    }

    func toggleCommentNotifications() {
        commentNotifications.toggle()
        saveSettings()
    }

    func updateVisibilityLevel(_ level: LocationVisibilityLevel) {
        visibilityLevel = level
        saveSettings()
    }

    func toggleFriendFailureNotifications() {
        friendFailureNotifications.toggle()
        saveSettings()
    }

    // New methods for regional privacy settings
    func updateRegionalDisplayMode(_ mode: RegionalDisplayMode) {
        regionalDisplayMode = mode
        saveSettings()

        // Update in UserSettingsManager too for immediate effect
        UserSettingsManager.shared.setRegionalDisplayMode(mode)
    }

    func toggleRegionalOptOut() {
        regionalOptOut.toggle()
        saveSettings()

        // Update in UserSettingsManager too for immediate effect
        UserSettingsManager.shared.setRegionalOptOut(regionalOptOut)
    }
}
