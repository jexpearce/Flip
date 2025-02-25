import FirebaseAuth
import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        if authManager.isAuthenticated {
            TabView {
                Group {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    FeedView()
                        .tabItem {
                            Label(
                                "Feed",
                                systemImage: "list.bullet.rectangle.fill")
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.mainGradient
                )
                .toolbarBackground(Theme.deepMidnightPurple, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
            }
            .onAppear {
                // Initialize the ScoreManager after Firebase is configured
                ScoreManager.shared.initialize()
            }

        } else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.mainGradient
                )
        }
    }
}