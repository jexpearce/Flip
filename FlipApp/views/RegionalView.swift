import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import MapKit
import SwiftUI

struct BuildingSelectorButton: View {
    let buildingName: String?
    let action: () -> Void
    let refreshAction: () -> Void
    @Binding var isRefreshing: Bool
    @State private var isPulsing = false
    @State private var hasAppeared = false

    // Check if this is the first time showing the button
    private var shouldPulse: Bool { !hasAppeared && (buildingName == nil || !hasAppeared) }

    var body: some View {
        HStack {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BUILDING").font(.system(size: 12, weight: .bold)).tracking(2)
                        .foregroundColor(.white.opacity(0.7))

                    Text(buildingName ?? "Tap to select building")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                .padding(.horizontal, 16)
            }

            // Refresh button
            Button(action: refreshAction) {
                ZStack {
                    if isRefreshing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    else {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))

                            Text("REFRESH").font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(width: 60).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            }
            .disabled(isRefreshing)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(isPulsing ? 0.6 : 0.2),
                        lineWidth: isPulsing ? 2 : 1
                    )
                    .animation(
                        isPulsing
                            ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
            }
        )
        .padding(.horizontal)
        .onAppear {
            // Only pulse if we should (first time or no building selected)
            if shouldPulse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { isPulsing = true }
                }

                // Turn off pulsing after the user has seen it
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        isPulsing = false
                        hasAppeared = true
                    }
                }
            }
        }
    }
}

struct RegionalView: View {
    @StateObject private var viewModel = RegionalViewModel.shared
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var showMap = false
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared

    // Add this state variable for the privacy sheet
    @State private var showPrivacySettings = false

    // Add state to track which leaderboard is currently visible - default to building
    @State private var currentLeaderboard: LeaderboardType = .building

    // Create our ViewModels for all leaderboards
    @StateObject private var regionalWeeklyViewModel = RegionalWeeklyLeaderboardViewModel()
    @StateObject private var regionalAllTimeViewModel = RegionalAllTimeLeaderboardViewModel()
    @StateObject private var globalWeeklyViewModel = GlobalWeeklyLeaderboardViewModel()
    @StateObject private var globalAllTimeViewModel = GlobalAllTimeLeaderboardViewModel()

    // Flag to track if this is first launch
    @State private var isFirstLaunch =
        UserDefaults.standard.bool(forKey: "hasShownRegionalView") == false

    // Regional view deep midnight purple gradient with subtle red
    private let regionalGradient = LinearGradient(
        colors: [
            Theme.deepMidnightPurple,  // Deep midnight purple
            Color(red: 28 / 255, green: 14 / 255, blue: 45 / 255),  // Midnight purple
            Color(red: 35 / 255, green: 14 / 255, blue: 40 / 255),  // Purple with slight red
            Color(red: 30 / 255, green: 12 / 255, blue: 36 / 255),  // Back to purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Red glow effect for accents
    private let redGlow = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255).opacity(0.5)

    var body: some View {
        NavigationStack {
            // Wrap the whole content in a ScrollView for smooth layout changes
            ScrollView {
                ZStack {
                    // Background with decorative elements
                    ZStack {
                        // Main gradient background
                        regionalGradient.edgesIgnoringSafeArea(.all)

                        // Top decorative glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
                                            .opacity(0.15),
                                        Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255)
                                            .opacity(0.05),
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 300
                                )
                            )
                            .frame(width: 300, height: 300).offset(x: 150, y: -150).blur(radius: 50)

                        // Bottom decorative glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
                                            .opacity(0.1),
                                        Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255)
                                            .opacity(0.05),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 250, height: 250).offset(x: -120, y: 350).blur(radius: 40)
                    }

