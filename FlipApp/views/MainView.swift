import SwiftUI

struct MainView: View {

  var body: some View {
    TabView {
      Group {
        HomeView().tabItem {
          Label("Home", systemImage: "house.fill")
        }
        FeedView().tabItem {
          Label("Feed", systemImage: "list.bullet.rectangle.fill")
        }
        ProfileView().tabItem {
          Label("Profile", systemImage: "person.fill")
        }
      }.background(Theme.mainGradient)
        .toolbarBackground(Theme.darkGray, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
    .accentColor(Theme.neonYellow)

  }
}
