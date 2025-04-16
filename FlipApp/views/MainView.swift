import FirebaseAuth
import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewRouter = ViewRouter()
    @StateObject private var leaderboardConsentManager = LeaderboardConsentManager.shared
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared

    @EnvironmentObject var appManager: AppManager
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var checkPermissionsOnAppear = true
    @State private var showLocationSettingsAlert = false
    
    // Helper to check if location permission is granted
    private var hasLocationPermission: Bool {
        permissionManager.locationAuthStatus == .authorizedWhenInUse || 
        permissionManager.locationAuthStatus == .authorizedAlways
    }
    
    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $viewRouter.selectedTab) {
                // First tab (left-most)
                FeedView().tabItem { Label("Feed", systemImage: "list.bullet.rectangle.fill") }
                    .tag(0)

                // Second tab (left of center) - RegionalView
                ZStack {
                    // Show RegionalView only if location permission is granted
                    if hasLocationPermission {
                        RegionalView()
                            .overlay(
                                Group {
                                    if leaderboardConsentManager.shouldPulseRegionalTab {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                PulsingTabIndicator()
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            )
                    } else {
                        // Show placeholder with location permission required message
                        VStack(spacing: 20) {
                            Image(systemName: "location.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("Location Access Required")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("This feature requires location permission to work")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showLocationSettingsAlert = true
                            }) {
                                Text("Enable Location")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.tealyGradient))
                            }
                            .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.mainGradient)
                    }
                }
                .tabItem { 
                    // Gray out the regional tab item when location is disabled
                    Label("Regional", systemImage: "location.fill")
                        .environment(\.symbolVariants, hasLocationPermission ? .fill : .none)
                        .foregroundColor(hasLocationPermission ? nil : .gray)
                }
                .disabled(!hasLocationPermission)
                .tag(1)

                // Center tab (Home)
                HomeView().background(Theme.mainGradient)
                    .tabItem {
                        VStack {
                            Image(systemName: "house.fill").font(.system(size: 24))
                            Text("Home")
                        }
                    }
                    .tag(2)

                // Fourth tab (right of center)
                FriendsView().tabItem { Label("Friends", systemImage: "person.2.fill") }.tag(3)

                // Fifth tab (right-most)
                ProfileView().background(Theme.mainGradient)
                    .tabItem { Label("Profile", systemImage: "person.fill") }.tag(4)
            }
            .accentColor(Theme.lightTealBlue)  // Set accent color for selected tab
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.mainGradient)
            .overlay(
                Group {
                    if appManager.isJoinedSession && appManager.liveSessionId != nil
                        && (appManager.currentState == .tracking
                            || appManager.currentState == .countdown
                            || appManager.currentState == .paused)
                    {
                        VStack {
                            JoinedSessionIndicator().padding(.horizontal).padding(.top, 15)

                            Spacer()
                        }
                    }
                }
            )
            .toolbarBackground(Theme.deepMidnightPurple, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar).toolbarColorScheme(.dark, for: .tabBar)
            .onAppear {
                // Initialize the ScoreManager after Firebase is configured
                ScoreManager.shared.initialize()

                // Apply custom tab bar appearance to emphasize center tab
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundColor = UIColor(Theme.deepMidnightPurple)

                // Add subtle glow to selected item
                appearance.selectionIndicatorTintColor = UIColor(Theme.lightTealBlue)

                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }

                // Check permissions when app launches
                if checkPermissionsOnAppear
                    && UserDefaults.standard.bool(forKey: "hasCompletedPermissionFlow")
                {
                    checkPermissionsOnAppear = false

                    // Check permissions status - but don't start the permission flow
                    permissionManager.checkPermissions()
                    // Only refresh permissions if we've already completed the flow
                    // DO NOT call requestAllPermissions here!
                }
            }
            // Listen for changes in location permission
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("locationPermissionChanged"))) { _ in
                // If location permission is revoked and we're on the regional tab, navigate back to home
                if !hasLocationPermission && viewRouter.selectedTab == 1 {
                    viewRouter.selectedTab = 2 // Switch to home tab
                }
            }
            .environmentObject(viewRouter)  // Add the permission manager as an environment object
            .environmentObject(permissionManager)
            .alert("Location Access Required", isPresented: $showLocationSettingsAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Location access is required to identify your current building and enable regional features.")
            }
        }
        else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.mainGradient)
        }
    }
}
