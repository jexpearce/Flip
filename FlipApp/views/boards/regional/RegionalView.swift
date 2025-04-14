import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import MapKit
import SwiftUI

struct RegionalView: View {
    @StateObject private var viewModel = RegionalViewModel.shared
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var showMap = false
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared
    @StateObject private var mapConsentManager = MapConsentManager.shared

    // Add this state variable for the privacy sheet
    @State private var showPrivacySettings = false

    // Add state to track which leaderboard is currently visible - default to building
    @State private var currentLeaderboard: LeaderboardType = .building

    // Create our ViewModels for all leaderboards
    @StateObject private var regionalWeeklyViewModel = RegionalWeeklyLeaderboardViewModel()
    @StateObject private var regionalAllTimeViewModel = RegionalAllTimeLeaderboardViewModel()
    @StateObject private var globalWeeklyViewModel = GlobalWeeklyLeaderboardViewModel()
    @StateObject private var globalAllTimeViewModel = GlobalAllTimeLeaderboardViewModel()
    @StateObject private var leaderboardConsentManager = LeaderboardConsentManager.shared
    @State private var showLeaderboardConsent = false

    // Red glow effect for accents
    private let redGlow = Theme.darkRed.opacity(0.5)

    var body: some View {
        NavigationStack {
            // Wrap the whole content in a ScrollView for smooth layout changes
            ScrollView {
                ZStack {
                    // Background with decorative elements
                    ZStack {
                        // Main gradient background
                        Theme.regionalGradient.edgesIgnoringSafeArea(.all)

                        // Top decorative glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.darkRed.opacity(0.15), Theme.darkRuby.opacity(0.05),
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
                                        Theme.darkRed.opacity(0.1), Theme.darkRuby.opacity(0.05),
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
                                                Theme.darkRed.opacity(0.8),
                                                Theme.darkerRed.opacity(0.8),
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
                                        color: Theme.darkRed.opacity(0.5),
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
                        .padding(.horizontal, 20).padding(.bottom, 30)  // Add animation to ensure smooth transition when leaderboard content changes
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
            // Check if we need to show leaderboard consent
            if !leaderboardConsentManager.hasGivenConsent {
                // Mark that the user has seen this tab
                leaderboardConsentManager.markRegionalTabSeen()
                // Check if we have location permission first
                let authStatus = locationPermissionManager.authorizationStatus
                if authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways {
                    // Only show consent if we have location permission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showLeaderboardConsent = true
                    }
                }
            }
            // Initialize all leaderboards when the view appears
            switch currentLeaderboard {
            case .regionalWeekly: regionalWeeklyViewModel.loadRegionalWeeklyLeaderboard()
            case .regionalAllTime: regionalAllTimeViewModel.loadRegionalAllTimeLeaderboard()
            case .globalWeekly: globalWeeklyViewModel.loadGlobalWeeklyLeaderboard()
            case .globalAllTime: globalAllTimeViewModel.loadGlobalAllTimeLeaderboard()
            default: break
            }
        }
        // Show "Open Settings" alert when location permission is denied
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
        .background(Theme.regionalGradient.edgesIgnoringSafeArea(.all))  // Load appropriate leaderboard data when switching tabs
        .overlay(
            ZStack {
                if showLeaderboardConsent {
                    LeaderboardConsentAlert(isPresented: $showLeaderboardConsent)
                }
                // Add map privacy alert
                if mapConsentManager.showMapPrivacyAlert {
                    MapPrivacyAlert(
                        isPresented: $mapConsentManager.showMapPrivacyAlert,
                        onAccept: {
                            mapConsentManager.acceptMapPrivacy()
                            showMap = true
                        },
                        onReject: { mapConsentManager.rejectMapPrivacy() }
                    )
                }
            }
        )
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
