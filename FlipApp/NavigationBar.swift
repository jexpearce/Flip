import SwiftUI

struct NavigationBar: View {
    @Binding var selectedTab: Tab
    
    enum Tab {
        case home
        case feed
        case profile
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([Tab.home, Tab.feed, Tab.profile], id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: imageFor(tab))
                            .font(.system(size: 24, weight: .semibold))
                        Text(textFor(tab))
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1)
                    }
                    .foregroundColor(selectedTab == tab ? Theme.neonYellow : Color.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 8)
        .padding(.bottom, max(UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0, 8))
        .background(
            Theme.darkGray
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Theme.neonYellow.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func imageFor(_ tab: Tab) -> String {
        switch tab {
        case .home:
            return "house.fill"
        case .feed:
            return "list.bullet.rectangle.fill"
        case .profile:
            return "person.fill"
        }
    }
    
    private func textFor(_ tab: Tab) -> String {
        switch tab {
        case .home:
            return "HOME"
        case .feed:
            return "FEED"
        case .profile:
            return "PROFILE"
        }
    }
}

