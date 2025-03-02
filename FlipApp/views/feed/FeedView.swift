import FirebaseAuth
import SwiftUI

struct FeedView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var viewModel = FeedViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Text("FEED")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
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
                            NavigationFeedSessionCard(
                                session: session,
                                viewModel: viewModel
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
            .onAppear {
                viewModel.loadFeed()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Empty state component
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Theme.buttonGradient)
                    .frame(width: 80, height: 80)
                    .opacity(0.2)
                
                Image(systemName: "person.2")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
            }

            Text("No Sessions Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

            Text("Add friends to see their focus sessions")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
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
    @FocusState private var isCommentFocused: Bool
    private var userProfileImageURL: String? {
            return viewModel.users[session.userId]?.profileImageURL
        }
    
    init(session: Session, viewModel: FeedViewModel) {
        self.session = session
        self.viewModel = viewModel
        // Initialize comment with existing value
        self._comment = State(initialValue: session.comment ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top section with user profile link
            NavigationLink(destination: UserProfileView(user: viewModel.getUser(for: session.userId))) {
                HStack(spacing: 12) {
                                    // Profile pic - replace with ProfileAvatarView
                                    ProfileAvatarView(
                                        imageURL: userProfileImageURL,
                                        size: 40,
                                        username: session.username
                                    )
                        
                    // Username and time
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
            .buttonStyle(PlainButtonStyle())
            
            // Session info (moved down from the header)
            HStack {
                Text("\(session.duration) min session")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                
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
            
            // Show actual duration if session failed
            if !session.wasSuccessful {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    Text("Lasted \(session.actualDuration) min")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Divider for visual separation
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 4)
            
            // Session title and notes if available
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
                    
                    Text(comment)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
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
                
                // Vertical layout for participants instead of horizontal
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
            
            // Comment button
            HStack {
                Spacer()
                
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
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
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
class FeedViewModel: ObservableObject {
    @Published var feedSessions: [Session] = []
    @Published var users: [String: FirebaseManager.FlipUser] = [:]
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    private let firebaseManager = FirebaseManager.shared

    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

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
        firebaseManager.db.collection("sessions")
            .whereField("userId", in: userIds)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self?.feedSessions = documents.compactMap { document in
                            try? document.data(as: Session.self)
                        }
                    }
                    self?.isLoading = false
                }
            }
    }
    // Add this to the FeedViewModel class

    func saveComment(sessionId: String, comment: String) {
        guard !comment.isEmpty, let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find the session in our local collection
        if let index = feedSessions.firstIndex(where: { $0.id.uuidString == sessionId }) {
            // Update the Firestore document
            firebaseManager.db.collection("sessions")
                .document(sessionId)
                .updateData(["comment": comment]) { [weak self] error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.showError = true
                            self?.errorMessage = "Failed to save comment: \(error.localizedDescription)"
                        }
                    } else {
                        // Update our local copy
                        DispatchQueue.main.async {
                            // The listener will automatically update the feedSessions array,
                            // but we don't need to do anything here explicitly
                        }
                    }
                }
        }
    }
    
    // This is for the case when you have no friends but still want to see your own sessions
    private func loadCurrentUserSessions(userId: String) {
        firebaseManager.db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showError = true
                        self?.errorMessage = error.localizedDescription
                    } else if let documents = snapshot?.documents {
                        self?.feedSessions = documents.compactMap { document in
                            try? document.data(as: Session.self)
                        }
                    }
                    self?.isLoading = false
                }
            }
    }
}
