//
//  MapViewModel.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/25/25.

import Foundation
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// Model for user location data - Enhanced with better timestamp handling
struct FriendLocation: Identifiable {
    let id: String
    let username: String
    let coordinate: CLLocationCoordinate2D
    let isCurrentlyFlipped: Bool
    let lastFlipTime: Date
    let lastFlipWasSuccessful: Bool
    let sessionDuration: Int  // in minutes
    let sessionStartTime: Date
    let isHistorical: Bool  // Flag to indicate if this is a past session
    let sessionIndex: Int   // Index to track which historical session (0 = current, 1 = most recent past, etc.)
    let participants: [String]?   // User IDs of participants
    let participantNames: [String]?  // Names of participants
    
    // Computed properties for UI
    var sessionMinutesElapsed: Int {
        if isHistorical {
            // For historical sessions, return the actual duration that was completed
            let seconds = lastFlipTime.timeIntervalSince(sessionStartTime)
            return Int(seconds / 60)
        } else {
            // For current sessions, calculate from current time
            let seconds = Date().timeIntervalSince(sessionStartTime)
            return Int(seconds / 60)
        }
    }
    
    var sessionTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: sessionStartTime, relativeTo: Date())
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: sessionStartTime)
    }
    
    var sessionDurationString: String {
        let minutes = sessionMinutesElapsed
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Enum for location visibility settings
enum LocationVisibilityLevel: String, CaseIterable {
    case everyone = "Everyone"
    case friendsOnly = "Friends Only"
    case nobody = "Nobody"
}

// ViewModel for Map Privacy Settings
class MapPrivacyViewModel: ObservableObject {
    @Published var visibilityLevel: LocationVisibilityLevel = .friendsOnly
    @Published var showSessionHistory: Bool = true
    private let db = Firestore.firestore()
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let document = document, document.exists {
                    if let visibilityString = document.data()?["visibilityLevel"] as? String,
                       let level = LocationVisibilityLevel(rawValue: visibilityString) {
                        DispatchQueue.main.async {
                            self.visibilityLevel = level
                        }
                    }
                    
                    if let showHistory = document.data()?["showSessionHistory"] as? Bool {
                        DispatchQueue.main.async {
                            self.showSessionHistory = showHistory
                        }
                    }
                } else {
                    // Create default settings if they don't exist
                    self.saveSettings()
                }
            }
    }
    
    func updateVisibilityLevel(_ level: LocationVisibilityLevel) {
        visibilityLevel = level
        saveSettings()
    }
    
    func updateShowSessionHistory(_ show: Bool) {
        showSessionHistory = show
        saveSettings()
    }
    
    private func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let settings: [String: Any] = [
            "visibilityLevel": visibilityLevel.rawValue,
            "showSessionHistory": showSessionHistory,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .setData(settings, merge: true) { error in
                if let error = error {
                    print("Error saving map privacy settings: \(error.localizedDescription)")
                }
            }
    }
}

