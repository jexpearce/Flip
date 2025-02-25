//
//  MapViewModel.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/25/25.
//

import Foundation
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

// Model for user location data
struct FriendLocation: Identifiable {
    let id: String
    let username: String
    let coordinate: CLLocationCoordinate2D
    let isCurrentlyFlipped: Bool
    let lastFlipTime: Date
    let lastFlipWasSuccessful: Bool
    let sessionDuration: Int  // in minutes
    let sessionStartTime: Date
    
    // Computed properties for UI
    var sessionMinutesElapsed: Int {
        let seconds = Date().timeIntervalSince(sessionStartTime)
        return Int(seconds / 60)
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
// Main ViewModel for the Map View
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var friendLocations: [FriendLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var locationListener: ListenerRegistration?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Request when-in-use authorization initially
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationTracking() {
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Start listening for friend locations
        startListeningForLocationUpdates()
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
        locationListener?.remove()
    }
    
    func refreshLocations() {
        // Force a refresh of friend locations
        stopLocationTracking()
        startLocationTracking()
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
        
        locationListener = db.collection("locations")
            .whereField("userId", in: userIds)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching locations: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let locations = documents.compactMap { document -> FriendLocation? in
                    let data = document.data()
                    
                    guard let userId = data["userId"] as? String,
                          let username = data["username"] as? String,
                          let geoPoint = data["currentLocation"] as? GeoPoint,
                          let isFlipped = data["isCurrentlyFlipped"] as? Bool,
                          let timestamp = (data["lastFlipTime"] as? Timestamp)?.dateValue(),
                          let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool
                    else { return nil }
                    
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
                        sessionStartTime: sessionStartTime
                    )
                }
                
                DispatchQueue.main.async {
                    self?.friendLocations = locations
                }
            }
    }
    
    // MARK: - CLLocationManagerDelegate methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location.coordinate
        
        // Center map on first location update
        if region.center.latitude == 37.7749 {
            centerOnUser()
        }
        
        // Update user's location in Firebase
        updateUserLocationInFirebase(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    // Update user location in Firebase during an active session
    private func updateUserLocationInFirebase(location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Get current app state from AppManager
        let appManager = AppManager.shared
        let isCurrentlyFlipped = appManager.currentState == .tracking && appManager.isFaceDown
        
        // Get session info
        let sessionDuration = appManager.selectedMinutes
        let sessionStartTime = Date().addingTimeInterval(-Double(appManager.remainingSeconds))
        let isSuccessful = appManager.currentState != .failed
        
        let locationData: [String: Any] = [
            "userId": userId,
            "username": FirebaseManager.shared.currentUser?.username ?? "User",
            "currentLocation": GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            "isCurrentlyFlipped": isCurrentlyFlipped,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": isSuccessful,
            "sessionDuration": sessionDuration,
            "sessionStartTime": Timestamp(date: sessionStartTime),
            "locationUpdatedAt": Timestamp(date: Date())
        ]
        
        db.collection("locations").document(userId).setData(locationData, merge: true) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            }
        }
    }
}