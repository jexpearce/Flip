import SwiftUI

struct JoinedSessionIndicator: View {
    @ObservedObject var liveSessionManager = LiveSessionManager.shared
    @EnvironmentObject var appManager: AppManager
    @State private var isGlowing = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var lastUpdateTime = Date()
    @State private var isInitializing = true  // Added to prevent immediate display

    private var joinedSession: LiveSessionManager.LiveSessionData? {
        return liveSessionManager.currentJoinedSession
    }

    // Elapsed time calculation
    private var formattedElapsedTime: String {
        // If app manager has accurate time, use it
        if appManager.currentState == .tracking || appManager.currentState == .countdown {
            let minutes = appManager.selectedMinutes - (appManager.remainingSeconds / 60)
            let seconds = appManager.remainingSeconds % 60
            return String(format: "%d:%02d", minutes, 60 - seconds)
        }
        // Otherwise use session data if available
        guard let session = joinedSession else { return "0:00" }

        let baseElapsed = session.elapsedSeconds
        // Calculate time since last update
        let timeSinceLast = Int(Date().timeIntervalSince(lastUpdateTime))
        // Add the timer elapsed seconds plus compensation for time since last update
        let adjustedElapsed =
            session.isPaused ? baseElapsed : baseElapsed + elapsedSeconds + timeSinceLast

        let minutes = adjustedElapsed / 60
        let seconds = adjustedElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Group {
            if appManager.isJoinedSession && !isInitializing {
                HStack(spacing: 8) {
                    // Live indicator
                    Circle().fill(appManager.isPaused ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                        .shadow(
                            color: (appManager.isPaused ? Color.orange : Color.green).opacity(0.6),
                            radius: isGlowing ? 4 : 2
                        )
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isGlowing
                        )

                    // Session info with starter name
                    Text(
                        appManager.isPaused
                            ? "PAUSED session with \(joinedSession?.starterUsername ?? "friend")"
                            : "In session with \(joinedSession?.starterUsername ?? "friend")"
                    )
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white)

                    Spacer()

                    // Elapsed time
                    Text(formattedElapsedTime).font(.system(size: 14, weight: .bold)).monospacedDigit()
                        .foregroundColor(.white).id(elapsedSeconds)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            appManager.isPaused ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            (appManager.isPaused ? Color.orange : Color.green)
                                                .opacity(0.8),
                                            (appManager.isPaused ? Color.orange : Color.green)
                                                .opacity(0.2),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
            } else {
                EmptyView()
            }
        }
        .onAppear {
            // Set up initial state
            isInitializing = true
            isGlowing = true
            lastUpdateTime = Date()
            
            // Start timer
            startTimer()
            
            // Delay showing the indicator to allow state to stabilize
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isInitializing = false
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: appManager.isPaused) { _ in
            // Reset the timer when pause state changes
            stopTimer()
            elapsedSeconds = 0
            lastUpdateTime = Date()
            if !appManager.isPaused {
                startTimer()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name("RefreshLiveSessions"))
        ) { _ in
            // Update last update time when we get fresh session data
            lastUpdateTime = Date()
        }
    }

    private func startTimer() {
        guard !appManager.isPaused else { return }

        elapsedSeconds = 0
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }

        // Make sure timer runs during scrolling
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}