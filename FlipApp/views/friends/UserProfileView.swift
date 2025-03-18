import FirebaseAuth
import FirebaseFirestore
import Foundation
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
    @StateObject private var weeklyViewModel = WeeklySessionListViewModel()
    @StateObject private var scoreManager = ScoreManager.shared
    @StateObject private var friendManager = FriendManager()
    @StateObject private var searchManager = SearchManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var userScore: Double = 3.0 // Default starting score
    @State private var userFriends: [FirebaseManager.FlipUser] = []
    @State private var mutualFriends: [FirebaseManager.FlipUser] = []
    @State private var loadingFriends = false
    @State private var isLoading = true // Add loading state
    
    // Cyan-midnight theme colors
    private let cyanBluePurpleGradient = LinearGradient(
        colors: [
            Color(red: 20/255, green: 10/255, blue: 40/255), // Deep midnight purple
            Color(red: 30/255, green: 18/255, blue: 60/255), // Medium midnight purple
            Color(red: 14/255, green: 101/255, blue: 151/255).opacity(0.7), // Dark cyan blue
            Color(red: 12/255, green: 74/255, blue: 110/255).opacity(0.6)  // Deeper cyan blue
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let cyanBlueAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let cyanBlueGlow = Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5)
    
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
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        // Check both local state and user data
        return friendRequestSent || FirebaseManager.shared.currentUser?.sentRequests.contains(user.id) ?? false
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
                        Circle()
                            .stroke(cyanBlueAccent.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(cyanBlueAccent, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                    }
                    
                    Text("Loading profile...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: cyanBlueGlow, radius: 6)
                }
            } else {
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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Immediately load data
            loadInitialData()
        }
        .sheet(isPresented: $showDetailedStats) {
            FriendStatsView(user: user)
        }
    }
    
    // Function to handle data loading
    private func loadInitialData() {
        // Start loading immediately
        Task {
            // Load sessions data
            weeklyViewModel.loadSessions(for: user.id)
            
            // Load user's score
            loadUserScore()
            
            // Short delay to ensure data is loaded and view rendering is complete
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Update UI with animation
            withAnimation(.spring()) {
                isLoading = false
                showStats = true
            }
        }
    }
    
    // Function to load user's score from Firebase
    private func loadUserScore() {
        FirebaseManager.shared.db.collection("users").document(user.id).getDocument { snapshot, error in
            if let data = snapshot?.data(), let score = data["score"] as? Double {
                DispatchQueue.main.async {
                    self.userScore = score
                }
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
                    guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self) else {
                        return
                    }
                    
                    let currentUserFriends = Set(userData.friends)
                    
                    // Now load all this user's friends
                    self.loadFriendsDetails(friendIds: user.friends) { loadedFriends in
                        DispatchQueue.main.async {
                            // Separate mutual friends from other friends
                            for friend in loadedFriends {
                                if currentUserFriends.contains(friend.id) || friend.id == currentUserId {
                                    self.mutualFriends.append(friend)
                                } else {
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
        } else {
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
    private func loadFriendsDetails(friendIds: [String], completion: @escaping ([FirebaseManager.FlipUser]) -> Void) {
        guard !friendIds.isEmpty else {
            completion([])
            return
        }
        
        let db = FirebaseManager.shared.db
        var loadedFriends: [FirebaseManager.FlipUser] = []
        let dispatchGroup = DispatchGroup()
        
        for friendId in friendIds {
            dispatchGroup.enter()
            
            db.collection("users").document(friendId).getDocument { document, error in
                defer { dispatchGroup.leave() }
                
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    loadedFriends.append(userData)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(loadedFriends)
        }
    }
    
    // Function to cancel a friend request
    private func cancelFriendRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = FirebaseManager.shared.db
        
        // Remove from recipient's friend requests
        db.collection("users").document(userId)
            .updateData([
                "friendRequests": FieldValue.arrayRemove([currentUserId])
            ])
        
        // Remove from sender's sent requests
        db.collection("users").document(currentUserId)
            .updateData([
                "sentRequests": FieldValue.arrayRemove([userId])
            ])
    }
}
struct EnhancedProfileBackgroundView: View {
    let cyanBluePurpleGradient: LinearGradient
    let cyanBlueAccent: Color
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            // Main background
            cyanBluePurpleGradient
                .edgesIgnoringSafeArea(.all)
            
            // Animated top decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.3),
                            cyanBlueAccent.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 150, y: -150)
                .blur(radius: 40)
                .opacity(animateGlow ? 0.8 : 0.6)
                .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGlow)
            
            // Bottom decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.2),
                            cyanBlueAccent.opacity(0.03)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -120, y: 350)
                .blur(radius: 35)
                .opacity(animateGlow ? 0.6 : 0.4)
                .animation(Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1), value: animateGlow)
            
            // Additional smaller accent glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.15),
                            cyanBlueAccent.opacity(0.01)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: 100, y: 200)
                .blur(radius: 30)
                .opacity(animateGlow ? 0.5 : 0.3)
                .animation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(2), value: animateGlow)
        }
        .onAppear {
            animateGlow = true
        }
    }
}

