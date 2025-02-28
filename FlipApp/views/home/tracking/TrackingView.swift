import SwiftUI

struct TrackingView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var isPausePressed = false
    @State private var isCancelPressed = false
    @State private var showingCancelAlert = false
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            // Live Session Indicator - NEW
            if appManager.isJoinedSession {
                JoinedSessionIndicator()
                    .padding(.bottom, 10)
            }
            
            // Status Icon
            Image(
                systemName: appManager.isFaceDown
                    ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.system(size: 60))
            .foregroundColor(appManager.isFaceDown ? Theme.offWhite : .red)

            // Status Text
            Text(appManager.isFaceDown ? "STAY FOCUSED!" : "FLIP YOUR PHONE!")
                .title()
                .foregroundColor(appManager.isFaceDown ? Theme.offWhite : .red)
                .multilineTextAlignment(.center)

            VStack(spacing: 15) {
                if appManager.isFaceDown {
                    Text("REMAINING")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(4)
                        .foregroundColor(Theme.offWhite.opacity(0.7))
                } else if !appManager.isFaceDown {
                    // Show seconds remaining to pause when phone is flipped
                    Text("YOU HAVE \(appManager.flipBackTimeRemaining) SECONDS TO PAUSE")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(4)
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Text(appManager.remainingTimeString)
                    .font(.system(size: 50, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Theme.darkGray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .strokeBorder(
                                        Theme.offWhite.opacity(0.3),
                                        lineWidth: 1)
                            )
                    )
                
                if !appManager.isFaceDown {
                    Text("\(appManager.remainingPauses) PAUSES REMAINING")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2)
                        .foregroundColor(Theme.offWhite.opacity(0.7))
                        .padding(.top, 5)
                }
            }
            
            // Only show action buttons if phone is flipped up
            if !appManager.isFaceDown && appManager.allowPauses && appManager.remainingPauses > 0 {
                VStack(spacing: 20) {
                    // Pause Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isPausePressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            appManager.pauseSession()
                            isPausePressed = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pause.circle.fill")
                            Text("PAUSE")
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
                        .scaleEffect(isPausePressed ? 0.95 : 1.0)
                    }
                    
                    // Cancel Button
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
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Cancel Session?", isPresented: $showingCancelAlert) {
            Button("Cancel Session", role: .destructive) {
                appManager.failSession()
            }
            Button("Keep Session", role: .cancel) {}
        } message: {
            Text("This session will be marked as failed. Are you sure?")
        }
    }
}


    
    private func getCircleColor(index: Int) -> Color {
        let colors: [Color] = [
            .green,
            .blue,
            .purple,
            .orange
        ]
        
        return colors[index % colors.count]
    }
