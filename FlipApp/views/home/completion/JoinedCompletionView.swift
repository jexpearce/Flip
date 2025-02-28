import SwiftUI
import FirebaseAuth  // Add this import

struct JoinedCompletionView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showNotes = false
    @State private var showButton = false
    @State private var isGlowing = false
    @State private var isButtonPressed = false
    
    // Session notes state variables - only original starter can edit
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    @State private var showSavingIndicator = false
    @State private var keyboardOffset: CGFloat = 0
    
    // Session participants
    @State private var participantDetails: [ParticipantDetail] = []
    @State private var loadingParticipants = true
    
    // Computed properties
    private var isOriginalStarter: Bool {
        guard let originalStarterId = appManager.originalSessionStarter,
              let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }
        return originalStarterId == currentUserId
    }
    
    private var canEditNotes: Bool {
        // Only the original starter can edit notes
        return isOriginalStarter
    }
    
    private var otherParticipantNames: String {
        let names = participantDetails
            .filter { $0.id != Auth.auth().currentUser?.uid }
            .map { $0.username }
        
        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            let allButLast = names.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(names.last!)"
        }
    }
    
    struct ParticipantDetail: Identifiable {
        let id: String
        let username: String
        let wasSuccessful: Bool
        let duration: Int
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Success content
            VStack(spacing: 15) {
                // Success Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .opacity(0.2)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.green.opacity(0.5), radius: isGlowing ? 15 : 8)
                }
                .scaleEffect(showIcon ? 1 : 0)
                .rotationEffect(.degrees(showIcon ? 0 : -180))
                
                // Title with animation
                VStack(spacing: 2) {
                    Text("GROUP SESSION COMPLETE")
                        .font(.system(size: 20, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    
                    Text("一緒に成功")
                        .font(.system(size: 12))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.7))
                }
                .offset(y: showTitle ? 0 : 50)
                .opacity(showTitle ? 1 : 0)
                
                // Group stats with animation
                VStack(spacing: 5) {
                    if loadingParticipants {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                            .padding(.vertical, 10)
                    } else {
                        if !otherParticipantNames.isEmpty {
                            Text("You and \(otherParticipantNames) completed:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("You completed:")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(appManager.selectedMinutes)")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 10)
                            
                            Text("minutes")
                                .font(.system(size: 16))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 4)
                        }
                        
                        Text("of focused work together!")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Participant list
                        if participantDetails.count > 1 {
                            ParticipantList(participants: participantDetails)
                                .padding(.top, 10)
                        }
                    }
                }
                .offset(y: showStats ? 0 : 50)
                .opacity(showStats ? 1 : 0)
            }
            
            // Session Notes section - only original starter can edit
            if showNotes {
                if canEditNotes {
                    // Editable notes for original starter
                    SessionNotesView(
                        sessionTitle: $sessionTitle,
                        sessionNotes: $sessionNotes
                    )
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, -5)
                } else if !sessionTitle.isEmpty || !sessionNotes.isEmpty {
                    // Read-only notes for other participants
                    ReadOnlyNotesView(
                        sessionTitle: sessionTitle,
                        sessionNotes: sessionNotes
                    )
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, -5)
                }
            }
            
            // Back Button with animation and notes saving
            Button(action: {
                withAnimation(.spring()) {
                    isButtonPressed = true
                    showSavingIndicator = true
                }
                
                // Hide keyboard first
                hideKeyboard()
                
                // Save session with notes if we're the original starter
                if canEditNotes {
                    sessionManager.addSession(
                        duration: appManager.selectedMinutes,
                        wasSuccessful: true,
                        actualDuration: appManager.selectedMinutes,
                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                    )
                }
                
                // Add a small delay to show "Saving..." effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    appManager.currentState = .initial
                    isButtonPressed = false
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
                    
                    Text(showSavingIndicator ? "SAVING..." : "BACK TO HOME")
                        .font(.system(size: 18, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                }
                .frame(width: 200, height: 50)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Theme.buttonGradient)
                        
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 25)
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
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            }
            .offset(y: showButton ? 0 : 50)
            .opacity(showButton ? 1 : 0)
            .padding(.top, 5)
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 25)
        // Make the screen scrollable only when keyboard is shown
        .offset(y: keyboardOffset)
        .onAppear {
            loadParticipantDetails()
            
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.keyboardOffset = -keyboardFrame.height/3 // Adjust to push content up just enough
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self.keyboardOffset = 0
                }
            }
            
            // Load session notes if we're not the original starter
            if !canEditNotes {
                loadSessionNotes()
            }
            
            // Stagger the animations for a nice effect
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
    
    private func loadParticipantDetails() {
        guard let sessionId = appManager.liveSessionId else {
            loadingParticipants = false
            return
        }
        
        FirebaseManager.shared.db.collection("live_sessions").document(sessionId).getDocument { document, error in
            guard let data = document?.data(),
                  let participants = data["participants"] as? [String],
                  let participantStatus = data["participantStatus"] as? [String: String] else {
                loadingParticipants = false
                return
            }
            
            // Load user details for each participant
            let group = DispatchGroup()
            var details: [ParticipantDetail] = []
            
            for participantId in participants {
                group.enter()
                
                FirebaseManager.shared.db.collection("users").document(participantId).getDocument { userDoc, userError in
                    if let userData = try? userDoc?.data(as: FirebaseManager.FlipUser.self) {
                        let isCompleted = participantStatus[participantId] == LiveSessionManager.ParticipantStatus.completed.rawValue
                        let duration = appManager.selectedMinutes
                        
                        details.append(ParticipantDetail(
                            id: participantId,
                            username: userData.username,
                            wasSuccessful: isCompleted,
                            duration: duration
                        ))
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.participantDetails = details.sorted { $0.username < $1.username }
                self.loadingParticipants = false
            }
        }
    }
    
    private func loadSessionNotes() {
        guard let sessionId = appManager.liveSessionId,
              let originalStarterId = appManager.originalSessionStarter else { return }
        
        // Try to find the most recent session with notes from the original starter
        FirebaseManager.shared.db.collection("sessions")
            .whereField("userId", isEqualTo: originalStarterId)
            .whereField("originalStarterId", isEqualTo: originalStarterId)
            .order(by: "startTime", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let document = snapshot?.documents.first,
                   let session = try? document.data(as: Session.self) {
                    DispatchQueue.main.async {
                        self.sessionTitle = session.sessionTitle ?? ""
                        self.sessionNotes = session.sessionNotes ?? ""
                    }
                }
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ParticipantList: View {
    let participants: [JoinedCompletionView.ParticipantDetail]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARTICIPANTS")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
            
            ForEach(participants) { participant in
                HStack {
                    Text(participant.username)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: participant.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(participant.wasSuccessful ? .green : .red)
                            .font(.system(size: 12))
                        
                        Text("\(participant.duration) min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ReadOnlyNotesView: View {
    let sessionTitle: String
    let sessionNotes: String
    
    var body: some View {
        VStack(spacing: 5) {
            // Section header
            Text("SESSION NOTES")
                .font(.system(size: 16, weight: .bold))
                .tracking(3)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                .padding(.bottom, 0)
            
            if !sessionTitle.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(sessionTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            if !sessionNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(sessionNotes)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.6),
                                Color(red: 16/255, green: 24/255, blue: 57/255).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}