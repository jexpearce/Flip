import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @ObservedObject private var sessionJoinCoordinator = SessionJoinCoordinator
        .shared
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared
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
                case .joinedCompleted:
                    JoinedCompletionView()
                case .mixedOutcome:
                    MixedOutcomeView()
                case .othersActive:
                    OthersActiveView()
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
                .zIndex(100)  // Ensure it appears above other content
            }
            if sessionManager.showStreakAchievement {
                StreakAchievementAlert(
                    isPresented: $sessionManager.showStreakAchievement,
                    streakStatus: sessionManager.streakAchievementStatus,
                    streakCount: sessionManager.streakCount
                )
            }

        }
        .onAppear {
            // Check if there's a pending session join request
            if sessionJoinCoordinator.shouldJoinSession,
                let sessionId = sessionJoinCoordinator.pendingSessionId
            {

                // Start the joining process
                liveSessionManager.isJoiningSession = true

                // First get session details
                liveSessionManager.getSessionDetails(sessionId: sessionId) {
                    sessionData in
                    if let session = sessionData {
                        // Join the session
                        liveSessionManager.joinSession(sessionId: sessionId) {
                            success, remainingSeconds, totalDuration in
                            if success {
                                // Actually join the live session with proper timing values
                                DispatchQueue.main.async {
                                    // Use AppManager to join the session
                                    appManager.joinLiveSession(
                                        sessionId: sessionId,
                                        remainingSeconds: remainingSeconds,
                                        totalDuration: totalDuration
                                    )
                                }
                            }

                            // Clear pending session either way
                            DispatchQueue.main.async {
                                sessionJoinCoordinator.clearPendingSession()
                                liveSessionManager.isJoiningSession = false
                            }
                        }
                    } else {
                        // No valid session found
                        DispatchQueue.main.async {
                            sessionJoinCoordinator.clearPendingSession()
                            liveSessionManager.isJoiningSession = false
                        }
                    }
                }
            }
        }
    }
}
