import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Background Gradient
                Theme.feedGradient.edgesIgnoringSafeArea(.all)

                // Enhanced decorative elements
                VStack {
                    // Top glow effect - brighter and more defined
                    ZStack {
                        // Base large glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.25),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 250
                                )
                            )
                            .frame(width: 400, height: 400).offset(x: 150, y: -250)

                        // Smaller, more intense center
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.4),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200).offset(x: 180, y: -220).blur(radius: 20)
                    }

                    Spacer()

                    // Bottom glow effect - enhanced with layered effect
                    ZStack {
                        // Base glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.mutedGreen.opacity(0.15),
                                        Theme.mutedGreen.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 350, height: 350).offset(x: -150, y: 120)

                        // Secondary glow - creates depth
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Theme.lightTealBlue.opacity(0.12),
                                        Theme.lightTealBlue.opacity(0.0),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 250, height: 250).offset(x: -180, y: 80).blur(radius: 15)
                    }
                }

                ScrollView {
                    VStack(spacing: 35) {
                        // Enhanced Header with better typography and glow
                        VStack(spacing: 8) {
                            Text("FEED").font(.system(size: 36, weight: .black)).tracking(8)
                                .foregroundColor(.white)
                                .shadow(color: Theme.mutedGreen.opacity(0.7), radius: 15)
                                .padding(.top, 40)
                            Spacer().frame(height: 24)

                            if viewModel.isLoading {
                                // Enhanced loading indicator with glass effect
                                VStack(spacing: 20) {
                                    ZStack {
                                        // Glowing circle behind spinner
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    gradient: Gradient(colors: [
                                                        Theme.mutedGreen.opacity(0.3),
                                                        Theme.mutedGreen.opacity(0.0),
                                                    ]),
                                                    center: .center,
                                                    startRadius: 1,
                                                    endRadius: 50
                                                )
                                            )
                                            .frame(width: 80, height: 80).blur(radius: 10)

                                        // Spinner
                                        ProgressView().scaleEffect(2).tint(Theme.mutedGreen)
                                    }
                                    .padding(.bottom, 5)

                                    // Loading text with animated dots
                                    Text("Loading sessions")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("Please wait while we load your feed")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity).frame(height: 220)
                                .background(
                                    ZStack {
                                        // Glass effect background
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.05))

                                        // Blurred gradient overlay
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.1),
                                                        Color.white.opacity(0.05),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )

                                        // Subtle border
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Theme.silveryGradient3, lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                                .padding(.horizontal, 20).padding(.top, 20)
                            }
                            else if viewModel.feedSessions.isEmpty {
                                // Enhanced empty state view
                                EmptyFeedView().padding(.top, 20)
                            }
                            else {
                                // Session cards with subtle spacing improvements
                                ForEach(
                                    Array(viewModel.feedSessions.enumerated()),
                                    id: \.element.id
                                ) { index, session in
                                    FeedSessionCard(session: session, viewModel: viewModel)
                                        .transition(.opacity).padding(.bottom, 16)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 20)
                    }
                    .refreshable {
                        print("FeedView refreshed - reloading feed data")
                        viewModel.loadFeed()
                    }
                }
                .onAppear {
                    print("FeedView appeared - loading feed data")
                    viewModel.loadFeed()
                }
                .onDisappear {
                    // Clean up listeners when view disappears to prevent memory leaks
                    print("FeedView disappeared - cleaning up listeners")
                    viewModel.cleanupLikesListeners()
                    viewModel.cleanupCommentsListeners()
                }
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage)
                }
                .padding(.top, 20)  // Add padding above the ScrollView
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Enhanced glowing circle with layered effect
            ZStack {
                // Base glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.mutedGreen.opacity(0.5), Theme.oliveGreen.opacity(0.0),
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 150, height: 150).blur(radius: 15)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.mutedGreen.opacity(0.7), Theme.mutedGreen.opacity(0.1),
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                // Icon with glow
                Image(systemName: "doc.text.image").font(.system(size: 50)).foregroundColor(.white)
                    .shadow(color: Theme.mutedGreen.opacity(0.8), radius: 10)
            }
            .padding(.top, 20)

            // Enhanced headline with layered text
            VStack(spacing: 6) {
                Text("NO SESSIONS YET").font(.system(size: 28, weight: .black)).tracking(6)
                    .foregroundColor(.white).shadow(color: Theme.mutedGreen.opacity(0.6), radius: 8)

                Text("No sessions available").font(.system(size: 14)).tracking(2)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Supportive text with better styling
            Text("Add friends to see their focus sessions in your feed")
                .font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center).padding(.horizontal, 30).padding(.top, 5)

            // Button removed as requested
        }
        .padding().padding(.horizontal, 20).padding(.bottom, 40)
    }
}
struct NavigationFeedSessionCard: View {
    let session: Session
    let viewModel: FeedViewModel
    @State private var showCommentField = false
    @State private var comment: String = ""
    @State private var showSavedIndicator = false
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0
    @State private var showLikesSheet = false
    @FocusState private var isCommentFocused: Bool

