import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendManager()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var liveSessionManager = LiveSessionManager.shared
    @State private var showingSearch = false
    @State private var isButtonPressed = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isJoiningSession = false
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var viewRouter: ViewRouter
    
    var body: some View {
        NavigationView {
            ZStack {
                // Custom gradient background with more orange/yellow color variety
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 26/255, green: 14/255, blue: 47/255), // Deep purple
                        Color(red: 65/255, green: 16/255, blue: 94/255), // Medium purple
                        Color(red: 35/255, green: 20/255, blue: 90/255), // Purple-red transition
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Main content
                ScrollView {
                    VStack(spacing: 22) {
                        // Vibrant title with glow
                        Text("FRIENDS")
                            .font(.system(size: 32, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.6), radius: 10)
                            .padding(.top, 20)
                        
                        // Golden Weekly Leaderboard - Redesigned component
                        WeeklyLeaderboard(
                            viewModel: leaderboardViewModel
                        )
                            .padding(.horizontal)

                        // Friend Requests Section - Enhanced with vibrant colors
                        if !viewModel.friendRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("FRIEND REQUESTS")
                                    .font(.system(size: 16, weight: .black))
                                    .tracking(5)
                                    .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                                    .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.6), radius: 6)

                                ForEach(viewModel.friendRequests) { user in
                                    EnhancedFriendRequestCard(user: user) { accepted in
                                        if accepted {
                                            viewModel.acceptFriendRequest(from: user.id)
                                        } else {
                                            viewModel.declineFriendRequest(from: user.id)
                                        }
                                    }
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Enhanced Find Friends Button - More vibrant and attractive
                        Button(action: {
                            withAnimation(.spring()) {
                                isButtonPressed = true
                                showingSearch = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isButtonPressed = false
                            }
                        }) {
                            HStack {
                                // Colorful icon with glow
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 249/255, green: 115/255, blue: 22/255),
                                                    Color(red: 234/255, green: 88/255, blue: 12/255)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.white.opacity(0.5), radius: 2)
                                }
                                
                                Text("Find Friends")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                ZStack {
                                    // Vibrant orange-yellow gradient
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.7),
                                                    Color(red: 234/255, green: 88/255, blue: 12/255).opacity(0.7)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    // Glass effect
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    // Glowing border
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.5), radius: 8)
                            .scaleEffect(isButtonPressed ? 0.96 : 1.0)
                        }
                        .padding(.horizontal)

                        // Friends list title - Enhanced with color
                        if !viewModel.friends.isEmpty {
                            Text("YOUR FRIENDS")
                                .font(.system(size: 16, weight: .black))
                                .tracking(5)
                                .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        
                        // Enhanced empty friends state
                        if viewModel.friends.isEmpty {
                            VStack(spacing: 20) {
                                // Animated glowing circle
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                                    Color(red: 14/255, green: 165/255, blue: 233/255).opacity(0.3)
                                                ]),
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 50
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.2")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.white.opacity(0.8), radius: 10)
                                }
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 15)

                                Text("No Friends Yet")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.white.opacity(0.5), radius: 8)

                                Text("Add friends to see their focus sessions")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 30)
                            .padding(.bottom, 50)
                        } else {
                            // Enhanced Friends List with better visuals
                            LazyVStack(spacing: 15) {
                                // Sort friends - live sessions first, then normal friends
                                ForEach(sortedFriends) { friend in
                                    // Create a ZStack where the NavigationLink is behind but covers most of the card
                                    ZStack(alignment: .topTrailing) {
                                        // NavigationLink for profile view - make it disabled when joining
                                        NavigationLink(destination: UserProfileView(user: friend.user)) {
                                            // Enhanced friend card with vibrant colors for live sessions
                                            EnhancedFriendCard(
                                                friend: friend.user,
                                                liveSession: friend.sessionData
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .disabled(isNavigationBlocked)
                                        
                                        // If this friend has a live session, add the join button on top
                                        if friend.sessionData != nil && friend.sessionData?.canJoin == true {
                                            // Enhanced join button with better visuals
                                            Button {
                                                handleJoinSession(sessionId: friend.sessionId)
                                            } label: {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 12, weight: .bold))
                                                    
                                                    Text("JOIN")
                                                        .font(.system(size: 14, weight: .black))
                                                        .tracking(1)
                                                }
                                                .foregroundColor(.white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(
                                                    ZStack {
                                                        // Vibrant green gradient
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: [
                                                                        Color(red: 22/255, green: 163/255, blue: 74/255),
                                                                        Color(red: 21/255, green: 128/255, blue: 61/255)
                                                                    ],
                                                                    startPoint: .top,
                                                                    endPoint: .bottom
                                                                )
                                                            )
                                                        
                                                        // Glass effect
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.white.opacity(0.1))
                                                        
                                                        // Subtle border
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                    }
                                                )
                                                .shadow(color: Color.green.opacity(0.5), radius: 6)
                                            }
                                            .padding(.trailing, 20)
                                            .padding(.top, 16)
                                        }
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingSearch) {
                FriendsSearchView()
            }
            .refreshable {
                viewModel.loadFriends()
                leaderboardViewModel.loadLeaderboard()
                liveSessionManager.listenForFriendSessions()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Join Session"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                liveSessionManager.listenForFriendSessions()
            }
            .onChange(of: liveSessionManager.activeFriendSessions) { _ in
                // Force view refresh when live sessions change
                viewModel.objectWillChange.send()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Block navigation when joining session
    private var isNavigationBlocked: Bool {
        return isJoiningSession || liveSessionManager.isJoiningSession
    }
    
    // Computed property to sort friends with live sessions first
    private var sortedFriends: [FriendWithSession] {
        var result: [FriendWithSession] = []
        
        // First add friends with live sessions
        for friend in viewModel.friends {
            // Check if this friend has an active session
            let session = liveSessionManager.activeFriendSessions.first { sessionId, sessionData in
                return sessionData.participants.contains(friend.id)
            }
            
            // Add this after you find the session
            if let (sessionId, sessionData) = session {
                // Additional checks to filter out stale sessions
                let isSessionTooOld = Date().timeIntervalSince(sessionData.lastUpdateTime) > 300 // 5 minutes
                let sessionEndTime = sessionData.startTime.addingTimeInterval(TimeInterval(sessionData.targetDuration * 60))
                let isSessionEnded = Date() > sessionEndTime
                
                if !isSessionTooOld && !isSessionEnded && sessionData.remainingSeconds > 0 {
                    result.append(FriendWithSession(
                        user: friend,
                        sessionId: sessionId,
                        sessionData: sessionData
                    ))
                } else {
                    // Add without session data if it's stale
                    result.append(FriendWithSession(
                        user: friend,
                        sessionId: nil,
                        sessionData: nil
                    ))
                }
            } else {
                result.append(FriendWithSession(
                    user: friend,
                    sessionId: nil,
                    sessionData: nil
                ))
            }
        }
        
        // Sort with live sessions first
        return result.sorted { a, b in
            if a.sessionData != nil && b.sessionData == nil {
                return true
            } else if a.sessionData == nil && b.sessionData != nil {
                return false
            } else {
                return a.user.username < b.user.username
            }
        }
    }
    
    // Helper struct to combine friend with session data
    struct FriendWithSession: Identifiable {
        let user: FirebaseManager.FlipUser
        let sessionId: String?
        let sessionData: LiveSessionManager.LiveSessionData?
        
        var id: String {
            return user.id
        }
    }
    
    // Handle join session logic
    private func handleJoinSession(sessionId: String?) {
        guard let sessionId = sessionId else {
            print("No session ID provided for joining")
            return
        }
        
        print("Attempting to join session with ID: \(sessionId)")
        
        // Block if user is already in a session
        if appManager.currentState != .initial {
            alertMessage = "You're already in a session. Please complete or cancel it before joining another."
            showAlert = true
            return
        }
        
        isJoiningSession = true
        
        // Get friend name from active sessions
        let friendName = liveSessionManager.activeFriendSessions[sessionId]?.starterUsername ?? "Friend"
        
        // First, try the direct join method from LiveSessionManager
        LiveSessionManager.shared.joinSession(sessionId: sessionId) { success, remainingSeconds, totalDuration in
            DispatchQueue.main.async {
                isJoiningSession = false
                
                if success {
                    print("Successfully joined session \(sessionId) via LiveSessionManager")
                    // Start the joined session directly through AppManager
                    appManager.joinLiveSession(
                        sessionId: sessionId,
                        remainingSeconds: remainingSeconds,
                        totalDuration: totalDuration
                    )
                    
                    // Also trigger home tab switch
                    NotificationCenter.default.post(
                        name: Notification.Name("SwitchToHomeTab"),
                        object: nil
                    )
                } else {
                    // Try backup method using coordinator if direct join fails
                    print("Direct join failed, trying via coordinator...")
                    
                    // Use the coordinator to pass session information
                    SessionJoinCoordinator.shared.setJoinSession(id: sessionId, name: friendName)
                    
                    // Trigger home tab switch
                    NotificationCenter.default.post(
                        name: Notification.Name("SwitchToHomeTab"),
                        object: nil
                    )
                    
                    // Show error if both methods fail
                    alertMessage = "Unable to join the session. It may be full or no longer available."
                    showAlert = true
                }
            }
        }
    }
}
