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
                backgroundGradient
                mainContent
            }
            .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingSearch) { FriendsSearchView() }
            .refreshable { await refreshData() }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Join Session"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear { Task { await refreshData() } }
            .onChange(of: liveSessionManager.activeFriendSessions) { _ in
                viewModel.objectWillChange.send()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Theme.mutedPurple,
                Theme.mediumPurple,
                Theme.darkPurpleBlue,
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                titleView
                WeeklyLeaderboard(viewModel: leaderboardViewModel).padding(.horizontal)
                friendRequestsSection
                findFriendsButton
                friendsListHeader
                friendsListContent
            }
            .padding(.bottom, 20)
        }
    }
    
    private var titleView: some View {
        Text("FRIENDS").font(.system(size: 32, weight: .black)).tracking(8)
            .foregroundColor(.white)
            .shadow(color: Theme.yellow.opacity(0.6), radius: 10)
            .padding(.top, 20)
    }
    
    private var friendRequestsSection: some View {
        Group {
            if !viewModel.friendRequests.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("FRIEND REQUESTS").font(.system(size: 16, weight: .black))
                        .tracking(5).foregroundColor(Theme.yellow)
                        .shadow(color: Theme.yellow.opacity(0.6), radius: 6)
                    
                    ForEach(viewModel.friendRequests) { user in
                        EnhancedFriendRequestCard(user: user) { accepted in
                            if accepted {
                                viewModel.acceptFriendRequest(from: user.id)
                            }
                            else {
                                viewModel.declineFriendRequest(from: user.id)
                            }
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var findFriendsButton: some View {
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
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.orange, Theme.yellowyOrange],
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
                
                Text("Find Friends").font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(findFriendsButtonBackground)
            .shadow(color: Theme.orange.opacity(0.5), radius: 8)
            .scaleEffect(isButtonPressed ? 0.96 : 1.0)
        }
        .padding(.horizontal)
    }
    
    private var findFriendsButtonBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.orange.opacity(0.7),
                            Theme.yellowyOrange.opacity(0.7),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
            
            RoundedRectangle(cornerRadius: 15)
                .stroke(Theme.silveryGradient, lineWidth: 1)
        }
    }
    
    private var friendsListHeader: some View {
        Group {
            if !viewModel.friends.isEmpty {
                Text("YOUR FRIENDS").font(.system(size: 16, weight: .black)).tracking(5)
                    .foregroundColor(Theme.lightTealBlue)
                    .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
    }
    
    private var friendsListContent: some View {
        Group {
            if viewModel.friends.isEmpty {
                emptyFriendsView
            } else {
                friendsListView
            }
        }
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.lightTealBlue.opacity(0.7),
                                Theme.darkTealBlue.opacity(0.3),
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.2").font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.8), radius: 10)
            }
            .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 15)
            
            Text("No Friends Yet").font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.5), radius: 8)
            
            Text("Add friends to see their focus sessions")
                .font(.system(size: 18)).foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 30).padding(.bottom, 50)
    }
    
    private var friendsListView: some View {
        LazyVStack(spacing: 15) {
            ForEach(sortedFriends) { friend in
                ZStack(alignment: .topTrailing) {
                    NavigationLink(
                        destination: UserProfileLoader(userId: friend.id)
                    ) {
                        EnhancedFriendCard(
                            friend: friend.user,
                            liveSession: friend.sessionData ?? createEmptyLiveSessionData()
                        )
                        .id("\(friend.id)-\(friend.sessionData?.id ?? "no-session")")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isNavigationBlocked)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal)
    }

    // Creates an empty session data object for use when there's no live session
    private func createEmptyLiveSessionData() -> LiveSessionManager.LiveSessionData {
        return LiveSessionManager.LiveSessionData(
            id: "no-session",
            starterId: "",
            starterUsername: "",
            participants: [],
            startTime: Date(),
            targetDuration: 0,
            remainingSeconds: 0,
            isPaused: false,
            allowPauses: false,
            maxPauses: 0,
            joinTimes: [:],
            participantStatus: [:],
            lastUpdateTime: Date()
        )
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
                let isSessionTooOld = Date().timeIntervalSince(sessionData.lastUpdateTime) > 300  // 5 minutes
                let sessionEndTime = sessionData.startTime.addingTimeInterval(
                    TimeInterval(sessionData.targetDuration * 60)
                )
                let isSessionEnded = Date() > sessionEndTime

                if !isSessionTooOld && !isSessionEnded && sessionData.remainingSeconds > 0 {
                    result.append(
                        FriendWithSession(
                            user: friend,
                            sessionId: sessionId,
                            sessionData: sessionData
                        )
                    )
                }
                else {
                    // Add without session data if it's stale
                    result.append(FriendWithSession(user: friend, sessionId: nil, sessionData: nil))
                }
            }
            else {
                result.append(FriendWithSession(user: friend, sessionId: nil, sessionData: nil))
            }
        }

        // Sort with live sessions first
        return result.sorted { a, b in
            if a.sessionData != nil && b.sessionData == nil {
                return true
            }
            else if a.sessionData == nil && b.sessionData != nil {
                return false
            }
            else {
                return a.user.username < b.user.username
            }
        }
    }

    // Helper struct to combine friend with session data
    struct FriendWithSession: Identifiable {
        let user: FirebaseManager.FlipUser
        let sessionId: String?
        let sessionData: LiveSessionManager.LiveSessionData?

        var id: String { return user.id }
    }

    private func refreshData() async {
        // Refresh all data sources concurrently
        async let friendsRefresh = viewModel.loadFriends()
        async let leaderboardRefresh = leaderboardViewModel.loadLeaderboard()
        async let sessionsRefresh = liveSessionManager.listenForFriendSessions()
        // Wait for all refreshes to complete
        _ = await [friendsRefresh, leaderboardRefresh, sessionsRefresh]
        // Force a view refresh
        await MainActor.run { viewModel.objectWillChange.send() }
    }
}
