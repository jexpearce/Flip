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
        return session.comment != nil && !session.comment!.isEmpty
    }
    
    private var hasGroupParticipants: Bool {
        return session.participants != nil && !session.participants!.isEmpty && session.participants!.count > 1
    }
    
    private var userProfileImageURL: String? {
        return viewModel.users[session.userId]?.profileImageURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with user info and action buttons
            HStack(spacing: 12) {
                // Left side: User info - only show if requested
                if showUserHeader {
                    ProfileAvatarView(
                        imageURL: userProfileImageURL,
                        size: 40,
                        username: session.username
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)

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
            
            // Comment section - only if comment exists
            if hasComment {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.username)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                        
                        Text(session.comment!)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                    }
                }
                .padding(.vertical, 4)
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
                                GroupParticipantBadge(
                                    username: participant.username,
                                    wasSuccessful: participant.wasSuccessful
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Action buttons and likes section
            VStack(spacing: 8) {
                // Like info section
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
                        isLiked.toggle()
                        if isLiked {
                            likesCount += 1
                        } else if likesCount > 0 {
                            likesCount -= 1
                        }
                        viewModel.likeSession(sessionId: session.id.uuidString)
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
        .sheet(isPresented: $showLikesSheet) {
            LikesListView(sessionId: session.id.uuidString, likesCount: likesCount)
        }
        .onAppear {
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

// Likes list view
struct LikesListView: View {
    let sessionId: String
    let likesCount: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [MockUser] = []
    
    // Mock struct for demo purposes
    struct MockUser: Identifiable {
        let id = UUID()
        let username: String
        let imageURL: String?
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Likes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            
            // Users list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(users) { user in
                        HStack(spacing: 12) {
                            // Profile image (placeholder)
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Theme.pink.opacity(0.5), Theme.purple.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 40, height: 40)
                                
                                Text(String(user.username.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            // Username
                            Text(user.username)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Spacer()
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
        .onAppear {
        }
    }

}