    private var userProfileImageURL: String? {
        return viewModel.users[session.userId]?.profileImageURL
    }

    init(session: Session, viewModel: FeedViewModel) {
        self.session = session
        self.viewModel = viewModel
        // Initialize comment with existing value
        self._comment = State(initialValue: session.comment ?? "")

        // Initialize likes from the viewModel
        let sessionId = session.id.uuidString
        self._isLiked = State(initialValue: viewModel.isLikedByUser(sessionId: sessionId))
        self._likesCount = State(initialValue: viewModel.getLikesForSession(sessionId: sessionId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with user info
            HStack(spacing: 12) {
                NavigationLink(
                    destination: UserProfileView(user: viewModel.getUser(for: session.userId))
                ) {
                    // Profile pic
                    ProfileAvatarView(
                        imageURL: userProfileImageURL,
                        size: 40,
                        username: session.username
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Username and time
                VStack(alignment: .leading, spacing: 4) {
                    NavigationLink(
                        destination: UserProfileView(user: viewModel.getUser(for: session.userId))
                    ) {
                        Text(session.username).font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(session.formattedStartTime).font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            session.wasSuccessful
                                ? LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(width: 30, height: 30)

                    Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                }
            }

            // Session info
            HStack {
                Text("\(session.duration) min session").font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                if !session.wasSuccessful {
                    Text("• Lasted \(session.actualDuration) min").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            // Content sections - only if content exists
            if let title = session.sessionTitle, !title.isEmpty {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .lineLimit(1)
            }

            if let notes = session.sessionNotes, !notes.isEmpty {
                Text(notes).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }

            // Existing comment display
            if let comment = session.comment, !comment.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    VStack(alignment: .leading, spacing: 2) {
                        NavigationLink(
                            destination: UserProfileView(
                                user: viewModel.getUser(for: session.userId)
                            )
                        ) {
                            Text(session.username).font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(comment).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                .padding(.top, 2)
            }

            // Participant list for group sessions
            if let participants = session.participants, !participants.isEmpty {
                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 4)

                Text("GROUP SESSION").font(.system(size: 12, weight: .medium)).tracking(1)
                    .foregroundColor(.white.opacity(0.7))

                // Vertical layout for participants
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(participants) { participant in
                        NavigationLink(
                            destination: UserProfileView(
                                user: viewModel.getUser(for: participant.id)
                            )
                        ) {
                            HStack(spacing: 8) {
                                // Small profile icon
                                Circle().fill(Color.white.opacity(0.1)).frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "person.fill").font(.system(size: 10))
                                            .foregroundColor(.white)
                                    )

                                Text(participant.username).font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)

                                Spacer()

                                // Success/failure icon
                                Image(
                                    systemName: participant.wasSuccessful
                                        ? "checkmark.circle.fill" : "xmark.circle.fill"
                                )
                                .foregroundColor(participant.wasSuccessful ? .green : .red)
                                .font(.system(size: 14))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // Like info section - Only show if there are likes
            if likesCount > 0 {
                Button(action: { showLikesSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").font(.system(size: 12))
                            .foregroundColor(Theme.pink.opacity(0.8))

                        if likesCount == 1 {
                            Text("1 like").font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        else {
                            Text("\(likesCount) likes").font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle()).padding(.top, 4)
            }

            // Action buttons
            HStack {
                Spacer()

                // Like button
                Button(action: {
                    // Toggle like state via ViewModel
                    viewModel.likeSession(sessionId: session.id.uuidString)

                    // Update local state for immediate UI feedback
                    isLiked.toggle()

                    // Update the count for immediate feedback
                    if isLiked {
                        likesCount += 1
                    }
                    else if likesCount > 0 {
                        likesCount -= 1
                    }
                }) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                        Image(systemName: isLiked ? "heart.fill" : "heart").font(.system(size: 16))
                            .foregroundColor(isLiked ? Theme.pink : .white)
                    }
                }
                .buttonStyle(BorderlessButtonStyle()).padding(.trailing, 6)

                // Comment button
                Button(action: {
                    withAnimation(.spring()) {
                        showCommentField.toggle()
                        if showCommentField {
                            // Focus the comment field after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isCommentFocused = true
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                        Image(
                            systemName: session.comment != nil ? "text.bubble.fill" : "text.bubble"
                        )
                        .font(.system(size: 16)).foregroundColor(.white)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.top, 4)

            // Comment field
            if showCommentField {
                CommentInputField(
                    comment: $comment,
                    isFocused: _isCommentFocused,
                    showSavedIndicator: $showSavedIndicator,
                    showCommentField: $showCommentField,
                    onSubmit: { newComment in saveComment(newComment) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity)).padding(.top, 8)
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        session.wasSuccessful ? Theme.successGradient2 : Theme.nonSuccessGradient2
                    )

                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 15).stroke(Theme.silveryGradient2, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2).contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping on the card
            if isCommentFocused { isCommentFocused = false }
        }
        .popover(isPresented: $showLikesSheet, arrowEdge: .top) {
            CompactLikesListView(
                sessionId: session.id.uuidString,
                likesCount: likesCount,
                viewModel: viewModel
            )
        }
        .onAppear { updateLikeState() }
        .onChange(of: viewModel.likedByUser[session.id.uuidString]) { updateLikeState() }
        .onChange(of: viewModel.sessionLikes[session.id.uuidString]) { updateLikeState() }
    }

    private func updateLikeState() {
        let sessionId = session.id.uuidString

        // Get like status from viewModel
        isLiked = viewModel.isLikedByUser(sessionId: sessionId)
        likesCount = viewModel.getLikesForSession(sessionId: sessionId)
    }

    private func saveComment(_ newComment: String) {
        guard !newComment.isEmpty else { return }

        // Save comment to Firestore
        viewModel.saveComment(sessionId: session.id.uuidString, comment: newComment)

        // Show the saved indicator
        withAnimation { showSavedIndicator = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
                showCommentField = false
            }
        }
    }
}
struct SessionComment: Codable, Identifiable {
    var id: String  // Document ID
    let sessionId: String
    let userId: String
    let username: String
    let comment: String
    let timestamp: Date

    // Computed property for timestamp formatting
    var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: timestamp))"
        }
        else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        }
        else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: timestamp)
        }
    }
}

class FeedViewModel: ObservableObject {
    @Published var feedSessions: [Session] = []
    @Published var users: [String: FirebaseManager.FlipUser] = [:]
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var sessionComments: [String: [SessionComment]] = [:]  // Map session ID to comments array
    private var globalProcessedSessionIds = Set<String>()
    private var sessionListener: ListenerRegistration?
    private var commentsListeners: [String: ListenerRegistration] = [:]
    @Published var sessionLikes: [String: Int] = [:]  // Map session ID to like count
    @Published var likedByUser: [String: Bool] = [:]  // Map session ID to whether current user liked it
    @Published var likesUsers: [String: [String]] = [:]  // Map session ID to array of user IDs who liked it
    @Published var userStreakStatus: [String: StreakStatus] = [:]

    private let firebaseManager = FirebaseManager.shared
    private var likesListeners: [String: ListenerRegistration] = [:]

    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        print("🔄 Loading feed for user: \(userId)")
        isLoading = true
        cleanupLikesListeners()
        cleanupCommentsListeners()

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let error = error {
                    print("❌ Error fetching user data: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                        self?.isLoading = false
                    }
                    return
                }

                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self) else {
                    print("❌ Failed to decode user data")
                    DispatchQueue.main.async { self?.isLoading = false }
                    return
                }

                // Proactively check current user data
                if !userData.username.isEmpty {
                    print("✅ Current user username: \(userData.username)")
                }
                else {
                    print("⚠️ Current user has EMPTY username!")
                }

                // Load your own user data - make sure we have the most current data
                self?.users[userId] = userData

                // Create an array that includes both your ID and your friends' IDs
                var allUserIds = userData.friends
                allUserIds.append(userId)  // Add your own userId to the query

                // NEW: Load all user data FIRST using a DispatchGroup before proceeding
                let group = DispatchGroup()
                var usernames: [String: String] = [:]

                for friendId in allUserIds {
                    group.enter()

                    self?.firebaseManager.db.collection("users").document(friendId)
                        .getDocument { document, error in
                            defer { group.leave() }

                            if let error = error {
                                print(
                                    "❌ Error loading user \(friendId): \(error.localizedDescription)"
                                )
                                return
                            }

                            // Try to get username
                            if let userData = document?.data(),
                                let username = userData["username"] as? String, !username.isEmpty
                            {
                                print("✅ Loaded username for \(friendId): \(username)")
                                usernames[friendId] = username

                                // Also cache in the users dictionary
                                if let userData = try? document?
                                    .data(as: FirebaseManager.FlipUser.self)
                                {
                                    DispatchQueue.main.async { self?.users[friendId] = userData }
                                }
                            }
                            else {
                                print("⚠️ Failed to load username for \(friendId)")
                            }
                        }
                }

                // Continue loading sessions only after all user data is fetched
                group.notify(queue: .main) {
                    print("👥 Loaded \(usernames.count) usernames")

                    if allUserIds.isEmpty {
                        // If you have no friends, just load your own sessions
                        self?.loadCurrentUserSessions(userId: userId)
                    }
                    else {
                        // Load sessions from both you and your friends
                        self?.loadFriendSessions(userIds: allUserIds)
                    }
                }
            }
    }
    func loadUserData(userId: String, completion: (() -> Void)? = nil) {
        // Skip if we already have this user's data and it has a valid username
        if let existingUser = users[userId],
            !existingUser.username.isEmpty && existingUser.username != "User"
        {
            print("📋 Using cached user data for \(userId): \(existingUser.username)")
            completion?()
            return
        }

        print("🔍 Loading user data for ID: \(userId)")

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let error = error {
                    print("❌ Error loading user data for \(userId): \(error.localizedDescription)")
                    completion?()
                    return
                }

                if let document = document, document.exists {
                    // First try to get raw username data directly
                    let rawData = document.data()

                    if let rawUsername = rawData?["username"] as? String, !rawUsername.isEmpty {
                        print("✅ Found raw username for \(userId): \(rawUsername)")

                        // Try to decode full user data
                        if let userData = try? document.data(as: FirebaseManager.FlipUser.self) {
                            // Verify username isn't empty in decoded data
                            if !userData.username.isEmpty {
                                DispatchQueue.main.async {
                                    self?.users[userId] = userData
                                    print("✅ Stored full user data for: \(userData.username)")
                                }
                            }
                            else {
                                // Username is empty in decoded data, create a fixed version
                                print("⚠️ Username empty in decoded data, creating fixed version")
                                let fixedUser = FirebaseManager.FlipUser(
                                    id: userId,
                                    username: rawUsername,
                                    totalFocusTime: userData.totalFocusTime,
                                    totalSessions: userData.totalSessions,
                                    longestSession: userData.longestSession,
                                    friends: userData.friends,
                                    friendRequests: userData.friendRequests,
                                    sentRequests: userData.sentRequests,
                                    profileImageURL: userData.profileImageURL
                                )

                                DispatchQueue.main.async { self?.users[userId] = fixedUser }
                            }
                        }
                        else {
                            // Couldn't decode full user, create minimal version with username
                            print("⚠️ Couldn't decode full user, creating minimal version")
                            let fallbackUser = FirebaseManager.FlipUser(
                                id: userId,
                                username: rawUsername,
                                totalFocusTime: 0,
                                totalSessions: 0,
                                longestSession: 0,
                                friends: [],
                                friendRequests: [],
                                sentRequests: []
                            )

                            DispatchQueue.main.async { self?.users[userId] = fallbackUser }
                        }
                    }
                    else {
                        print("❌ No valid username for \(userId) in document data")
                    }
                }
                else {
                    print("❌ No user document found for ID: \(userId)")
                }

                completion?()
            }
    }
    func loadUserStreakStatus(userId: String, completion: @escaping (StreakStatus) -> Void) {
        // Check if we already have the status cached
        if let cachedStatus = userStreakStatus[userId] {
            completion(cachedStatus)
            return
        }

        // Otherwise load from Firestore
        firebaseManager.db.collection("users").document(userId).collection("streak")
            .document("current")
            .getDocument { [weak self] snapshot, error in
                var status: StreakStatus = .none

                if let data = snapshot?.data(), let statusString = data["streakStatus"] as? String,
                    let streakStatus = StreakStatus(rawValue: statusString)
                {
                    status = streakStatus

                    // Cache the result
                    DispatchQueue.main.async { self?.userStreakStatus[userId] = status }
                }

                // Return the status
                completion(status)
            }
    }
    func getUserStreakStatus(userId: String) -> StreakStatus {
        return userStreakStatus[userId] ?? .none
    }
    func getUser(for userId: String) -> FirebaseManager.FlipUser {
        // Return the user if we have it, otherwise return a default user
        // We attempt to get the cached data first
        if let cachedUser = users[userId],
            !cachedUser.username.isEmpty && cachedUser.username != "User"
        {
            return cachedUser
        }

        // If we don't have it cached, make sure we load it for next time
        // Use a higher priority for this immediate request
        DispatchQueue.global(qos: .userInitiated).async { self.loadUserData(userId: userId) }

        // Return a placeholder user until the data loads
        // Use userId prefix as fallback for better identification
        let userIdPrefix = String(userId.prefix(4))
        return FirebaseManager.FlipUser(
            id: userId,
            username: "User \(userIdPrefix)",
            totalFocusTime: 0,
            totalSessions: 0,
            longestSession: 0,
            friends: [],
            friendRequests: [],
            sentRequests: []
        )
    }
    func preloadUserData(for sessions: [Session]) {
        print("Preloading user data for \(sessions.count) sessions")
        let dispatchGroup = DispatchGroup()

        // Create a set of all user IDs needed (to avoid duplicates)
        var userIds = Set<String>()

        for session in sessions {
            userIds.insert(session.userId)
            dispatchGroup.enter()
            loadUserStreakStatus(userId: session.userId) { _ in dispatchGroup.leave() }

            if let commentorId = session.commentorId { userIds.insert(commentorId) }

            // Include participants from group sessions
            if let participants = session.participants {
                for participant in participants {
                    userIds.insert(participant.id)
                    dispatchGroup.enter()
                    loadUserStreakStatus(userId: participant.id) { _ in dispatchGroup.leave() }
                }
            }
        }

        print("Need to load \(userIds.count) unique users")

        // Load each user in parallel but track with dispatch group
        for userId in userIds {
            dispatchGroup.enter()
            loadUserData(userId: userId) { dispatchGroup.leave() }
        }

        // After all users are loaded, refresh the UI
        dispatchGroup.notify(queue: .main) { [weak self] in
            print("✅ Completed preloading user data")
            self?.objectWillChange.send()
        }
    }
    private func loadFriendSessions(userIds: [String]) {
        // Remove any existing listeners
        cleanupLikesListeners()
        cleanupCommentsListeners()

        // Remove existing session listener
        sessionListener?.remove()

        print("Loading sessions for users: \(userIds)")
        var localProcessedSessionIds = Set<String>()

        // Create a Set to track unique session IDs we've already processed
        //        var processedSessionIds = Set<String>()

        sessionListener = firebaseManager.db.collection("sessions")
            .whereField("userId", in: userIds).order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                        print("Error loading sessions: \(error.localizedDescription)")
                    }
                    else if let documents = snapshot?.documents {
                        print("Loaded \(documents.count) sessions")

                        // Process documents into sessions, filtering out duplicates
                        var uniqueSessions: [Session] = []

                        for document in documents {
                            guard let session = try? document.data(as: Session.self) else {
                                continue
                            }

                            let sessionId = session.id.uuidString

                            // First check against our global session ID set
                            if !self.globalProcessedSessionIds.contains(sessionId)
                                && !localProcessedSessionIds.contains(sessionId)
                            {
                                self.globalProcessedSessionIds.insert(sessionId)
                                localProcessedSessionIds.insert(sessionId)
                                uniqueSessions.append(session)
                            }
                            else {
                                print("Skipping duplicate session ID: \(sessionId)")
                            }
                        }

                        // Sort by start time, newest first
                        uniqueSessions.sort { $0.startTime > $1.startTime }

                        if self.feedSessions.isEmpty {
                            self.feedSessions = uniqueSessions
                        }
                        else {
                            // Add new sessions from this batch that aren't already in feedSessions
                            for session in uniqueSessions {
                                if !self.feedSessions.contains(where: { $0.id == session.id }) {
                                    self.feedSessions.append(session)
                                }
                            }
                            // Re-sort the combined list
                            self.feedSessions.sort { $0.startTime > $1.startTime }
                        }
                        // Preload all user data before loading other session data
                        self.preloadUserData(for: self.feedSessions)

                        // After loading sessions, load all associated data
                        self.loadAllSessionData()
                    }
                    self.isLoading = false
                }
            }
    }

    // Update the loadCurrentUserSessions method similarly
    private func loadCurrentUserSessions(userId: String) {
        // Remove any existing listeners
        cleanupLikesListeners()
        cleanupCommentsListeners()

        // Remove existing session listener
        sessionListener?.remove()

        print("Loading sessions for user: \(userId)")

        // Create a Set to track unique session IDs we've already processed
        var processedSessionIds = Set<String>()

        sessionListener = firebaseManager.db.collection("sessions")
            .whereField("userId", isEqualTo: userId).order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                        print("Error loading sessions: \(error.localizedDescription)")
                    }
                    else if let documents = snapshot?.documents {
                        print("Loaded \(documents.count) sessions")

                        // Process documents into sessions, filtering out duplicates
                        var uniqueSessions: [Session] = []

                        for document in documents {
                            guard let session = try? document.data(as: Session.self) else {
                                continue
                            }

                            let sessionId = session.id.uuidString

                            // Only add the session if we haven't seen this ID before
                            if !processedSessionIds.contains(sessionId) {
                                processedSessionIds.insert(sessionId)
                                uniqueSessions.append(session)
                            }
                            else {
                                print("Skipping duplicate session ID: \(sessionId)")
                            }
                        }

                        // Sort by start time, newest first
                        uniqueSessions.sort { $0.startTime > $1.startTime }

                        self.feedSessions = uniqueSessions

                        // After loading sessions, load all associated data
                        self.loadAllSessionData()
                    }
                    self.isLoading = false
                }
            }
    }
    func loadCommentsForSession(_ sessionId: String) {
        // Remove any existing listener
        commentsListeners[sessionId]?.remove()

        // Create a new listener for comments
        let listener = firebaseManager.db.collection("sessions").document(sessionId)
            .collection("comments").order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    // Parse comments
                    self.sessionComments[sessionId] = documents.compactMap { document in
                        guard let userId = document.data()["userId"] as? String,
                            let username = document.data()["username"] as? String,
                            let comment = document.data()["comment"] as? String,
                            let timestamp = document.data()["timestamp"] as? Timestamp
                        else { return nil }

                        return SessionComment(
                            id: document.documentID,
                            sessionId: sessionId,
                            userId: userId,
                            username: username,
                            comment: comment,
                            timestamp: timestamp.dateValue()
                        )
                    }

                    // Trigger UI update
                    self.objectWillChange.send()
                }
            }

        // Store the listener for cleanup
        commentsListeners[sessionId] = listener
    }

    // Add this method to add a new comment (instead of updating)
    func addComment(sessionId: String, comment: String, userId: String, username: String) {
        guard !comment.isEmpty else { return }

        // First, get the session details to find the session owner
        firebaseManager.db.collection("sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error getting session for comment: \(error.localizedDescription)")
                    return
                }

                guard let sessionData = document?.data(),
                    let sessionOwnerId = sessionData["userId"] as? String
                else {
                    print("Invalid session data for comment")
                    return
                }

                // Create comment data
                let commentData: [String: Any] = [
                    "userId": userId, "username": username, "comment": comment,
                    "timestamp": Timestamp(date: Date()),
                ]

                // Add to the comments subcollection
                self.firebaseManager.db.collection("sessions").document(sessionId)
                    .collection("comments")
                    .addDocument(data: commentData) { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.showError = true
                                self.errorMessage =
                                    "Failed to save comment: \(error.localizedDescription)"
                                print("Error saving comment: \(error.localizedDescription)")
                            }
                        }
                        else {
                            print("Comment saved successfully")

                            // Send notification to session owner if it's not the current user
                            if sessionOwnerId != userId {
                                self.sendCommentNotification(
                                    to: sessionOwnerId,
                                    from: userId,
                                    fromUsername: username,
                                    comment: comment
                                )
                            }

                            // Explicitly reload the comments for this session
                            DispatchQueue.main.async { self.loadCommentsForSession(sessionId) }
                        }
                    }
            }
    }
    private func sendCommentNotification(
        to recipientId: String,
        from senderId: String,
        fromUsername: String,
        comment: String
    ) {
        // Create notification data
        let notificationData: [String: Any] = [
            "type": "comment", "fromUserId": senderId, "fromUsername": fromUsername,
            "timestamp": Timestamp(date: Date()), "comment": comment, "read": false,
            "silent": false,  // This makes it not vibrate/sound but still show badge & banner
        ]

        // Add to the recipient's notifications collection
        firebaseManager.db.collection("users").document(recipientId).collection("notifications")
            .addDocument(data: notificationData) { error in
                if let error = error {
                    print("Error creating comment notification: \(error.localizedDescription)")
                }
                else {
                    print("Comment notification sent to user: \(recipientId)")
                }
            }
    }
    func deleteComment(sessionId: String, commentId: String) {
        firebaseManager.db.collection("sessions").document(sessionId).collection("comments")
            .document(commentId)
            .delete { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage =
                            "Failed to delete comment: \(error.localizedDescription)"
                    }
                }
            }
    }

    // Add this method to cleanup listeners
    func cleanupCommentsListeners() {
        for (_, listener) in commentsListeners { listener.remove() }
        commentsListeners.removeAll()
    }

    func cleanupLikesListeners() {
        for (_, listener) in likesListeners { listener.remove() }
        likesListeners.removeAll()
    }

    // Original comment method - kept for backward compatibility
    func saveComment(sessionId: String, comment: String) {
        guard !comment.isEmpty, let _currentUserId = Auth.auth().currentUser?.uid else { return }

        // Update the Firestore document
        firebaseManager.db.collection("sessions").document(sessionId)
            .updateData(["comment": comment]) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = "Failed to save comment: \(error.localizedDescription)"
                    }
                }
            }
    }

    // New method to save comment with commentor information
    func saveCommentWithUser(sessionId: String, comment: String, userId: String, username: String) {
        guard !comment.isEmpty else { return }

        // Store more information about the comment
        let commentData: [String: Any] = [
            "comment": comment, "commentorId": userId, "commentorName": username,
            "commentTime": Timestamp(date: Date()),
        ]

        // Update the Firestore document
        firebaseManager.db.collection("sessions").document(sessionId)
            .updateData(commentData) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = "Failed to save comment: \(error.localizedDescription)"
                    }
                }
            }
    }
    func loadAllSessionData() {
        print("Loading data for all visible sessions")

        // First clean up any existing listeners
        cleanupCommentsListeners()
        cleanupLikesListeners()

        // IMPROVED: Load user data for all visible sessions first
        var userIds = Set(feedSessions.map { $0.userId })

        // Add commentor IDs if they exist
        for session in feedSessions {
            if let commentorId = session.commentorId { userIds.insert(commentorId) }

            // Also include participants from group sessions
            if let participants = session.participants {
                let filteredParticipants = participants.filter { participant in
                    participant.id != Auth.auth().currentUser?.uid
                }
                for participant in filteredParticipants { userIds.insert(participant.id) }
            }
        }

        print("Preloading user data for \(userIds.count) users")

        // Load all user data first
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()
            loadUserData(userId: userId) { dispatchGroup.leave() }
        }

        // Then load likes and comments for each visible session
        dispatchGroup.notify(queue: .main) {
            print("User data preloading complete, loading session data")
            for session in self.feedSessions {
                let sessionId = session.id.uuidString

                // Load likes
                self.loadLikesForSession(sessionId)

                // Load comments
                self.loadCommentsForSession(sessionId)
            }
        }
    }

    func likeSession(sessionId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        // Create a unique ID for the like document
        let likeId = "\(sessionId)_\(currentUserId)"
        let likeRef = firebaseManager.db.collection("likes").document(likeId)

        print("Processing like toggle for session: \(sessionId), user: \(currentUserId)")

        // Check if user already liked this session
        likeRef.getDocument { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error checking like status: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                // User already liked the session, so unlike it
                print("Unlike action: Removing existing like")
                likeRef.delete { error in
                    if let error = error {
                        print("Error removing like: \(error.localizedDescription)")
                    }
                    else {
                        print("Like removed successfully")

                        // Don't update UI here - let the listener handle it
                        // This prevents race conditions
                    }
                }
            }
            else {
                // User hasn't liked the session yet, so add a like
                print("Like action: Adding new like")
                let timestamp = Timestamp(date: Date())

                // Get user data for display
                let username = self.users[currentUserId]?.username ?? "User"

                // Store like data
                let likeData: [String: Any] = [
                    "userId": currentUserId, "username": username, "sessionId": sessionId,
                    "timestamp": timestamp,
                ]

                likeRef.setData(likeData) { error in
                    if let error = error {
                        print("Error adding like: \(error.localizedDescription)")
                    }
                    else {
                        print("Like added successfully")

                    }
                }
            }
        }
    }

    // Improved method to load likes
    func loadLikesForSession(_ sessionId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        print("Loading likes for session: \(sessionId)")

        // Remove any existing listener
        likesListeners[sessionId]?.remove()

        // Create a listener for this session's likes
        let listener = firebaseManager.db.collection("likes")
            .whereField("sessionId", isEqualTo: sessionId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error loading likes: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No likes found for session: \(sessionId)")
                    // Initialize with empty data
                    DispatchQueue.main.async {
                        self.sessionLikes[sessionId] = 0
                        self.likedByUser[sessionId] = false
                        self.likesUsers[sessionId] = []
                        self.objectWillChange.send()
                    }
                    return
                }

                print("Found \(documents.count) likes for session: \(sessionId)")

                DispatchQueue.main.async {
                    // Get all user IDs who liked this session
                    let userIds = documents.compactMap { document -> String? in
                        return document.data()["userId"] as? String
                    }

                    // Update the session likes info
                    self.sessionLikes[sessionId] = userIds.count
                    self.likedByUser[sessionId] = userIds.contains(currentUserId)
                    self.likesUsers[sessionId] = userIds

                    // Trigger UI update
                    self.objectWillChange.send()
                }
            }

        // Store the listener for cleanup
        likesListeners[sessionId] = listener
    }

    // Get likes count for a session
    func getLikesForSession(sessionId: String) -> Int { return sessionLikes[sessionId] ?? 0 }

    // Check if current user liked a session
    func isLikedByUser(sessionId: String) -> Bool { return likedByUser[sessionId] ?? false }

    // Get users who liked a session
    func getLikeUsers(sessionId: String, completion: @escaping ([FirebaseManager.FlipUser]) -> Void)
    {
        let userIds = likesUsers[sessionId] ?? []

        if userIds.isEmpty {
            completion([])
            return
        }

        // For small lists, we can use our cached user data
        var likeUsers: [FirebaseManager.FlipUser] = []
        var missingUserIds: [String] = []

        for userId in userIds {
            if let user = users[userId] {
                likeUsers.append(user)
            }
            else {
                missingUserIds.append(userId)
            }
        }

        // If we have all users cached, return them
        if missingUserIds.isEmpty {
            completion(likeUsers)
            return
        }

        // Otherwise, load missing users from Firestore
        let group = DispatchGroup()

        for userId in missingUserIds {
            group.enter()

            firebaseManager.db.collection("users").document(userId)
                .getDocument { [weak self] document, error in
                    if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                        likeUsers.append(userData)

                        // Cache the user for future use
                        self?.users[userId] = userData
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) { completion(likeUsers) }
    }

    deinit {
        sessionListener?.remove()
        cleanupLikesListeners()
        cleanupCommentsListeners()
    }
}