// Main ViewModel for the Map View - Enhanced with improved location tracking
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var friendLocations: [FriendLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isFirstLoad: Bool = true
    
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var locationListener: ListenerRegistration?
    private var locationUpdateTimer: Timer?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        // Request authorization on init
        requestLocationAuthorization()
    }
    
    private func requestLocationAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startLocationTracking() {
        // Start continuous location updates
        locationManager.startUpdatingLocation()
        
        // Setup a timer to refresh locations periodically
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refreshLocations()
        }
        
        // Start listening for friend locations
        startListeningForLocationUpdates()
    }
    
    func stopLocationTracking() {
        // Stop the location manager
        locationManager.stopUpdatingLocation()
        
        // Remove the listener
        locationListener?.remove()
        
        // Invalidate timer
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        // This ensures we don't keep tracking in background
        Task { @MainActor in
            LocationHandler.shared.completelyStopLocationUpdates()
        }
        
        print("Map location tracking fully stopped")
    }
    
    func refreshLocations() {
        // Fetch fresh data without stopping tracking
        print("Refreshing map locations...")
        startListeningForLocationUpdates()
    }
    
    func centerOnUser() {
        guard let userLocation = userLocation else { return }
        
        withAnimation {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Friend Locations & Session History
    
    private func startListeningForLocationUpdates() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // First get the user's friends list
        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self,
                  let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
            else { return }
            
            // Include the current user and their friends
            var userIds = userData.friends
            userIds.append(currentUserId)
            
            // Listen for location updates from these users
            self.listenForLocations(userIds: userIds)
        }
    }
    
    private func listenForLocations(userIds: [String]) {
        // Stop any existing listener
        locationListener?.remove()
        
        // Listen for real-time updates of active sessions
        locationListener = db.collection("locations")
            .whereField("userId", in: userIds)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error in location listener: \(error.localizedDescription)")
                    return
                }
                
                // Process current locations
                var currentLocations: [FriendLocation] = []
                if let documents = snapshot?.documents {
                    currentLocations = self.processLocationDocuments(documents, isHistorical: false, sessionIndex: 0)
                    print("Received \(currentLocations.count) current locations")
                }
                
                // Now fetch historical sessions for each user - always limit to 3 per user
                let dispatchGroup = DispatchGroup()
                var historicalLocations: [FriendLocation] = []
                
                for userId in userIds {
                    dispatchGroup.enter()
                    self.fetchHistoricalSessions(userId: userId, limit: 3) { locations in
                        historicalLocations.append(contentsOf: locations)
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    // Update UI with all locations
                    self.friendLocations = currentLocations + historicalLocations
                    
                    print("Total locations displayed: \(self.friendLocations.count) (Current: \(currentLocations.count), Historical: \(historicalLocations.count))")
                    
                    // Center on user location if this is first load
                    if self.isFirstLoad, let userLocation = self.userLocation {
                        self.isFirstLoad = false
                        self.region = MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            }
    }
    
    private func fetchHistoricalSessions(userId: String, limit: Int, completion: @escaping ([FriendLocation]) -> Void) {
        // Always show session history for map functionality
        let showSessionHistory = true
        
        if !showSessionHistory {
            completion([])
            return
        }
        
        // Fetch historical sessions from session_locations collection
        db.collection("session_locations")
            .whereField("userId", isEqualTo: userId)
            .order(by: "sessionEndTime", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion([])
                    return
                }
                
                if let error = error {
                    print("Error fetching session_locations: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var historicalLocations: [FriendLocation] = []
                
                // Process each document into a historical location
                if let documents = snapshot?.documents {
                    for (index, document) in documents.enumerated() {
                        if let location = self.processHistoricalDocument(document, userId: userId, index: index + 1) {
                            historicalLocations.append(location)
                        }
                    }
                }
                
                // Also fetch group sessions where this user was a participant
                self.fetchGroupSessions(userId: userId) { groupLocations in
                    // First, combine and sort all locations
                    let allLocations = (historicalLocations + groupLocations)
                        .sorted(by: { $0.lastFlipTime > $1.lastFlipTime })
                    
                    // Take only the first 'limit' elements
                    let limitedLocations = allLocations.prefix(limit)
                    
                    // Now update indices in a separate step after the array is created
                    let result = limitedLocations.enumerated().map { index, location -> FriendLocation in
                        return FriendLocation(
                            id: location.id,
                            username: location.username,
                            coordinate: location.coordinate,
                            isCurrentlyFlipped: location.isCurrentlyFlipped,
                            lastFlipTime: location.lastFlipTime,
                            lastFlipWasSuccessful: location.lastFlipWasSuccessful,
                            sessionDuration: location.sessionDuration,
                            sessionStartTime: location.sessionStartTime,
                            isHistorical: true,
                            sessionIndex: index + 1, // +1 because current session is 0
                            participants: location.participants,
                            participantNames: location.participantNames
                        )
                    }
                    
                    completion(Array(result))
                }
            }
    }
    
    private func processLocationDocuments(_ documents: [QueryDocumentSnapshot], isHistorical: Bool, sessionIndex: Int) -> [FriendLocation] {
        return documents.compactMap { document -> FriendLocation? in
            let data = document.data()
            
            guard let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let geoPoint = data["currentLocation"] as? GeoPoint,
                  let isFlipped = data["isCurrentlyFlipped"] as? Bool,
                  let timestamp = (data["lastFlipTime"] as? Timestamp)?.dateValue(),
                  let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool
            else {
                print("Skipping document - missing required fields")
                return nil
            }
            
            let sessionDuration = data["sessionDuration"] as? Int ?? 25 // Default to 25 min
            let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue() ?? timestamp
            
            return FriendLocation(
                id: userId,
                username: username,
                coordinate: CLLocationCoordinate2D(
                    latitude: geoPoint.latitude,
                    longitude: geoPoint.longitude
                ),
                isCurrentlyFlipped: isFlipped,
                lastFlipTime: timestamp,
                lastFlipWasSuccessful: wasSuccessful,
                sessionDuration: sessionDuration,
                sessionStartTime: sessionStartTime,
                isHistorical: isHistorical,
                sessionIndex: sessionIndex,
                participants: nil,
                participantNames: nil
            )
        }
    }
    
    // MARK: - Profile Navigation
    
    func loadUserForProfile(userId: String, completion: @escaping (FirebaseManager.FlipUser?) -> Void) {
        // Extract clean userId from potential composite IDs (like userId_hist_1)
        let cleanUserId = userId.split(separator: "_").first.map(String.init) ?? userId
        
        // Fetch the user data from Firestore
        db.collection("users").document(cleanUserId)
            .getDocument { document, error in
                if let error = error {
                    print("Error loading user for profile: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self) else {
                    print("Could not decode user data for profile")
                    completion(nil)
                    return
                }
                
                DispatchQueue.main.async {
                        completion(userData)
                    }
            }
    }
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update local userLocation property
        userLocation = location.coordinate
        
        // Center map on first location update
        if isFirstLoad {
            centerOnUser()
            isFirstLoad = false
        }
        
        // Update user's location in Firebase - regardless of session state for continuous tracking
        updateUserLocationInFirebase(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            print("Location authorization status changed: \(status.rawValue)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    private func processHistoricalDocument(_ document: QueryDocumentSnapshot, userId: String, index: Int) -> FriendLocation? {
        let data = document.data()
        
        guard let username = data["username"] as? String,
              let geoPoint = data["location"] as? GeoPoint,
              let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
              let sessionEndTime = (data["sessionEndTime"] as? Timestamp)?.dateValue()
        else { return nil }
        
        // IMPORTANT CHANGE: Explicitly check for the wasSuccessful field and add debug
        let wasSuccessful: Bool
        if let successValue = data["lastFlipWasSuccessful"] as? Bool {
            wasSuccessful = successValue
            print("Session for \(username) success status: \(wasSuccessful)")
        } else {
            // Default to true if field is missing
            wasSuccessful = true
            print("WARNING: Missing success status for \(username), defaulting to true")
        }
        
        let sessionDuration = data["sessionDuration"] as? Int ?? 25
        let participants = data["participants"] as? [String]
        let participantNames = data["participantNames"] as? [String]
        
        return FriendLocation(
            id: "\(userId)_hist_\(index + 1)",
            username: username,
            coordinate: CLLocationCoordinate2D(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude
            ),
            isCurrentlyFlipped: false,
            lastFlipTime: sessionEndTime,
            lastFlipWasSuccessful: wasSuccessful,  // Use our explicitly checked value
            sessionDuration: sessionDuration,
            sessionStartTime: sessionStartTime,
            isHistorical: true,
            sessionIndex: index + 1,
            participants: participants,
            participantNames: participantNames
        )
    }

    // New method to fetch group sessions
    private func fetchGroupSessions(userId: String, completion: @escaping ([FriendLocation]) -> Void) {
        // Query for sessions where this user was a participant
        db.collection("session_locations")
            .whereField("participants", arrayContains: userId)
            .order(by: "sessionEndTime", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion([])
                    return
                }
                
                if let error = error {
                    print("Error fetching group sessions: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var groupLocations: [FriendLocation] = []
                
                if let documents = snapshot?.documents {
                    for (index, document) in documents.enumerated() {
                        if let location = self.processHistoricalDocument(document, userId: "\(userId)_group_\(index)", index: index) {
                            groupLocations.append(location)
                        }
                    }
                }
                
                completion(groupLocations)
            }
    }
    
    // MARK: - Firebase Location Updates
    
    // Update user location in Firebase - enhanced to work continuously
    private func updateUserLocationInFirebase(location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get current app state from AppManager
        let appManager = AppManager.shared
        let isInRelevantState = appManager.currentState == .tracking ||
                               appManager.currentState == .completed ||
                               appManager.currentState == .failed
        
        // Get username from FirebaseManager
        let username = FirebaseManager.shared.currentUser?.username ?? "User"
        
        // Create base location data
        var locationData: [String: Any] = [
            "userId": userId,
            "username": username,
            "currentLocation": GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            "locationUpdatedAt": Timestamp(date: Date())
        ]
        
        // Add session-specific data if in a relevant state
        if isInRelevantState {
            let isCurrentlyFlipped = appManager.currentState == .tracking && appManager.isFaceDown
            let sessionDuration = appManager.selectedMinutes
            let sessionStartTime = Date().addingTimeInterval(-Double(appManager.remainingSeconds))
            let isSuccessful = appManager.currentState != .failed
            
            // Add session-specific fields
            locationData["isCurrentlyFlipped"] = isCurrentlyFlipped
            locationData["lastFlipTime"] = Timestamp(date: Date())
            locationData["lastFlipWasSuccessful"] = isSuccessful
            locationData["sessionDuration"] = sessionDuration
            locationData["sessionStartTime"] = Timestamp(date: sessionStartTime)
        } else {
            // For non-session state, set defaults for session fields
            locationData["isCurrentlyFlipped"] = false
            locationData["lastFlipWasSuccessful"] = true
        }
        
        // Update location in Firestore
        db.collection("locations").document(userId).setData(locationData, merge: true) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            }
        }
    }
}