struct ProfileHeaderView: View {
    let user: FirebaseManager.FlipUser
    let userScore: Double
    let cyanBlueGlow: Color
    let cyanBlueAccent: Color
    let isCurrentUser: Bool
    let isFriend: Bool
    let hasSentFriendRequest: Bool
    @State private var streakStatus: StreakStatus = .none
    @Binding var showRemoveFriendAlert: Bool
    @Binding var showCancelRequestAlert: Bool
    @Binding var showAddFriendConfirmation: Bool
    
    // Helper function to get rank
    private func getRank(for score: Double) -> (name: String, color: Color) {
        switch score {
            case 0.0..<30.0:
                return ("Novice", Color(red: 156/255, green: 163/255, blue: 231/255)) // Periwinkle
            case 30.0..<60.0:
                return ("Apprentice", Color(red: 96/255, green: 165/255, blue: 250/255)) // Light blue
            case 60.0..<90.0:
                return ("Beginner", Color(red: 59/255, green: 130/255, blue: 246/255)) // Blue
            case 90.0..<120.0:
                return ("Steady", Color(red: 16/255, green: 185/255, blue: 129/255)) // Green
            case 120.0..<150.0:
                return ("Focused", Color(red: 249/255, green: 180/255, blue: 45/255)) // Bright amber
            case 150.0..<180.0:
                return ("Disciplined", Color(red: 249/255, green: 115/255, blue: 22/255)) // Orange
            case 180.0..<210.0:
                return ("Resolute", Color(red: 239/255, green: 68/255, blue: 68/255)) // Red
            case 210.0..<240.0:
                return ("Master", Color(red: 236/255, green: 72/255, blue: 153/255)) // Pink
            case 240.0..<270.0:
                return ("Guru", Color(red: 147/255, green: 51/255, blue: 234/255)) // Vivid purple
            case 270.0...300.0:
                return ("Enlightened", Color(red: 236/255, green: 64/255, blue: 255/255)) // Bright fuchsia
            default:
                return ("Unranked", Color.gray)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 15) {
                // Profile Picture with Streak Indicator
                EnhancedProfileAvatarWithStreak(
                    imageURL: user.profileImageURL,
                    size: 80,
                    username: user.username,
                    streakStatus: streakStatus
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    // Username with truncation handling
                    Text(user.username)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: cyanBlueGlow, radius: 8)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 180, alignment: .leading)
                    
                    // Display rank name
                    let rank = getRank(for: userScore)
                    Text(rank.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(rank.color)
                        .shadow(color: rank.color.opacity(0.5), radius: 4)
                }
                
                Spacer()
                
                // Rank Circle
                RankCircle(score: userScore)
                    .frame(width: 60, height: 60)
            }
            
