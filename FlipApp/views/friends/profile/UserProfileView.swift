import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct UserProfileView: View {
    let user: FirebaseManager.FlipUser
    @State private var showStats = false
    @State private var showDetailedStats = false
    @State private var showRemoveFriendAlert = false
    @State private var showCancelRequestAlert = false
    @State private var showAddFriendConfirmation = false
    @State private var showFriendsList = false
    @State private var friendRequestSent = false
    @State private var showBlockUserAlert = false
    @StateObject private var weeklyViewModel = WeeklySessionListViewModel()
    @StateObject private var friendManager = FriendManager()
    @StateObject private var searchManager = SearchManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var userScore: Double = 3.0  // Default starting score
    @State private var userFriends: [FirebaseManager.FlipUser] = []
    @State private var mutualFriends: [FirebaseManager.FlipUser] = []
    @State private var loadingFriends = false
    @State private var isLoading = true  // Add loading state

    // Cyan-midnight theme colors
    private let cyanBluePurpleGradient = LinearGradient(
        colors: [
            Theme.deepMidnightPurple,  // Deep midnight purple
            Theme.mediumMidnightPurple,  // Medium midnight purple
            Theme.darkCyanBlue.opacity(0.7),  // Dark cyan blue
            Theme.deeperCyanBlue.opacity(0.6),  // Deeper cyan blue
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let cyanBlueAccent = Theme.lightTealBlue
    private let cyanBlueGlow = Theme.lightTealBlue.opacity(0.5)

    // Check if this is the current user's profile
    private var isCurrentUser: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return user.id == currentUserId
    }

    // Check if this user is a friend
    private var isFriend: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return user.friends.contains(currentUserId)
    }

    // Check if we've sent a friend request to this user
    private var hasSentFriendRequest: Bool {
        guard let _currentUserId = Auth.auth().currentUser?.uid else { return false }
        // Check both local state and user data
        return friendRequestSent
            || FirebaseManager.shared.currentUser?.sentRequests.contains(user.id) ?? false
    }

    private var weeksLongestSession: Int? {
        return weeklyViewModel.weeksLongestSession > 0 ? weeklyViewModel.weeksLongestSession : nil
    }

    var body: some View {
        ZStack {
            // Enhanced background with decorative elements
            EnhancedProfileBackgroundView(
                cyanBluePurpleGradient: cyanBluePurpleGradient,
                cyanBlueAccent: cyanBlueAccent
            )

            if isLoading {
                // Enhanced loading indicator overlay
                VStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(cyanBlueAccent.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)

                        Circle().trim(from: 0, to: 0.7).stroke(cyanBlueAccent, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1).repeatForever(autoreverses: false),
                                value: isLoading
                            )
                    }

                    Text("Loading profile...").font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white).shadow(color: cyanBlueGlow, radius: 6)
                }
            }
            else {
                // Main content after loading
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Profile Header - using our improved version
                        ProfileHeaderView(
                            user: user,
                            userScore: userScore,
                            cyanBlueGlow: cyanBlueGlow,
                            cyanBlueAccent: cyanBlueAccent,
                            isCurrentUser: isCurrentUser,
                            isFriend: isFriend,
                            hasSentFriendRequest: hasSentFriendRequest,
                            showRemoveFriendAlert: $showRemoveFriendAlert,
                            showCancelRequestAlert: $showCancelRequestAlert,
                            showAddFriendConfirmation: $showAddFriendConfirmation
                        )

                        // Friend status badge
                        if !isCurrentUser {
                            FriendStatusBadgeView(
                                isFriend: isFriend,
                                hasSentFriendRequest: hasSentFriendRequest
                            )
                            .padding(.horizontal)
                            // Block user button
                            Button(action: { showBlockUserAlert = true }) {
                                HStack {
                                    Image(systemName: "slash.circle").font(.system(size: 16))
                                    Text("Block User").font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red).padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.top, 8)
                        }

                        // Friends count button - leads to friends list
                        FriendsCountButton(
                            user: user,
                            isCurrentUser: isCurrentUser,
                            cyanBlueAccent: cyanBlueAccent,
                            showFriendsList: $showFriendsList,
                            loadUserFriends: loadUserFriends
                        )

                        // Stats Summary Card with button to detailed view
                        EnhancedStatsCardView(
                            user: user,
                            cyanBlueAccent: cyanBlueAccent,
                            showDetailedStats: $showDetailedStats
                        )

                        // Enhanced Longest Session Card - Weekly Stats
                        EnhancedWeeklyStatsView(
                            user: user,
                            weeksLongestSession: weeksLongestSession,
                            cyanBlueAccent: cyanBlueAccent,
                            cyanBlueGlow: cyanBlueGlow
                        )

                        // Recent Sessions
                        RecentSessionsView(
                            user: user,
                            weeklyViewModel: weeklyViewModel,
                            cyanBlueGlow: cyanBlueGlow
                        )
                    }
                    .padding(.bottom, 30)
                }

                // Friends List overlay when activated
                if showFriendsList {
                    UserFriendsListView(
                        user: user,
                        isPresented: $showFriendsList,
                        mutualFriends: mutualFriends,
                        userFriends: userFriends,
                        loadingFriends: loadingFriends
                    )
                }

                // Alert Overlays
                AlertOverlays(
                    showRemoveFriendAlert: $showRemoveFriendAlert,
                    showCancelRequestAlert: $showCancelRequestAlert,
                    showAddFriendConfirmation: $showAddFriendConfirmation,
                    user: user,
                    friendManager: friendManager,
                    searchManager: searchManager,
                    friendRequestSent: $friendRequestSent,
                    cancelFriendRequest: cancelFriendRequest,
                    presentationMode: presentationMode
                )
                // Block user alert
                .alert(isPresented: $showBlockUserAlert) {
                    Alert(
                        title: Text("Block User"),
                        message: Text(
                            "Are you sure you want to block \(user.username)? This will remove them from your friends list and prevent them from interacting with you."
                        ),
                        primaryButton: .destructive(Text("Block")) { blockUser() },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Immediately load data
            loadInitialData()
        }
        .sheet(isPresented: $showDetailedStats) { FriendStatsView(user: user) }
    }

    // Function to handle data loading
    private func loadInitialData() {
        // Start loading immediately
        Task {
            do {
                // Load sessions data
                await weeklyViewModel.loadSessions(for: user.id)
                // Load user's score
                loadUserScore()
                // Ensure we're on the main thread for UI updates
                await MainActor.run {
                    withAnimation(.spring()) {
                        isLoading = false
                        showStats = true
                    }
                }
            }
            catch {
                print("Error loading profile data: \(error)")
                // Even if there's an error, we should show the profile
                await MainActor.run {
                    withAnimation(.spring()) {
                        isLoading = false
                        showStats = true
                    }
                }
            }
        }
    }

    // Function to load user's score from Firebase
    private func loadUserScore() {
        FirebaseManager.shared.db.collection("users").document(user.id)
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let score = data["score"] as? Double {
                    DispatchQueue.main.async { self.userScore = score }
                }
            }
    }

    // Function to load a user's friends with mutual friends highlighted
    private func loadUserFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        loadingFriends = true
        userFriends = []
        mutualFriends = []

        // Only continue if not viewing own profile (to avoid redundant work)
        if user.id != currentUserId {
            // First, get the current user's friends for comparison
            FirebaseManager.shared.db.collection("users").document(currentUserId)
                .getDocument { document, error in
                    guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                    else { return }

                    let currentUserFriends = Set(userData.friends)

                    // Now load all this user's friends
                    self.loadFriendsDetails(friendIds: user.friends) { loadedFriends in
                        DispatchQueue.main.async {
                            // Separate mutual friends from other friends
                            for friend in loadedFriends {
                                if currentUserFriends.contains(friend.id)
                                    || friend.id == currentUserId
                                {
                                    self.mutualFriends.append(friend)
                                }
                                else {
                                    self.userFriends.append(friend)
                                }
                            }

                            // Sort both lists alphabetically
                            self.mutualFriends.sort { $0.username < $1.username }
                            self.userFriends.sort { $0.username < $1.username }

                            self.loadingFriends = false
                        }
                    }
                }
        }
        else {
            // If viewing own profile, just load all friends
            loadFriendsDetails(friendIds: user.friends) { loadedFriends in
                DispatchQueue.main.async {
                    self.userFriends = loadedFriends.sorted { $0.username < $1.username }
                    self.loadingFriends = false
                }
            }
        }
    }

    // Helper function to load friend details
    private func loadFriendsDetails(
        friendIds: [String],
        completion: @escaping ([FirebaseManager.FlipUser]) -> Void
    ) {
        guard !friendIds.isEmpty else {
            completion([])
            return
        }

        let db = FirebaseManager.shared.db
        var loadedFriends: [FirebaseManager.FlipUser] = []
        let dispatchGroup = DispatchGroup()

        for friendId in friendIds {
            dispatchGroup.enter()

            db.collection("users").document(friendId)
                .getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                        loadedFriends.append(userData)
                    }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(loadedFriends) }
    }

    // Function to cancel a friend request
    private func cancelFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = FirebaseManager.shared.db

        // Remove from recipient's friend requests
        db.collection("users").document(userId)
            .updateData(["friendRequests": FieldValue.arrayRemove([currentUserId])])

        // Remove from sender's sent requests
        db.collection("users").document(currentUserId)
            .updateData(["sentRequests": FieldValue.arrayRemove([userId])])
    }

    // Function to block a user
    private func blockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        // Get current user document
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .getDocument { document, error in
                if let error = error {
                    print("Error getting current user document: \(error.localizedDescription)")
                    return
                }
                guard let document = document, document.exists,
                    var userData = try? document.data(as: FirebaseManager.FlipUser.self)
                else {
                    print("Failed to parse current user data")
                    return
                }
                // Add user to blocked list if not already blocked
                if !userData.blockedUsers.contains(user.id) {
                    userData.blockedUsers.append(user.id)
                    // Remove from friends list if they're a friend
                    if userData.friends.contains(user.id) {
                        userData.friends.removeAll { $0 == user.id }
                    }
                    // Remove from friend requests if they sent one
                    if userData.friendRequests.contains(user.id) {
                        userData.friendRequests.removeAll { $0 == user.id }
                    }
                    // Remove from sent requests if we sent one
                    if userData.sentRequests.contains(user.id) {
                        userData.sentRequests.removeAll { $0 == user.id }
                    }
                    // Update the document
                    do {
                        try FirebaseManager.shared.db.collection("users").document(currentUserId)
                            .setData(from: userData)
                        // Update local user object
                        DispatchQueue.main.async { FirebaseManager.shared.currentUser = userData }
                        // Dismiss the profile view
                        presentationMode.wrappedValue.dismiss()
                    }
                    catch { print("Error updating user document: \(error.localizedDescription)") }
                }
            }
    }
}
