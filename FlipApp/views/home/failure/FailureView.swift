import SwiftUI

struct FailureView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isTryAgainPressed = false
    @State private var isChangeTimePressed = false
    @State private var showSavingIndicator = false
    @State private var showNotes = false
    @State private var keyboardOffset: CGFloat = 0
    
    // New state variables for session notes
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    
    var body: some View {
        VStack(spacing: 15) {
            // Failure content - more compact
            VStack(spacing: 15) {
                // Failure Icon with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .opacity(0.2)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
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
                        .shadow(color: Color.red.opacity(0.5), radius: 10)
                }
                
                // Title with Japanese - more compact
                VStack(spacing: 2) {
                    Text("SESSION FAILED!")
                        .font(.system(size: 24, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Color.red.opacity(0.5), radius: 8)
                    
                    Text("セッション失敗")
                        .font(.system(size: 12))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text("Your phone was moved during the session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
            }
            
            // Session Notes section
            if showNotes {
                SessionNotesView(
                    sessionTitle: $sessionTitle,
                    sessionNotes: $sessionNotes
                )
                .transition(.scale.combined(with: .opacity))
                .padding(.top, -5)
            }
            
            // Buttons - more compact
            VStack(spacing: 15) {
                // Try Again Button with enhanced styling and notes saving
                Button(action: {
                    withAnimation(.spring()) {
                        isTryAgainPressed = true
                        showSavingIndicator = true
                    }
                    
                    // Hide keyboard first
                    hideKeyboard()
                    
                    // Save session with notes before restarting
                    sessionManager.addSession(
                        duration: appManager.selectedMinutes,
                        wasSuccessful: false,
                        actualDuration: appManager.selectedMinutes - appManager.remainingSeconds / 60,
                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        appManager.startCountdown()
                        isTryAgainPressed = false
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
                        
                        Text(showSavingIndicator ? "Saving..." : "Try Again")
                        
                        if !showSavingIndicator {
                            Text("(\(appManager.selectedMinutes) min)")
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
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
                    .scaleEffect(isTryAgainPressed ? 0.95 : 1.0)
                }
                
                // Change Time Button with glass effect and notes saving
                Button(action: {
                    withAnimation(.spring()) {
                        isChangeTimePressed = true
                        showSavingIndicator = true
                    }
                    
                    // Hide keyboard first
                    hideKeyboard()
                    
                    // Save session with notes before going back
                    sessionManager.addSession(
                        duration: appManager.selectedMinutes,
                        wasSuccessful: false,
                        actualDuration: appManager.selectedMinutes - appManager.remainingSeconds / 60,
                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                    )
                    
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
                        
                        Text(showSavingIndicator && isChangeTimePressed ? "Saving..." : "Change Time")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white)
                    .frame(width: 180, height: 42)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 22)
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
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 6)
                    .scaleEffect(isChangeTimePressed ? 0.95 : 1.0)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 5)
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 25)
        // Make the screen scrollable only when keyboard is shown
        .offset(y: keyboardOffset)
        .onAppear {
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
            
            // Animate the notes section appearing
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                showNotes = true
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