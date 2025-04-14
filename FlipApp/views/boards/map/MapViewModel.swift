import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import SwiftUI

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var friendLocations: [FriendLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isFirstLoad: Bool = true

    @Published var refreshInProgress = false
    private var lastRefreshTime = Date().timeIntervalSince1970 - 60

    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var locationListener: ListenerRegistration?
    private var locationUpdateTimer: Timer?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = false  // Prevent background tracking
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = false
    }

    func startLocationTracking() {
        // ONLY start tracking if we already have permission
        let authStatus = locationManager.authorizationStatus

        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            // Configure and start location updates
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 50
            locationManager.startUpdatingLocation()

            // Setup refresh timer
            locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
                [weak self] _ in self?.refreshLocations()
            }

            // Start listening for friend locations
            startListeningForLocationUpdates()
        }
        else {
            // Don't request permission here - log it instead
            print("Map location tracking deferred until permission is granted")

            // Optional: you could set up a NotificationCenter observer to be notified
            // when permission is granted by PermissionManager
        }
    }

    func stopLocationTracking() {
        // Stop location manager
        locationManager.stopUpdatingLocation()

        // Remove Firestore listeners
        locationListener?.remove()

        // Invalidate refresh timer
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        Task { @MainActor in LocationHandler.shared.completelyStopLocationUpdates() }

        print("Map location tracking stopped")
    }

    func refreshLocations() {
        // Prevent multiple refreshes in quick succession
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastRefreshTime < 5.0 && refreshInProgress {
            print("⏱️ Skipping refresh, too soon after last refresh")
            return
        }

        print("🔄 Starting location refresh")
        refreshInProgress = true
        lastRefreshTime = currentTime

        // Clear existing data before refresh to avoid duplicates
        ProfileImageCache.shared.clearCache()

        // Start with a clean slate for friend locations
        DispatchQueue.main.async { self.friendLocations = [] }

        // Fresh reload of friend locations with delay to ensure clean state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startListeningForLocationUpdates()

            // Set a timeout to mark refresh as completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.refreshInProgress = false }
        }
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
                    let showHistorySetting = data["showSessionHistory"] as? Bool
                {
                    showHistory = showHistorySetting
                }
                else {
                    showHistory = true  // Default to showing history if setting not found
                }

                // Get the user's friends list
                self.db.collection("users").document(currentUserId)
                    .getDocument { [weak self] document, error in
                        guard let self = self,
                            let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                        else { return }

                        // Include the current user and their friends
                        var userIds = userData.friends
                        userIds.append(currentUserId)

                        // FIRST: Clear existing listeners
                        self.locationListener?.remove()

                        // SECOND: Listen for ACTIVE SESSIONS first
                        self.listenForActiveSessions(userIds: userIds)

                        // THIRD: Only if user has opted to see history, fetch past sessions
                        if showHistory {
                            // Wait a bit to ensure active sessions are processed first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                // Fetch historical sessions for EACH user, limited to 3 per user
                                let dispatchGroup = DispatchGroup()
                                var historicalLocations: [FriendLocation] = []

                                for userId in userIds {
                                    dispatchGroup.enter()
                                    self.fetchHistoricalSessions(userId: userId, limit: 3) {
                                        locations in
                                        historicalLocations.append(contentsOf: locations)
                                        dispatchGroup.leave()
                                    }
                                }

                                dispatchGroup.notify(queue: .main) {
                                    // Add historical locations to the existing active locations
                                    DispatchQueue.main.async {
                                        // Get current active locations
                                        let currentLocations = self.friendLocations

                                        // Merge with historical, avoiding duplicates
                                        var newLocations = currentLocations
                                        for location in historicalLocations {
                                            // Only add if not already present (by ID)
                                            if !newLocations.contains(where: {
                                                $0.id == location.id
                                            }) {
                                                newLocations.append(location)
                                            }
                                        }

                                        self.friendLocations = newLocations
                                        print(
                                            "📍 Total locations on map: \(self.friendLocations.count) (active: \(currentLocations.count), historical: \(historicalLocations.count))"
                                        )
                                    }
                                }
                            }
                        }
                    }
            }
    }

    private func listenForActiveSessions(userIds: [String]) {
        print("👥 Listening for active sessions for \(userIds.count) users")

        // Stop any existing listener
        locationListener?.remove()

        // Listen ONLY for locations with active sessions
        locationListener = db.collection("locations").whereField("userId", in: userIds)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error in location listener: \(error.localizedDescription)")
                    return
                }

                var currentLocations: [FriendLocation] = []
                if let documents = snapshot?.documents {
                    print("📑 Processing \(documents.count) active location documents")

                    // Process each location document
                    for document in documents {
                        let data = document.data()

                        // Only include if there's a valid session time and it's recent
                        if let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?
                            .dateValue(), Date().timeIntervalSince(sessionStartTime) < 7200,  // Less than 2 hours old
                            let lastFlipTime = (data["lastFlipTime"] as? Timestamp)?.dateValue(),
                            Date().timeIntervalSince(lastFlipTime) < 3600
                        {  // Less than 1 hour since last flip

                            // Extract all required fields
                            guard let userId = data["userId"] as? String,
                                let username = data["username"] as? String,
                                let geoPoint = data["currentLocation"] as? GeoPoint,
                                let isFlipped = data["isCurrentlyFlipped"] as? Bool
                            else { continue }

                            // CRITICAL: Explicitly check success field
                            let wasSuccessful: Bool
                            if let successField = data["lastFlipWasSuccessful"] as? Bool {
                                wasSuccessful = successField
                                print("📱 Active session success status: \(wasSuccessful)")
                            }
                            else {
                                // Default to true only if field is missing
                                wasSuccessful = true
                                print(
                                    "⚠️ Missing success field for active session, defaulting to success"
                                )
                            }

                            let sessionDuration = data["sessionDuration"] as? Int ?? 25  // Default to 25 min

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
                                sessionIndex: 0,  // Current session has index 0
                                participants: nil,
                                participantNames: nil
                            )

                            currentLocations.append(location)
                        }
                    }

                    print("👁️ Found \(currentLocations.count) active session locations")
                }

                // Update UI with active locations
                DispatchQueue.main.async {
                    // Replace the locations array with just active locations
                    // Historical locations will be added later
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

    private func fetchHistoricalSessions(
        userId: String,
        limit: Int,
        completion: @escaping ([FriendLocation]) -> Void
    ) {
        // Fetch historical sessions from session_locations collection with a time cutoff
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        db.collection("session_locations").whereField("userId", isEqualTo: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneMonthAgo))  // Only sessions from last month
            .order(by: "sessionEndTime", descending: true).limit(to: limit)
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
                        if let location = self.processHistoricalDocument(
                            document,
                            userId: userId,
                            index: index + 1
                        ) {
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
                    let result = limitedLocations.enumerated()
                        .map { index, location -> FriendLocation in
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
                                sessionIndex: index + 1,  // +1 because current session is 0
                                participants: location.participants,
                                participantNames: location.participantNames
                            )
                        }

                    completion(Array(result))
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

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: manager.startUpdatingLocation()
        default: print("Location authorization status changed: \(status.rawValue)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    // In MapViewModel.swift - modify the processHistoricalDocument function:
    // Replace the processHistoricalDocument function in MapViewModel with this fixed version

    private func processHistoricalDocument(
        _ document: QueryDocumentSnapshot,
        userId: String,
        index: Int
    ) -> FriendLocation? {
        let data = document.data()

        guard let username = data["username"] as? String,
            let geoPoint = data["location"] as? GeoPoint,
            let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
            let sessionEndTime = (data["sessionEndTime"] as? Timestamp)?.dateValue(),
            // Don't show sessions from more than a month ago
            Date().timeIntervalSince(sessionEndTime) < 2_592_000
        else { return nil }

        // CRITICAL FIX: Explicitly check all possible field names for success status
        // Log the keys present in the document for debugging
        print("🧹 Historical session document fields: \(Array(data.keys).joined(separator: ", "))")

        // First determine the success status with clear checks
        let wasSuccessful: Bool

        // Try all known field names - explicit checks for each field type
        if let successValue = data["lastFlipWasSuccessful"] as? Bool {
            print("✅ Found direct success field: \(successValue)")
            wasSuccessful = successValue
        }
        else if let successValue = data["wasSuccessful"] as? Bool {
            print("✅ Found alternative wasSuccessful field: \(successValue)")
            wasSuccessful = successValue
        }
        else if let actualDuration = getIntegerValue(from: data["actualDuration"]),
            let targetDuration = getIntegerValue(from: data["sessionDuration"])
        {
            // If we can't find an explicit flag, infer from duration
            let success = actualDuration >= Int(Double(targetDuration) * 0.9)  // 90% threshold
            print(
                "📊 Inferred success from duration: \(success) (actual: \(actualDuration), target: \(targetDuration))"
            )
            wasSuccessful = success
        }
        else {
            // Last resort - check if any failure indicators exist
            let hasFailed = data["didFail"] as? Bool ?? false
            let wasAborted = data["wasAborted"] as? Bool ?? false

            if hasFailed || wasAborted {
                print("❌ Found failure indicator")
                wasSuccessful = false
            }
            else {
                // Default to success if we can't determine
                print("⚠️ Could not determine success state, defaulting to success")
                wasSuccessful = true
            }
        }

        // IMPORTANT: Log the final determination for debugging
        print("🏁 Session for \(username): success=\(wasSuccessful)")

        let sessionDuration = getIntegerValue(from: data["sessionDuration"]) ?? 25
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
            lastFlipWasSuccessful: wasSuccessful,  // FIXED: Use our explicit determination
            sessionDuration: sessionDuration,
            sessionStartTime: sessionStartTime,
            isHistorical: true,
            sessionIndex: index,
            participants: participants,
            participantNames: participantNames
        )
    }

    // Helper function to safely extract integer values from different types
    private func getIntegerValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        else if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        else if let stringValue = value as? String, let parsed = Int(stringValue) {
            return parsed
        }
        else if let numberValue = value as? NSNumber {
            return numberValue.intValue
        }
        return nil
    }

    // New method to fetch group sessions
    private func fetchGroupSessions(
        userId: String,
        completion: @escaping ([FriendLocation]) -> Void
    ) {
        // One month time limit
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        // Query for sessions where this user was a participant
        db.collection("session_locations").whereField("participants", arrayContains: userId)
            .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneMonthAgo))
            .order(by: "sessionEndTime", descending: true).limit(to: 5)
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
                        if let location = self.processHistoricalDocument(
                            document,
                            userId: "\(userId)_group_\(index)",
                            index: index
                        ) {
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
        let isInRelevantState =
            appManager.currentState == .tracking || appManager.currentState == .completed
            || appManager.currentState == .failed

        // ONLY update location in Firebase if in an active session
        if isInRelevantState {
            // Get username from FirebaseManager
            let username = FirebaseManager.shared.currentUser?.username ?? "User"

            // Create base location data
            var locationData: [String: Any] = [
                "userId": userId, "username": username,
                "currentLocation": GeoPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ), "locationUpdatedAt": Timestamp(date: Date()),
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
            db.collection("locations").document(userId)
                .setData(locationData, merge: true) { error in
                    if let error = error {
                        print("Error updating location: \(error.localizedDescription)")
                    }
                }
        }
    }
}
