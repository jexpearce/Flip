import SwiftUI
import FirebaseAuth

struct LiveSessionCard: View {
    let session: LiveSessionManager.LiveSessionData
    let isFriend: Bool
    
    @State private var isPressed = false
    @State private var isGlowing = false
    @StateObject private var sessionTimer = LiveSessionTimer()
    
    // Computed properties for live sessions
    private var isFull: Bool { return session.isFull }
    private var canJoin: Bool { return session.canJoin }
    
    // Computed real-time elapsed time string
    private var formattedElapsedTime: String {
        // Use sessionTimer.currentTick to force update
        let _ = sessionTimer.currentTick

        // Calculate elapsed time including drift compensation
        let baseElapsed = session.elapsedSeconds
        let timeSinceUpdate = Int(
            Date().timeIntervalSince1970 - session.lastUpdateTime.timeIntervalSince1970
        )
        let adjustment = session.isPaused ? 0 : min(timeSinceUpdate, 60)  // Limit adjustment to avoid huge jumps

        let totalElapsed = baseElapsed + adjustment
        let minutes = totalElapsed / 60
        let seconds = totalElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // LEFT SIDE: Profile picture with Live indicator if active
                ZStack(alignment: .topTrailing) {
                    // Default profile picture for non-friends
                    if !isFriend {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .foregroundColor(getProfileColor())
                            .shadow(color: getProfileShadowColor(), radius: 8)
                    } else {
                        // For friends, use the ProfilePictureWithStreak component (if available)
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .foregroundColor(getProfileColor())
                            .shadow(color: getProfileShadowColor(), radius: 8)
                    }

                    // Live indicator badge with animation
                    Circle().fill(isFull ? Color.gray : getLiveIndicatorColor())
                        .frame(width: 14, height: 14)
                        .shadow(color: getLiveIndicatorColor().opacity(0.6), radius: isGlowing ? 4 : 2)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isGlowing
                        )
                        .overlay(Circle().stroke(Color.black, lineWidth: 1)).offset(x: 2, y: -2)
                }

                // User info section
                VStack(alignment: .leading, spacing: 5) {
                    // LIVE text with pulse animation
                    HStack(spacing: 6) {
                        Text("LIVE").font(.system(size: 14, weight: .heavy))
                            .foregroundColor(isFull ? .gray : getLiveTextColor())
                            .shadow(color: getLiveTextColor().opacity(0.6), radius: isGlowing ? 4 : 2)
                            .scaleEffect(isGlowing ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isGlowing
                            )

                        Circle().fill(getLiveIndicatorColor()).frame(width: 6, height: 6)
                            .opacity(isGlowing ? 0.8 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: isGlowing
                            )
                    }

                    // Username with styling
                    Text(session.starterUsername).font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: getUsernameShadowColor(), radius: 6)

                    // Show brief session info
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill").font(.system(size: 12))
                            .foregroundColor(getInfoIconColor())

