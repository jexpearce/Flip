import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore




struct EnhancedFriendCard: View {
    let friend: FirebaseManager.FlipUser
    @State private var isPressed = false
    @State private var isGlowing = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    @StateObject private var sessionTimer = LiveSessionTimer()
    @State private var streakStatus: StreakStatus = .none
    
    // LiveSessionData if the friend is in an active session
    let liveSession: LiveSessionManager.LiveSessionData?
    
    // Computed properties for live sessions
    private var isLive: Bool {
        return liveSession != nil
    }
    
    private var isFull: Bool {
        return liveSession?.isFull ?? false
    }
    
    private var canJoin: Bool {
        return false // Disabled joining by setting canJoin to always return false
        // Original code: return liveSession?.canJoin ?? false
    }
    
    // Computed real-time elapsed time string
    private var formattedElapsedTime: String {
        guard let session = liveSession else { return "0:00" }
        
        // Use sessionTimer.currentTick to force update
        let _ = sessionTimer.currentTick
        
        // Calculate elapsed time including drift compensation
        let baseElapsed = session.elapsedSeconds
        let timeSinceUpdate = Int(Date().timeIntervalSince1970 - session.lastUpdateTime.timeIntervalSince1970)
        let adjustment = session.isPaused ? 0 : min(timeSinceUpdate, 60) // Limit adjustment to avoid huge jumps
        
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
                    // NEW: Profile picture with streak status
                    ProfilePictureWithStreak(
                        imageURL: friend.profileImageURL,
                        username: friend.username,
                        size: 56,
                        streakStatus: streakStatus
                    )
                    .shadow(color: isLive ? Color.green.opacity(0.6) : Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 8)
                    
                    // Live indicator badge with animation
                    if isLive {
                        Circle()
                            .fill(isFull ? Color.gray : Color.green)
                            .frame(width: 14, height: 14)
                            .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                            .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isGlowing)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .offset(x: 2, y: -2)
                            .onAppear {
                                isGlowing = true
                            }
                    }
                }
                
                // User info section - Enhanced styling
                VStack(alignment: .leading, spacing: 5) {
                    if isLive {
                        // When Live: LIVE text with pulse animation
                        HStack(spacing: 6) {
                            Text("LIVE")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(isFull ? .gray : .green)
                                .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                                .scaleEffect(isGlowing ? 1.05 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
                            
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .opacity(isGlowing ? 0.8 : 0.4)
                                .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isGlowing)
                        }
                    } else if streakStatus != .none {
                        // NEW: Show streak status when not live
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                                .shadow(color: streakStatus == .redFlame ? Color.red.opacity(0.6) : Color.orange.opacity(0.6),
                                       radius: isGlowing ? 4 : 2)
                                .scaleEffect(isGlowing ? 1.05 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
                            
                            Text(streakStatus == .redFlame ? "BLAZING" : "ON FIRE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                                .shadow(color: streakStatus == .redFlame ? Color.red.opacity(0.4) : Color.orange.opacity(0.4),
                                        radius: 2)
                        }
                    }
                    
                    // Username with enhanced styling
                    Text(friend.username)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    
                    // Show session count in normal state or live session info
                    if !isLive {
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 168/255, green: 85/255, blue: 247/255))
                            
                            Text("\(friend.totalSessions) sessions")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        // Show brief session info for live sessions
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                            
                            Text("Target: \(liveSession?.targetDuration ?? 0)min")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.leading, 10)

                Spacer()

                // RIGHT SIDE: Join button or stats with enhanced styling
                if isLive {
                    // Show join button or full indicator
                    if canJoin {
                        // We'll render this from the parent view - but this will be unreachable now
                        Spacer().frame(width: 90, height: 36)
                    } else {
                        // Modified to always show disabled state instead of FULL
                        Text("DISABLED")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                }
                            )
                    }
                } else {
                    // Normal state: Show focus time with enhanced styling
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(friend.totalFocusTime) min")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.5), radius: 6)

                        HStack(spacing: 6) {
                            Text("focus time")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.8))
                            
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.8))
                        }
                    }
                }
            }
            
            // Session timing information - only shown for live sessions
            if isLive, let session = liveSession {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 10)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TIME")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(1)
                                .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.8))
                            
                            // Use our real-time updated timer here
                            Text(formattedElapsedTime)
                                .font(.system(size: 18, weight: .bold))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .id(sessionTimer.currentTick) // Force refresh when counter changes
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 4)
                        }
                        
                        Spacer()
                        
                        if session.isPaused {
                            // Show paused status
                            HStack(spacing: 6) {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255))
                                
                                Text("PAUSED")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        } else {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("TARGET")
                                    .font(.system(size: 12, weight: .medium))
                                    .tracking(1)
                                    .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.8))
                                
                                Text("\(session.targetDuration) min")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.5), radius: 4)
                            }
                        }
                    }
                }
                .padding(.top, -5)
            }
        }
        .padding()
        .background(
            ZStack {
                // Base background with different colors for live vs normal
                RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isLive && !isFull ? [
                                        Color(red: 21/255, green: 128/255, blue: 61/255).opacity(0.3),
                                        Color(red: 30/255, green: 58/255, blue: 138/255).opacity(0.2)
                                    ] : [
                                        Color(red: 30/255, green: 58/255, blue: 138/255).opacity(0.2),
                                        Color(red: 88/255, green: 28/255, blue: 135/255).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                
                // Glass effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                // Border with different colors based on state
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        getCardBorderGradient(),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: getCardShadowColor(), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            // Update the session timer with this card's session data
            if let session = liveSession {
                sessionTimer.updateSession(session: session)
            }
            
            // NEW: Load streak status from Firestore
            loadStreakStatus()
        }
        .onDisappear {
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshLiveSessions"))) { _ in
            // Update session timer with fresh data
            if let session = liveSession {
                sessionTimer.updateSession(session: session)
            }
            
            // Force UI update
            //self.objectWillChange.send()
        }
    }
    
    // NEW: Helper to load streak status for the friend
    private func loadStreakStatus() {
        FirebaseManager.shared.db.collection("users").document(friend.id)
            .collection("streak").document("current")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let statusString = data["streakStatus"] as? String,
                   let status = StreakStatus(rawValue: statusString) {
                    
                    DispatchQueue.main.async {
                        self.streakStatus = status
                    }
                }
            }
    }
    
    
    // NEW: Helper to get dynamic card border gradient based on state
    private func getCardBorderGradient() -> LinearGradient {
        if isLive && !isFull {
            // Live session border
            return LinearGradient(
                colors: [
                    Color.green.opacity(isGlowing ? 0.8 : 0.5),
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if streakStatus == .redFlame {
            // Red flame streak border
            return LinearGradient(
                colors: [
                    Color.red.opacity(isGlowing ? 0.7 : 0.5),
                    Color.red.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if streakStatus == .orangeFlame {
            // Orange flame streak border
            return LinearGradient(
                colors: [
                    Color.orange.opacity(isGlowing ? 0.7 : 0.5),
                    Color.orange.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Default border
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.5),
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // NEW: Helper to get dynamic card shadow color based on state
    private func getCardShadowColor() -> Color {
        if isLive && !isFull {
            return Color.green.opacity(0.3)
        } else if streakStatus == .redFlame {
            return Color.red.opacity(0.3)
        } else if streakStatus == .orangeFlame {
            return Color.orange.opacity(0.3)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    // Start timer to update the elapsed time every second
    private func startTimer() {
        // Only start the timer if this is a live session and not paused
        guard isLive, let session = liveSession, !session.isPaused else { return }
        
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