            // Display streak status if active - moved to its own row
            if streakStatus != .none {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                        .shadow(color: streakStatus == .redFlame ? Color.red.opacity(0.6) : Color.orange.opacity(0.6), radius: 4)
                    
                    Text(streakStatus == .redFlame ? "BLAZING STREAK" : "ON FIRE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                        .shadow(color: streakStatus == .redFlame ? Color.red.opacity(0.4) : Color.orange.opacity(0.4), radius: 2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(streakStatus == .redFlame ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(streakStatus == .redFlame ? Color.red.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Only show friend action buttons if this is not the current user's profile
            if !isCurrentUser {
                HStack {
                    Spacer()
                    if isFriend {
                        // Remove friend button
                        Button(action: {
                            showRemoveFriendAlert = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.fill.badge.minus")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                        }
                    } else if hasSentFriendRequest {
                        // Pending request indicator
                        Button(action: {
                            showCancelRequestAlert = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.orange.opacity(0.3), radius: 4)
                        }
                    } else {
                        // Add friend button
                        Button(action: {
                            showAddFriendConfirmation = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cyanBlueAccent.opacity(0.7),
                                                cyanBlueAccent.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.fill.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
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
                            )
                            .shadow(color: cyanBlueGlow, radius: 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .onAppear {
            // Load streak status on appear
            loadStreakStatus()
        }
    }
    
    // Function to load the user's streak status
    private func loadStreakStatus() {
        FirebaseManager.shared.db.collection("users").document(user.id)
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
}

// MARK: - Friend Status Badge Component
struct FriendStatusBadgeView: View {
    let isFriend: Bool
    let hasSentFriendRequest: Bool
    
    var body: some View {
        if isFriend {
            FriendStatusBadge(
                text: "Friends",
                icon: "person.2.fill",
                color: Color.green
            )
        } else if hasSentFriendRequest {
            FriendStatusBadge(
                text: "Friend Request Sent",
                icon: "clock.fill",
                color: Color.orange
            )
        }
    }
}

// MARK: - Friends Count Button Component
struct FriendsCountButton: View {
    let user: FirebaseManager.FlipUser
    let isCurrentUser: Bool
    let cyanBlueAccent: Color
    @Binding var showFriendsList: Bool
    let loadUserFriends: () -> Void
    
    var body: some View {
        Button(action: {
            loadUserFriends()
            showFriendsList = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    // The title shows appropriate text based on whose profile it is
                    Text(isCurrentUser ? "YOUR FRIENDS" : "\(user.username.uppercased())'S FRIENDS")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(cyanBlueAccent)
                        
                        Text("\(user.friends.count) friends")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    cyanBlueAccent.opacity(0.4),
                                    cyanBlueAccent.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.05))
                    
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
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
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

// MARK: - Stats Card Component
struct EnhancedStatsCardView: View {
    let user: FirebaseManager.FlipUser
    let cyanBlueAccent: Color
    @Binding var showDetailedStats: Bool
    @State private var animatePulse = false
    
    var body: some View {
        VStack(spacing: 15) {
            // Quick Stats overview
            HStack(spacing: 30) {
                EnhancedStatBox(
                    title: "SESSIONS",
                    value: "\(user.totalSessions)",
                    icon: "timer",
                    accentColor: cyanBlueAccent
                )
                
                EnhancedStatBox(
                    title: "FOCUS TIME",
                    value: "\(user.totalFocusTime)m",
                    icon: "clock.fill",
                    accentColor: cyanBlueAccent
                )
            }
            .padding(.vertical, 5)
            
            // View detailed stats button
            Button(action: {
                showDetailedStats = true
            }) {
                HStack {
                    Text("VIEW DETAILED STATS")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 4)
                        .offset(x: animatePulse ? 4 : 0)
                        .animation(Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: animatePulse)
                }
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        cyanBlueAccent.opacity(0.4),
                                        cyanBlueAccent.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                cyanBlueAccent.opacity(0.5),
                                cyanBlueAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                animatePulse = true
            }
        }
    }
}

struct EnhancedWeeklyStatsView: View {
    let user: FirebaseManager.FlipUser
    let weeksLongestSession: Int?
    let cyanBlueAccent: Color
    let cyanBlueGlow: Color
    @State private var animate = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(user.username)'s LONGEST FLIP")
                        .font(.system(size: 14, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text("THIS WEEK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(cyanBlueAccent.opacity(0.3))
                        )
                        .foregroundColor(.white.opacity(0.9))
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.yellow,
                                    Color.orange
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.orange.opacity(0.7), radius: 4)
                        .rotationEffect(Angle(degrees: animate ? 5 : -5))
                        .animation(Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: animate)
                }

                Text(weeksLongestSession != nil ? "\(weeksLongestSession!) min" : "No sessions yet this week")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: cyanBlueGlow, radius: 8)
                    .opacity(animate ? 1 : 0.7)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            }
            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                cyanBlueAccent.opacity(0.4),
                                cyanBlueAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle pattern overlay
                HStack(spacing: 0) {
                    ForEach(0..<20) { i in
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: 100)
                            .opacity(0.03)
                            .offset(x: CGFloat(i * 15))
                    }
                }
                .mask(RoundedRectangle(cornerRadius: 18))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }
}
// MARK: - Recent Sessions Component
struct RecentSessionsView: View {
    let user: FirebaseManager.FlipUser
    let weeklyViewModel: WeeklySessionListViewModel
    let cyanBlueGlow: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("RECENT SESSIONS")
                .font(.system(size: 16, weight: .black))
                .tracking(5)
                .foregroundColor(.white)
                .shadow(color: cyanBlueGlow, radius: 6)
                .padding(.horizontal)

            // Using the WeeklySessionList component
            WeeklySessionList(userId: user.id, viewModel: weeklyViewModel)
        }
    }
}

// MARK: - Alert Overlays Component
struct AlertOverlays: View {
    @Binding var showRemoveFriendAlert: Bool
    @Binding var showCancelRequestAlert: Bool
    @Binding var showAddFriendConfirmation: Bool
    let user: FirebaseManager.FlipUser
    let friendManager: FriendManager
    let searchManager: SearchManager
    @Binding var friendRequestSent: Bool
    let cancelFriendRequest: (String) -> Void
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        ZStack {
            if showRemoveFriendAlert {
                RemoveFriendAlert(
                    isPresented: $showRemoveFriendAlert,
                    username: user.username
                ) {
                    // Handle friend removal
                    friendManager.removeFriend(friendId: user.id)
                    // Navigate back after removing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
            if showCancelRequestAlert {
                CancelFriendRequestAlert(
                    isPresented: $showCancelRequestAlert,
                    username: user.username
                ) {
                    // Handle canceling the friend request
                    cancelFriendRequest(user.id)
                    
                    // Update local state
                    friendRequestSent = false
                }
            }
            
            if showAddFriendConfirmation {
                AddFriendConfirmation(
                    isPresented: $showAddFriendConfirmation,
                    username: user.username
                ) {
                    // Send friend request
                    searchManager.sendFriendRequest(to: user.id)
                    friendRequestSent = true
                }
            }
        }
    }
}

// Friends list popup view component
struct UserFriendsListView: View {
    let user: FirebaseManager.FlipUser
    @Binding var isPresented: Bool
    let mutualFriends: [FirebaseManager.FlipUser]
    let userFriends: [FirebaseManager.FlipUser]
    let loadingFriends: Bool
    
    // Colors
    private let cyanBlueAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let cyanBlueGlow = Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5)
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(user.username)'s FRIENDS")
                            .font(.system(size: 22, weight: .black))
                            .tracking(3)
                            .foregroundColor(.white)
                            .shadow(color: cyanBlueGlow, radius: 8)
                        
                        Text("\(user.friends.count) total friends")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                if loadingFriends {
                    // Loading indicator
                    Spacer()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(cyanBlueAccent)
                            .scaleEffect(1.5)
                        
                        Text("Loading friends...")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Mutual friends section
                            if !mutualFriends.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("MUTUAL FRIENDS")
                                        .font(.system(size: 16, weight: .bold))
                                        .tracking(2)
                                        .foregroundColor(cyanBlueAccent)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(mutualFriends) { friend in
                                        FriendRow(friend: friend, isMutual: true)
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                    .padding(.vertical, 10)
                            }
                            
                            // Other friends section
                            if !userFriends.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(mutualFriends.isEmpty ? "FRIENDS" : "OTHER FRIENDS")
                                        .font(.system(size: 16, weight: .bold))
                                        .tracking(2)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(userFriends) { friend in
                                        FriendRow(friend: friend, isMutual: false)
                                    }
                                }
                            }
                            
                            // Empty state
                            if mutualFriends.isEmpty && userFriends.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.top, 30)
                                    
                                    Text("No friends yet")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("This user hasn't added any friends yet")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9, maxHeight: UIScreen.main.bounds.height * 0.8)
            .background(
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 30/255, green: 14/255, blue: 60/255),
                                    Color(red: 14/255, green: 30/255, blue: 60/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}

// Friend row component for the friends list
struct FriendRow: View {
    let friend: FirebaseManager.FlipUser
    let isMutual: Bool
    
    // Colors
    private let cyanBlueAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: UserProfileView(user: friend)) {
            HStack(spacing: 12) {
                // Profile picture
                ProfileAvatarView(
                    imageURL: friend.profileImageURL,
                    size: 50,
                    username: friend.username
                )
                
                // Friend info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(friend.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: isMutual ? cyanBlueAccent.opacity(0.6) : Color.white.opacity(0.3), radius: 4)
                        
                        if isMutual {
                            // Mutual friend badge
                            Text("Mutual")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(cyanBlueAccent.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(cyanBlueAccent.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 12) {
                        Label("\(friend.totalSessions) sessions", systemImage: "timer")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Label("\(friend.totalFocusTime)m focus", systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // Different background for mutual friends
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isMutual ? cyanBlueAccent.opacity(0.15) : Color.white.opacity(0.05))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isMutual ?
                            LinearGradient(
                                colors: [
                                    cyanBlueAccent.opacity(0.5),
                                    cyanBlueAccent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Friend status badge component
struct FriendStatusBadge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.top, -5)
    }
}

// Add friend confirmation overlay
struct AddFriendConfirmation: View {
    @Binding var isPresented: Bool
    let username: String
    let onConfirm: () -> Void
    @State private var isConfirmPressed = false
    @State private var isCancelPressed = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Alert card
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)
                        .opacity(0.2)
                    
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                }
                .padding(.top, 20)
                
                // Title
                VStack(spacing: 4) {
                    Text("ADD FRIEND?")
                        .font(.system(size: 22, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    
                    Text("友達を追加")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Message
                Text("Send a friend request to \(username)?")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Buttons
                HStack(spacing: 15) {
                    // Cancel button
                    Button(action: {
                        withAnimation(.spring()) {
                            isCancelPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCancelPressed = false
                            isPresented = false
                        }
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                    }
                    
                    // Add friend button
                    Button(action: {
                        withAnimation(.spring()) {
                            isConfirmPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isConfirmPressed = false
                            isPresented = false
                            onConfirm()
                        }
                    }) {
                        Text("SEND REQUEST")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(0.8)
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .scaleEffect(isConfirmPressed ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
            }
            .frame(width: 320)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.darkGray)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
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
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}

// Detailed stats view popup
struct FriendStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: FirebaseManager.FlipUser
    @State private var animateStats = false
    
    // Cyan-midnight theme colors
    private let cyanBlueAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let cyanBlueGlow = Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5)
    
    var averageSessionLength: Int {
        if user.totalSessions == 0 {
            return 0
        }
        return user.totalFocusTime / user.totalSessions
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 10/255, blue: 40/255), // Deep midnight purple
                    Color(red: 30/255, green: 18/255, blue: 60/255), // Medium midnight purple
                    Color(red: 14/255, green: 101/255, blue: 151/255).opacity(0.7), // Dark cyan blue
                    Color(red: 12/255, green: 74/255, blue: 110/255).opacity(0.6)  // Deeper cyan blue
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.2),
                            cyanBlueAccent.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: -150)
                .blur(radius: 50)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(user.username)'s STATS")
                            .font(.system(size: 24, weight: .black))
                            .tracking(6)
                            .foregroundColor(.white)
                            .shadow(color: cyanBlueGlow, radius: 8)
                        
                        Text("スタッツ")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 40)
                
                // Main stats display
                VStack(spacing: 30) {
                    // Total Focus Time
                    FriendStatCard(
                        title: "TOTAL FOCUS TIME",
                        value: "\(user.totalFocusTime)",
                        unit: "minutes",
                        icon: "clock.fill",
                        color: cyanBlueAccent,
                        delay: 0
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Total Sessions
                    FriendStatCard(
                        title: "TOTAL SESSIONS",
                        value: "\(user.totalSessions)",
                        unit: "completed",
                        icon: "checkmark.circle.fill",
                        color: Color(red: 16/255, green: 185/255, blue: 129/255),
                        delay: 0.1
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Average Session Length
                    FriendStatCard(
                        title: "AVERAGE SESSION LENGTH",
                        value: "\(averageSessionLength)",
                        unit: "minutes",
                        icon: "chart.bar.fill",
                        color: Color(red: 245/255, green: 158/255, blue: 11/255),
                        delay: 0.2
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Longest Session
                    FriendStatCard(
                        title: "LONGEST SESSION",
                        value: "\(user.longestSession)",
                        unit: "minutes",
                        icon: "crown.fill",
                        color: Color(red: 236/255, green: 72/255, blue: 153/255),
                        delay: 0.3
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK TO PROFILE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cyanBlueAccent.opacity(0.7),
                                                cyanBlueAccent.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                
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
                        .shadow(color: cyanBlueGlow, radius: 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .opacity(animateStats ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateStats)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateStats = true
                }
            }
        }
    }
}

struct FriendStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            .scaleEffect(animate ? 1 : 0.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 6)
                    
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(animate ? 1 : 0)
                .offset(x: animate ? 0 : -20)
            }
            
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animate = true
                }
            }
        }
    }
}
struct EnhancedStatBox: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 54, height: 54)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: accentColor.opacity(0.6), radius: 4)
            }
            .scaleEffect(animateValue ? 1.0 : 0.9)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateValue)
            
            Text(value)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
                .shadow(color: accentColor.opacity(0.7), radius: 4)
                .opacity(animateValue ? 1 : 0)
                .offset(y: animateValue ? 0 : 10)
                .animation(.spring(response: 0.6).delay(0.3), value: animateValue)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .opacity(animateValue ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateValue)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateValue = true
            }
        }
    }
}

