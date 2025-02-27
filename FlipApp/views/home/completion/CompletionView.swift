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
    
    // New state variables for session notes
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    @State private var showSavingIndicator = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Top section - Success content
                VStack(spacing: 20) {
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
                            .frame(width: 100, height: 100)
                            .opacity(0.2)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
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
                    VStack(spacing: 4) {
                        Text("SESSION COMPLETE")
                            .font(.system(size: 28, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        
                        Text("おめでとう")
                            .font(.system(size: 14))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .offset(y: showTitle ? 0 : 50)
                    .opacity(showTitle ? 1 : 0)
                    
                    // Stats with animation
                    VStack(spacing: 15) {
                        Text("Well done.")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(appManager.selectedMinutes)")
                            .font(.system(size: 60, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 10)
                        
                        Text("minutes")
                            .font(.system(size: 20))
                            .tracking(4)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
                        
                        Text("of pure focused time achieved.")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                }
                .padding(.bottom, 10)
                
                // Session Notes section
                if showNotes {
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
                    
                    // Save session with notes
                    sessionManager.addSessionWithNotes(
                        duration: appManager.selectedMinutes,
                        wasSuccessful: true,
                        actualDuration: appManager.selectedMinutes,
                        sessionTitle: sessionTitle.isEmpty ? nil : sessionTitle,
                        sessionNotes: sessionNotes.isEmpty ? nil : sessionNotes
                    )
                    
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
                            .font(.system(size: 20, weight: .black))
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
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
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
    }
}