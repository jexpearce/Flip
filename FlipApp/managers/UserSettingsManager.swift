import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class UserSettingsManager {
    static let shared = UserSettingsManager()
    
    private let db = Firestore.firestore()
    private var userSettingsCache: [String: Any]?
    private var userSettingsListener: ListenerRegistration?
    
    private init() {
        setupSettingsListener()
    }
    
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
                } else {
                    // Initialize with default settings if document doesn't exist
                    self.userSettingsCache = [
                        "friendFailureNotifications": true,
                        "visibilityLevel": "friendsOnly",
                        "showSessionHistory": true
                    ]
                    
                    // Create the settings document with defaults
                    self.saveSettingsToFirestore(settings: self.userSettingsCache!)
                }
            }
    }
    
    // Called when user signs in
    func onUserSignIn() {
        setupSettingsListener()
    }
    
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
        
        db.collection("user_settings").document(userId).setData(updatedSettings, merge: true) { error in
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
                "friendFailureNotifications": true,
                "visibilityLevel": "friendsOnly",
                "showSessionHistory": true
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
    
    // Get visibility level
    var visibilityLevel: String {
        return getSetting(key: "visibilityLevel", defaultValue: "friendsOnly")
    }
    
    // Check if session history is shown
    var isSessionHistoryShown: Bool {
        return getSetting(key: "showSessionHistory", defaultValue: true)
    }
}