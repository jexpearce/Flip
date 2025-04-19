import FirebaseAuth
import SwiftUI
import FirebaseFirestore

struct JoinSessionPopup: View {
    let sessionId: String
    let starterUsername: String
    @Binding var isPresented: Bool
    @State private var participants: [ParticipantInfo] = []
    @State private var isLoading = true
    @State private var isJoining = false
    @State private var showParticipants = false
    @State private var targetDuration: Int = 0
    // Environment objects
    @EnvironmentObject var appManager: AppManager
    // Animation states
    @State private var isGlowing = false
    @State private var showPulse = false
    @State private var pulseOpacity = 0.0
    @State private var buttonScale = 1.0
    @State private var animateGradient = false
    @State private var allowsPauses: Bool = false
    @State private var pauseCount: Int = 0
    @State private var pauseDuration: Int = 0
    struct ParticipantInfo: Identifiable {
        let id: String
        let username: String
    }
    var body: some View {
        ZStack {
            // Semi-transparent background overlay with blur effect
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all).blur(radius: 0.5)
                .onTapGesture {
                    // Optional: dismiss on background tap
                    // withAnimation { isPresented = false }
                }
            // Main popup container
            VStack(spacing: 0) {
                // Decorative pulse effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.lightTealBlue.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200).scaleEffect(showPulse ? 1.2 : 0.8)
                        .opacity(pulseOpacity)
                        .animation(
                            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: showPulse
                        )
                        .onAppear {
                            pulseOpacity = 0.6
                            showPulse = true
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: 0).offset(y: -80).zIndex(1)
                // Top section with glowing live indicator
                VStack(spacing: 15) {
                    // LIVE badge with glow
                    HStack(spacing: 8) {
                        Circle().fill(Color.green).frame(width: 12, height: 12)
                            .shadow(
                                color: Color.green.opacity(isGlowing ? 0.8 : 0.4),
                                radius: isGlowing ? 8 : 4
                            )
                            .animation(
                                Animation.easeInOut(duration: 1.2)
                                    .repeatForever(autoreverses: true),
                                value: isGlowing
                            )
                        Text("LIVE SESSION").font(.system(size: 14, weight: .black)).tracking(2)
                            .foregroundColor(Color.green)
                    }
                    .padding(.vertical, 6).padding(.horizontal, 12)
                    .background(
                        Capsule().fill(Color.black.opacity(0.3))
                            .overlay(
                                Capsule().strokeBorder(Color.green.opacity(0.6), lineWidth: 1.5)
                            )
                    )
                    // Host name with large, prominent display
                    Text(starterUsername).font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white).multilineTextAlignment(.center)
                        .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 10)
                    // Session info
                    if !isLoading {
                        Text("\(targetDuration) min focus session")
                            .font(.system(size: 18, weight: .medium)).foregroundColor(Theme.yellow)
                            .padding(.top, 5)
                        VStack(spacing: 4) {
                            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 6)
                            if allowsPauses {
                                HStack(spacing: 6) {
                                    Image(systemName: "pause.circle.fill").font(.system(size: 14))
                                        .foregroundColor(Color.white.opacity(0.9))
                                    if pauseCount > 10 {
                                        Text("Unlimited pauses, \(pauseDuration)min each")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.white.opacity(0.9))
                                    }
                                    else {
                                        Text(
                                            "\(pauseCount) pauses allowed, \(pauseDuration)min each"
                                        )
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.white.opacity(0.9))
                                    }
                                }
                            }
                            else {
                                HStack(spacing: 6) {
                                    Image(systemName: "pause.slash").font(.system(size: 14))
                                        .foregroundColor(Color.white.opacity(0.9))
                                    Text("No pauses allowed").font(.system(size: 14))
                                        .foregroundColor(Color.white.opacity(0.9))
                                }
                            }
                        }
                    }
                }
                .padding(.top, 30).padding(.bottom, 20)
                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1), .white.opacity(0.3), .white.opacity(0.1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1).padding(.horizontal, 30)
                // Middle section - participants
                VStack(spacing: 15) {
                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Loading session info...").font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.vertical, 30)
                    }
                    else {
                        // Participants section
                        VStack(alignment: .leading, spacing: 15) {
                            // Participants header with expand/collapse
                            Button(action: {
                                withAnimation(.spring()) { showParticipants.toggle() }
                            }) {
                                HStack {
                                    Text("PARTICIPANTS (\(participants.count))")
                                        .font(.system(size: 14, weight: .bold)).tracking(1)
                                        .foregroundColor(Theme.lightTealBlue)
                                    Spacer()
                                    Image(
                                        systemName: showParticipants ? "chevron.up" : "chevron.down"
                                    )
                                    .font(.system(size: 12)).foregroundColor(Theme.lightTealBlue)
                                }
                            }
                            .padding(.horizontal, 25)
                            if showParticipants {
                                // Participant list
                                VStack(spacing: 10) {
                                    ForEach(participants) { participant in
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Theme.lightTealBlue.opacity(0.3),
                                                                Theme.deepBlue.opacity(0.2),
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 32, height: 32)
                                                Circle()
                                                    .strokeBorder(
                                                        Color.white.opacity(0.3),
                                                        lineWidth: 1
                                                    )
                                                    .frame(width: 32, height: 32)
                                                Image(
                                                    systemName: participant.username
                                                        == starterUsername
                                                        ? "person.fill.checkmark" : "person.fill"
                                                )
                                                .font(.system(size: 14)).foregroundColor(.white)
                                            }
                                            Text(participant.username).font(.system(size: 16))
                                                .foregroundColor(.white)
                                            Spacer()
                                            // For the host, show special badge
                                            if participant.username == starterUsername {
                                                Text("HOST").font(.system(size: 10, weight: .bold))
                                                    .tracking(1).foregroundColor(.white)
                                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                                    .background(
                                                        Capsule()
                                                            .fill(Theme.lightTealBlue.opacity(0.3))
                                                            .overlay(
                                                                Capsule()
                                                                    .strokeBorder(
                                                                        Theme.lightTealBlue.opacity(
                                                                            0.5
                                                                        ),
                                                                        lineWidth: 1
                                                                    )
                                                            )
                                                    )
                                            }
                                        }
                                        .padding(.vertical, 8).padding(.horizontal, 15)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.05))
                                        )
                                    }
                                }
                                .padding(.horizontal, 25)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 15)
                        // Message about joining with kaomoji
                        VStack(spacing: 4) {
                            Text(
                                "Join \(starterUsername)'s focus session and complete it together!"
                            )
                            .font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            Text("(•̀ᴗ•́)و ✧").font(.system(size: 18)).foregroundColor(Theme.yellow)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 25).padding(.bottom, 10)
                    }
                }
                .frame(minHeight: 100)
                // Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1), .white.opacity(0.3), .white.opacity(0.1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1).padding(.horizontal, 30)
                // Bottom section - buttons
                HStack(spacing: 15) {
                    // Cancel button
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                            SessionJoinCoordinator.shared.clearPendingSession()
                        }
                    }) {
                        Text("CANCEL").font(.system(size: 16, weight: .bold)).tracking(1)
                            .foregroundColor(.white.opacity(0.8)).frame(height: 50)
                            .frame(minWidth: 120)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 15)
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                    }
                    // Join button
                    Button(action: {
                        // Set loading state
                        isJoining = true
                        
                        print("CRITICAL FIX: Using ultra-safe join process")
                        
                        // CRITICAL: Dismiss the popup BEFORE doing anything else
                        withAnimation { isPresented = false }
                        
                        // Add a delay to ensure the popup is fully dismissed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Only continue if we're still in joining state
                            guard isJoining else { return }
                            
                            // Get current user info
                            guard let userId = Auth.auth().currentUser?.uid else {
                                self.isJoining = false
                                return
                            }
                            
                            // Check if trying to join own session
                            if sessionId.contains(userId) {
                                print("Cannot join your own session")
                                self.isJoining = false
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.error)
                                return
                            }
                            
                            // CRITICAL: Use a timeout
                            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                                if self.isJoining {
                                    print("Join operation timed out")
                                    self.isJoining = false
                                }
                            }
                            
                            // CRITICAL: Simplest possible approach to get session data
                            LiveSessionManager.shared.db.collection("live_sessions").document(sessionId).getDocument { document, error in
                                // Handle errors
                                if let error = error {
                                    print("Error fetching session: \(error.localizedDescription)")
                                    self.isJoining = false
                                    return
                                }
                                
                                // Check document exists
                                guard let data = document?.data() else {
                                    print("Session document doesn't exist or is empty")
                                    self.isJoining = false
                                    return
                                }
                                
                                // Extract minimal required data
                                guard let remainingSeconds = data["remainingSeconds"] as? Int,
                                      let targetDuration = data["targetDuration"] as? Int,
                                      let starterUsername = data["starterUsername"] as? String else {
                                    print("Missing critical session data")
                                    self.isJoining = false
                                    return
                                }
                                
                                // CRITICAL: Update Firebase in background FIRST
                                let updateData: [String: Any] = [
                                    "participants": FieldValue.arrayUnion([userId]),
                                    "joinTimes.\(userId)": Timestamp(date: Date()),
                                    "participantStatus.\(userId)": "active",
                                    "lastUpdateTime": FieldValue.serverTimestamp()
                                ]
                                
                                LiveSessionManager.shared.db.collection("live_sessions").document(sessionId).updateData(updateData) { error in
                                    if let error = error {
                                        print("Error updating session: \(error.localizedDescription)")
                                    }
                                    
                                    // CRITICAL: Now safely join with reliable data on main thread
                                    DispatchQueue.main.async {
                                        // Set minimal AppManager properties
                                        AppManager.shared.shouldShowFriendRequestName = starterUsername
                                        
                                        // Reset state
                                        self.isJoining = false
                                        
                                        // CRITICAL: Significant delay before actual join
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            print("Starting actual join process with clean state")
                                            
                                            // Clear any pending session state
                                            SessionJoinCoordinator.shared.clearPendingSession()
                                            
                                            // Finally start the join
                                            AppManager.shared.joinLiveSession(
                                                sessionId: sessionId,
                                                remainingSeconds: remainingSeconds,
                                                totalDuration: targetDuration
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }){
                        ZStack {
                            // Pulsing background effect for the button
                            RoundedRectangle(cornerRadius: 15).fill(Color.green.opacity(0.3))
                                .scaleEffect(buttonScale).opacity((buttonScale - 1.0) * 0.5)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true),
                                    value: buttonScale
                                )
                            Text("JOIN NOW").font(.system(size: 16, weight: .bold)).tracking(1)
                                .foregroundColor(.white).frame(height: 50).frame(minWidth: 120)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(
                                                LinearGradient(
                                                    colors: animateGradient
                                                        ? [
                                                            Color.green.opacity(0.8),
                                                            Theme.lightTealBlue.opacity(0.6),
                                                        ]
                                                        : [
                                                            Theme.lightTealBlue.opacity(0.6),
                                                            Color.green.opacity(0.8),
                                                        ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .animation(
                                                Animation.easeInOut(duration: 3.0)
                                                    .repeatForever(autoreverses: true),
                                                value: animateGradient
                                            )
                                        RoundedRectangle(cornerRadius: 15)
                                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.green.opacity(0.5), radius: 8)
                                .opacity(isJoining ? 0 : 1)
                            if isJoining {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                    }
                    .disabled(isLoading || isJoining)
                    .onAppear {
                        // Start pulsing animation for the join button
                        withAnimation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        ) {
                            buttonScale = 1.1
                            animateGradient = true
                        }
                    }
                }
                .padding(.vertical, 25)
            }
            .frame(width: min(UIScreen.main.bounds.width - 40, 360))
            .background(
                ZStack {
                    // Enhanced dark gradient background with more depth
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.darkBlue.opacity(0.95),
                                    Theme.deepMidnightPurple.opacity(0.95),
                                    Theme.mutedPink.opacity(0.25),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    // Animated star field effect
                    ForEach(0..<15) { i in
                        Circle().fill(Color.white)
                            .frame(
                                width: CGFloat.random(in: 1...2.5),
                                height: CGFloat.random(in: 1...2.5)
                            )
                            .position(
                                x: CGFloat.random(in: 20...340),
                                y: CGFloat.random(in: 20...500)
                            )
                            .opacity(isGlowing ? 0.6 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 1.5...3.0))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...1.5)),
                                value: isGlowing
                            )
                            .blur(radius: 0.3)
                    }
                    // Subtle patterns for visual interest
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        i == 0
                                            ? Theme.lightTealBlue.opacity(0.05)
                                            : i == 1
                                                ? Color.green.opacity(0.05)
                                                : Theme.yellow.opacity(0.05), Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: CGFloat(80 + i * 40)
                                )
                            )
                            .frame(width: CGFloat(160 + i * 80), height: CGFloat(160 + i * 80))
                            .offset(x: CGFloat([-80, 80, -60][i]), y: CGFloat([100, -80, 150][i]))
                            .blur(radius: 20)
                    }
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.03))
                    // Top highlight
                    RoundedRectangle(cornerRadius: 25).trim(from: 0, to: 0.5)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .rotationEffect(.degrees(180)).padding(1)
                    // Glowing border with animation
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isGlowing ? 0.7 : 0.5),
                                    Theme.lightTealBlue.opacity(isGlowing ? 0.5 : 0.3),
                                    Color.white.opacity(isGlowing ? 0.2 : 0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
        }
        .onAppear {
            // Start animations
            isGlowing = true
            // Load session participants
            loadSessionDetails()
        }
    }
    private func loadSessionDetails() {
        isLoading = true
        LiveSessionManager.shared.getSessionDetails(sessionId: sessionId) { sessionData in
            if let session = sessionData {
                // Get participants
                var participantList: [ParticipantInfo] = []
                // Keep track of processed usernames to avoid duplicates
                var processedUserIds = Set<String>()
                // First add the session starter
                participantList.append(
                    ParticipantInfo(id: session.starterId, username: session.starterUsername)
                )
                processedUserIds.insert(session.starterId)
                // Batch load other participants
                let group = DispatchGroup()
                for participantId in session.participants {
                    // Skip if already processed (like the starter)
                    if processedUserIds.contains(participantId) { continue }
                    group.enter()
                    FirebaseManager.shared.db.collection("users").document(participantId)
                        .getDocument { document, error in
                            defer { group.leave() }
                            if let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                            {
                                let participantInfo = ParticipantInfo(
                                    id: participantId,
                                    username: userData.username
                                )
                                participantList.append(participantInfo)
                            }
                        }
                }
                // When all participants are loaded
                group.notify(queue: .main) {
                    // Sort with host first, then alphabetically
                    self.participants = participantList.sorted { p1, p2 in
                        if p1.id == session.starterId { return true }
                        if p2.id == session.starterId { return false }
                        return p1.username < p2.username
                    }
                    // Store session duration and pause settings
                    self.targetDuration = session.targetDuration
                    // Store pause settings
                    self.allowsPauses = session.allowPauses
                    self.pauseCount = session.maxPauses
                    // Additional Firebase query to get pause duration
                    if session.allowPauses {
                        LiveSessionManager.shared.db.collection("live_sessions").document(sessionId)
                            .getDocument { document, error in
                                if let data = document?.data(),
                                    let pauseDuration = data["pauseDuration"] as? Int
                                {
                                    self.pauseDuration = pauseDuration
                                }
                                else {
                                    // Default pause duration if not found
                                    self.pauseDuration = 5
                                }
                                self.isLoading = false
                            }
                    }
                    else {
                        self.isLoading = false
                    }
                    // Show participants section if there are multiple participants
                    if participantList.count > 1 { self.showParticipants = true }
                }
            }
            else {
                // Session not found or error loading
                DispatchQueue.main.async {
                    // Close the popup after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation { isPresented = false }
                    }
                }
            }
        }
    }
}
