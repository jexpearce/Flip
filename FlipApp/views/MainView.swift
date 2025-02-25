import FirebaseAuth
import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        if authManager.isAuthenticated {
            TabView {
                // First tab (left-most)
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet.rectangle.fill")
                    }
                
                // Second tab (left of center)
                MapView()
                
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                
                // Center tab (Home)
                HomeView()
                    .background(Theme.mainGradient)
                    .tabItem {
                        VStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                            Text("Home")
                        }
                    }
                
                // Fourth tab (right of center)
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }
                
                // Fifth tab (right-most)
                ProfileView()
                    .background(Theme.mainGradient)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .accentColor(Color(red: 56/255, green: 189/255, blue: 248/255)) // Set accent color for selected tab
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.mainGradient)
            .toolbarBackground(Theme.deepMidnightPurple, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
            .onAppear {
                // Initialize the ScoreManager after Firebase is configured
                ScoreManager.shared.initialize()
                
                // Apply custom tab bar appearance to emphasize center tab
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                appearance.backgroundColor = UIColor(Theme.deepMidnightPurple)
                
                // Add subtle glow to selected item
                appearance.selectionIndicatorTintColor = UIColor(
                    red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0
                )
                
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        } else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.mainGradient)
        }
    }
}

