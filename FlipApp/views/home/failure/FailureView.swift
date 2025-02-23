import SwiftUI

struct FailureView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var isTryAgainPressed = false
    @State private var isChangeTimePressed = false
    
    var body: some View {
        VStack(spacing: 30) {
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
                    .frame(width: 100, height: 100)
                    .opacity(0.2)
                
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
                    .shadow(color: Color.red.opacity(0.5), radius: 10)
            }

            // Title with Japanese
            VStack(spacing: 4) {
                Text("SESSION FAILED!")
                    .font(.system(size: 34, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .shadow(color: Color.red.opacity(0.5), radius: 8)

                Text("セッション失敗")
                    .font(.system(size: 14))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.7))
            }

            Text("Your phone was moved during the session")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

            VStack(spacing: 20) {
                // Try Again Button with enhanced styling
                Button(action: {
                    withAnimation(.spring()) {
                        isTryAgainPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appManager.startCountdown()
                        isTryAgainPressed = false
                    }
                }) {
                    HStack {
                        Text("Try Again")
                        Text("(\(appManager.selectedMinutes) min)")
                    }
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
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

                // Change Time Button with glass effect
                Button(action: {
                    withAnimation(.spring()) {
                        isChangeTimePressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appManager.currentState = .initial
                        isChangeTimePressed = false
                    }
                }) {
                    Text("Change Time")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 44)
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
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 30)
    }
}
