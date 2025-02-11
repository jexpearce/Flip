import SwiftUI

struct FailureView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.3), radius: 10)

            VStack(spacing: 15) {
                Text("Session Failed!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.red)

                Text("Your phone was moved during the session")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 20) {
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
                    .background(Theme.neonYellow)
                    .cornerRadius(25)
                }

                Button(action: {
                    appManager.currentState = .initial
                }) {
                    Text("Change Time")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.neonYellow)
                        .frame(width: 200, height: 44)
                        .background(Color(white: 0.2))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Theme.neonYellow, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 30)
        .background(Theme.mainGradient)
    }
}