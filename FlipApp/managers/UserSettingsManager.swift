import FirebaseAuth
import FirebaseFirestore
import SwiftUI

enum RegionalDisplayMode: String, CaseIterable {
    case normal = "normal"
    case anonymous = "anonymous"
}

class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()
    @Published private(set) var regionalDisplayMode: RegionalDisplayMode = .normal
    @Published private(set) var regionalOptOut: Bool = false
    @Published private(set) var friendFailureNotifications: Bool = true
    @Published private(set) var commentNotifications: Bool = true
    @Published private(set) var visibilityLevel: String = "friendsOnly"
    @Published private(set) var showSessionHistory: Bool = true
    // Add this new property for live session privacy
    @Published private(set) var restrictLiveSessionsToFriends: Bool = false

    private let db = Firestore.firestore()
    private var userSettingsCache: [String: Any]?
    private var userSettingsListener: ListenerRegistration?

    private init() { setupSettingsListener() }

    // Setup a listener for real-time updates to user settings
    private func setupSettingsListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Remove any existing listener
        userSettingsListener?.remove()

        // Set up a new listener
        userSettingsListener = db.collection("user_settings").document(userId)
            .addSnapshotListener { [weak self] document, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error listening for settings updates: \(error.localizedDescription)")
                    return
                }

                if let document = document, document.exists {
                    self.userSettingsCache = document.data()

                    // Update @Published properties from data
                    if let data = document.data() {
                        if let modeString = data["regionalDisplayMode"] as? String,
                            let mode = RegionalDisplayMode(rawValue: modeString)
                        {
                            self.regionalDisplayMode = mode
                        }
                        self.regionalOptOut = data["regionalOptOut"] as? Bool ?? false
                        self.friendFailureNotifications =
                            data["friendFailureNotifications"] as? Bool ?? true
                        self.commentNotifications = data["commentNotifications"] as? Bool ?? true
                        self.visibilityLevel = data["visibilityLevel"] as? String ?? "friendsOnly"
                        self.showSessionHistory = data["showSessionHistory"] as? Bool ?? true
                        // Add this line to load the restrict live sessions setting
                        self.restrictLiveSessionsToFriends =
                            data["restrictLiveSessionsToFriends"] as? Bool ?? false
                    }
                }
                else {
                    // Initialize with default settings if document doesn't exist
                    self.userSettingsCache = [
                        "friendFailureNotifications": true, "visibilityLevel": "friendsOnly",
                        "showSessionHistory": true,
                        "regionalDisplayMode": RegionalDisplayMode.normal.rawValue,
                        "regionalOptOut": false, "restrictLiveSessionsToFriends": false,  // Add default value
                    ]

                    // Set default values for @Published properties
                    self.regionalDisplayMode = .normal
                    self.regionalOptOut = false
                    self.friendFailureNotifications = true
                    self.commentNotifications = true
                    self.visibilityLevel = "friendsOnly"
                    self.showSessionHistory = true
                    self.restrictLiveSessionsToFriends = false  // Set default value

                    // Create the settings document with defaults
                    self.saveSettingsToFirestore(settings: self.userSettingsCache!)
                }
            }
    }

    // Add this new method to set the restriction
    func setRestrictLiveSessionsToFriends(_ restrict: Bool) {
        guard var settings = userSettingsCache else {
            userSettingsCache = [
                "friendFailureNotifications": true, "visibilityLevel": "friendsOnly",
                "showSessionHistory": true,
                "regionalDisplayMode": RegionalDisplayMode.normal.rawValue, "regionalOptOut": false,
                "restrictLiveSessionsToFriends": restrict,
            ]
            saveSettingsToFirestore(settings: userSettingsCache!)
            return
        }
        settings["restrictLiveSessionsToFriends"] = restrict
        userSettingsCache = settings
        saveSettingsToFirestore(settings: settings)
    }

    // Called when user signs in
    func onUserSignIn() { setupSettingsListener() }

    // Called when user signs out
    func onUserSignOut() {
        userSettingsListener?.remove()
        userSettingsCache = nil
    }

    // Save settings to Firestore
    private func saveSettingsToFirestore(settings: [String: Any]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        var updatedSettings = settings
        updatedSettings["updatedAt"] = FieldValue.serverTimestamp()

        db.collection("user_settings").document(userId)
            .setData(updatedSettings, merge: true) { error in
                if let error = error {
                    print("Error saving settings: \(error.localizedDescription)")
                }
            }
    }

    // Update a specific setting
    func updateSetting(key: String, value: Any) {
        guard var settings = userSettingsCache else {
            // Initialize with defaults if cache is empty
            userSettingsCache = [
                "friendFailureNotifications": true, "visibilityLevel": "friendsOnly",
                "showSessionHistory": true,
                "regionalDisplayMode": RegionalDisplayMode.normal.rawValue, "regionalOptOut": false,
            ]
            updateSetting(key: key, value: value)
            return
        }

        settings[key] = value
        userSettingsCache = settings
        saveSettingsToFirestore(settings: settings)
    }

    // Get a specific setting with a default value
    func getSetting<T>(key: String, defaultValue: T) -> T {
        guard let settings = userSettingsCache, let value = settings[key] as? T else {
            return defaultValue
        }
        return value
    }

    // MARK: - Specific settings getters

    // Check if friend failure notifications are enabled
    var areFriendFailureNotificationsEnabled: Bool {
        return getSetting(key: "friendFailureNotifications", defaultValue: true)
    }

    var areCommentNotificationsEnabled: Bool {
        return getSetting(key: "commentNotifications", defaultValue: true)
    }

    // MARK: - Regional leaderboard privacy settings

    // Set regional display mode
    func setRegionalDisplayMode(_ mode: RegionalDisplayMode) {
        self.regionalDisplayMode = mode
        updateSetting(key: "regionalDisplayMode", value: mode.rawValue)
    }

    func setRegionalOptOut(_ optOut: Bool) {
        self.regionalOptOut = optOut
        updateSetting(key: "regionalOptOut", value: optOut)
    }
}
