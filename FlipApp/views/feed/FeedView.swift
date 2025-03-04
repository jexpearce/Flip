import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("FEED")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                        .padding(.top, 20)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                            .padding(.top, 50)
                    } else if viewModel.feedSessions.isEmpty {
                        // Empty state view
                        EmptyFeedView()
                    } else {
                        // Session cards
                        ForEach(viewModel.feedSessions) { session in
                            FeedSessionCard(
                                session: session,
                                viewModel: viewModel
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 26/255, green: 14/255, blue: 47/255),
                        Color(red: 48/255, green: 30/255, blue: 103/255),
                        Color(red: 26/255, green: 14/255, blue: 47/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .onAppear {
                viewModel.loadFeed()
            }
            .refreshable {
                viewModel.loadFeed()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 26/255, green: 14/255, blue: 47/255),
                    Color(red: 48/255, green: 30/255, blue: 103/255),
                    Color(red: 26/255, green: 14/255, blue: 47/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Empty state component
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.pink.opacity(0.3), Theme.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                
                Image(systemName: "doc.text.image")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
            }

            Text("No Sessions Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 6)

            Text("Add friends to see their focus sessions in your feed")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                // Navigate to Friends view or show Friend search
                NotificationCenter.default.post(
                    name: Notification.Name("SwitchToFriendsTab"),
                    object: nil
                )
            }) {
                Text("Find Friends")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.pink.opacity(0.7), Theme.purple.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Theme.purple.opacity(0.3), radius: 5)
            }
        }
        .padding(.top, 50)
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
                NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
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
                    NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                        Text(session.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(session.formattedStartTime)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Status icon
                ZStack {
                    Circle()
                        .fill(session.wasSuccessful ?
                              LinearGradient(colors: [Color.green, Color.green.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.red, Color.red.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Session info
            HStack {
                Text("\(session.duration) min session")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                if !session.wasSuccessful {
                    Text("• Lasted \(session.actualDuration) min")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Content sections - only if content exists
            if let title = session.sessionTitle, !title.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            if let notes = session.sessionNotes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            // Existing comment display
            if let comment = session.comment, !comment.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                            Text(session.username)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(comment)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                }
                .padding(.top, 2)
            }
            
            // Participant list for group sessions
            if let participants = session.participants, !participants.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 4)
                
                Text("GROUP SESSION")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                // Vertical layout for participants
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(participants) { participant in
                        NavigationLink(
                            destination: UserProfileView(user: viewModel.getUser(for: participant.id))
                        ) {
                            HStack(spacing: 8) {
                                // Small profile icon
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(participant.username)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Success/failure icon
                                Image(systemName: participant.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
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
                Button(action: {
                    showLikesSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.pink.opacity(0.8))
                        
                        if likesCount == 1 {
                            Text("1 like")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("\(likesCount) likes")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
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
                    } else if likesCount > 0 {
                        likesCount -= 1
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(isLiked ? Theme.pink : .white)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 6)
                
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
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: session.comment != nil ? "text.bubble.fill" : "text.bubble")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
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
                    onSubmit: { newComment in
                        saveComment(newComment)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        session.wasSuccessful ?
                        LinearGradient(
                            colors: [
                                Color(red: 26/255, green: 32/255, blue: 58/255).opacity(0.9),
                                Color(red: 17/255, green: 54/255, blue: 71/255).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        :
                        LinearGradient(
                            colors: [
                                Color(red: 45/255, green: 21/255, blue: 38/255).opacity(0.9),
                                Color(red: 26/255, green: 32/255, blue: 58/255).opacity(0.8)
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
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping on the card
            if isCommentFocused {
                isCommentFocused = false
            }
        }
        .popover(isPresented: $showLikesSheet, arrowEdge: .top) {
            CompactLikesListView(sessionId: session.id.uuidString, likesCount: likesCount, viewModel: viewModel)
        }
        .onAppear {
            updateLikeState()
        }
        .onChange(of: viewModel.likedByUser[session.id.uuidString]) { newValue in
            updateLikeState()
        }
        .onChange(of: viewModel.sessionLikes[session.id.uuidString]) { newValue in
            updateLikeState()
        }
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
        withAnimation {
            showSavedIndicator = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
                showCommentField = false
            }
        }
    }
}
struct SessionComment: Codable, Identifiable {
    var id: String // Document ID
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
        } else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
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
    @Published var sessionComments: [String: [SessionComment]] = [:] // Map session ID to comments array
    private var commentsListeners: [String: ListenerRegistration] = [:]
    @Published var sessionLikes: [String: Int] = [:] // Map session ID to like count
    @Published var likedByUser: [String: Bool] = [:] // Map session ID to whether current user liked it
    @Published var likesUsers: [String: [String]] = [:] // Map session ID to array of user IDs who liked it
    
    private let firebaseManager = FirebaseManager.shared
    private var likesListeners: [String: ListenerRegistration] = [:]

    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        cleanupLikesListeners()
        cleanupCommentsListeners()

        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                        self?.isLoading = false
                    }
                    return
                }

                guard
                    let userData = try? document?.data(
                        as: FirebaseManager.FlipUser.self)
                else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    return
                }

                // Load your own user data - make sure we have the most current data
                self?.users[userId] = userData
                
                // Create an array that includes both your ID and your friends' IDs
                var allUserIds = userData.friends
                allUserIds.append(userId) // Add your own userId to the query
                
                // Load latest user data for all friends - this ensures we have up-to-date stats
                for friendId in userData.friends {
                    self?.loadUserData(userId: friendId)
                }
                
                if allUserIds.isEmpty {
                    // If you have no friends, just load your own sessions
                    self?.loadCurrentUserSessions(userId: userId)
                } else {
                    // Load sessions from both you and your friends
                    self?.loadFriendSessions(userIds: allUserIds)
                }
            }
    }
    
    func loadUserData(userId: String) {
        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    DispatchQueue.main.async {
                        self?.users[userId] = userData
                    }
                }
            }
    }
    
    func getUser(for userId: String) -> FirebaseManager.FlipUser {
        // Return the user if we have it, otherwise return a default user
        // We attempt to get the cached data first
        if let cachedUser = users[userId] {
            return cachedUser
        }
        
        // If we don't have it cached, make sure we load it for next time
        loadUserData(userId: userId)
        
        // Return a placeholder user until the data loads
        return FirebaseManager.FlipUser(
            id: userId,
            username: "User",
            totalFocusTime: 0,
            totalSessions: 0,
            longestSession: 0,
            friends: [],
            friendRequests: [],
            sentRequests: []
        )
    }
    
    private func loadFriendSessions(userIds: [String]) {
        // Remove any existing listeners
        cleanupLikesListeners()
        
        firebaseManager.db.collection("sessions")
            .whereField("userId", in: userIds)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self.feedSessions = documents.compactMap { document in
                            try? document.data(as: Session.self)
                        }
                        
                        // Load like data for each session
                        for session in self.feedSessions {
                            self.loadLikesForSession(session.id.uuidString)
                        }
                    }
                    self.isLoading = false
                }
            }
    }
    
    private func loadCurrentUserSessions(userId: String) {
        // Remove any existing listeners
        cleanupLikesListeners()
        
        firebaseManager.db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        self.showError = true
                        self.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self.feedSessions = documents.compactMap { document in
                            try? document.data(as: Session.self)
                        }
                        
                        // Load like data for each session
                        for session in self.feedSessions {
                            self.loadLikesForSession(session.id.uuidString)
                        }
                    }
                    self.isLoading = false
                }
            }
    }
    
    private func loadLikesForSession(_ sessionId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Create a listener for this session's likes
        let listener = firebaseManager.db.collection("likes")
            .whereField("sessionId", isEqualTo: sessionId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    return
                }
                
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
    func loadCommentsForSession(_ sessionId: String) {
        // Remove any existing listener
        commentsListeners[sessionId]?.remove()
        
        // Create a new listener for comments
        let listener = firebaseManager.db.collection("sessions")
            .document(sessionId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else {
                    return
                }
                
                DispatchQueue.main.async {
                    // Parse comments
                    self.sessionComments[sessionId] = documents.compactMap { document in
                        guard let userId = document.data()["userId"] as? String,
                              let username = document.data()["username"] as? String,
                              let comment = document.data()["comment"] as? String,
                              let timestamp = document.data()["timestamp"] as? Timestamp else {
                            return nil
                        }
                        
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
        
        // Create comment data
        let commentData: [String: Any] = [
            "userId": userId,
            "username": username,
            "comment": comment,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Add to the comments subcollection
        firebaseManager.db.collection("sessions")
                .document(sessionId)
                .collection("comments")
                .addDocument(data: commentData) { [weak self] error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showError = true
                            self?.errorMessage = "Failed to save comment: \(error.localizedDescription)"
                            print("Error saving comment: \(error.localizedDescription)")
                        }
                    } else {
                        print("Comment saved successfully")
                        
                        // Explicitly reload the comments for this session
                        DispatchQueue.main.async {
                            self?.loadCommentsForSession(sessionId)
                        }
                    }
                }
        }
    func deleteComment(sessionId: String, commentId: String) {
        firebaseManager.db.collection("sessions")
            .document(sessionId)
            .collection("comments")
            .document(commentId)
            .delete { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showError = true
                        self?.errorMessage = "Failed to delete comment: \(error.localizedDescription)"
                    }
                }
            }
    }

    // Add this method to cleanup listeners
    func cleanupCommentsListeners() {
        for (_, listener) in commentsListeners {
            listener.remove()
        }
        commentsListeners.removeAll()
    }
    
    private func cleanupLikesListeners() {
        for (_, listener) in likesListeners {
            listener.remove()
        }
        likesListeners.removeAll()
    }

    // Original comment method - kept for backward compatibility
    func saveComment(sessionId: String, comment: String) {
        guard !comment.isEmpty, let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Update the Firestore document
        firebaseManager.db.collection("sessions")
            .document(sessionId)
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
            "comment": comment,
            "commentorId": userId,
            "commentorName": username,
            "commentTime": Timestamp(date: Date())
        ]
        
        // Update the Firestore document
        firebaseManager.db.collection("sessions")
            .document(sessionId)
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
        
        // Then load likes and comments for each visible session
        for session in feedSessions {
            let sessionId = session.id.uuidString
            
            // Load likes
            loadLikesForSession(sessionId)
            
            // Load comments
            loadCommentsForSession(sessionId)
        }
    }
    
    
    // Like/unlike a session
    func likeSession(sessionId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Create a unique ID for the like document
        let likeId = "\(sessionId)_\(currentUserId)"
        let likeRef = firebaseManager.db.collection("likes").document(likeId)
        
        // Check if user already liked this session
        likeRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // User already liked the session, so unlike it
                likeRef.delete { error in
                    if let error = error {
                        print("Error removing like: \(error.localizedDescription)")
                    }
                }
            } else {
                // User hasn't liked the session yet, so add a like
                let timestamp = Timestamp(date: Date())
                
                // Get user data for display
                let username = self.users[currentUserId]?.username ?? "User"
                
                // Store like data
                let likeData: [String: Any] = [
                    "userId": currentUserId,
                    "username": username,
                    "sessionId": sessionId,
                    "timestamp": timestamp
                ]
                
                likeRef.setData(likeData) { error in
                    if let error = error {
                        print("Error adding like: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Get likes count for a session
    func getLikesForSession(sessionId: String) -> Int {
        return sessionLikes[sessionId] ?? 0
    }
    
    
    // Check if current user liked a session
    func isLikedByUser(sessionId: String) -> Bool {
        return likedByUser[sessionId] ?? false
    }
    
    // Get users who liked a session
    func getLikeUsers(sessionId: String, completion: @escaping ([FirebaseManager.FlipUser]) -> Void) {
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
            } else {
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
            
            firebaseManager.db.collection("users").document(userId).getDocument { [weak self] document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    likeUsers.append(userData)
                    
                    // Cache the user for future use
                    self?.users[userId] = userData
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(likeUsers)
        }
    }
    
    deinit {
        cleanupLikesListeners()
        cleanupCommentsListeners()
    }
}