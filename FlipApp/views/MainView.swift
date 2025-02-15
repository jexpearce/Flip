import FirebaseAuth
import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    FeedView()
                        .tabItem {
                            Label("Feed", systemImage: "list.bullet.rectangle.fill")
                        }
                    FriendsView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2.fill")
                        }
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .background(Theme.mainGradient)
                .toolbarBackground(Theme.darkGray, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .accentColor(.white)
                .tint(.white)
            } else {
                AuthView()
            }
        }
    }
}