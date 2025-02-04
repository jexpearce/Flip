import SwiftUI

struct MainView: View {
    @State private var selectedTab: NavigationBar.Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    ContentView()
                case .feed:
                    FeedView()
                case .profile:
                    ProfileView()
                }
            }
            .ignoresSafeArea(.keyboard)
            
            NavigationBar(selectedTab: $selectedTab)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
