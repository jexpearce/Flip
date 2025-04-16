import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @ObservedObject private var sessionJoinCoordinator = SessionJoinCoordinator.shared
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared
    @State private var showRules = false
    @State private var showJoinConfirmation = false
    @State private var joinSessionName = ""
    @State private var joinSessionId = ""
    @State private var isJoining = false

    var body: some View {
        ZStack {
            // Main content based on app state
            VStack(spacing: 30) {
                switch appManager.currentState {
                case .initial: SetupView()
                case .paused: PausedView()
                case .countdown: CountdownView()
                case .tracking: TrackingView()
                case .failed: FailureView()
                case .completed: CompletionView()
                case .joinedCompleted: JoinedCompletionView()
                case .mixedOutcome: MixedOutcomeView()
                case .othersActive: OthersActiveView()
                }
            }

            // Rules overlay
            if showRules { RulesView(showRules: $showRules) }

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
        // Add the join session confirmation alert
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowLiveSessionJoinConfirmation"))) { _ in
            if let joinInfo = sessionJoinCoordinator.getJoinSession() {
                // Check if we're trying to join our own session
                if joinInfo.id.contains(Auth.auth().currentUser?.uid ?? "") {
                    print("Preventing join of your own session")
                    sessionJoinCoordinator.clearPendingSession()
                    // Show an error message to the user
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                } else {
                    joinSessionId = joinInfo.id
                    joinSessionName = joinInfo.name
                    showJoinConfirmation = true
                }
            }
        }
        .alert("Join Live Session", isPresented: $showJoinConfirmation) {
            Button("Cancel", role: .cancel) {
                sessionJoinCoordinator.clearPendingSession()
            }
            
            Button("Join Session") {
                isJoining = true
                
                // Guard against joining your own session
                guard !joinSessionId.contains(Auth.auth().currentUser?.uid ?? "") else {
                    print("Preventing join of your own session")
                    sessionJoinCoordinator.clearPendingSession()
                    isJoining = false
                    return
                }
                
                // IMPROVED: Use a timeout mechanism
                let joinTask = DispatchWorkItem {
                    // If we're still joining after 8 seconds, there's likely a problem
                    if self.isJoining {
                        self.isJoining = false
                        sessionJoinCoordinator.clearPendingSession()
                        
                        // Haptic feedback for error
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                        
                        print("Join operation timed out after 8 seconds")
                    }
                }
                
                // Schedule timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: joinTask)
                
                // Directly join the live session
                LiveSessionManager.shared.joinSession(sessionId: joinSessionId) { success, remainingSeconds, targetDuration in
                    // Cancel the timeout
                    joinTask.cancel()
                    
                    self.isJoining = false
                    
                    if success {
                        print("Successfully joined session: \(joinSessionId) with \(remainingSeconds) seconds remaining")
                        
                        // Initialize session with the joined session's settings and start immediately
                        DispatchQueue.main.async {
                            // Directly join and start the live session
                            appManager.joinLiveSession(
                                sessionId: joinSessionId,
                                remainingSeconds: remainingSeconds,
                                totalDuration: targetDuration
                            )
                            
                            // Clear the pending session after successful join
                            sessionJoinCoordinator.clearPendingSession()
                        }
                    } else {
                        // Show error
                        print("Failed to join session: \(joinSessionId)")
                        sessionJoinCoordinator.clearPendingSession()
                        
                        // Haptic feedback for error
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                }
            }
            .disabled(isJoining)
        } message: {
            Text("Do you want to join \(joinSessionName)'s focus session?")
        }
        .onAppear {
            // Check if there's a pending session join request
            if sessionJoinCoordinator.shouldJoinSession,
                let sessionId = sessionJoinCoordinator.pendingSessionId
            {
                // IMPROVED: Add validation check for own session
                if sessionId.contains(Auth.auth().currentUser?.uid ?? "") {
                    print("Preventing auto-join of own session")
                    sessionJoinCoordinator.clearPendingSession()
                    return
                }

                // Start the joining process
                liveSessionManager.isJoiningSession = true

                // Add timeout to prevent indefinite "joining" state
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    if self.liveSessionManager.isJoiningSession == true {
                        print("Auto-join timed out after 8 seconds")
                        self.liveSessionManager.isJoiningSession = false
                        sessionJoinCoordinator.clearPendingSession()
                    }
                }

                // First get session details
                liveSessionManager.getSessionDetails(sessionId: sessionId) { sessionData in
                    if let session = sessionData {
                        // Validate the session is not too old
                        if Date().timeIntervalSince(session.lastUpdateTime) > 120 {
                            print("Auto-join prevented - session is stale")
                            DispatchQueue.main.async {
                                sessionJoinCoordinator.clearPendingSession()
                                liveSessionManager.isJoiningSession = false
                            }
                            return
                        }
                        
                        // Join the session
                        liveSessionManager.joinSession(sessionId: sessionId) { success, remainingSeconds, totalDuration in
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
                    }
                    else {
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