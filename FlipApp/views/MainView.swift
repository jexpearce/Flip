import FirebaseAuth
import SwiftUI

class ViewRouter: ObservableObject {
    @Published var selectedTab: Int = 2 // Home tab as default (center)
    @Published var friendToShow: FirebaseManager.FlipUser? = nil
    
    func showFriendProfile(friend: FirebaseManager.FlipUser) {
        self.friendToShow = friend
    }
}

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var viewRouter = ViewRouter()

    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $viewRouter.selectedTab) {
                // First tab (left-most)
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet.rectangle.fill")
                    }
                    .tag(0)
                
                // Second tab (left of center)
                MapView()
                    .tabItem {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tag(1)
                
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
                    .tag(2)
                
                // Fourth tab (right of center)
                FriendsView()
                    .tabItem {
                        Label("Friends", systemImage: "person.2.fill")
                    }
                    .tag(3)
                
                // Fifth tab (right-most)
                ProfileView()
                    .background(Theme.mainGradient)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
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
            .environmentObject(viewRouter)
        } else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.mainGradient)
        }
    }
}