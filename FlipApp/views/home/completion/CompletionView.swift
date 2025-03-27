import FirebaseAuth
import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showNotes = false
    @State private var showButton = false
    @State private var isGlowing = false
    @State private var isButtonPressed = false

    // State variables for first-time session
    @State private var isFirstSession = false
    @State private var isCheckingFirstSession = true
    @State private var showLeaderboard = false

    // Session notes state variables
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    @State private var showSavingIndicator = false
    @State private var keyboardOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success content
                VStack(spacing: 18) {
                    // Success Icon with animation
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 34 / 255, green: 197 / 255,
                                            blue: 94 / 255
                                        ).opacity(0.3),
                                        Color(
                                            red: 22 / 255, green: 163 / 255,
                                            blue: 74 / 255
                                        ).opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 34 / 255, green: 197 / 255,
                                            blue: 94 / 255),
                                        Color(
                                            red: 22 / 255, green: 163 / 255,
                                            blue: 74 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 34 / 255, green: 197 / 255,
                                    blue: 94 / 255
                                ).opacity(isGlowing ? 0.6 : 0.3),
                                radius: isGlowing ? 15 : 8)
                    }
                    .scaleEffect(showIcon ? 1 : 0)
                    .rotationEffect(.degrees(showIcon ? 0 : -180))

                    // Title with animation
                    Text(
                        isFirstSession
                            ? "FIRST SESSION COMPLETE" : "SESSION COMPLETE"
                    )
                    .font(.system(size: 28, weight: .black))
                    .tracking(6)
                    .foregroundColor(.white)
                    .shadow(
                        color: Color(
                            red: 34 / 255, green: 197 / 255, blue: 94 / 255
                        ).opacity(0.5), radius: 8
                    )
                    .offset(y: showTitle ? 0 : 50)
                    .opacity(showTitle ? 1 : 0)

                    // Stats card with animation
                    VStack(spacing: 15) {
                        Text(
                            isFirstSession
                                ? "Congratulations on your first session!"
                                : "Congratulations!"
                        )
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(
                            Color(
                                red: 250 / 255, green: 204 / 255, blue: 21 / 255
                            ))

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(appManager.selectedMinutes)")
                                .font(.system(size: 50, weight: .black))
                                .foregroundColor(.white)
                                .shadow(
                                    color: Color(
                                        red: 56 / 255, green: 189 / 255,
                                        blue: 248 / 255
                                    ).opacity(0.6), radius: 10)

                            Text("minutes")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 4)
                        }

                        Text("of focused work completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 25)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(
                                                red: 60 / 255, green: 30 / 255,
                                                blue: 110 / 255
                                            ).opacity(0.5),
                                            Color(
                                                red: 40 / 255, green: 20 / 255,
                                                blue: 80 / 255
                                            ).opacity(0.3),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))

                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                }

                // Conditional content: First-time leaderboard or session notes
                if isCheckingFirstSession {
                    // Loading placeholder
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .frame(height: 150)
                        .transition(.opacity)
                } else if isFirstSession {
                    // First-time leaderboard
                    if showLeaderboard,
                        let userId = Auth.auth().currentUser?.uid
                    {
                        FirstTimeLeaderboardView(
                            userId: userId,
                            username: FirebaseManager.shared.currentUser?
                                .username ?? "User",
                            duration: appManager.selectedMinutes,
                            wasSuccessful: true
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                } else if showNotes {
                    // Regular session notes for returning users
                    SessionNotesView(
                        sessionTitle: $sessionTitle,
                        sessionNotes: $sessionNotes
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Back Button with animation and notes saving
                Button(action: {
                    withAnimation(.spring()) {
                        isButtonPressed = true
                        showSavingIndicator = true
                    }

                    // Hide keyboard first
                    hideKeyboard()

                    // For first-time users, set a default title
                    if isFirstSession {
                        let rank = FirstTimeLeaderboardManager.shared.userRank
                        let total = FirstTimeLeaderboardManager.shared
                            .totalUsers
                        sessionTitle =
                            "My First Session!: Ranked \(rank)th of \(total)"
                    }

                    // FIXED: Only save NEW session if it hasn't been recorded already
                    if !appManager.sessionAlreadyRecorded {
                        // Save session with notes
                        sessionManager.addSession(
                            duration: appManager.selectedMinutes,
                            wasSuccessful: true,
                            actualDuration: appManager.selectedMinutes,
                            sessionTitle: sessionTitle.isEmpty
                                ? nil : sessionTitle,
                            sessionNotes: sessionNotes.isEmpty
                                ? nil : sessionNotes
                        )
                        // Mark as recorded to prevent duplicates
                        appManager.sessionAlreadyRecorded = true
                    } else {
                        // If already recorded, update the most recent session with the notes
                        if !sessionTitle.isEmpty || !sessionNotes.isEmpty {
                            // Find and update the most recent session for this user
                            guard let userId = Auth.auth().currentUser?.uid
                            else { return }
                            // Take the first session (most recent) that matches the user ID
                            if let index = sessionManager.sessions.firstIndex(
                                where: { $0.userId == userId })
                            {
                                let session = sessionManager.sessions[index]
                                // Create a new session with updated notes
                                let updatedSession = Session(
                                    id: session.id,
                                    userId: session.userId,
                                    username: session.username,
                                    startTime: session.startTime,
                                    duration: session.duration,
                                    wasSuccessful: session.wasSuccessful,
                                    actualDuration: session.actualDuration,
                                    sessionTitle: sessionTitle.isEmpty
                                        ? nil : sessionTitle,
                                    sessionNotes: sessionNotes.isEmpty
                                        ? nil : sessionNotes,
                                    participants: session.participants,
                                    originalStarterId: session
                                        .originalStarterId,
                                    wasJoinedSession: session.wasJoinedSession,
                                    comment: session.comment,
                                    commentorId: session.commentorId,
                                    commentorName: session.commentorName,
                                    commentTime: session.commentTime,
                                    liveSessionId: session.liveSessionId
                                )
                                // Update the session in Firebase
                                try? FirebaseManager.shared.db.collection(
                                    "sessions"
                                )
                                .document(session.id.uuidString)
                                .setData(from: updatedSession)
                            }
                        }
                    }

                    // Add a small delay to show "Saving..." effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        appManager.currentState = .initial
                        isButtonPressed = false
                        appManager.sessionAlreadyRecorded = false  // Reset for next session
                        showSavingIndicator = false
                    }
                }) {
                    HStack {
                        if showSavingIndicator {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }

                        Text(showSavingIndicator ? "SAVING..." : "RETURN HOME")
                            .font(.system(size: 18, weight: .black))
                            .tracking(2)
                            .foregroundColor(.white)
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(
                                                red: 168 / 255, green: 85 / 255,
                                                blue: 247 / 255),
                                            Color(
                                                red: 88 / 255, green: 28 / 255,
                                                blue: 135 / 255),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.2),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(
                        color: Color(
                            red: 168 / 255, green: 85 / 255, blue: 247 / 255
                        ).opacity(0.5), radius: 8
                    )
                    .scaleEffect(isButtonPressed ? 0.97 : 1.0)
                }
                .padding(.horizontal, 30)
                .offset(y: showButton ? 0 : 50)
                .opacity(showButton ? 1 : 0)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 30)
        }
        // Make the screen scrollable only when keyboard is shown
        .offset(y: keyboardOffset)
        .onAppear {
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification, object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[
                    UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.keyboardOffset = -keyboardFrame.height / 3  // Adjust to push content up just enough
                    }
                }
            }

            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification, object: nil,
                queue: .main
            ) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self.keyboardOffset = 0
                }
            }

            // Check if this is the user's first session
            checkFirstSession()

            // Stagger the animations for a nice effect
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showIcon = true
            }

            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(0.2)
            ) {
                showTitle = true
            }

            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(0.4)
            ) {
                showStats = true
            }

            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(0.6)
            ) {
                if !isFirstSession {
                    showNotes = true
                }
            }

            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.8).delay(0.8)
            ) {
                showButton = true
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                isGlowing = true
            }
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func checkFirstSession() {
        guard let _userId = Auth.auth().currentUser?.uid else {
            isCheckingFirstSession = false
            return
        }

        FirebaseManager.shared.hasCompletedFirstSession { hasCompleted in
            // This is a first session if the user hasn't completed one before
            self.isFirstSession = !hasCompleted

            // If this is their first session, record it
            if self.isFirstSession {
                // Record the first session to the first_sessions collection
                FirebaseManager.shared.recordFirstSession(
                    duration: self.appManager.selectedMinutes,
                    wasSuccessful: true
                ) { success in
                    DispatchQueue.main.async {
                        self.isCheckingFirstSession = false

                        // Show the leaderboard with animation
                        withAnimation(.spring()) {
                            self.showLeaderboard = true
                        }
                    }
                }
            } else {
                // Not a first-time user
                DispatchQueue.main.async {
                    self.isCheckingFirstSession = false

                    // Show notes section instead
                    withAnimation(.spring()) {
                        self.showNotes = true
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
            for: nil)
    }
}