struct WeeklySessionList: View {
    @ObservedObject var viewModel: WeeklySessionListViewModel
    @State private var showingAllSessions = false
    let userId: String
    
    init(userId: String, viewModel: WeeklySessionListViewModel = WeeklySessionListViewModel()) {
        self.userId = userId
        self.viewModel = viewModel
    }
    
    private var displayedSessions: [Session] {
        if showingAllSessions {
            return viewModel.sessions
        } else {
            return Array(viewModel.sessions.prefix(5))
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            ForEach(displayedSessions) { session in
                SessionHistoryCard(session: session)
            }
            
            if viewModel.sessions.isEmpty {
                Text("No sessions recorded yet")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
            
            if viewModel.sessions.count > 5 {
                Button(action: {
                    withAnimation(.spring()) {
                        showingAllSessions.toggle()
                    }
                }) {
                    HStack {
                        Text(showingAllSessions ? "Show Less" : "Show More")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: showingAllSessions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.5),
                                            Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
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
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 6)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.loadSessions(for: userId)
        }
    }
}


class WeeklySessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var weeksLongestSession: Int = 0
    private let firebaseManager = FirebaseManager.shared

    func loadSessions(for userId: String) {
        firebaseManager.db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self?.sessions = documents.compactMap { document in
                        try? document.data(as: Session.self)
                    }
                    
                    // Calculate this week's longest session
                    let calendar = Calendar.current
                    let currentDate = Date()
                    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
                    
                    let thisWeeksSessions = self?.sessions.filter { session in
                        // Only include successful sessions from this week
                        session.wasSuccessful && calendar.isDate(session.startTime, equalTo: weekStart, toGranularity: .weekOfYear)
                    } ?? []
                    
                    self?.weeksLongestSession = thisWeeksSessions.max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration ?? 0
                }
            }
    }
}
