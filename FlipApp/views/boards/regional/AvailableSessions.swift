import SwiftUI
import FirebaseAuth

struct AvailableSessionsView: View {
    let buildingSessions: [LiveSessionManager.LiveSessionData]
    @Environment(\.presentationMode) var presentationMode
    @State private var showJoinConfirmation = false
    @State private var selectedSession: LiveSessionManager.LiveSessionData? = nil
    @State private var pulsingEffect = false
    @State private var friendFiltered = false
    
    // Helper computed properties
    private var friendSessions: [LiveSessionManager.LiveSessionData] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        return buildingSessions.filter { session in
            // Check if this session has the current user as a friend
            let isFriend = FirebaseManager.shared.currentUser?.friends.contains(session.starterId) ?? false
            return isFriend && session.starterId != currentUserId
        }
    }
    
    private var otherSessions: [LiveSessionManager.LiveSessionData] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        
        return buildingSessions.filter { session in
            // Check if this session starter is not a friend and not the current user
            let isFriend = FirebaseManager.shared.currentUser?.friends.contains(session.starterId) ?? false
            return !isFriend && session.starterId != currentUserId
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle animations
                Theme.regionalGradient.edgesIgnoringSafeArea(.all)
                
                // Decorative background elements
                ZStack {
                    // Pulsing circle
                    Circle()
                        .fill(RadialGradient(
                            colors: [Theme.lightTealBlue.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        ))
                        .frame(width: 500, height: 500)
                        .offset(x: 150, y: -250)
                        .scaleEffect(pulsingEffect ? 1.1 : 1.0)
                        .blur(radius: 40)
                        .animation(
                            Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
                            value: pulsingEffect
                        )
                    
                    // Bottom glow
                    Circle()
                        .fill(RadialGradient(
                            colors: [Theme.lightTealBlue.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        ))
                        .frame(width: 400, height: 400)
                        .offset(x: -150, y: 300)
                        .blur(radius: 40)
                }
                
                // Main content
                VStack(spacing: 0) {
                    // Header with filter
                    HStack {
                        Button(action: {
                            withAnimation {
                                friendFiltered.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(friendFiltered ? "Showing Friends" : "All Sessions")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(friendFiltered ? Theme.lightTealBlue : .white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(friendFiltered ? Theme.lightTealBlue : .white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                friendFiltered ? Theme.lightTealBlue.opacity(0.5) : Color.white.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Title with count
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AVAILABLE SESSIONS")
                                .font(.system(size: 22, weight: .black))
                                .tracking(2)
                                .foregroundColor(.white)
                            
                            Text("Join a live session in this building")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Only show count badge if we have sessions
                        if (friendFiltered ? friendSessions.count : (friendSessions.count + otherSessions.count)) > 0 {
                            Text("\(friendFiltered ? friendSessions.count : (friendSessions.count + otherSessions.count))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Theme.lightTealBlue.opacity(0.3))
                                        .overlay(
                                            Circle()
                                                .stroke(Theme.lightTealBlue.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Session lists
                    ScrollView {
                        VStack(spacing: 25) {
                            // Friend sessions section
                            if !friendSessions.isEmpty {
                                sessionSection(
                                    title: "FRIEND SESSIONS",
                                    iconName: "person.2.fill",
                                    iconColor: Color.green,
                                    sessions: friendSessions,
                                    isFriendSection: true
                                )
                            }
                            
                            // Other sessions section (only show if not filtered)
                            if !otherSessions.isEmpty && !friendFiltered {
                                sessionSection(
                                    title: "OTHER PEOPLE NEARBY",
                                    iconName: "building.2.fill",
                                    iconColor: Theme.lightTealBlue,
                                    sessions: otherSessions,
                                    isFriendSection: false
                                )
                            }
                            
                            // Empty state
                            if (friendFiltered ? friendSessions.isEmpty : (friendSessions.isEmpty && otherSessions.isEmpty)) {
                                VStack(spacing: 15) {
                                    Image(systemName: "person.3.sequence.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.5))
                                        .padding(.bottom, 10)
                                    
                                    Text(friendFiltered ? "No Friend Sessions Available" : "No Sessions Available")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(friendFiltered ?
                                         "None of your friends are currently in a session that can be joined" :
                                         "There are no sessions available to join at this time")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 30)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Start background animations
                withAnimation {
                    pulsingEffect = true
                }
            }
        }
        .fullScreenCover(item: $selectedSession) { session in
            // Use our custom JoinSessionPopup when a session is selected
            JoinSessionPopup(
                sessionId: session.id,
                starterUsername: session.starterUsername,
                isPresented: Binding(
                    get: { self.selectedSession != nil },
                    set: { if !$0 { self.selectedSession = nil } }
                )
            )
            .environmentObject(AppManager.shared)
        }
    }
    
    // Helper function to create a session section
    private func sessionSection(title: String, iconName: String, iconColor: Color, sessions: [LiveSessionManager.LiveSessionData], isFriendSection: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(iconColor)
                
                Spacer()
                
                Text("\(sessions.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            // Session cards in horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(sessions) { session in
                        EnhancedSessionCard(
                            session: session,
                            isFriend: isFriendSection,
                            onJoin: {
                                // Show the join popup
                                selectedSession = session
                            }
                        )
                        .frame(width: min(UIScreen.main.bounds.width * 0.8, 280))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }
}

// Enhanced session card with better visual design
struct EnhancedSessionCard: View {
    let session: LiveSessionManager.LiveSessionData
    let isFriend: Bool
    let onJoin: () -> Void
    
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
        let adjustment = session.isPaused ? 0 : min(timeSinceUpdate, 60) // Limit adjustment
        
        let totalElapsed = baseElapsed + adjustment
        let minutes = totalElapsed / 60
        let seconds = totalElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Button(action: {
            if canJoin {
                withAnimation(.spring()) {
                    isPressed = true
                }
                
                // Add a small delay for the button press animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onJoin()
                }
            }
        }) {
            VStack(spacing: 0) {
                // Session header
                HStack(spacing: 12) {
                    // User avatar with live indicator
                    ZStack(alignment: .topTrailing) {
                        // Avatar circle
                        ZStack {
                            Circle()
                                .fill(getGradient())
                                .frame(width: 48, height: 48)
                            
                            Circle()
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 48, height: 48)
                            
                            // User icon
                            Image(systemName: isFriend ? "person.fill.checkmark" : "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        
                        // Live indicator
                        ZStack {
                            Circle()
                                .fill(canJoin ? Color.green : Color.gray)
                                .frame(width: 14, height: 14)
                                .shadow(color: canJoin ? Color.green.opacity(0.6) : Color.gray.opacity(0.4),
                                        radius: isGlowing ? 4 : 2)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true),
                                    value: isGlowing
                                )
                            
                            Circle()
                                .strokeBorder(Color.black.opacity(0.3), lineWidth: 1)
                                .frame(width: 14, height: 14)
                        }
                        .offset(x: 2, y: -2)
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.starterUsername)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text("LIVE")
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(canJoin ? Color.green : Color.gray.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(canJoin ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(canJoin ? Color.green.opacity(0.3) : Color.gray.opacity(0.3),
                                                             lineWidth: 1)
                                        )
                                )
                            
                            Text("\(session.targetDuration)min")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Divider
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.1), .white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                
                // Session details
                HStack(spacing: 8) {
                    // Elapsed time
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ELAPSED")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formattedElapsedTime)
                            .font(.system(size: 18, weight: .bold))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .id(sessionTimer.currentTick) // Force refresh
                    }
                    
                    Spacer()
                    
                    // Participant count
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("PARTICIPANTS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 4) {
                            Text("\(session.participants.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(session.isFull ? "(FULL)" : "")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Join button section
                HStack {
                    Spacer()
                    
                    // Join button or status
                    Group {
                        if canJoin {
                            HStack(spacing: 8) {
                                Text("JOIN SESSION")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isFriend ?
                                          LinearGradient(
                                            colors: [Color.green.opacity(0.7), Theme.lightTealBlue.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          ) :
                                          LinearGradient(
                                            colors: [Theme.lightTealBlue.opacity(0.7), Theme.purple.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .shadow(color: isFriend ? Color.green.opacity(0.3) : Theme.lightTealBlue.opacity(0.3), radius: 4)
                        } else {
                            Text(isFull ? "SESSION FULL" : "UNAVAILABLE")
                                .font(.system(size: 14, weight: .medium))
                                .tracking(1)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .background(
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: getBackgroundColors(),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                    
                    // Border with gradient
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            getCardBorderGradient(),
                            lineWidth: 1.2
                        )
                }
            )
            .shadow(color: getCardShadowColor(), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            // Start animations
            isGlowing = true
            
            // Update the session timer
            sessionTimer.updateSession(session: session)
        }
    }
    
    // Helper functions to get colors based on friend status
    private func getGradient() -> LinearGradient {
        if isFriend {
            return LinearGradient(
                colors: [Color.green.opacity(0.7), Theme.forestGreen.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Theme.lightTealBlue.opacity(0.7), Theme.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func getBackgroundColors() -> [Color] {
        if isFriend {
            return [
                Theme.forestGreen.opacity(0.4),
                Theme.darkBlue.opacity(0.3),
                Theme.deepMidnightPurple.opacity(0.3)
            ]
        } else {
            return [
                Theme.darkBlue.opacity(0.4),
                Theme.deepMidnightPurple.opacity(0.3),
                Theme.mutedPink.opacity(0.15)
            ]
        }
    }
    
    private func getCardBorderGradient() -> LinearGradient {
        if isFriend {
            return LinearGradient(
                colors: [
                    Color.green.opacity(isGlowing ? 0.7 : 0.4),
                    Color.white.opacity(0.3),
                    Color.green.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Theme.lightTealBlue.opacity(isGlowing ? 0.7 : 0.4),
                    Color.white.opacity(0.3),
                    Theme.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func getCardShadowColor() -> Color {
        return isFriend ?
            Color.green.opacity(0.2) :
            Theme.lightTealBlue.opacity(0.2)
    }
}