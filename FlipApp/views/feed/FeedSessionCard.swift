import FirebaseAuth
import SwiftUI

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
    @State private var isHovering = false  // For hover effect
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

    private var userProfileImageURL: String? {
        return viewModel.users[session.userId]?.profileImageURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card content with padding
            VStack(alignment: .leading, spacing: 14) {
                // Top section with user info and action buttons
                HStack(spacing: 12) {
                    // Left side: User info - only show if requested
                    if showUserHeader {
                        NavigationLink(destination: UserProfileLoader(userId: session.userId)) {
                            // UPDATED: Simplified avatar with streak - no outer ring
                            EnhancedProfileAvatarWithStreak(
                                imageURL: userProfileImageURL,
                                size: 46,
                                username: session.username,
                                streakStatus: viewModel.getUserStreakStatus(userId: session.userId)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        VStack(alignment: .leading, spacing: 2) {
                            NavigationLink(destination: UserProfileLoader(userId: session.userId)) {
                                Text(session.username).font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(session.formattedStartTime).font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Spacer()

                    // Right side: Status icon
                    ZStack {
                        Circle().fill(statusColor).frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                            .shadow(color: statusGlow, radius: 5)

                        // Status icon
                        Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                            .font(.system(size: 16, weight: .black)).foregroundColor(.white)
                    }
                }

                // Rest of the card content remains the same
                // ... (existing code for session info, content sections, etc.)

                // Session info section
                HStack {
                    Text(sessionStatusText).font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white).shadow(color: statusGlow.opacity(0.5), radius: 4)

                    if !session.wasSuccessful {
                        Text("• Lasted \(session.actualDuration) min").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .padding(.vertical, 6)

                // Content sections - Enhanced with better styling
                if hasContent {
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = session.sessionTitle, !title.isEmpty {
                            Text(title).font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white).lineLimit(2)
                        }

                        if let notes = session.sessionNotes, !notes.isEmpty {
                            Text(notes).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading).lineLimit(3)
                        }
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    .background(
                        ZStack {
                            // Glass effect background
                            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))

                            // Highlight on top edge
                            RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180))
                                .padding(1)

                            // Subtle border
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        }
                    )
                }

                // Comment section with improved visual design
                if hasComment || (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0
                {
                    CommentsView(session: session, viewModel: viewModel).padding(.vertical, 6)
                }

                // Group session participants with enhanced visual style
                if hasGroupParticipants {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header with subtle glow
                        Text("GROUP SESSION").font(.system(size: 12, weight: .bold)).tracking(2)
                            .foregroundColor(
                                session.wasSuccessful
                                    ? Theme.mutedGreen.opacity(0.9) : Theme.mutedRed.opacity(0.9)
                            )
                            .shadow(color: statusGlow.opacity(0.4), radius: 4)

                        // Horizontal scrolling participant badges
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(session.participants!) { participant in
                                    NavigationLink(
                                        destination: UserProfileLoader(userId: participant.id)
                                    ) {
                                        GroupParticipantBadge(
                                            username: participant.username,
                                            wasSuccessful: participant.wasSuccessful
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 2).padding(.bottom, 2)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // Action buttons and likes section with improved styling
                VStack(spacing: 10) {
                    // Like info section with enhanced styling
                    if likesCount > 0 {
                        Button(action: { showLikesSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill").font(.system(size: 12))
                                    .foregroundColor(Theme.orange.opacity(0.9))

                                if likesCount == 1 {
                                    Text("1 like").font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                else {
                                    Text("\(likesCount) likes")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)

                    // Action buttons with enhanced styling
                    HStack(spacing: 20) {
                        // Like button
                        Button(action: {
                            // Toggle like state via ViewModel
                            viewModel.likeSession(sessionId: session.id.uuidString)

                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isLiked ? Theme.orange : .white.opacity(0.9))

                                Text("Like").font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isLiked ? Theme.orange : .white.opacity(0.9))
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
                                }
                                else {
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

                                Text("Comment").font(.system(size: 14, weight: .medium))
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
                        onSubmit: { newComment in saveComment(newComment) }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity)).padding(.top, 12)
                }
            }
            .padding(.vertical, 18).padding(.horizontal, 18)
        }
        .background(
            ZStack {
                // Base gradient background
                RoundedRectangle(cornerRadius: 20).fill(cardGradient)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),  // More visible at top
                        Color.white.opacity(0.0),  // Fades to invisible at 1/3 down
                    ],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.2)  // End at 30% down the card
                )
                .mask(RoundedRectangle(cornerRadius: 20))

                // Subtle glass effect overlay
                RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05))

                // Top highlight for glass effect
                RoundedRectangle(cornerRadius: 20).trim(from: 0, to: 0.5)
                    .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

                // Glowing border based on session status
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                session.wasSuccessful
                                    ? Theme.mutedGreen.opacity(0.3) : Theme.mutedRed.opacity(0.3),
                                Color.white.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )

                // Subtle indicator at the top
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        session.wasSuccessful
                            ? Theme.mutedGreen.opacity(0.8) : Theme.mutedRed.opacity(0.8)
                    )
                    .frame(width: 40, height: 3).padding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .shadow(color: statusGlow.opacity(0.2), radius: 15, x: 0, y: 5).contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping on the card
            if isCommentFocused { isCommentFocused = false }
        }
        .onHover { hovering in  // Only works on macOS/iPadOS
            withAnimation(.easeInOut(duration: 0.2)) { isHovering = hovering }
        }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .popover(isPresented: $showLikesSheet, arrowEdge: .top) {
            CompactLikesListView(
                sessionId: session.id.uuidString,
                likesCount: likesCount,
                viewModel: viewModel
            )
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
                if let keyboardFrame = notification.userInfo?[
                    UIResponder.keyboardFrameEndUserInfoKey
                ] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }

            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in keyboardHeight = 0 }
        }
        .onDisappear {
            // Remove keyboard observers
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: viewModel.likedByUser[session.id.uuidString]) { updateLikeState() }
        .onChange(of: viewModel.sessionLikes[session.id.uuidString]) { updateLikeState() }
    }

    // MARK: - Helper Properties

    // Enhanced gradient based on session success/failure
    private var cardGradient: LinearGradient {
        if session.wasSuccessful {
            return Theme.successGradient
        }
        else {
            return Theme.nonSuccessGradient
        }
    }

    // Enhanced status indicator colors
    private var statusColor: LinearGradient {
        session.wasSuccessful
            ? LinearGradient(
                colors: [Theme.mutedGreen, Theme.darkerGreen],
                startPoint: .top,
                endPoint: .bottom
            ) : Theme.redGradient
    }

    // Status glow color
    private var statusGlow: Color {
        session.wasSuccessful ? Theme.mutedGreen.opacity(0.6) : Theme.mutedRed.opacity(0.6)
    }

    // Helper properties for content checks
    private var hasContent: Bool {
        return (session.sessionTitle != nil && !session.sessionTitle!.isEmpty)
            || (session.sessionNotes != nil && !session.sessionNotes!.isEmpty)
    }

    private var hasComment: Bool {
        return (session.comment != nil && !session.comment!.isEmpty)
            || (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0
    }

    private var hasGroupParticipants: Bool {
        return session.participants != nil && !session.participants!.isEmpty
            && session.participants!.count > 1
    }

    private var currentUserName: String {
        guard let userId = Auth.auth().currentUser?.uid else { return "You" }
        return viewModel.users[userId]?.username ?? "You"
    }

    // Session status text
    private var sessionStatusText: String {
        if session.wasSuccessful {
            return "Completed \(session.duration) min session"
        }
        else {
            return "Attempted \(session.duration) min session"
        }
    }

    // MARK: - Helper Methods

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
        withAnimation { showSavedIndicator = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
                showCommentField = false
                isCommentFocused = false
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
                .foregroundColor(wasSuccessful ? Theme.mutedGreen : Theme.mutedRed)
                .shadow(
                    color: wasSuccessful
                        ? Theme.mutedGreen.opacity(0.6) : Theme.mutedRed.opacity(0.6),
                    radius: 4
                )

            Text(username).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))

                // Top highlight
                RoundedRectangle(cornerRadius: 12).trim(from: 0, to: 0.5)
                    .fill(Color.white.opacity(0.1)).rotationEffect(.degrees(180)).padding(1)

                // Subtle border
                RoundedRectangle(cornerRadius: 12).stroke(Theme.silveryGradient3, lineWidth: 1)
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
        .padding(12).background(backgroundView).shadow(color: Color.black.opacity(0.1), radius: 4)
    }

    // MARK: - Subviews

    private var commentEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if comment.isEmpty { placeholderText }

            // Text editor
            editorField
        }
        .background(editorBackground)
    }

    private var placeholderText: some View {
        Text("Add a comment (100 chars max)...").font(.system(size: 14))
            .foregroundColor(.white.opacity(0.4)).padding(.top, 8).padding(.leading, 8)
            .allowsHitTesting(false)
    }

    private var editorField: some View {
        TextEditor(text: $comment).font(.system(size: 14)).foregroundColor(.white).padding(4)
            .frame(height: 80).focused($isFocused).scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: comment) {
                if comment.count > maxChars { comment = String(comment.prefix(maxChars)) }
            }
    }

    private var editorBackground: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2))

            // Glass effect
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))

            // Highlight on top
            RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

            // Focus/active border
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isFocused ? Theme.mutedGreen.opacity(0.6) : Color.white.opacity(0.2),
                    lineWidth: 1
                )
        }
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
        Text("\(comment.count)/\(maxChars)").font(.system(size: 12))
            .foregroundColor(
                comment.count > maxChars * Int(0.8) ? Theme.orange : .white.opacity(0.6)
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
            Text("Cancel").font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    ZStack {
                        // Base shape
                        Capsule().fill(Color.black.opacity(0.3))

                        // Glass effect
                        Capsule().fill(Color.white.opacity(0.05))

                        // Subtle border
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var submitButton: some View {
        Button(action: {
            isFocused = false
            let currentComment = comment  // Capture current comment
            onSubmit(currentComment)  // Pass the comment
        }) { submitButtonContent }
        .disabled(comment.isEmpty || comment.count > maxChars).opacity(comment.isEmpty ? 0.5 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }

    private var submitButtonContent: some View {
        HStack {
            if showSavedIndicator {
                Image(systemName: "checkmark").font(.system(size: 12, weight: .bold))
            }
            else {
                Text("Save").font(.system(size: 14, weight: .medium))
            }
        }
        .foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8).frame(width: 70)
        .background(submitButtonBackground)
    }

    private var submitButtonBackground: some View {
        ZStack {
            // Base gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Theme.mutedGreen.opacity(0.7), Theme.darkerGreen.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Glass effect
            Capsule().fill(Color.white.opacity(0.1))

            // Highlight on top
            Capsule().trim(from: 0, to: 0.5).fill(Color.white.opacity(0.15))
                .rotationEffect(.degrees(180)).padding(1)

            // Subtle border
            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
        }
        .shadow(color: Theme.mutedGreen.opacity(0.4), radius: 4)
    }

    private var backgroundView: some View {
        ZStack {
            // Base shape
            RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.3))

            // Glass effect
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))

            // Highlight on top
            RoundedRectangle(cornerRadius: 14).trim(from: 0, to: 0.5)
                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

            // Subtle border
            RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
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
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .shadow(color: Theme.orange.opacity(0.4), radius: 4)

                Spacer()

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.2))

            if isLoading {
                // Enhanced loading indicator
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ZStack {
                            // Glowing circle behind spinner
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Theme.orange.opacity(0.3), Theme.orange.opacity(0.0),
                                        ]),
                                        center: .center,
                                        startRadius: 1,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60).blur(radius: 8)

                            // Spinner
                            ProgressView().tint(Theme.orange).scaleEffect(1.2)
                        }

                        Text("Loading likes...").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            }
            else if users.isEmpty {
                // Enhanced empty state
                VStack(spacing: 10) {
                    ZStack {
                        // Faded heart background
                        Circle().fill(Theme.orange.opacity(0.15)).frame(width: 60, height: 60)
                            .blur(radius: 10)

                        Image(systemName: "heart.slash").font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 4)

                    Text("No likes yet").font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 30)
            }
            else {
                // Enhanced users list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileLoader(userId: user.id)) {
                                HStack(spacing: 12) {
                                    // Enhanced profile image
                                    ProfileAvatarView(
                                        imageURL: user.profileImageURL,
                                        size: 40,
                                        username: user.username
                                    )
                                    .overlay(Circle().stroke(Theme.silveryGradient3, lineWidth: 1))

                                    // Username with subtle shadow
                                    Text(user.username).font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1)

                                    Spacer()

                                    // Enhanced chevron indicator
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        // Glass background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.05))

                                        // Highlight on top
                                        RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                                            .fill(Color.white.opacity(0.08))
                                            .rotationEffect(.degrees(180)).padding(1)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            if users.last?.id != user.id {
                                Divider().background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)  // Limit the height for compact display
            }
        }
        .background(
            ZStack {
                // Base gradient
                Theme.baseGradient

                // Glass effect
                Color.white.opacity(0.05)

                // Border
                RoundedRectangle(cornerRadius: 16).stroke(Theme.silveryGradient3, lineWidth: 1)
            }
        )
        .cornerRadius(16).shadow(color: Color.black.opacity(0.3), radius: 20).frame(width: 300)
        .onAppear { loadUsers() }
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
        VStack(alignment: .leading, spacing: 8) {
            // Display existing comments from sessionComments
            if let comments = viewModel.sessionComments[session.id.uuidString], !comments.isEmpty {
                ForEach(comments) { comment in
                    CommentBubble(comment: comment, viewModel: viewModel).padding(.vertical, 2)
                }
            }
            // For backward compatibility, handle legacy comment field
            else if let comment = session.comment, !comment.isEmpty {
                // Legacy comment handling with enhanced styling
                HStack(alignment: .top, spacing: 10) {
                    // Comment icon bubble with glow
                    ZStack {
                        Circle().fill(Theme.lightTealBlue.opacity(0.2)).frame(width: 28, height: 28)

                        Image(systemName: "text.bubble.fill").font(.system(size: 14))
                            .foregroundColor(Theme.lightTealBlue.opacity(0.8))
                            .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Check if we have commentor information
                        if let commentorId = session.commentorId,
                            let commentorName = session.commentorName
                        {
                            // Keep the NavigationLink inside this scope where commentorId is defined
                            NavigationLink(destination: UserProfileLoader(userId: commentorId)) {
                                Text(commentorName).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                                    .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(comment).font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9)).lineLimit(3)
                                .padding(.vertical, 2)

                            // Show comment time if available
                            if let commentTime = session.commentTime {
                                Text(formatTime(commentTime)).font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5)).padding(.top, 2)
                            }
                        }
                        else {
                            // Legacy comments without user info - show session owner
                            NavigationLink(destination: UserProfileLoader(userId: session.userId)) {
                                Text(session.username).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                                    .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(comment).font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9)).lineLimit(3)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.vertical, 4)
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
        }
        else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        else {
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
                // Glow effect
                Circle().fill(Theme.lightTealBlue.opacity(0.15)).frame(width: 32, height: 32)
                    .blur(radius: 4)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.lightTealBlue.opacity(0.3), Theme.darkTealBlue.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                // Icon
                Image(systemName: "text.bubble.fill").font(.system(size: 14))
                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Username with enhanced styling
                NavigationLink(destination: UserProfileLoader(userId: comment.userId)) {
                    Text(comment.username).font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                        .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                }
                .buttonStyle(PlainButtonStyle())

                // Comment text with enhanced styling
                Text(comment.comment).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                    .lineLimit(4).padding(.vertical, 2)

                // Comment time with subtle styling
                Text(comment.formattedTime).font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Delete button (only shows on long press for own comments)
            if showDeleteConfirm && comment.userId == Auth.auth().currentUser?.uid {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash").font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8)).padding(6)
                        .background(
                            ZStack {
                                // Glass background
                                Circle().fill(Color.black.opacity(0.3))

                                // Subtle border
                                Circle().stroke(Color.red.opacity(0.3), lineWidth: 1)
                            }
                        )
                }
                .transition(.scale.combined(with: .opacity)).buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))
                .opacity(showDeleteConfirm ? 0.3 : 0)
        )
        .contentShape(Rectangle())  // Make the entire area tappable
        .onLongPressGesture(minimumDuration: 0.5) {
            // Only show delete option if comment belongs to current user
            if comment.userId == Auth.auth().currentUser?.uid {
                withAnimation(.spring()) { showDeleteConfirm = true }

                // Auto-hide after 3 seconds if not tapped
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring()) { showDeleteConfirm = false }
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
                secondaryButton: .cancel { showDeleteConfirm = false }
            )
        }
    }
}
