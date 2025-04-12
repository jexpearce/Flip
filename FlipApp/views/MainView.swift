import FirebaseAuth
import SwiftUI

class ViewRouter: ObservableObject {
    @Published var selectedTab: Int = 2  // Home tab as default (center)
    init() {
        // Set up notification to handle tab switching from other parts of the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabSwitch),
            name: Notification.Name("SwitchToHomeTab"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRegionalTabSwitch),
            name: Notification.Name("SwitchToRegionalTab"),
            object: nil
        )
    }

    // ADD THIS METHOD
    @objc func handleTabSwitch() {
        // Switch to home tab (index 2)
        selectedTab = 2
    }
    @objc func handleRegionalTabSwitch() {
        // Switch to regional tab (index 1)
        selectedTab = 1
    }
    deinit { NotificationCenter.default.removeObserver(self) }
}

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewRouter = ViewRouter()
    @StateObject private var leaderboardConsentManager = LeaderboardConsentManager.shared

    @EnvironmentObject var appManager: AppManager
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var checkPermissionsOnAppear = true
    
    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $viewRouter.selectedTab) {
                // First tab (left-most)
                FeedView()
                    .tabItem { Label("Feed", systemImage: "list.bullet.rectangle.fill") }
                    .tag(0)

                // Second tab (left of center) - RegionalView
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
                    .tabItem { Label("Regional", systemImage: "location.fill") }
                    .tag(1)

                // Center tab (Home)
                HomeView()
                    .background(Theme.mainGradient)
                    .tabItem {
                        VStack {
                            Image(systemName: "house.fill").font(.system(size: 24))
                            Text("Home")
                        }
                    }
                    .tag(2)

                // Fourth tab (right of center)
                FriendsView()
                    .tabItem { Label("Friends", systemImage: "person.2.fill") }
                    .tag(3)

                // Fifth tab (right-most)
                ProfileView()
                    .background(Theme.mainGradient)
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(4)
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

                // NEW CODE: Check permissions when app launches
                if checkPermissionsOnAppear {
                    checkPermissionsOnAppear = false

                    // Check permissions status
                    permissionManager.checkPermissions()

                    // If permissions are not granted and this is a returning user,
                    // start the permission flow after a short delay
                    if !permissionManager.allPermissionsGranted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            permissionManager.requestAllPermissions()
                        }
                    }
                }
            }
            .environmentObject(viewRouter)  // Add the permission manager as an environment object
            .environmentObject(permissionManager)
        }
        else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.mainGradient)
        }
    }
}