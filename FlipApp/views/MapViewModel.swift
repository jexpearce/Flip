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
    let sessionIndex: Int   // Index to track which historical session (0 = current, 1 = most recent, etc.)
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
        locationManager.allowsBackgroundLocationUpdates = false // Prevent background tracking
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = false
    }
    
    func startLocationTracking() {
        // Request authorization first
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Start location updates but with limited accuracy for the map view
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // Only update after significant movement
        locationManager.startUpdatingLocation()
        
        // Setup a timer to refresh locations periodically - less frequent to save battery
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshLocations()
        }
        
        // Start listening for friend locations
        startListeningForLocationUpdates()
    }
    
    func stopLocationTracking() {
        // Stop location manager
        locationManager.stopUpdatingLocation()
        
        // Remove Firestore listeners
        locationListener?.remove()
        
        // Invalidate refresh timer
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        Task { @MainActor in
            LocationHandler.shared.completelyStopLocationUpdates()
        }
        
        print("Map location tracking stopped")
    }
    
    func refreshLocations() {
        // Fresh reload of friend locations
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
    
    func startListeningForLocationUpdates() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Get user's privacy settings first
        db.collection("users").document(currentUserId).collection("settings").document("mapPrivacy")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                let showHistory: Bool
                if let document = document, document.exists, let data = document.data(),
                   let showHistorySetting = data["showSessionHistory"] as? Bool {
                    showHistory = showHistorySetting
                } else {
                    showHistory = true // Default to showing history if setting not found
                }
                
                // Get the user's friends list
                self.db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
                    guard let self = self,
                          let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                    else { return }
                    
                    // Include the current user and their friends
                    var userIds = userData.friends
                    userIds.append(currentUserId)
                    
                    // FIRST: Listen for ONLY ACTIVE SESSIONS
                    self.listenForActiveSessions(userIds: userIds)
                    
                    // SECOND: Only if user has opted to see history, fetch past sessions
                    if showHistory {
                        // Fetch historical sessions for EACH user, limited to 3 per user
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
                            // Add historical locations to the existing active locations
                            self.friendLocations.append(contentsOf: historicalLocations)
                            print("Added \(historicalLocations.count) historical locations to map")
                        }
                    }
                }
            }
    }
    
    private func listenForActiveSessions(userIds: [String]) {
        // Stop any existing listener
        locationListener?.remove()
        
        // Listen ONLY for locations with active sessions
        locationListener = db.collection("locations")
            .whereField("userId", in: userIds)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error in location listener: \(error.localizedDescription)")
                    return
                }
                
                var currentLocations: [FriendLocation] = []
                if let documents = snapshot?.documents {
                    // Process each location document
                    for document in documents {
                        let data = document.data()
                        
                        // Only include if there's a valid session time and it's recent
                        if let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
                           Date().timeIntervalSince(sessionStartTime) < 7200, // Less than 2 hours old
                           let lastFlipTime = (data["lastFlipTime"] as? Timestamp)?.dateValue(),
                           Date().timeIntervalSince(lastFlipTime) < 3600 { // Less than 1 hour since last flip
                            
                            // Extract all required fields
                            guard let userId = data["userId"] as? String,
                                  let username = data["username"] as? String,
                                  let geoPoint = data["currentLocation"] as? GeoPoint,
                                  let isFlipped = data["isCurrentlyFlipped"] as? Bool else {
                                continue
                            }
                            
                            // CRITICAL: Properly check if session was successful
                            let wasSuccessful: Bool
                            if let successField = data["lastFlipWasSuccessful"] as? Bool {
                                wasSuccessful = successField
                            } else {
                                // Default to true if field is missing
                                wasSuccessful = true
                            }
                            
                            let sessionDuration = data["sessionDuration"] as? Int ?? 25 // Default to 25 min
                            
                            // Create FriendLocation for active session
                            let location = FriendLocation(
                                id: userId,
                                username: username,
                                coordinate: CLLocationCoordinate2D(
                                    latitude: geoPoint.latitude,
                                    longitude: geoPoint.longitude
                                ),
                                isCurrentlyFlipped: isFlipped,
                                lastFlipTime: lastFlipTime,
                                lastFlipWasSuccessful: wasSuccessful,
                                sessionDuration: sessionDuration,
                                sessionStartTime: sessionStartTime,
                                isHistorical: false,
                                sessionIndex: 0, // Current session has index 0
                                participants: nil,
                                participantNames: nil
                            )
                            
                            currentLocations.append(location)
                        }
                    }
                    
                    print("Found \(currentLocations.count) active session locations")
                }
                
                // Update UI with active locations - we'll add historical locations separately
                DispatchQueue.main.async {
                    self.friendLocations = currentLocations
                    
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
        // Fetch historical sessions from session_locations collection with a time cutoff
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        db.collection("session_locations")
            .whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneMonthAgo)) // Only sessions from last month
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
                  Date().timeIntervalSince(timestamp) < 7200 // Ignore sessions older than 2 hours
            else {
                print("Skipping document - missing required fields or too old")
                return nil
            }
            
            // Properly handle the success/failure state
            let wasSuccessful: Bool
            if let successField = data["lastFlipWasSuccessful"] as? Bool {
                wasSuccessful = successField
            } else {
                // Default to true if field is missing
                wasSuccessful = true
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
    
    // In MapViewModel.swift - modify the processHistoricalDocument function:
    private func processHistoricalDocument(_ document: QueryDocumentSnapshot, userId: String, index: Int) -> FriendLocation? {
        let data = document.data()
        
        guard let username = data["username"] as? String,
              let geoPoint = data["location"] as? GeoPoint,
              let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
              let sessionEndTime = (data["sessionEndTime"] as? Timestamp)?.dateValue(),
              // Don't show sessions from more than a month ago
              Date().timeIntervalSince(sessionEndTime) < 2592000
        else { return nil }
        
        // CRITICAL FIX: Check multiple possible field names for success status
        // This fixes the issue with failed sessions always showing as successful
        let wasSuccessful: Bool
        if let successValue = data["lastFlipWasSuccessful"] as? Bool {
            wasSuccessful = successValue
        } else if let successValue = data["wasSuccessful"] as? Bool {
            wasSuccessful = successValue
        } else if let actualDuration = data["actualDuration"] as? Int,
                  let targetDuration = data["sessionDuration"] as? Int {
            // If we can't find an explicit success/failure flag,
            // infer it from whether the actual duration matches the target
            wasSuccessful = (
                actualDuration >= targetDuration * Int(0.9)
            ) // Consider success if at least 90% completed
        } else {
            // Default to success only as last resort
            wasSuccessful = true
        }
        
        print("Historical session for \(username): success=\(wasSuccessful), fields: \(data.keys.joined(separator: ", "))")
        
        let sessionDuration = data["sessionDuration"] as? Int ?? 25
        let participants = data["participants"] as? [String]
        let participantNames = data["participantNames"] as? [String]
        
        return FriendLocation(
            id: "\(userId)_hist_\(index)",
            username: username,
            coordinate: CLLocationCoordinate2D(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude
            ),
            isCurrentlyFlipped: false,
            lastFlipTime: sessionEndTime,
            lastFlipWasSuccessful: wasSuccessful,
            sessionDuration: sessionDuration,
            sessionStartTime: sessionStartTime,
            isHistorical: true,
            sessionIndex: index,
            participants: participants,
            participantNames: participantNames
        )
    }
    
    // New method to fetch group sessions
    private func fetchGroupSessions(userId: String, completion: @escaping ([FriendLocation]) -> Void) {
        // One month time limit
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // Query for sessions where this user was a participant
        db.collection("session_locations")
            .whereField("participants", arrayContains: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneMonthAgo))
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
        
        // ONLY update location in Firebase if in an active session
        if isInRelevantState {
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
            
            // Add session-specific data
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
            
            // Update location in Firestore
            db.collection("locations").document(userId).setData(locationData, merge: true) { error in
                if let error = error {
                    print("Error updating location: \(error.localizedDescription)")
                }
            }
        }
    }
}
