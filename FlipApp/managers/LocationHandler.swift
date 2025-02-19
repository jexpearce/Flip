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

    func startLocationUpdates(_ heartbeat:@escaping ()->()) {
        if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }

        self.motionManager.deviceMotionUpdateInterval = 1
        self.motionManager.startDeviceMotionUpdates()

        print("Starting location updates")
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
                        heartbeat()
                    }
                }
            } catch {
                print("Could not start location updates")
            }
            return
        }
    }

    func stopLocationUpdates() {
        print("Stopping location updates")
        self.updatesStarted = false
        self.motionManager.stopDeviceMotionUpdates()
    }
}