                        Text("Target: \(session.targetDuration)min")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.leading, 10)

                Spacer()

                // RIGHT SIDE: Join button or full indicator
                if canJoin {
                    Button(action: {
                        // Show simple join confirmation alert
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // Prevent joining your own session
                        if session.starterId == Auth.auth().currentUser?.uid {
                            print("Cannot join your own session")
                            let errorGenerator = UINotificationFeedbackGenerator()
                            errorGenerator.notificationOccurred(.error)
                            return
                        }
                        
                        // Use the session ID and creator's name for confirmation
                        SessionJoinCoordinator.shared.pendingSessionId = session.id
                        SessionJoinCoordinator.shared.pendingSessionName = session.starterUsername
                        SessionJoinCoordinator.shared.pendingTimestamp = Date()
                        SessionJoinCoordinator.shared.shouldJoinSession = true
                        
                        // Post notification to show confirmation dialog
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowLiveSessionJoinConfirmation"),
                            object: nil
                        )
                    }) {
                        Text("JOIN").font(.system(size: 14, weight: .bold)).tracking(1)
                            .foregroundColor(.white).padding(.vertical, 8).padding(.horizontal, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(getJoinButtonColor().opacity(0.3))
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(getJoinButtonColor().opacity(0.6), lineWidth: 1)
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                else {
                    // Show FULL indicator when session can't be joined
                    Text(isFull ? "FULL" : "UNAVAILABLE").font(.system(size: 14, weight: .bold)).tracking(1)
                        .foregroundColor(.gray).padding(.vertical, 8).padding(.horizontal, 16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2))

                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            }
                        )
                }
            }

            // Session timing information
            VStack(spacing: 8) {
                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 10)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TIME").font(.system(size: 12, weight: .medium)).tracking(1)
                            .foregroundColor(getTimeTextColor().opacity(0.8))

                        // Use real-time updated timer
                        Text(formattedElapsedTime).font(.system(size: 18, weight: .bold))
                            .monospacedDigit().foregroundColor(.white)
                            .id(sessionTimer.currentTick)  // Force refresh when counter changes
                            .shadow(color: getTimeTextColor().opacity(0.5), radius: 4)
                    }

                    Spacer()

                    if session.isPaused {
                        // Show paused status
                        HStack(spacing: 6) {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(Theme.mutedRed)

                            Text("PAUSED").font(.system(size: 12, weight: .bold))
                                .foregroundColor(Theme.mutedRed)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Theme.mutedRed.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.mutedRed.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TARGET").font(.system(size: 12, weight: .medium)).tracking(1)
                                .foregroundColor(getTargetTextColor().opacity(0.8))

                            Text("\(session.targetDuration) min")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                .shadow(color: getTargetTextColor().opacity(0.5), radius: 4)
                        }
                    }
                }
            }
            .padding(.top, -5)
        }
        .padding()
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: getBackgroundColors(),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glass effect
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                // Border with different colors based on state
                RoundedRectangle(cornerRadius: 16).stroke(getCardBorderGradient(), lineWidth: 1)
            }
        )
        .shadow(color: getCardShadowColor(), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            // Start glowing animation
            isGlowing = true
            
            // Update the session timer
            sessionTimer.updateSession(session: session)
        }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name("RefreshLiveSessions"))
        ) { _ in
            // Update session timer with fresh data
            sessionTimer.updateSession(session: session)
        }
    }
    
    // Helper functions to get colors based on friend status
    private func getProfileColor() -> Color {
        return isFriend ? Theme.vibrantPurple : Theme.blue
    }
    
    private func getProfileShadowColor() -> Color {
        return isFriend ? Theme.vibrantPurple.opacity(0.5) : Theme.blue.opacity(0.5)
    }
    
    private func getLiveIndicatorColor() -> Color {
        return isFriend ? Color.green : Theme.blue
    }
    
    private func getLiveTextColor() -> Color {
        return isFriend ? Color.green : Theme.blue
    }
    
    private func getUsernameShadowColor() -> Color {
        return isFriend ? Theme.lightTealBlue.opacity(0.5) : Theme.blue.opacity(0.5)
    }
    
    private func getInfoIconColor() -> Color {
        return isFriend ? Theme.yellow : Theme.blue
    }
    
    private func getJoinButtonColor() -> Color {
        return isFriend ? Color.green : Theme.blue
    }
    
    private func getTimeTextColor() -> Color {
        return isFriend ? Theme.lightTealBlue : Theme.blue
    }
    
    private func getTargetTextColor() -> Color {
        return isFriend ? Theme.yellow : Theme.blue
    }
    
    private func getBackgroundColors() -> [Color] {
        if isFriend {
            return [Theme.forestGreen.opacity(0.3), Theme.darkBlue.opacity(0.2)]
        } else {
            return [Theme.darkBlue.opacity(0.3), Theme.blue800.opacity(0.2)]
        }
    }
    
    private func getCardBorderGradient() -> LinearGradient {
        if isFriend {
            return LinearGradient(
                colors: [Color.green.opacity(isGlowing ? 0.8 : 0.5), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Theme.blue.opacity(isGlowing ? 0.8 : 0.5), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func getCardShadowColor() -> Color {
        return isFriend ? Color.green.opacity(0.3) : Theme.blue.opacity(0.3)
    }
} 