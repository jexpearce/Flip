import SwiftUI

struct PausedView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showingCancelAlert = false
    @State private var isResumePressed = false
    @State private var isCancelPressed = false
    
    var body: some View {
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

            Text("\(appManager.pausedRemainingFlips) retries left")
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
        .alert("Cancel Session?", isPresented: $showingCancelAlert) {
            Button("Cancel Session", role: .destructive) {
                appManager.failSession()
            }
            Button("Keep Session", role: .cancel) {}
        } message: {
            Text("This session will be marked as failed. Are you sure?")
        }
    }

    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
