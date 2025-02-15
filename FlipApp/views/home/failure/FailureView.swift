import SwiftUI

struct FailureView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 30) {
            // Failure Icon
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .retroGlow()

            // Title with Japanese
            VStack(spacing: 4) {
                Text("SESSION FAILED!")
                    .font(.system(size: 34, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()
                
                Text("セッション失敗")
                    .font(.system(size: 14))
                    .tracking(4)
                    .foregroundColor(.gray)
            }

            Text("Your phone was moved during the session")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .retroGlow()

            VStack(spacing: 20) {
                // Try Again Button
                Button(action: {
                    appManager.startCountdown()
                }) {
                    HStack {
                        Text("Try Again")
                        Text("(\(appManager.selectedMinutes) min)")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        Color.white
                            .shadow(color: .white.opacity(0.5), radius: 10)
                    )
                    .cornerRadius(25)
                }

                // Change Time Button
                Button(action: {
                    appManager.currentState = .initial
                }) {
                    Text("Change Time")
                        .font(.system(size: 18, weight: .medium))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 44)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .retroGlow()
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 30)
        .background(Theme.mainGradient)
    }
}