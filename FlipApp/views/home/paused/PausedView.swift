import SwiftUI

struct PausedView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showingCancelAlert = false
    @State private var isResumePressed = false
    @State private var isCancelPressed = false
    
    var body: some View {
        ZStack {
            // Main Paused View Content
            VStack(spacing: 30) {
                // Pause Icon with enhanced glow
                ZStack {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .frame(width: 100, height: 100)
                        .opacity(0.2)
                    
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 10)
                }

                // Title with Japanese
                VStack(spacing: 4) {
                    Text("SESSION PAUSED")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                    Text("一時停止中")
                        .font(.system(size: 14))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Time Display with enhanced styling
                Text(formatTime(seconds: appManager.pausedRemainingSeconds))
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 10)

                Text("\(appManager.remainingPauses) retries left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

                // Resume Button with glass effect
                Button(action: {
                    withAnimation(.spring()) {
                        isResumePressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appManager.resumeSession()
                        isResumePressed = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                        Text("RESUME")
                    }
                    .font(.system(size: 24, weight: .black))
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
                    .scaleEffect(isResumePressed ? 0.95 : 1.0)
                }

                // Cancel Button with warning style
                Button(action: {
                    withAnimation(.spring()) {
                        isCancelPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingCancelAlert = true
                        isCancelPressed = false
                    }
                }) {
                    Text("CANCEL SESSION")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 239/255, green: 68/255, blue: 68/255),
                                                Color(red: 185/255, green: 28/255, blue: 28/255)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .opacity(0.8)
                                
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 6)
                        .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                }
            }
            .padding()
            
            // Custom alert overlay
            if showingCancelAlert {
                CustomCancelAlert(
                    isPresented: $showingCancelAlert,
                    onConfirm: {
                        appManager.failSession()
                    }
                )
            }
        }
    }

    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct CustomCancelAlert: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @State private var isConfirmPressed = false
    @State private var isCancelPressed = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Alert card
            VStack(spacing: 20) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)
                        .opacity(0.2)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
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
                        .shadow(color: Color.red.opacity(0.5), radius: 8)
                }
                .padding(.top, 20)
                
                // Title
                VStack(spacing: 4) {
                    Text("CANCEL SESSION?")
                        .font(.system(size: 22, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: Color.red.opacity(0.5), radius: 6)
                    
                    Text("セッションをキャンセル")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Message
                Text("This session will be marked as failed and you will lose points.")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Buttons
                HStack(spacing: 15) {
                    // Keep Session button
                    Button(action: {
                        withAnimation(.spring()) {
                            isCancelPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCancelPressed = false
                            isPresented = false
                        }
                    }) {
                        Text("KEEP SESSION")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                    }
                    
                    // Cancel Session button
                    Button(action: {
                        withAnimation(.spring()) {
                            isConfirmPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isConfirmPressed = false
                            isPresented = false
                            onConfirm()
                        }
                    }) {
                        Text("CANCEL SESSION")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(0.8)
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .scaleEffect(isConfirmPressed ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 25)
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
        }
        .transition(.opacity)
    }
}