import Foundation
import SwiftUI

struct FriendCard: View {
    let friend: FirebaseManager.FlipUser
    @State private var isPressed = false
    @State private var isJoinPressed = false
    @State private var isGlowing = false
    
    // LiveSessionData if the friend is in an active session
    let liveSession: LiveSessionManager.LiveSessionData?
    let onJoinSession: (() -> Void)?
    
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // LEFT SIDE: User info or Live indicator
                if isLive {
                    // When Live: Show elapsed time and target
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isFull ? Color.gray : Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
                                .onAppear {
                                    isGlowing = true
                                }
                            
                            Text("LIVE")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(isFull ? .gray : .green)
                                .shadow(color: Color.green.opacity(0.6), radius: isGlowing ? 4 : 2)
                        }
                        
                        Text(friend.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    }
                } else {
                    // Normal state: Show user info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(friend.username)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

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

                Spacer()

                // RIGHT SIDE: Join button or stats
                if isLive {
                    // Show join button or full indicator
                    if canJoin {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isJoinPressed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isJoinPressed = false
                                onJoinSession?()
                            }
                        }) {
                            Text("JOIN LIVE")
                                .font(.system(size: 16, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.green.opacity(0.4))
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.green.opacity(0.8), lineWidth: 1.5)
                                    }
                                )
                                .scaleEffect(isJoinPressed ? 0.95 : 1.0)
                                .shadow(color: Color.green.opacity(0.5), radius: 6)
                        }
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
                            
                            Text(session.elapsedTimeString)
                                .font(.system(size: 16, weight: .bold))
                                .monospacedDigit()
                                .foregroundColor(.white)
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
        .onTapGesture {
            if !isLive {
                withAnimation {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
        }
    }
}