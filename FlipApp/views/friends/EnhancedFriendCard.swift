import FirebaseAuth
import SwiftUI

struct EnhancedFriendCard: View {
    let friend: FirebaseManager.FlipUser?
    let liveSession: LiveSessionManager.LiveSessionData
    @State private var isPressed = false
    @State private var isGlowing = false
    @State private var timer: Timer? = nil
    @StateObject private var sessionTimer = LiveSessionTimer()
    @State private var streakStatus: StreakStatus = .none
    @State private var showBlockAlert = false
    @StateObject private var friendManager = FriendManager()

    // Computed properties for live sessions
    private var isLive: Bool { return true }
    private var isFull: Bool { return liveSession.isFull }
    private var canJoin: Bool {
        // If there's a live session and it has proper values, check if joinable
        // Make sure remaining seconds is actually populated (could be 0 if not set)
        // We need at least 1 minute to join, not 3 minutes (more permissive)
        return !liveSession.isFull && liveSession.remainingSeconds > 60
    }
    private var isFriend: Bool { return friend != nil }
    private var username: String {
        return friend?.username ?? liveSession.starterUsername
    }
    private var userId: String {
        return friend?.id ?? liveSession.starterId
    }
    private var profileImageURL: String? {
        return friend?.profileImageURL
    }

