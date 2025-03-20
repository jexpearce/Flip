import ActivityKit
import CoreLocation
import CoreMotion
import SwiftUI

@MainActor class LocationHandler: ObservableObject {

    static let shared = LocationHandler()
    private let locationManager: CLLocationManager
    private let motionManager: CMMotionManager
    private var background: CLBackgroundActivitySession?

    @Published var lastLocation = CLLocation()
    @Published var isStationary = false
    @Published var count = 0

    @Published
    var updatesStarted: Bool = UserDefaults.standard.bool(
        forKey: "liveUpdatesStarted")
    {
        didSet {
            UserDefaults.standard.set(
                updatesStarted, forKey: "liveUpdatesStarted")
        }
    }

    @Published
    var backgroundActivity: Bool = UserDefaults.standard.bool(
        forKey: "BGActivitySessionStarted")
    {
        didSet {
            backgroundActivity
                ? self.background = CLBackgroundActivitySession()
                : self.background?.invalidate()
            UserDefaults.standard.set(
                backgroundActivity, forKey: "BGActivitySessionStarted")
        }
    }

    private init() {
        self.locationManager = CLLocationManager()
        self.motionManager = CMMotionManager()
    }

    func startLocationUpdates() {
        // First check permission status without requesting
        let authStatus = self.locationManager.authorizationStatus
        
        let appManager = AppManager.shared
        let isInSession = appManager.currentState == .tracking || appManager.currentState == .countdown
        
        // Configure the location manager
        self.locationManager.allowsBackgroundLocationUpdates = isInSession
        self.locationManager.showsBackgroundLocationIndicator = isInSession
        
        if isInSession {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.locationManager.distanceFilter = 1000
            self.locationManager.pausesLocationUpdatesAutomatically = true
        } else {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.distanceFilter = 10
            self.locationManager.pausesLocationUpdatesAutomatically = false
        }
        
        self.motionManager.deviceMotionUpdateInterval = isInSession ? 1.0 : 3.0
        self.motionManager.startDeviceMotionUpdates()

        // ONLY start actual location updates if we have permission
        if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
            print("Starting location updates - background mode: \(isInSession)")
            Task {
                do {
                    self.updatesStarted = true
                    let updates = CLLocationUpdate.liveUpdates()
                    for try await update in updates {
                        if !self.updatesStarted { break }
                        if let loc = update.location {
                            self.lastLocation = loc
                            self.isStationary = update.isStationary
                            self.count += 1
                        }
                    }
                } catch {
                    print("Could not start location updates: \(error)")
                }
                return
            }
        } else {
            print("Cannot start location updates: No permission")
            // Don't request here - let PermissionManager handle it
        }
    }

    func stopLocationUpdates() {
        print("Stopping location updates")
        self.updatesStarted = false
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    // New method to completely stop all tracking
    func completelyStopLocationUpdates() {
        print("Completely stopping location updates")
        self.updatesStarted = false
        
        // Force cancel the location updates
        self.locationManager.stopUpdatingLocation()
        self.motionManager.stopDeviceMotionUpdates()
        
        // Explicitly disable background mode to stop the indicator
        self.locationManager.allowsBackgroundLocationUpdates = false
        self.locationManager.showsBackgroundLocationIndicator = false
        
        // Also stop any active background activity session
        if backgroundActivity {
            self.background?.invalidate()
            self.backgroundActivity = false
        }
    }
}
