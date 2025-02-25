import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showRules = false
    
    var body: some View {
        ZStack {
            // Main content based on app state
            VStack(spacing: 30) {
                switch appManager.currentState {
                case .initial:
                    SetupView()
                case .paused:
                    PausedView()
                case .countdown:
                    CountdownView()
                case .tracking:
                    TrackingView()
                case .failed:
                    FailureView()
                case .completed:
                    CompletionView()
                }
            }
            
            // Rules button (only shown on initial screen)
            if appManager.currentState == .initial {
                VStack {
                    HStack {
                        Spacer()
                        RulesButtonView(showRules: $showRules)
                            .padding(.top, 10)
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
            }
            
            // Rules overlay
            if showRules {
                RulesView(showRules: $showRules)
            }
            
            // Rank Promotion Alert
            if sessionManager.showPromotionAlert {
                RankPromotionAlert(
                    isPresented: $sessionManager.showPromotionAlert,
                    rankName: sessionManager.promotionRankName,
                    rankColor: sessionManager.promotionRankColor
                )
                .zIndex(100) // Ensure it appears above other content
            }
        }
    }
}