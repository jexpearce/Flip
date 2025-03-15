import SwiftUI
import FirebaseAuth

struct FailureView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isTryAgainPressed = false
    @State private var isChangeTimePressed = false
    @State private var showSavingIndicator = false
    @State private var showNotes = false
    @State private var keyboardOffset: CGFloat = 0
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showActions = false
    @State private var isGlowing = false
    
    // Session notes state variables
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Failure content
                VStack(spacing: 25) {
                    // Failure Icon with enhanced styling
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3),
                                        Color(red: 185/255, green: 28/255, blue: 28/255).opacity(0.2)
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
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 239/255, green: 68/255, blue: 68/255),
                                        Color(red: 185/255, green: 28/255, blue: 28/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(isGlowing ? 0.6 : 0.3), radius: isGlowing ? 15 : 10)
                    }
                    .scaleEffect(showIcon ? 1 : 0)
                    
                    // Title
                    Text("SESSION FAILED")
                        .font(.system(size: 28, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 8)
                        .offset(y: showTitle ? 0 : 50)
                        .opacity(showTitle ? 1 : 0)
                    
                    // Stats card
                    VStack(spacing: 15) {
                        Text("Your phone was moved during the session")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Calculate the actual duration in minutes
                        let actualDuration = (appManager.selectedMinutes * 60 - appManager.remainingSeconds) / 60
                        
                        if actualDuration > 0 {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(actualDuration)")
                                    .font(.system(size: 42, weight: .black))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 10)
                                
                                Text(actualDuration == 1 ? "minute" : "minutes")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.leading, 4)
                            }
                            
                            Text("completed before failure")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 25)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 60/255, green: 30/255, blue: 110/255).opacity(0.5),
                                            Color(red: 40/255, green: 20/255, blue: 80/255).opacity(0.3)
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
                                            Color.white.opacity(0.1)
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
                
                // Session Notes section
                if showNotes {
                    SessionNotesView(
                        sessionTitle: $sessionTitle,
                        sessionNotes: $sessionNotes
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Try Again Button with enhanced styling and notes saving
                    Button(action: {
                        withAnimation(.spring()) {
                            isTryAgainPressed = true
                            showSavingIndicator = true
                        }
                        
                        // Hide keyboard first
                        hideKeyboard()
                        
                        // FIXED: Only save NEW session if it hasn't been recorded already
                        if !appManager.sessionAlreadyRecorded {
                            // Save session with notes before restarting
                            sessionManager.addSession(
                                duration: appManager.selectedMinutes,
                                wasSuccessful: false,
                                actualDuration: (appManager.selectedMinutes * 60 - appManager.remainingSeconds) / 60,
                                sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                                sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                            )
                            // Mark as recorded to prevent duplicates
                            appManager.sessionAlreadyRecorded = true
                        } else {
                            // If already recorded, update the most recent session with the notes
                            if !sessionTitle.isEmpty || !sessionNotes.isEmpty {
                                // Find and update the most recent session for this user
                                guard let userId = Auth.auth().currentUser?.uid else { return }
                                // Take the first session (most recent) that matches the user ID
                                if let index = sessionManager.sessions.firstIndex(where: { $0.userId == userId }) {
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
                                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes,
                                        participants: session.participants,
                                        originalStarterId: session.originalStarterId,
                                        wasJoinedSession: session.wasJoinedSession,
                                        comment: session.comment,
                                        commentorId: session.commentorId,
                                        commentorName: session.commentorName,
                                        commentTime: session.commentTime,
                                        liveSessionId: session.liveSessionId
                                    )
                                    // Update the session in Firebase
                                    try? FirebaseManager.shared.db.collection("sessions")
                                        .document(session.id.uuidString)
                                        .setData(from: updatedSession)
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            appManager.startCountdown()
                            isTryAgainPressed = false
                            appManager.sessionAlreadyRecorded = false // Reset for new session
                            showSavingIndicator = false
                        }
                    }) {
                        HStack {
                            if showSavingIndicator && isTryAgainPressed {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(showSavingIndicator && isTryAgainPressed ? "SAVING..." : "TRY AGAIN")
                                .font(.system(size: 18, weight: .black))
                                .tracking(2)
                                .foregroundColor(.white)
                            
                            if !showSavingIndicator || !isTryAgainPressed {
                                Text("(\(appManager.selectedMinutes) MIN)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 168/255, green: 85/255, blue: 247/255),
                                                Color(red: 88/255, green: 28/255, blue: 135/255)
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
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color(red: 168/255, green: 85/255, blue: 247/255).opacity(0.5), radius: 8)
                        .scaleEffect(isTryAgainPressed ? 0.97 : 1.0)
                    }
                    
                    // Change Time Button with glass effect
                    Button(action: {
                        withAnimation(.spring()) {
                            isChangeTimePressed = true
                            showSavingIndicator = true
                        }
                        
                        // Hide keyboard first
                        hideKeyboard()
                        
                        // FIXED: Only save NEW session if it hasn't been recorded already
                        if !appManager.sessionAlreadyRecorded {
                            // Save session with notes before going back
                            sessionManager.addSession(
                                duration: appManager.selectedMinutes,
                                wasSuccessful: false,
                                actualDuration: (appManager.selectedMinutes * 60 - appManager.remainingSeconds) / 60,
                                sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                                sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                            )
                            // Mark as recorded to prevent duplicates
                            appManager.sessionAlreadyRecorded = true
                        } else {
                            // If already recorded, update the most recent session with the notes
                            if !sessionTitle.isEmpty || !sessionNotes.isEmpty {
                                // Find and update the most recent session for this user
                                guard let userId = Auth.auth().currentUser?.uid else { return }
                                // Take the first session (most recent) that matches the user ID
                                if let index = sessionManager.sessions.firstIndex(where: { $0.userId == userId }) {
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
                                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes,
                                        participants: session.participants,
                                        originalStarterId: session.originalStarterId,
                                        wasJoinedSession: session.wasJoinedSession,
                                        comment: session.comment,
                                        commentorId: session.commentorId,
                                        commentorName: session.commentorName,
                                        commentTime: session.commentTime,
                                        liveSessionId: session.liveSessionId
                                    )
                                    // Update the session in Firebase
                                    try? FirebaseManager.shared.db.collection("sessions")
                                        .document(session.id.uuidString)
                                        .setData(from: updatedSession)
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            appManager.currentState = .initial
                            isChangeTimePressed = false
                            showSavingIndicator = false
                        }
                    }) {
                        HStack {
                            if showSavingIndicator && isChangeTimePressed {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(showSavingIndicator && isChangeTimePressed ? "SAVING..." : "CHANGE TIME")
                                .font(.system(size: 16, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.white.opacity(0.1), radius: 6)
                        .scaleEffect(isChangeTimePressed ? 0.97 : 1.0)
                    }
                }
                .padding(.horizontal, 30)
                .offset(y: showActions ? 0 : 50)
                .opacity(showActions ? 1 : 0)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 40)
        }
        // Make the screen scrollable when keyboard is shown
        .offset(y: keyboardOffset)
        .onAppear {
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.keyboardOffset = -keyboardFrame.height/3
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self.keyboardOffset = 0
                }
            }
            
            // Stagger animations for a nice effect
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showIcon = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showTitle = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                showStats = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
                showNotes = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
                showActions = true
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}