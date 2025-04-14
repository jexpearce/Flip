import CoreLocation
import Foundation
import SwiftUI

class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()

    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var showCustomAlert = false
    @Published var showSettingsAlert = false  // New alert for directing to Settings

    // Track if we've already shown the alert to avoid repeated prompts
    private var hasShownCustomAlert = false

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus

        // Load hasShownCustomAlert from UserDefaults
        hasShownCustomAlert = UserDefaults.standard.bool(forKey: "hasShownLocationAlert")
    }

    func requestPermissionWithCustomAlert() {
        // Check if we've already shown the alert and user denied
        if hasShownCustomAlert && authorizationStatus == .denied {
            // Show settings alert instead
            showSettingsAlert = true
            return
        }

        // Show our enhanced alert first (NotificationCenter will handle it)
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEnhancedLocationAlert"),
            object: nil
        )
        showCustomAlert = true

        // Mark that we've shown the alert
        hasShownCustomAlert = true
        UserDefaults.standard.set(true, forKey: "hasShownLocationAlert")
    }

    func checkRegionalAvailability(completion: @escaping (Bool) -> Void) {
        // If permissions are already granted, return true
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            completion(true)
            return
        }

        // If permissions are denied and we've shown the alert, show the settings alert
        if authorizationStatus == .denied && hasShownCustomAlert {
            showSettingsAlert = true
            completion(false)
            return
        }

        // If permissions are not determined, request them
        if authorizationStatus == .notDetermined {
            requestPermissionWithCustomAlert()
            // We'll rely on the delegate to track status changes
            completion(false)
            return
        }

        // Default fallback
        completion(false)
    }

    func requestSystemPermission() {
        // Add a delay to ensure the custom alert is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            print("Requesting system location permission after delay")
            // Then request the system permission
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    // Open settings app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // CLLocationManagerDelegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("Location permission status updated: \(self.authorizationStatus.rawValue)")

            // Notify observers that permissions changed
            NotificationCenter.default.post(
                name: Notification.Name("locationPermissionChanged"),
                object: nil
            )
        }
    }
}
