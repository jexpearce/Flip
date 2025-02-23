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
            }

            //                    .tabViewStyle(.page)
            //                    .indexViewStyle(.page(backgroundDisplayMode: .always))
            //                    .background(Color.pink)
            //                    .toolbarBackground(
            //                        Color(red: 26 / 255, green: 14 / 255, blue: 47 / 255)
            //                            .opacity(0.98),
            //                        for: .tabBar
            //                    )
            .toolbarBackground(.red, for: .tabBar)
            //                    .toolbarBackground(.visible, for: .tabBar)
            //                    .accentColor(Theme.orange)  // Selected tab color
            //                    .tint(Color.white.opacity(0.4))  // Unselected tab color
        } else {
            AuthView().frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Theme.mainGradient
                )
        }
    }

}
