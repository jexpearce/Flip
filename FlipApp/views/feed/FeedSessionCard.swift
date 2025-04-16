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
                userHeaderView
                sessionInfoSection
                contentSectionsView
                commentSectionView
                groupParticipantsView
                actionButtonsView
                commentFieldView
            }
            .padding(.vertical, 18).padding(.horizontal, 18)
        }
        .background(cardBackground).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
        .onAppear(perform: onAppearSetup)
        .onDisappear {
            // Remove keyboard observers
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: viewModel.likedByUser[session.id.uuidString]) { updateLikeState() }
        .onChange(of: viewModel.sessionLikes[session.id.uuidString]) { updateLikeState() }
    }
    // MARK: - View Components

    private var userHeaderView: some View {
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
            statusIconView
        }
    }
    private var statusIconView: some View {
        ZStack {
            Circle().fill(statusColor).frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                .shadow(color: statusGlow, radius: 5)

            // Status icon
            Image(systemName: session.wasSuccessful ? "checkmark" : "xmark")
                .font(.system(size: 16, weight: .black)).foregroundColor(.white)
        }
    }
    private var sessionInfoSection: some View {
        // Session info section
        HStack {
            Text(sessionStatusText).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                .shadow(color: statusGlow.opacity(0.5), radius: 4)

            if !session.wasSuccessful {
                Text("• Lasted \(session.actualDuration) min").font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
    private var contentSectionsView: some View {
        Group {
            if hasContent {
                VStack(alignment: .leading, spacing: 8) {
                    if let title = session.sessionTitle, !title.isEmpty {
                        Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            .lineLimit(2)
                    }

                    if let notes = session.sessionNotes, !notes.isEmpty {
                        Text(notes).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading).lineLimit(3)
                    }
                }
                .padding(.vertical, 10).padding(.horizontal, 12).background(contentBackground)
            }
        }
    }
    private var contentBackground: some View {
        ZStack {
            // Glass effect background
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))

            // Highlight on top edge
            RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                .fill(Color.white.opacity(0.08)).rotationEffect(.degrees(180)).padding(1)

            // Subtle border
            RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        }
    }
    private var commentSectionView: some View {
        Group {
            if hasComment || (viewModel.sessionComments[session.id.uuidString]?.count ?? 0) > 0 {
                CommentsView(session: session, viewModel: viewModel).padding(.vertical, 6)
            }
        }
    }
    private var groupParticipantsView: some View {
        Group {
            if hasGroupParticipants {
                VStack(alignment: .leading, spacing: 10) {
                    // Header with subtle glow
                    Text(groupSessionTitle).font(.system(size: 12, weight: .bold)).tracking(2)
                        .foregroundColor(
                            session.wasSuccessful
                                ? Theme.mutedGreen.opacity(0.9) : Theme.mutedRed.opacity(0.9)
                        )
                        .shadow(color: statusGlow.opacity(0.4), radius: 4)

                    // Add description text
                    Text(groupSessionDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 4)

                    // Horizontal scrolling participant badges
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // First show the current user (session owner)
                            NavigationLink(
                                destination: UserProfileLoader(userId: session.userId)
                            ) {
                                GroupParticipantBadge(
                                    username: viewModel.users[session.userId]?.username ?? "You",
                                    status: session.wasSuccessful ? "completed" : "failed"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Then show the session starter if different from current user
                            if let originalStarterId = session.originalStarterId, session.userId != originalStarterId {
                                let starterName = viewModel.users[originalStarterId]?.username ?? "Host"
                                
                                NavigationLink(
                                    destination: UserProfileLoader(userId: originalStarterId)
                                ) {
                                    GroupParticipantBadge(
                                        username: starterName + " (Host)",
                                        status: getStatusForParticipant(originalStarterId)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Show all participants with status
                            ForEach(session.participants ?? [], id: \.userId) { participant in
                                // Skip if this is already the main user or original starter displayed above
                                if participant.userId != session.userId && participant.userId != session.originalStarterId {
                                    NavigationLink(
                                        destination: UserProfileLoader(userId: participant.userId)
                                    ) {
                                        GroupParticipantBadge(
                                            username: viewModel.users[participant.userId]?.username ?? "User",
                                            status: participant.status
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 2).padding(.bottom, 2)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
    private var actionButtonsView: some View {
        // Action buttons and likes section with improved styling
        VStack(spacing: 10) {
            // Like info section with enhanced styling
            likeInfoSection
            Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)

            // Action buttons with enhanced styling
            actionButtonsRow
        }
        .padding(.top, 4)
    }
    private var likeInfoSection: some View {
        Group {
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
                            Text("\(likesCount) likes").font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    private var actionButtonsRow: some View {
        HStack(spacing: 20) {
            // Like button
            likeButton
            // Comment button
            commentButton
            Spacer()
        }
    }
    private var likeButton: some View {
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
    }
    private var commentButton: some View {
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
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(.white.opacity(0.9))

                Text("Comment").font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    private var commentFieldView: some View {
        Group {
            if showCommentField {
                CommentInputField(
                    comment: $comment,
                    isFocused: _isCommentFocused,
                    showSavedIndicator: $showSavedIndicator,
                    showCommentField: $showCommentField,
                    onSubmit: { newComment in saveComment() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity)).padding(.top, 12)
            }
        }
    }
    private var cardBackground: some View {
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

    // Group session title that shows who started it
    private var groupSessionTitle: String {
        let username = viewModel.users[session.userId]?.username ?? "User"
        
        if let originalStarterId = session.originalStarterId {
            if originalStarterId == session.userId {
                // This person started the session
                return "GROUP SESSION STARTER"
            } else {
                // This person joined someone else's session
                let starterName = viewModel.users[originalStarterId]?.username ?? "User"
                return "JOINED \(starterName.uppercased())'S SESSION"
            }
        } else {
            // Fallback if originalStarterId is not available
            return "GROUP SESSION"
        }
    }

    // Group session description below the title
    private var groupSessionDescription: String {
        let username = viewModel.users[session.userId]?.username ?? "User"
        
        if let originalStarterId = session.originalStarterId {
            if originalStarterId == session.userId {
                // This person started the session
                return "Started a group session"
            } else {
                // This person joined someone else's session
                let starterName = viewModel.users[originalStarterId]?.username ?? "Someone"
                return "Joined \(starterName)'s session"
            }
        } else {
            // Fallback if originalStarterId is not available
            return "Participated in a group session"
        }
    }

    // MARK: - Helper Methods

    private func onAppearSetup() {
        // Update like state when the view appears
        updateLikeState()

        // Load user's streak status
        viewModel.loadUserStreakStatus(userId: session.userId) { status in
            self.userStreakStatus = status
        }

        setupKeyboardNotifications()
    }
    private func setupKeyboardNotifications() {
        // Set up keyboard notifications
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect
            {
                keyboardHeight = keyboardFrame.height
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in keyboardHeight = 0 }
    }

    private func updateLikeState() {
        let sessionId = session.id.uuidString

        // Get like status from viewModel
        isLiked = viewModel.isLikedByUser(sessionId: sessionId)
        likesCount = viewModel.getLikesForSession(sessionId: sessionId)
    }

    private func saveComment() {
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

    // Implementation of the getStatusForParticipant method
    private func getStatusForParticipant(_ userId: String) -> String? {
        // First check if the participant is in the participants array
        if let participants = session.participants {
            for participant in participants {
                if participant.userId == userId {
                    return participant.status
                }
            }
        }
        
        // If this is the session creator but they're not in participants
        if userId == session.originalStarterId {
            // Assume active unless we know better
            return "active"
        }
        
        // Default to nil if we can't determine status
        return nil
    }
}
// Enhanced individual participant badge
struct GroupParticipantBadge: View {
    let username: String
    let status: String? // "completed", "failed", "active" or nil
    
    var body: some View {
        HStack(spacing: 6) {
            // Status indicator with improved styling
            statusIcon
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(statusColor)
                .shadow(color: statusColor.opacity(0.6), radius: 4)

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
    
    // Determine the appropriate icon based on status
    private var statusIcon: Image {
        if let status = status {
            switch status {
            case "completed":
                return Image(systemName: "checkmark.circle.fill")
            case "failed":
                return Image(systemName: "xmark.circle.fill")
            case "active":
                return Image(systemName: "clock.fill")
            default:
                return Image(systemName: "person.circle.fill")
            }
        } else {
            return Image(systemName: "person.circle.fill")
        }
    }
    
    // Determine the appropriate color based on status
    private var statusColor: Color {
        if let status = status {
            switch status {
            case "completed":
                return Theme.mutedGreen
            case "failed":
                return Theme.mutedRed
            case "active":
                return Color.blue
            default:
                return Color.gray
            }
        } else {
            return Color.gray
        }
    }
}
