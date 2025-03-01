import SwiftUI

struct FeedSessionCard: View {
    let session: Session
    let viewModel: FeedViewModel
    let showUserHeader: Bool
    @State private var showCommentField = false
    @State private var comment: String = ""
    @State private var showSavedIndicator = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isCommentFocused: Bool
    
    // Update initializer with optional parameter
    init(session: Session, viewModel: FeedViewModel, showUserHeader: Bool = true) {
        self.session = session
        self.viewModel = viewModel
        self.showUserHeader = showUserHeader
        // Initialize comment with existing value
        self._comment = State(initialValue: session.comment ?? "")
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
        return session.sessionTitle != nil || session.sessionNotes != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info - only show if requested
            if showUserHeader {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.buttonGradient)
                            .frame(width: 40, height: 40)
                            .opacity(0.2)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                        Text(session.formattedStartTime)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
            }
            
            // Right side action buttons
            HStack {
                Spacer()
                
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
                .padding(.trailing, 6)

                // Status Icon with enhanced styling - made larger
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 44, height: 44)
                        .opacity(0.8)
                    
                    Image(systemName: session.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .shadow(color: session.wasSuccessful ? Color.green.opacity(0.5) : Color.red.opacity(0.5), radius: 4)
                }
            }

            // Session duration info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(session.duration) min session")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                if !session.wasSuccessful {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text("Lasted \(session.actualDuration) min")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Session title and notes if available
            if hasContent {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Session Title if available
                    if let title = session.sessionTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
                            .lineLimit(2)
                    }
                    
                    // Session Notes if available
                    if let notes = session.sessionNotes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal, 3)
            }
            
            // Comment if available
            if let comment = session.comment, !comment.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, 2)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(comment)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                }
                .padding(.horizontal, 3)
                .padding(.top, 2)
            }
            
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
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping on the card
            if isCommentFocused {
                isCommentFocused = false
            }
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

// ParticipantBadges displays the participants in a group session
struct ParticipantBadges: View {
    let participants: [Session.Participant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("GROUP SESSION")
                .font(.system(size: 12, weight: .medium))
                .tracking(1)
                .foregroundColor(.white.opacity(0.7))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(participants) { participant in
                        GroupParticipantBadge(
                            username: participant.username,
                            wasSuccessful: participant.wasSuccessful
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 4)
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
                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6) :
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
                    .fill(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.8), lineWidth: 1)
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