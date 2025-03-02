import SwiftUI
import FirebaseAuth

struct FeedSessionCard: View {
    let session: Session
    let viewModel: FeedViewModel
    let showUserHeader: Bool
    @State private var showCommentField = false
    @State private var comment: String = ""
    @State private var showSavedIndicator = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0
    @State private var showLikesSheet = false
    @FocusState private var isCommentFocused: Bool
    
    // Update initializer with optional parameter
    init(session: Session, viewModel: FeedViewModel, showUserHeader: Bool = true) {
        self.session = session
        self.viewModel = viewModel
        self.showUserHeader = showUserHeader
        // Initialize comment with existing value
        self._comment = State(initialValue: session.comment ?? "")
        
        // Initialize likes from the viewModel
        let sessionId = session.id.uuidString
        self._isLiked = State(initialValue: viewModel.isLikedByUser(sessionId: sessionId))
        self._likesCount = State(initialValue: viewModel.getLikesForSession(sessionId: sessionId))
    }
    
    private var cardGradient: LinearGradient {
        if session.wasSuccessful {
            return LinearGradient(
                colors: [
                    Color(red: 26/255, green: 32/255, blue: 58/255).opacity(0.9),
                    Color(red: 17/255, green: 54/255, blue: 71/255).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 45/255, green: 21/255, blue: 38/255).opacity(0.9),
                    Color(red: 26/255, green: 32/255, blue: 58/255).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var statusColor: LinearGradient {
        session.wasSuccessful ?
            LinearGradient(
                colors: [
                    Color(red: 34/255, green: 197/255, blue: 94/255),
                    Color(red: 22/255, green: 163/255, blue: 74/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            ) :
            LinearGradient(
                colors: [
                    Color(red: 239/255, green: 68/255, blue: 68/255),
                    Color(red: 185/255, green: 28/255, blue: 28/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    private var hasContent: Bool {
        return (session.sessionTitle != nil && !session.sessionTitle!.isEmpty) ||
               (session.sessionNotes != nil && !session.sessionNotes!.isEmpty)
    }
    
    private var hasComment: Bool {
        return (session.comment != nil && !session.comment!.isEmpty) ||
               (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0
    }
    
    private var hasGroupParticipants: Bool {
        return session.participants != nil && !session.participants!.isEmpty && session.participants!.count > 1
    }
    
    private var userProfileImageURL: String? {
        return viewModel.users[session.userId]?.profileImageURL
    }
    
    private var currentUserName: String {
        guard let userId = Auth.auth().currentUser?.uid else { return "You" }
        return viewModel.users[userId]?.username ?? "You"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with user info and action buttons
            HStack(spacing: 12) {
                // Left side: User info - only show if requested
                if showUserHeader {
                    NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                        ProfileAvatarView(
                            imageURL: userProfileImageURL,
                            size: 40,
                            username: session.username
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    VStack(alignment: .leading, spacing: 2) {
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
                }

                Spacer()
                
                // Right side: Status icon
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 36, height: 36)
                        .opacity(0.8)
                    
                    Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Session info section
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
            if hasContent {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = session.sessionTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    if let notes = session.sessionNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Comment section - using the improved CommentView component
            if hasComment || (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0 {
                CommentsView(session: session, viewModel: viewModel)
            }
            
            // Group session participants - only if it's a group session
            if hasGroupParticipants {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GROUP SESSION")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(session.participants!) { participant in
                                NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: participant.id))) {
                                    GroupParticipantBadge(
                                        username: participant.username,
                                        wasSuccessful: participant.wasSuccessful
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Action buttons and likes section
            VStack(spacing: 8) {
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
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    // Like button
                    Button(action: {
                        // Toggle like state via ViewModel
                        viewModel.likeSession(sessionId: session.id.uuidString)
                        
                        // Update local state for immediate UI feedback
                        isLiked.toggle()
                        
                        // Update the count for immediate feedback
                        // (this will be properly updated when the Firestore listener fires)
                        if isLiked {
                            likesCount += 1
                        } else if likesCount > 0 {
                            likesCount -= 1
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(isLiked ? Theme.pink : .white)
                            
                            Text("Like")
                                .font(.system(size: 14))
                                .foregroundColor(isLiked ? Theme.pink : .white.opacity(0.9))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
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
                        HStack(spacing: 4) {
                            Image(systemName: hasComment ? "text.bubble.fill" : "text.bubble")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Text("Comment")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
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
                        // Save comment
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
                    .fill(cardGradient)
                
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
            // Update like state when the view appears
            updateLikeState()
            
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                keyboardHeight = 0
            }
        }
        .onDisappear {
            // Remove keyboard observers
            NotificationCenter.default.removeObserver(self)
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
        guard !comment.isEmpty else { return }
        
        // Get the current user's ID and name
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Get the current user's name for the comment
        let commentorName = currentUserName
        
        // Save comment to new subcollection
        viewModel.addComment(
            sessionId: session.id.uuidString,
            comment: newComment,
            userId: currentUserId,
            username: commentorName
        )
        
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

// Individual participant badge
struct GroupParticipantBadge: View {
    let username: String
    let wasSuccessful: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(wasSuccessful ? .green : .red)
            
            Text(username)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Comment input field component
struct CommentInputField: View {
    @Binding var comment: String
    @FocusState var isFocused: Bool
    @Binding var showSavedIndicator: Bool
    @Binding var showCommentField: Bool
    var onSubmit: (String) -> Void
    
    private let maxChars = 100
    
    var body: some View {
        VStack(spacing: 8) {
            // Break down the HStack into more manageable chunks
            HStack {
                // Comment input field
                commentInputContainer
                
                // Character count
                characterCountView
            }
            
            // Action buttons
            actionButtonsView
        }
        .padding(10)
        .background(
            backgroundContainer
        )
    }
    
    private var commentInputContainer: some View {
        ZStack(alignment: .topLeading) {
            placeholderText
            
            TextEditor(text: $comment)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(4)
                .frame(height: 80)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: comment) { newValue in
                    if newValue.count > maxChars {
                        comment = String(newValue.prefix(maxChars))
                    }
                }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isFocused ?
                            Theme.lightTealBlue.opacity(0.6) :
                                Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private var placeholderText: some View {
        Group {
            if comment.isEmpty {
                Text("Add a comment (100 chars max)...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 8)
                    .padding(.leading, 8)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var characterCountView: some View {
        Text("\(comment.count)/\(maxChars)")
            .font(.system(size: 12))
            .foregroundColor(
                comment.count > maxChars * Int(0.8) ? .orange : .white
                    .opacity(0.6)
            )
            .frame(width: 50)
    }
    
    private var actionButtonsView: some View {
        HStack {
            Spacer()
            
            // Cancel button
            cancelButton
            
            // Submit button
            submitButton
        }
    }
    
    private var cancelButton: some View {
        Button(action: {
            isFocused = false
            withAnimation(.spring()) {
                showCommentField = false
            }
        }) {
            Text("Cancel")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            isFocused = false
            onSubmit(comment)
        }) {
            HStack {
                if showSavedIndicator {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                } else {
                    Text("Save")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(width: 70)
            .background(
                Capsule()
                    .fill(Theme.lightTealBlue.opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(Theme.lightTealBlue.opacity(0.8), lineWidth: 1)
                    )
            )
        }
        .disabled(comment.isEmpty || comment.count > maxChars)
        .opacity(comment.isEmpty ? 0.5 : 1.0)
    }
    
    private var backgroundContainer: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
struct CompactLikesListView: View {
    let sessionId: String
    let likesCount: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [FirebaseManager.FlipUser] = []
    @State private var isLoading = true
    let viewModel: FeedViewModel
    
    init(sessionId: String, likesCount: Int, viewModel: FeedViewModel = FeedViewModel()) {
        self.sessionId = sessionId
        self.likesCount = likesCount
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("\(likesCount) \(likesCount == 1 ? "Like" : "Likes")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding()
            } else if users.isEmpty {
                Text("No likes yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Users list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileView(user: user)) {
                                HStack(spacing: 12) {
                                    // Profile image
                                    ProfileAvatarView(
                                        imageURL: user.profileImageURL,
                                        size: 36,
                                        username: user.username
                                    )
                                    
                                    // Username
                                    Text(user.username)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .frame(maxHeight: 300) // Limit the height for compact display
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 26/255, green: 14/255, blue: 47/255),
                    Color(red: 48/255, green: 30/255, blue: 103/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: 280)
        .cornerRadius(16)
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        
        viewModel.getLikeUsers(sessionId: sessionId) { likeUsers in
            self.users = likeUsers
            self.isLoading = false
        }
    }
}
// Replace the existing CommentView with this one
// Updated CommentsView with the fixed CommentBubble
struct CommentsView: View {
    let session: Session
    let viewModel: FeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Display existing comments from sessionComments
            if let comments = viewModel.sessionComments[session.id.uuidString], !comments.isEmpty {
                ForEach(comments) { comment in
                    CommentBubble(comment: comment, viewModel: viewModel)
                }
            }
            // For backward compatibility, handle legacy comment field
            else if let comment = session.comment, !comment.isEmpty {
                // Legacy comment
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Check if we have commentor information
                        if let commentorId = session.commentorId, let commentorName = session.commentorName {
                            // Display the comment with the correct user
                            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: commentorId))) {
                                Text(commentorName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(comment)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                            
                            // Show comment time if available
                            if let commentTime = session.commentTime {
                                Text(formatTime(commentTime))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        } else {
                            // Legacy comments without user info - show session owner
                            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                                Text(session.username)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(comment)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            // Load comments when view appears
            viewModel.loadCommentsForSession(session.id.uuidString)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// Add a new component for individual comments
// Update the CommentBubble with delete functionality
struct CommentBubble: View {
    let comment: SessionComment
    let viewModel: FeedViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: comment.userId))) {
                    Text(comment.username)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(comment.comment)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                
                Text(comment.formattedTime)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make the entire area tappable
        .onLongPressGesture(minimumDuration: 0.5) {
            // Only show delete option if comment belongs to current user
            if comment.userId == Auth.auth().currentUser?.uid {
                showDeleteAlert = true
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Comment"),
                message: Text("Are you sure you want to delete this comment?"),
                primaryButton: .destructive(Text("Delete")) {
                    // Delete the comment
                    viewModel.deleteComment(sessionId: comment.sessionId, commentId: comment.id)
                },
                secondaryButton: .cancel()
            )
        }
    }
}