                    VStack(spacing: 20) {
                        // Title with enhanced visual style and privacy button
                        HStack {
                            Text("REGIONAL").font(.system(size: 28, weight: .black)).tracking(8)
                                .foregroundColor(.white).shadow(color: redGlow, radius: 8)
                                .padding(.leading)

                            Spacer()

                            // Add privacy button
                            RegionalPrivacyButton(showSettings: $showPrivacySettings) {
                                showPrivacySettings = true
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 50).padding(.bottom, 10)

                        // Building selection button - Improved version
                        BuildingSelectorButton(
                            buildingName: viewModel.selectedBuilding?.name,
                            action: {
                                // Check location permissions before allowing building selection
                                locationPermissionManager.checkRegionalAvailability {
                                    hasPermission in
                                    if hasPermission { viewModel.startBuildingIdentification() }
                                }
                            },
                            refreshAction: {
                                // Check location permissions before refreshing
                                locationPermissionManager.checkRegionalAvailability {
                                    hasPermission in
                                    if hasPermission { viewModel.refreshCurrentBuilding() }
                                }
                            },
                            isRefreshing: $viewModel.isRefreshing
                        )

                        // Leaderboard container with animated transitions
                        ZStack {
                            // Building Leaderboard (default)
                            if currentLeaderboard == .building {
                                // Modified RegionalLeaderboard with navigation arrow
                                VStack {
                                    RegionalLeaderboard(viewModel: viewModel.leaderboardViewModel)
                                        .overlay(
                                            HStack {
                                                Spacer()

                                                // Right arrow to regional weekly
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        currentLeaderboard = .regionalWeekly
                                                    }
                                                }) {
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(.white.opacity(0.7))
                                                        .padding(8)
                                                        .background(
                                                            Circle().fill(Color.white.opacity(0.1))
                                                        )
                                                }
                                                .padding(.trailing, 30).padding(.top, 12)
                                            },
                                            alignment: .topTrailing
                                        )
                                }
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .leading),
                                        removal: .move(edge: .leading)
                                    )
                                )
                            }

                            // Regional Weekly Leaderboard
                            if currentLeaderboard == .regionalWeekly {
                                RegionalWeeklyLeaderboard(
                                    viewModel: regionalWeeklyViewModel,
                                    currentLeaderboard: $currentLeaderboard
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    )
                                )
                            }

                            // Regional All Time Leaderboard
                            if currentLeaderboard == .regionalAllTime {
                                RegionalAllTimeLeaderboard(
                                    viewModel: regionalAllTimeViewModel,
                                    currentLeaderboard: $currentLeaderboard
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    )
                                )
                            }

                            // Global Weekly Leaderboard
                            if currentLeaderboard == .globalWeekly {
                                GlobalWeeklyLeaderboard(
                                    viewModel: globalWeeklyViewModel,
                                    currentLeaderboard: $currentLeaderboard
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)
                                    )
                                )
                            }

                            // Global All Time Leaderboard
                            if currentLeaderboard == .globalAllTime {
                                GlobalAllTimeLeaderboard(
                                    viewModel: globalAllTimeViewModel,
                                    currentLeaderboard: $currentLeaderboard
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing),
                                        removal: .move(edge: .trailing)
                                    )
                                )
                            }
                        }
                        .padding(.horizontal).animation(.easeInOut, value: currentLeaderboard)

                        Spacer(minLength: 20)  // Add minimum spacing

                        // Map Button - Fixed at bottom with a glowing effect
                        Button(action: {
                            // Check for map consent and location permissions
                            showMapView()
                        }) {
                            ZStack {
                                // Button background
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 220 / 255,
                                                    green: 38 / 255,
                                                    blue: 38 / 255
                                                )
                                                .opacity(0.8),
                                                Color(
                                                    red: 185 / 255,
                                                    green: 28 / 255,
                                                    blue: 28 / 255
                                                )
                                                .opacity(0.8),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.8),
                                                        Color.white.opacity(0.2),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(
                                        color: Color(
                                            red: 220 / 255,
                                            green: 38 / 255,
                                            blue: 38 / 255
                                        )
                                        .opacity(0.5),
                                        radius: 15,
                                        x: 0,
                                        y: 0
                                    )

                                HStack(spacing: 14) {
                                    // Map icon with glowing effect
                                    ZStack {
                                        Circle().fill(Color.white.opacity(0.15))
                                            .frame(width: 42, height: 42)

                                        Image(systemName: "map.fill")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.white.opacity(0.8), radius: 2)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("FRIENDS MAP").font(.system(size: 20, weight: .black))
                                            .tracking(3).foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.3), radius: 1)

                                        Text("See past and live flip session locations! (Beta)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    }

                                    Spacer()

                                    // Arrow indicator
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 80)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 30)
                        // Add animation to ensure smooth transition when leaderboard content changes
                        .animation(.easeInOut, value: currentLeaderboard)
                    }
                    .padding(.bottom, 20)  // Add padding to ensure content is not cut off
                }
            }  // End of ScrollView
            .sheet(isPresented: $viewModel.showBuildingSelection) {
                BuildingSelectionView(
                    isPresented: $viewModel.showBuildingSelection,
                    buildings: viewModel.suggestedBuildings,
                    onBuildingSelected: { building in viewModel.selectBuilding(building) }
                )
            }  // Add privacy settings sheet
            .sheet(isPresented: $showPrivacySettings) { RegionalPrivacySheet() }
        }
        .fullScreenCover(isPresented: $showMap) { MapView().environmentObject(viewRouter) }
        .onAppear {
            checkLocationPermission()
            viewModel.loadCurrentBuilding()

            // Initialize all leaderboards when the view appears
            switch currentLeaderboard {
            case .regionalWeekly: regionalWeeklyViewModel.loadRegionalWeeklyLeaderboard()
            case .regionalAllTime: regionalAllTimeViewModel.loadRegionalAllTimeLeaderboard()
            case .globalWeekly: globalWeeklyViewModel.loadGlobalWeeklyLeaderboard()
            case .globalAllTime: globalAllTimeViewModel.loadGlobalAllTimeLeaderboard()
            default: break
            }
        }  // Show "Open Settings" alert when location permission is denied
        .alert(isPresented: $locationPermissionManager.showSettingsAlert) {
            Alert(
                title: Text("Location Permission Required"),
                message: Text(
                    "Regional features need location access. Please go to Settings and enable location for Flip."
                ),
                primaryButton: .default(Text("Open Settings")) {
                    LocationPermissionManager.shared.openSettings()
                },
                secondaryButton: .cancel()
            )
        }
        .background(regionalGradient.edgesIgnoringSafeArea(.all))
        // Load appropriate leaderboard data when switching tabs
        .onChange(of: currentLeaderboard) {
            switch currentLeaderboard {
            case .building:
                // Building leaderboard handles its own data loading
                break
            case .regionalWeekly: regionalWeeklyViewModel.loadRegionalWeeklyLeaderboard()
            case .regionalAllTime: regionalAllTimeViewModel.loadRegionalAllTimeLeaderboard()
            case .globalWeekly: globalWeeklyViewModel.loadGlobalWeeklyLeaderboard()
            case .globalAllTime: globalAllTimeViewModel.loadGlobalAllTimeLeaderboard()
            }
        }
    }

    // Show map with permission checks and privacy alert if needed
    func showMapView() {
        print("Map button tapped, starting map view process")

        // First check location permissions
        locationPermissionManager.checkRegionalAvailability { hasPermission in
            print("Location permission check result: \(hasPermission)")

            if hasPermission {
                // Then check map consent
                MapConsentManager.shared.checkAndRequestConsent { consentGranted in
                    print("Map consent check result: \(consentGranted)")

                    if consentGranted {
                        // Explicitly set on main thread
                        DispatchQueue.main.async {
                            print("Opening map view")
                            self.showMap = true
                        }
                    }
                }
            }
        }
    }

    private func checkLocationPermission() {
        // Move the potentially blocking operation to a background thread
        DispatchQueue.global(qos: .userInitiated)
            .async {
                let status = CLLocationManager().authorizationStatus

                // If we need to show UI, dispatch back to the main thread
                if status == .denied || status == .restricted || status == .notDetermined {
                    DispatchQueue.main.async {
                        self.locationPermissionManager.requestPermissionWithCustomAlert()
                    }
                }
            }
    }
}

class RegionalViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RegionalViewModel()

    @Published var leaderboardViewModel = RegionalLeaderboardViewModel()
    @Published var currentLocation: CLLocation?
    @Published var selectedBuilding: BuildingInfo?
    @Published var suggestedBuildings: [MKPlacemark] = []
    @Published var showBuildingSelection = false
    @Published var isRefreshing = false
    @Published var showCustomLocationCreation = false

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // CRITICAL: Only request if permission flow is complete
        let authStatus = locationManager.authorizationStatus
        let isFirstLaunch = UserDefaults.standard.bool(forKey: "isPotentialFirstTimeUser")

        // Only request permissions automatically if:
        // 1. Not the first launch (to allow your sequence to run)
        // 2. Or permissions are already determined (already granted or denied)
        if !isFirstLaunch || authStatus != .notDetermined {
            // Safe to request permissions here
            if authStatus == .notDetermined { locationManager.requestWhenInUseAuthorization() }
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

        // If we have a selected building, check if user has moved far from it
        if let building = selectedBuilding {
            let buildingLocation = CLLocation(
                latitude: building.coordinate.latitude,
                longitude: building.coordinate.longitude
            )

            let distance = location.distance(from: buildingLocation)

            // If user has moved more than threshold, suggest a building change
            if distance > 100 {  // 100 meters away from current building
                print(
                    "User has moved \(Int(distance))m from current building, checking for new buildings..."
                )
                startBuildingIdentification()
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
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    @MainActor func loadNearbyUsers() {
        // If we have a selected building, load building leaderboard
        if let building = selectedBuilding {
            leaderboardViewModel.loadBuildingLeaderboard(building: building)
            return
        }

        // Otherwise load regional leaderboard based on location
        let location = LocationHandler.shared.lastLocation
        if location.horizontalAccuracy > 0 {
            leaderboardViewModel.loadRegionalLeaderboard(near: location)
        }
        else if let managerLocation = currentLocation {
            leaderboardViewModel.loadRegionalLeaderboard(near: managerLocation)
        }
    }

    @MainActor func startBuildingIdentification() {
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
                    self.showBuildingSelection = true
                }
                else {
                    // No buildings found - show a custom popup
                    self.showNoNearbyBuildingsAlert()
                }
            }
        }
    }

    func selectBuilding(_ building: BuildingInfo) {
        self.selectedBuilding = building

        // For debugging - print exact coordinate values and building ID
        let standardizedId = String(
            format: "building-%.6f-%.6f",
            building.coordinate.latitude,
            building.coordinate.longitude
        )
        print("🏢 Selected building: \(building.name)")
        print("🌐 Coordinates: \(building.coordinate.latitude), \(building.coordinate.longitude)")
        print("🆔 Standardized ID: \(standardizedId)")

        // Save the selected building to Firestore
        if let userId = Auth.auth().currentUser?.uid {
            let buildingData: [String: Any] = [
                "id": standardizedId,  // Use standardized ID here
                "name": building.name, "latitude": building.coordinate.latitude,
                "longitude": building.coordinate.longitude,
                "lastUpdated": FieldValue.serverTimestamp(),
            ]

            FirebaseManager.shared.db.collection("users").document(userId).collection("settings")
                .document("currentBuilding")
                .setData(buildingData) { error in
                    if let error = error {
                        print("Error saving building info: \(error.localizedDescription)")
                    }
                    else {
                        print(
                            "Building info saved successfully with standardized ID: \(standardizedId)"
                        )

                        // When loading the leaderboard, also check nearby sessions that might not have the exact building ID
                        DispatchQueue.main.async {
                            self.leaderboardViewModel.loadBuildingLeaderboard(building: building)
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
                        self?.selectedBuilding = building
                        self?.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                    }
                }
                else {
                    // No building set yet, load users based on GPS location
                    DispatchQueue.main.async { self?.loadNearbyUsers() }
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
}
