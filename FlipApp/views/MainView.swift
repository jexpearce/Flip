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
                .toolbarBackground(
                    Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.98),
                    for: .tabBar
                )
                .toolbarBackground(.visible, for: .tabBar)
                .accentColor(.white)  // Selected tab color
                .tint(Color.white.opacity(0.4))  // Unselected tab color
            } else {
                AuthView()
            }
        }
    }
}