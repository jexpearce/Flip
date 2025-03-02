import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore

struct FriendCard: View {
    let friend: FirebaseManager.FlipUser
    @State private var isPressed = false
    @State private var isGlowing = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    
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
        return liveSession?.canJoin ?? false
    }
    
    // Computed real-time elapsed time string
    private var formattedElapsedTime: String {
        guard let session = liveSession else { return "0:00" }
        
        let totalElapsed = session.elapsedSeconds + (session.isPaused ? 0 : elapsedSeconds)
        let minutes = totalElapsed / 60
        let seconds = totalElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // LEFT SIDE: Profile picture with Live indicator if active
                ZStack(alignment: .topTrailing) {
                    ProfileAvatarView(
                        imageURL: friend.profileImageURL,
                        size: 50,
                        username: friend.username
                    )
                    
                    // Live indicator badge
                    if isLive {
                        Circle()
                            .fill(isFull ? Color.gray : Color.green)
                            .frame(width: 12, height: 12)
                            .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
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
                
                // User info section
                VStack(alignment: .leading, spacing: 5) {
                    if isLive {
                        // When Live: LIVE text
                        HStack(spacing: 4) {
                            Text("LIVE")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(isFull ? .gray : .green)
                                .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                        }
                    }
                    
                    // Always show username
                    Text(friend.username)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    
                    // Show session count in normal state
                    if !isLive {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(friend.totalSessions) sessions")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.leading, 8)

                Spacer()

                // RIGHT SIDE: Join button or stats
                if isLive {
                    // Show join button or full indicator
                    if canJoin {
                        // We'll render this from the parent view
                        Spacer().frame(width: 90, height: 36)
                    } else if isFull {
                        Text("LIVE (FULL)")
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
                    // Normal state: Show focus time
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(friend.totalFocusTime) min")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                        HStack(spacing: 6) {
                            Text("total focus time")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            
            // Session timing information - only shown for live sessions
            if isLive, let session = liveSession {
                VStack(spacing: 4) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 10)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TIME")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // Use our real-time updated timer here instead of the static value
                            Text(formattedElapsedTime)
                                .font(.system(size: 16, weight: .bold))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .id(elapsedSeconds) // Force refresh when counter changes
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TARGET")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(session.targetDuration) min")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, -5)
            }
        }
        .padding()
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 15)
                            .fill(isLive && !isFull ?
                                  AnyShapeStyle(LinearGradient(
                                    colors: [
                                        Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.2),
                                        Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )) :
                                  AnyShapeStyle(Theme.buttonGradient.opacity(0.1))
                            )
                // Glass effect
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                // Border
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isLive && !isFull ?
                        LinearGradient(
                            colors: [
                                Color.green.opacity(isGlowing ? 0.8 : 0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: isLive && !isFull ? Color.green.opacity(0.3) : Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
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