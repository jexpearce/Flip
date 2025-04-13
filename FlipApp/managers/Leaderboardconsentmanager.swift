import SwiftUI

class LeaderboardConsentManager: ObservableObject {
    static let shared = LeaderboardConsentManager()
    
    // Keys for UserDefaults
    private let consentKey = "hasGivenLeaderboardConsent"
    private let seenRegionalTabKey = "hasSeenRegionalTab"
    private let shouldPulseRegionalTabKey = "shouldPulseRegionalTab"
    
    // Published properties to bind to UI
    @Published var hasGivenConsent: Bool = false
    @Published var hasSeenRegionalTab: Bool = false
    @Published var shouldPulseRegionalTab: Bool = false
    
    // Initialize with stored values
    init() {
        // Load values after properties are initialized
        loadValuesFromDefaults()
    }
    
    private func loadValuesFromDefaults() {
        let defaults = UserDefaults.standard
        
        // Load saved values
        hasGivenConsent = defaults.bool(forKey: consentKey)
        hasSeenRegionalTab = defaults.bool(forKey: seenRegionalTabKey)
        
        // For pulsing, either load from defaults or compute it
        if defaults.object(forKey: shouldPulseRegionalTabKey) != nil {
            shouldPulseRegionalTab = defaults.bool(forKey: shouldPulseRegionalTabKey)
        } else {
            // If not explicitly set, compute based on other values
            shouldPulseRegionalTab = !hasGivenConsent && !hasSeenRegionalTab
            defaults.set(shouldPulseRegionalTab, forKey: shouldPulseRegionalTabKey)
        }
    }
    
    // Mark that the user has seen the regional tab
    func markRegionalTabSeen() {
        hasSeenRegionalTab = true
        UserDefaults.standard.set(true, forKey: seenRegionalTabKey)
        
        // Stop pulsing after seen
        disablePulsing()
    }
    
    // Set the consent status
    func setConsent(granted: Bool) {
        hasGivenConsent = granted
        UserDefaults.standard.set(granted, forKey: consentKey)
        
        // Stop pulsing after consent decision
        disablePulsing()
    }
    
    // Stop the pulsing effect
    func disablePulsing() {
        shouldPulseRegionalTab = false
        UserDefaults.standard.set(false, forKey: shouldPulseRegionalTabKey)
    }
    
    // Reset consent (for testing)
    func resetConsent() {
        hasGivenConsent = false
        hasSeenRegionalTab = false
        shouldPulseRegionalTab = true
        UserDefaults.standard.set(false, forKey: consentKey)
        UserDefaults.standard.set(false, forKey: seenRegionalTabKey)
        UserDefaults.standard.set(true, forKey: shouldPulseRegionalTabKey)
    }
    
    // Check if we have permission to add user to leaderboards
    func canAddToLeaderboard() -> Bool {
        return true
    }
}