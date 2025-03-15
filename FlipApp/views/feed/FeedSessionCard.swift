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
    @State private var isHovering = false // For hover effect
    @State private var userStreakStatus: StreakStatus = .none
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
    
    // Enhanced gradient based on session success/failure
    private var cardGradient: LinearGradient {
        if session.wasSuccessful {
            return LinearGradient(
                colors: [
                    Color(red: 10/255, green: 28/255, blue: 45/255).opacity(0.95),
                    Color(red: 12/255, green: 40/255, blue: 60/255).opacity(0.9),
                    Color(red: 20/255, green: 44/255, blue: 55/255).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 45/255, green: 25/255, blue: 40/255).opacity(0.95),
                    Color(red: 35/255, green: 24/255, blue: 48/255).opacity(0.9),
                    Color(red: 25/255, green: 20/255, blue: 45/255).opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Enhanced status indicator colors
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
    
    // Status glow color
    private var statusGlow: Color {
        session.wasSuccessful ?
            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.6) :
            Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.6)
    }
    
    // Helper properties for content checks
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
    
    // Session status text - UPDATED as requested
    private var sessionStatusText: String {
        if session.wasSuccessful {
            return "Completed \(session.duration) min session"
        } else {
            return "Attempted \(session.duration) min session"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card content with padding
            VStack(alignment: .leading, spacing: 12) {
                // Top section with user info and action buttons
                HStack(spacing: 12) {
                    // Left side: User info - only show if requested
                    if showUserHeader {
                        NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                                ProfileAvatarWithStreak(
                                    imageURL: userProfileImageURL,
                                    size: 44,
                                    username: session.username,
                                    streakStatus: viewModel.getUserStreakStatus(userId: session.userId)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .shadow(color: statusGlow.opacity(0.3), radius: 6)
                            }
                            .buttonStyle(PlainButtonStyle())

                        VStack(alignment: .leading, spacing: 2) {
                            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                                Text(session.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: statusGlow.opacity(0.5), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(session.formattedStartTime)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()
                    
                    // Right side: Status icon with enhanced design
                    ZStack {
                        // Larger glow behind the status icon
                        Circle()
                            .fill(statusGlow.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .blur(radius: 8)
                        
                        // Status background with gradient
                        Circle()
                            .fill(statusColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: statusGlow, radius: 5)
                        
                        // Status icon
                        Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 1)
                    }
                }
                .padding(.bottom, 4)
                
                // Session info section - UPDATED TEXT LOGIC HERE
                HStack {
                    // Using the new sessionStatusText computed property
                    Text(sessionStatusText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: statusGlow.opacity(0.5), radius: 4)
                    
                    if !session.wasSuccessful {
                        Text("• Lasted \(session.actualDuration) min")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                // Content sections - Enhanced with better styling
                if hasContent {
                    VStack(alignment: .leading, spacing: 6) {
                        if let title = session.sessionTitle, !title.isEmpty {
                            Text(title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                        
                        if let notes = session.sessionNotes, !notes.isEmpty {
                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .padding(.bottom, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
                
                // Comment section with improved visual design
                if hasComment || (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0 {
                    CommentsView(session: session, viewModel: viewModel)
                        .padding(.vertical, 4)
                }
                
                // Group session participants with enhanced visual style
                if hasGroupParticipants {
                    VStack(alignment: .leading, spacing: 8) {
                        // Header with subtle glow
                        Text("GROUP SESSION")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(2)
                            .foregroundColor(session.wasSuccessful ?
                                            Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.9) :
                                            Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.9))
                            .shadow(color: statusGlow.opacity(0.4), radius: 4)
                        
                        // Horizontal scrolling participant badges
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
                            .padding(.horizontal, 2)
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Action buttons and likes section with improved styling
                VStack(spacing: 8) {
                    // Like info section with enhanced styling
                    if likesCount > 0 {
                        Button(action: {
                            showLikesSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.9))
                                    .shadow(color: Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.5), radius: 4)
                                
                                if likesCount == 1 {
                                    Text("1 like")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Text("\(likesCount) likes")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .padding(.vertical, 4)
                    
                    // Action buttons with enhanced styling
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            // Toggle like state via ViewModel
                            viewModel.likeSession(sessionId: session.id.uuidString)
                            
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Update the count for immediate feedback

                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isLiked ?
                                                    Color(red: 249/255, green: 115/255, blue: 22/255) :
                                                    .white.opacity(0.9))
                                    .shadow(color: isLiked ?
                                           Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.5) :
                                           .clear,
                                           radius: isLiked ? 4 : 0)
                                
                                Text("Like")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isLiked ?
                                                    Color(red: 249/255, green: 115/255, blue: 22/255) :
                                                    .white.opacity(0.9))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Comment button
                        Button(action: {
                            print("Comment button pressed, current state: \(showCommentField)")
                            // Force reset the comment field if it's already in a hidden state
                            withAnimation(.spring()) {
                                if !showCommentField {
                                    comment = ""  // Clear any previous comment text
                                    showCommentField = true
                                    // Focus the comment field after a brief delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isCommentFocused = true
                                    }
                                } else {
                                    showCommentField = false
                                    isCommentFocused = false
                                }
                            }
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: hasComment ? "text.bubble.fill" : "text.bubble")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Comment")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                }
                .padding(.top, 4)
                
                // Comment field with improved styling
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
                    .padding(.top, 12)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .background(
            ZStack {
                // Base gradient background
                RoundedRectangle(cornerRadius: 18)
                    .fill(cardGradient)
                
                // Subtle glass effect overlay
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                
                // Glowing border based on session status - subtler now
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                session.wasSuccessful ?
                                    Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.2) :
                                    Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                
                // Subtle indicator at the top (not a thick line anymore)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .shadow(color: statusGlow.opacity(0.2), radius: 15, x: 0, y: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping on the card
            if isCommentFocused {
                isCommentFocused = false
            }
        }
        .onHover { hovering in // Only works on macOS/iPadOS
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .popover(isPresented: $showLikesSheet, arrowEdge: .top) {
            CompactLikesListView(sessionId: session.id.uuidString, likesCount: likesCount, viewModel: viewModel)
        }
        .onAppear {
                // Update like state when the view appears
                updateLikeState()
                
                // Load user's streak status
                viewModel.loadUserStreakStatus(userId: session.userId) { status in
                    self.userStreakStatus = status
                }
                
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
        
        // Save the comment text before clearing the input
        let commentToSave = comment
        
        // Clear the comment field immediately for UI feedback
        self.comment = ""
        
        // Save comment to new subcollection
        viewModel.addComment(
            sessionId: session.id.uuidString,
            comment: commentToSave,
            userId: currentUserId,
            username: commentorName
        )
        
        // Haptic feedback for successful comment
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Explicitly reload comments after adding
        viewModel.loadCommentsForSession(session.id.uuidString)
        
        // Show the saved indicator
        withAnimation {
            showSavedIndicator = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
                
                // Important: This allows the comment button to be clicked again
                showCommentField = false
                isCommentFocused = false
                
                print("Comment field reset after submission")
            }
        }
    }
}

// Enhanced individual participant badge
struct GroupParticipantBadge: View {
    let username: String
    let wasSuccessful: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            // Status indicator with improved styling
            Image(systemName: wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(wasSuccessful ?
                                Color(red: 34/255, green: 197/255, blue: 94/255) :
                                Color(red: 239/255, green: 68/255, blue: 68/255))
                .shadow(color: wasSuccessful ?
                       Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.6) :
                       Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.6),
                       radius: 4)
            
            Text(username)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                
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
        .shadow(color: Color.black.opacity(0.15), radius: 4)
    }
}


struct CommentInputField: View {
    @Binding var comment: String
    @FocusState var isFocused: Bool
    @Binding var showSavedIndicator: Bool
    @Binding var showCommentField: Bool
    var onSubmit: (String) -> Void
    
    private let maxChars = 100
    
    var body: some View {
        VStack(spacing: 10) {
            // Break down into smaller components
            commentEditorView
            actionButtonsRow
        }
        .padding(12)
        .background(backgroundView)
        .shadow(color: Color.black.opacity(0.1), radius: 4)
    }
    
    // MARK: - Subviews
    
    private var commentEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if comment.isEmpty {
                placeholderText
            }
            
            // Text editor
            editorField
        }
        .background(editorBackground)
    }
    
    private var placeholderText: some View {
        Text("Add a comment (100 chars max)...")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.4))
            .padding(.top, 8)
            .padding(.leading, 8)
            .allowsHitTesting(false)
    }
    
    private var editorField: some View {
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
    
    private var editorBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isFocused ?
                        Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.6) :
                            Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }
    
    private var actionButtonsRow: some View {
        HStack {
            characterCounter
            Spacer()
            cancelButton
            submitButton
        }
    }
    
    private var characterCounter: some View {
        Text("\(comment.count)/\(maxChars)")
            .font(.system(size: 12))
            .foregroundColor(
                comment.count > maxChars * Int(0.8) ?
                    Color(red: 249/255, green: 115/255, blue: 22/255) :
                    .white.opacity(0.6)
            )
    }
    
    private var cancelButton: some View {
        Button(action: {
            isFocused = false
            withAnimation(.spring()) {
                comment = ""  // Clear comment on cancel
                showCommentField = false
            }
            print("Comment cancelled")
        }) {
            Text("Cancel")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var submitButton: some View {
        Button(action: {
            isFocused = false
            let currentComment = comment  // Capture current comment
            onSubmit(currentComment)  // Pass the comment
        }) {
            submitButtonContent
        }
        .disabled(comment.isEmpty || comment.count > maxChars)
        .opacity(comment.isEmpty ? 0.5 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var submitButtonContent: some View {
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
        .background(submitButtonBackground)
    }
    
    private var submitButtonBackground: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.7),
                        Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color(red: 34/255, green: 197/255, blue: 94/255).opacity(0.4), radius: 4)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Enhanced likes list view
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
        VStack(spacing: 0) {
            // Header with enhanced styling
            HStack {
                Text("\(likesCount) \(likesCount == 1 ? "Like" : "Likes")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 249/255, green: 115/255, blue: 22/255).opacity(0.4), radius: 4)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            if isLoading {
                // Enhanced loading indicator
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(Color(red: 249/255, green: 115/255, blue: 22/255))
                            .scaleEffect(1.2)
                        
                        Text("Loading...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            } else if users.isEmpty {
                // Enhanced empty state
                VStack(spacing: 8) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 4)
                    
                    Text("No likes yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            } else {
                // Enhanced users list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileView(user: user)) {
                                HStack(spacing: 12) {
                                    // Enhanced profile image
                                    ProfileAvatarView(
                                        imageURL: user.profileImageURL,
                                        size: 40,
                                        username: user.username
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    
                                    // Username with subtle shadow
                                    Text(user.username)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1)
                                    
                                    Spacer()
                                    
                                    // Enhanced chevron indicator
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    Color.white.opacity(0.05)
                                        .cornerRadius(8)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if users.last?.id != user.id {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300) // Limit the height for compact display
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 23/255, blue: 42/255), // Dark blue-green
                    Color(red: 20/255, green: 36/255, blue: 50/255), // Midnight teal
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20)
        .frame(width: 300)
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

// Enhanced comments view
struct CommentsView: View {
    let session: Session
    let viewModel: FeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Display existing comments from sessionComments
            if let comments = viewModel.sessionComments[session.id.uuidString], !comments.isEmpty {
                ForEach(comments) { comment in
                    CommentBubble(comment: comment, viewModel: viewModel)
                        .padding(.vertical, 2)
                }
            }
            // For backward compatibility, handle legacy comment field
            else if let comment = session.comment, !comment.isEmpty {
                // Legacy comment handling with enhanced styling
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Check if we have commentor information
                        if let commentorId = session.commentorId, let commentorName = session.commentorName {
                            // Display the comment with the correct user
                            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: commentorId))) {
                                Text(commentorName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.9))
                                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
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
                                    .padding(.top, 2)
                            }
                        } else {
                            // Legacy comments without user info - show session owner
                            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                                Text(session.username)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.9))
                                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text(comment)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .onAppear {
            // Load comments when view appears
            print("CommentsView appeared for session: \(session.id.uuidString)")
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

// Enhanced comment bubble component
struct CommentBubble: View {
    let comment: SessionComment
    let viewModel: FeedViewModel
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Comment icon with enhanced styling
            ZStack {
                Circle()
                    .fill(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Username with enhanced styling
                NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: comment.userId))) {
                    Text(comment.username)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.9))
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Comment text with enhanced styling
                Text(comment.comment)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(4)
                    .padding(.vertical, 2)
                
                // Comment time with subtle styling
                Text(comment.formattedTime)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Delete button (only shows on long press for own comments)
            if showDeleteConfirm && comment.userId == Auth.auth().currentUser?.uid {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    Circle()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .transition(.scale.combined(with: .opacity))
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .opacity(showDeleteConfirm ? 0.3 : 0)
        )
        .contentShape(Rectangle()) // Make the entire area tappable
        .onLongPressGesture(minimumDuration: 0.5) {
            // Only show delete option if comment belongs to current user
            if comment.userId == Auth.auth().currentUser?.uid {
                withAnimation(.spring()) {
                    showDeleteConfirm = true
                }
                
                // Auto-hide after 3 seconds if not tapped
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring()) {
                        showDeleteConfirm = false
                    }
                }
                
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
                    withAnimation {
                        viewModel.deleteComment(sessionId: comment.sessionId, commentId: comment.id)
                    }
                    showDeleteConfirm = false
                },
                secondaryButton: .cancel {
                    showDeleteConfirm = false
                }
            )
        }
    }
}
