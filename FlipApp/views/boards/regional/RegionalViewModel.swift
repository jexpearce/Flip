import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import MapKit
import SwiftUI

class RegionalViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RegionalViewModel()

    @Published var leaderboardViewModel = RegionalLeaderboardViewModel()
    @Published var currentLocation: CLLocation?
    @Published var selectedBuilding: BuildingInfo?
    @Published var suggestedBuildings: [MKPlacemark] = []
    @Published var showBuildingSelection = false
    @Published var isRefreshing = false
    @Published var showCustomLocationCreation = false
    @Published var shouldPulseBuildingButton = false

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        setupLocationManager()
        
        // Check if we should start pulsing the building button
        if PermissionManager.shared.locationAuthStatus == .authorizedWhenInUse || 
           PermissionManager.shared.locationAuthStatus == .authorizedAlways {
            if selectedBuilding == nil {
                shouldPulseBuildingButton = true
            }
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // CRITICAL: Only request if permission flow is complete
        let authStatus = locationManager.authorizationStatus
        if !PermissionManager.shared.isPermissionLocked() && authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        // Listen for location updates from LocationHandler
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("locationUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocation {
                self?.currentLocation = location
                self?.loadNearbyUsers()
            }
        }
    }

    @MainActor func refreshCurrentBuilding() {
        if PermissionManager.shared.isPermissionLocked() {
            print("⏸️ RegionalView: Deferring building refresh until InitialView completes")
            return
        }
        isRefreshing = true

        // Request a high accuracy location update
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()

        // Get current location
        let location = LocationHandler.shared.lastLocation

        // Skip if location is invalid
        guard location.horizontalAccuracy > 0 else {
            isRefreshing = false
            return
        }

        // If we have a selected building, check if user has moved far from it using the new method
        if let building = selectedBuilding {
            // Use the new method to determine if we should update the building
            if BuildingIdentificationService.shared.shouldUpdateBuilding(
                currentLocation: location,
                currentBuilding: building
            ) {
                print("User has moved significantly from current building, checking for new buildings...")
                // Instead of showing building selection, automatically find and select the new building
                BuildingIdentificationService.shared.identifyNearbyBuildings(at: location) {
                    [weak self] buildings, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error identifying buildings: \(error.localizedDescription)")
                        self.isRefreshing = false
                        return
                    }
                    DispatchQueue.main.async {
                        if let buildings = buildings, !buildings.isEmpty {
                            // Automatically select the first building (which is already sorted by session count and distance)
                            let buildingName = BuildingIdentificationService.shared.getBuildingName(
                                from: buildings[0]
                            )
                            let buildingInfo = BuildingInfo(
                                id: "",  // The BuildingInfo init will standardize this
                                name: buildingName,
                                coordinate: buildings[0].coordinate
                            )
                            self.selectBuilding(buildingInfo)
                        }
                        self.isRefreshing = false
                    }
                }
            }
            else {
                // Still in the same building
                isRefreshing = false
            }
        }
        else {
            // No building selected, try to find one
            startBuildingIdentification()
        }
    }

    // MARK: - CLLocationManagerDelegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location
        print("Location update received in RegionalViewModel: \(location.coordinate)")
        
        // Check if we need to update the building based on the new location
        if let building = selectedBuilding {
            if BuildingIdentificationService.shared.shouldUpdateBuilding(
                currentLocation: location,
                currentBuilding: building
            ) {
                print("Location update shows significant movement - refreshing building")
                Task { @MainActor in
                    self.refreshCurrentBuilding()
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    func canLoadLeaderboardData() -> Bool {
        return LeaderboardConsentManager.shared.canAddToLeaderboard()
    }

    // Modify the loadNearbyUsers method to check for consent:
    @MainActor func loadNearbyUsers() {
        // Ensure the user has completed at least one session before loading the leaderboard
        guard let userId = Auth.auth().currentUser?.uid else { return }
        // Check if user has consented to leaderboards
        guard canLoadLeaderboardData() else {
            print("User has not consented to leaderboards. Skipping leaderboard loading.")
            return
        }

        FirebaseManager.shared.db.collection("sessions").whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    // User has completed at least one session, proceed to load leaderboard
                    if let building = self.selectedBuilding {
                        self.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                    }
                    else {
                        let location = LocationHandler.shared.lastLocation
                        if location.horizontalAccuracy > 0 {
                            self.leaderboardViewModel.loadRegionalLeaderboard(near: location)
                        }
                        else if let managerLocation = self.currentLocation {
                            self.leaderboardViewModel.loadRegionalLeaderboard(near: managerLocation)
                        }
                    }
                }
                else {
                    print("User has no completed sessions. Skipping leaderboard loading.")
                }
            }
    }

    @MainActor func startBuildingIdentification() {
        if PermissionManager.shared.isPermissionLocked() {
            print("⏸️ RegionalView: Deferring building identification until InitialView completes")
            return
        }
        // Request high-accuracy location for building identification
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()

        var location: CLLocation

        // Get the most accurate location available
        let lastLocation = LocationHandler.shared.lastLocation

        if lastLocation.horizontalAccuracy > 0 && lastLocation.horizontalAccuracy < 50 {
            location = lastLocation
        }
        else if let managerLocation = currentLocation,
            managerLocation.horizontalAccuracy > 0 && managerLocation.horizontalAccuracy < 50
        {
            location = managerLocation
        }
        else {
            // If we don't have an accurate location, use the last known location
            location = lastLocation
        }

        BuildingIdentificationService.shared.identifyNearbyBuildings(at: location) {
            [weak self] buildings, error in
            guard let self = self else { return }

            self.isRefreshing = false

            if let error = error {
                print("Error identifying buildings: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                if let buildings = buildings, !buildings.isEmpty {
                    self.suggestedBuildings = buildings
                    // If no building is selected, automatically select the first building
                    // This is independent of leaderboard consent or session completion
                    if self.selectedBuilding == nil {
                        let buildingName = BuildingIdentificationService.shared.getBuildingName(
                            from: buildings[0]
                        )
                        let buildingInfo = BuildingInfo(
                            id: "",  // The BuildingInfo init will standardize this
                            name: buildingName,
                            coordinate: buildings[0].coordinate
                        )
                        self.selectBuilding(buildingInfo)
                    }
                    else {
                        self.showBuildingSelection = true
                    }
                }
                else {
                    // No buildings found - show a custom popup
                    self.showNoNearbyBuildingsAlert()
                }
            }
        }
    }

    func selectBuilding(_ building: BuildingInfo) {
        // Store the building with standardized ID format
        let standardizedBuilding = BuildingInfo(
            id: "",  // The BuildingInfo init will standardize this
            name: building.name,
            coordinate: building.coordinate
        )
        self.selectedBuilding = standardizedBuilding

        // For debugging - print exact coordinate values and building ID
        print("🏢 Selected building: \(standardizedBuilding.name)")
        print(
            "🌐 Coordinates: \(standardizedBuilding.coordinate.latitude), \(standardizedBuilding.coordinate.longitude)"
        )
        print("🆔 Building ID: \(standardizedBuilding.id)")

        // Save the selected building to Firestore regardless of leaderboard consent
        if let userId = Auth.auth().currentUser?.uid {
            let buildingData: [String: Any] = [
                "id": standardizedBuilding.id, "name": standardizedBuilding.name,
                "latitude": standardizedBuilding.coordinate.latitude,
                "longitude": standardizedBuilding.coordinate.longitude,
                "lastUpdated": FieldValue.serverTimestamp(),
            ]

            FirebaseManager.shared.db.collection("users").document(userId).collection("settings")
                .document("currentBuilding")
                .setData(buildingData) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error saving building info: \(error.localizedDescription)")
                    }
                    else {
                        print(
                            "Building info saved successfully with ID: \(standardizedBuilding.id)"
                        )

                        // Only load leaderboard if user has given consent
                        let hasConsent = LeaderboardConsentManager.shared.canAddToLeaderboard()
                        if hasConsent {
                            DispatchQueue.main.async {
                                self.loadNearbyUsers()
                                // Add a short additional delay and force a fresh leaderboard load
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.leaderboardViewModel.loadBuildingLeaderboard(
                                        building: standardizedBuilding
                                    )
                                }
                            }
                        }
                        else {
                            print(
                                "⚠️ User hasn't given leaderboard consent yet, not loading leaderboard"
                            )
                        }
                    }
                }
        }
    }

    func loadCurrentBuilding() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        FirebaseManager.shared.db.collection("users").document(userId).collection("settings")
            .document("currentBuilding")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                if let data = document?.data(), let id = data["id"] as? String,
                    let name = data["name"] as? String, let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double
                {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )
                    let building = BuildingInfo(id: id, name: name, coordinate: coordinate)

                    DispatchQueue.main.async {
                        self.selectedBuilding = building
                        
                        // Check if we should update the building based on current location
                        let currentLocation = LocationHandler.shared.lastLocation
                        if currentLocation.horizontalAccuracy > 0 {
                            if BuildingIdentificationService.shared.shouldUpdateBuilding(
                                currentLocation: currentLocation,
                                currentBuilding: building
                            ) {
                                print("Current location differs significantly from saved building - refreshing")
                                self.refreshCurrentBuilding()
                            } else {
                                // Only load leaderboard if user has completed sessions
                                self.loadNearbyUsers()
                            }
                        } else {
                            // If we don't have an accurate location yet, just load with the existing building
                            self.loadNearbyUsers()
                        }
                    }
                }
                else {
                    // No building set yet, try to identify and select one automatically
                    DispatchQueue.main.async { self.startBuildingIdentification() }
                }
            }
    }

    private func showNoNearbyBuildingsAlert() {
        // Create custom alert if needed
        // For simplicity, let's use a standard alert
        let alert = UIAlertController(
            title: "No Buildings Nearby",
            message:
                "You don't appear to be near any recognizable buildings. You can create a custom location instead.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Create Custom Location", style: .default) { _ in
                // Show custom location creation screen
                // This would typically navigate to a custom location creation screen
                self.showCustomLocationCreation = true
            }
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Find the current UIWindow and present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            rootViewController.present(alert, animated: true)
        }
    }

    @MainActor func selectNearestBuilding() {
        // Only stop pulsing if we're successful
        if selectedBuilding == nil {
            isRefreshing = true
            var location: CLLocation
            
            // Get the most accurate location available
            let lastLocation = LocationHandler.shared.lastLocation
            
            if lastLocation.horizontalAccuracy > 0 {
                location = lastLocation
            } else if let managerLocation = currentLocation, managerLocation.horizontalAccuracy > 0 {
                location = managerLocation
            } else {
                // If we don't have an accurate location, use a fallback
                isRefreshing = false
                return
            }
            
            BuildingIdentificationService.shared.identifyNearbyBuildings(at: location) { [weak self] buildings, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let buildings = buildings, !buildings.isEmpty {
                        // Automatically select the first building
                        let buildingName = BuildingIdentificationService.shared.getBuildingName(from: buildings[0])
                        let buildingInfo = BuildingInfo(
                            id: "",  // The BuildingInfo init will standardize this
                            name: buildingName,
                            coordinate: buildings[0].coordinate
                        )
                        self.selectBuilding(buildingInfo)
                        // Stop pulsing the button once we've selected a building
                        self.shouldPulseBuildingButton = false
                    }
                    self.isRefreshing = false
                }
            }
        } else {
            // If we already have a building, just stop pulsing
            shouldPulseBuildingButton = false
        }
    }
}