    // Computed real-time elapsed time string
    private var formattedElapsedTime: String {
        // Use sessionTimer.currentTick to force update
        let _ = sessionTimer.currentTick

        // Calculate elapsed time including drift compensation
        let baseElapsed = liveSession.elapsedSeconds
        let timeSinceUpdate = Int(
            Date().timeIntervalSince1970 - liveSession.lastUpdateTime.timeIntervalSince1970
        )
        let adjustment = liveSession.isPaused ? 0 : min(timeSinceUpdate, 60)  // Limit adjustment to avoid huge jumps

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
                    if let friend = friend {
                        ProfilePictureWithStreak(
                            imageURL: friend.profileImageURL,
                            username: friend.username,
                            size: 56,
                            streakStatus: streakStatus
                        )
                        .shadow(
                            color: getProfileShadowColor(),
                            radius: 8
                        )
                        .contextMenu {
                            Button(action: { showBlockAlert = true }) {
                                Label("Block User", systemImage: "exclamationmark.shield")
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
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
                        .onAppear { isGlowing = true }
                }

                // User info section - Enhanced styling
                VStack(alignment: .leading, spacing: 5) {
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

                    // Username with enhanced styling
                    Text(username).font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: getUsernameShadowColor(), radius: 6)

                    // Show brief session info for live sessions
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill").font(.system(size: 12))
                            .foregroundColor(getInfoIconColor())

                        Text("Target: \(liveSession.targetDuration)min")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.leading, 10)

                Spacer()

                // RIGHT SIDE: Join button or stats with enhanced styling
                if canJoin {
                    Button(action: {
                        // Show simple join confirmation alert
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        // Prevent joining your own session
                        if liveSession.starterId == Auth.auth().currentUser?.uid
                        {
                            print("Cannot join your own session")
                            let errorGenerator = UINotificationFeedbackGenerator()
                            errorGenerator.notificationOccurred(.error)
                            return
                        }
                        // If first-time user, check if they've completed their first session
                        FirebaseManager.shared.hasCompletedFirstSession { hasCompleted in
                            if !hasCompleted && isFriend {
                                // Show first session required alert
                                SessionJoinCoordinator.shared.showFirstSessionRequiredAlert =
                                    true
                                return
                            }
                            DispatchQueue.main.async {
                                // If all validation passes, prepare to join session
                                SessionJoinCoordinator.shared.pendingSessionId = liveSession.id
                                SessionJoinCoordinator.shared.pendingSessionName =
                                    liveSession.starterUsername
                                SessionJoinCoordinator.shared.pendingTimestamp = Date()
                                SessionJoinCoordinator.shared.shouldJoinSession = true
                                // Post notification to show confirmation dialog
                                NotificationCenter.default.post(
                                    name: Notification.Name(
                                        "ShowLiveSessionJoinConfirmation"
                                    ),
                                    object: nil
                                )
                            }
                        }
                    }) {
                        Text("JOIN").font(.system(size: 14, weight: .bold)).tracking(1)
                            .foregroundColor(.white).padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(getJoinButtonColor().opacity(0.3))
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(getJoinButtonColor().opacity(0.6), lineWidth: 1)
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                else {
                    // Show FULL indicator when session can't be joined
                    Text(isFull ? "FULL" : "< 1 MIN LEFT")
                        .font(.system(size: 14, weight: .bold)).tracking(1)
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

            // Session timing information - only shown for live sessions
            VStack(spacing: 8) {
                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 10)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TIME").font(.system(size: 12, weight: .medium)).tracking(1)
                            .foregroundColor(getInfoIconColor().opacity(0.8))

                        // Use our real-time updated timer here
                        Text(formattedElapsedTime).font(.system(size: 18, weight: .bold))
                            .monospacedDigit().foregroundColor(.white)
                            .id(sessionTimer.currentTick)  // Force refresh when counter changes
                            .shadow(color: getTimeTextColor().opacity(0.5), radius: 4)
                    }

                    Spacer()

                    if liveSession.isPaused {
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

                            Text("\(liveSession.targetDuration) min")
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
                // Base background with different colors for live vs normal
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isFriend && !isFull
                                ? [Theme.forestGreen.opacity(0.3), Theme.darkBlue.opacity(0.2)]
                                : !isFriend && !isFull
                                    ? [Theme.darkBlue.opacity(0.3), Theme.blue800.opacity(0.2)]
                                    : [Theme.darkBlue.opacity(0.2), Theme.deepPurple.opacity(0.2)],
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
        .onLongPressGesture {
            if isFriend {
                // Tactile feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                // Show block alert
                showBlockAlert = true
            }
        }
        .alert("Block \(friend?.username ?? "User")", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                friendManager.blockUser(userId: userId) { success in
                    if success {
                        // Optionally show a success message or handle UI updates
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
        } message: {
            Text(
                "Are you sure you want to block \(friend?.username ?? "this user")? This will remove them from your friends list and prevent them from interacting with you."
            )
        }
        .onAppear {
            // Update the session timer with this card's session data
            sessionTimer.updateSession(session: liveSession)

            // Load streak status from Firestore
            loadStreakStatus()

            isGlowing = true // Ensure glow starts
        }
        .onDisappear { stopTimer() }
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name("RefreshLiveSessions"))
        ) { _ in
            // Update session timer with fresh data
            sessionTimer.updateSession(session: liveSession)

            // Force UI update
            //self.objectWillChange.send()
        }
    }

    // Helper to load streak status for the friend
    private func loadStreakStatus() {
        // Ensure friend exists before loading streak
        guard let friendId = friend?.id else { return }
        FirebaseManager.shared.db.collection("users").document(friendId).collection("streak")
            .document("current")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let statusString = data["streakStatus"] as? String,
                    let status = StreakStatus(rawValue: statusString)
                {
                    DispatchQueue.main.async { self.streakStatus = status }
                } else {
                    // Default to none if no streak data
                    DispatchQueue.main.async { self.streakStatus = .none }
                }
            }
    }

    // Helper to get dynamic card border gradient based on state
    private func getCardBorderGradient() -> LinearGradient {
        if isFriend && !isFull {
            // Friend Live border
            return LinearGradient(
                colors: [Color.green.opacity(isGlowing ? 0.8 : 0.5), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if !isFriend && !isFull {
            // Non-Friend Live border
            return LinearGradient(
                colors: [Theme.blue.opacity(isGlowing ? 0.8 : 0.5), Color.white.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        else {
            // Default border (Full session or error)
            return Theme.silveryGradient2
        }
    }

    // Helper to get dynamic card shadow color based on state
    private func getCardShadowColor() -> Color {
        if isFriend && !isFull {
            return Color.green.opacity(0.3)
        } else if !isFriend && !isFull {
            return Theme.blue.opacity(0.3)
        }
        else {
            // Consistent shadow for Full sessions
            return Color.black.opacity(0.2)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Dynamic color helpers based on isFriend
    private func getProfileColor() -> Color { return isFriend ? Theme.vibrantPurple : Theme.blue }
    private func getProfileShadowColor() -> Color {
        return isFriend ? Theme.vibrantPurple.opacity(0.5) : Theme.blue.opacity(0.5)
    }
    private func getLiveIndicatorColor() -> Color { return isFriend ? Color.green : Theme.blue }
    private func getLiveTextColor() -> Color { return isFriend ? Color.green : Theme.blue }
    private func getUsernameShadowColor() -> Color {
        return isFriend ? Theme.lightTealBlue.opacity(0.5) : Theme.blue.opacity(0.5)
    }
    private func getInfoIconColor() -> Color { return isFriend ? Theme.yellow : Theme.blue }
    private func getJoinButtonColor() -> Color { return isFriend ? Color.green : Theme.blue }
    private func getTimeTextColor() -> Color { return isFriend ? Theme.lightTealBlue : Theme.blue }
    private func getTargetTextColor() -> Color { return isFriend ? Theme.yellow : Theme.blue }
}
