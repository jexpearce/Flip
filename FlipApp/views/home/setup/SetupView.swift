import SwiftUI
class SessionJoinCoordinator {
    static let shared = SessionJoinCoordinator()
    
    private var sessionData: (id: String, name: String)? = nil
    
    func setJoinSession(id: String, name: String) {
        sessionData = (id, name)
    }
    
    func getJoinSession() -> (id: String, name: String)? {
        let data = sessionData
        sessionData = nil
        return data
    }
}
struct SetupView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var isButtonPressed = false
    @State private var showPauseDisabledWarning = false
    @AppStorage("hasShownPauseWarning") private var hasShownPauseWarning = false
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared
    @State private var isJoining = false
    @State private var showJoiningIndicator = false
    
    // Check if we're navigating back from a joined session view
    @State private var joinLiveSessionMode = false
    @State private var sessionToJoin: (id: String, name: String)? = nil

    var body: some View {
        ZStack {
            // Main View Content
            VStack(spacing: 25) {
                // Title Section with logo to the right
                HStack(spacing: 15) {
                    Text("FLIP")
                        .font(.system(size: 80, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .retroGlow()
  
                    Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 55, weight: .bold)) // Bigger & bolder SF Symbol
                            .foregroundColor(Color.white.opacity(1.0)) // Max brightness
                            .shadow(color: .white, radius: 5) // Adds a soft glow
                            .overlay(
                                Image(systemName: "arrow.2.squarepath")
                                    .font(.system(size: 55))
                                    .foregroundColor(.white.opacity(0.25)) // Fake stroke effect
                                    .offset(x: 1, y: 1)
                            )
                            .rotationEffect(.degrees(isButtonPressed ? 360 : 0))
                            .animation(
                                .spring(response: 2.0, dampingFraction: 0.6)
                                    .repeatForever(autoreverses: false),
                                value: isButtonPressed
                            )
                    }
                .padding(.top, 50)
                .onAppear { isButtonPressed = true }

                // Set Time Title
                VStack(spacing: 4) {
                    if joinLiveSessionMode, let sessionInfo = sessionToJoin {
                        Text("JOIN \(sessionInfo.name.uppercased())'S SESSION")
                            .font(.system(size: 20, weight: .black))
                            .tracking(6)
                            .foregroundColor(.white)
                            .retroGlow()
                            .multilineTextAlignment(.center)
                        
                        Text("友達と一緒に")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("SET TIME")
                            .font(.system(size: 24, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .retroGlow()
                        Text("タイマーの設定")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Circular Time Picker
                CircularTime(selectedMinutes: $appManager.selectedMinutes)
                    .padding(.top, -10)
                    .disabled(joinLiveSessionMode) // Disable time selection for joined sessions
                    .opacity(joinLiveSessionMode ? 0.7 : 1)

                // Controls
                HStack(spacing: 20) {
                    ControlButton(title: "ALLOW PAUSE") {
                        Spacer()
                        Toggle("", isOn: $appManager.allowPauses)
                            .toggleStyle(ModernToggleStyle())
                            .disabled(joinLiveSessionMode) // Disable in join mode
                            .onChange(of: appManager.allowPauses) { newValue in
                                if !newValue {
                                    // Only show the warning if it hasn't been shown before
                                    if !hasShownPauseWarning {
                                        showPauseDisabledWarning = true
                                        hasShownPauseWarning = true
                                    }
                                    appManager.maxPauses = 0
                                } else {
                                    appManager.maxPauses = 3
                                }
                            }
                        Spacer()
                    }

                    ControlButton(title: "# OF PAUSES") {
                        HStack {
                            Text("\(appManager.maxPauses)")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(
                                    (appManager.allowPauses && !joinLiveSessionMode)
                                        ? .white : .white.opacity(0.3))

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(
                                    (appManager.allowPauses && !joinLiveSessionMode)
                                        ? .white : .white.opacity(0.3)
                                )
                                .offset(y: 2)
                        }
                    }
                    .overlay(
                        Menu {
                            Picker("", selection: $appManager.maxPauses) {
                                ForEach(0...10, id: \.self) { number in
                                    Text("\(number)").tag(number)
                                }
                            }
                        } label: {
                            Color.clear
                        }
                        .disabled(!appManager.allowPauses || joinLiveSessionMode)
                    )
                }
                .padding(.horizontal)

                // Begin Button
                BeginButton {
                    // Only start a regular session here, joining is handled in onAppear
                    if !joinLiveSessionMode {
                        appManager.startCountdown()
                    }
                }
                .overlay(
                    Group {
                        if joinLiveSessionMode {
                            Text("JOINING...")
                                .font(.system(size: 36, weight: .black))
                                .tracking(8)
                                .foregroundColor(.white)
                                .shadow(color: Color.green.opacity(0.6), radius: 8)
                                .opacity(showJoiningIndicator ? 1 : 0)
                        }
                    }
                )
                .disabled(joinLiveSessionMode) // Disable when joining

                Spacer()
            }
            
            // Join Session Mode Control - shown only during join mode
            if joinLiveSessionMode {
                VStack {
                    Spacer()
                    Button(action: {
                        // FIXED: This button now correctly cancels join mode instead of trying to join
                        joinLiveSessionMode = false
                        sessionToJoin = nil
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 40)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.red.opacity(0.7))
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                    }
                    .disabled(showJoiningIndicator) // Disable during join process
                    .padding(.bottom, 50)
                }
            }
            
            // Loading Overlay
            if showJoiningIndicator {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.white)
                            
                            Text("Joining Session...")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    )
                    .transition(.opacity)
            }
            
            // Custom Alert Overlay
            if showPauseDisabledWarning {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            // Warning Icon
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 249/255, green: 115/255, blue: 22/255),
                                            Color(red: 194/255, green: 65/255, blue: 12/255)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Theme.orange.opacity(0.5), radius: 10)
                                .padding(.top, 30)
                            
                            // Warning Title
                            VStack(spacing: 4) {
                                Text("WARNING")
                                    .font(.system(size: 28, weight: .black))
                                    .tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: Theme.orange.opacity(0.5), radius: 8)
                                
                                Text("警告")
                                    .font(.system(size: 14))
                                    .tracking(4)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Alert Message
                            Text("With pauses disabled, flipping your phone at any time will instantly fail your session.")
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                            
                            // Confirm Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    showPauseDisabledWarning = false
                                }
                            }) {
                                Text("GOT IT")
                                    .font(.system(size: 20, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.white)
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
                            }
                            .padding(.bottom, 30)
                        }
                        .frame(width: 320)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Theme.darkGray)
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.3))
                                
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
                        .shadow(color: Color.black.opacity(0.5), radius: 20)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    )
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Check if we're being called to join a session
            if let sessionData = SessionJoinCoordinator.shared.getJoinSession() {
                joinLiveSessionMode = true
                sessionToJoin = sessionData
                
                // Show joining indicator
                withAnimation {
                    showJoiningIndicator = true
                }
                
                // Get session details and AUTO-JOIN after verification
                LiveSessionManager.shared.getSessionDetails(sessionId: sessionData.id) { session in
                    if let session = session {
                        DispatchQueue.main.async {
                            // Set timer and values first
                            appManager.selectedMinutes = session.targetDuration
                            
                            // Then auto-join the session
                            LiveSessionManager.shared.joinSession(sessionId: sessionData.id) { success, remainingSeconds, totalDuration in
                                if success {
                                    appManager.joinLiveSession(
                                        sessionId: sessionData.id,
                                        remainingSeconds: remainingSeconds,
                                        totalDuration: totalDuration
                                    )
                                    
                                    // Hide join indicator after short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            showJoiningIndicator = false
                                        }
                                    }
                                } else {
                                    // Handle failure
                                    print("Failed to join session")
                                    withAnimation {
                                        showJoiningIndicator = false
                                        joinLiveSessionMode = false
                                    }
                                }
                            }
                        }
                    } else {
                        // Session doesn't exist, reset join mode
                        DispatchQueue.main.async {
                            withAnimation {
                                showJoiningIndicator = false
                                joinLiveSessionMode = false
                            }
                        }
                    }
                }
            }
        }
    }
}