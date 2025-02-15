import SwiftUI

struct CompletionView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 30) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .retroGlow()

            // Title
            VStack(spacing: 4) {
                Text("SESSION COMPLETE")
                    .font(.system(size: 28, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()

                Text("おめでとう")
                    .font(.system(size: 14))
                    .tracking(4)
                    .foregroundColor(.gray)
            }

            // Stats
            VStack(spacing: 15) {
                Text("Well done.")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)

                Text("\(appManager.selectedMinutes)")
                    .font(.system(size: 60, weight: .black))
                    .foregroundColor(.white)
                    .retroGlow()

                Text("minutes")
                    .font(.system(size: 20))
                    .tracking(4)
                    .foregroundColor(.white)
                    .retroGlow()

                Text("of pure focused time achieved.")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }

            // Back Button
            Button(action: {
                appManager.currentState = .initial
            }) {
                Text("BACK TO HOME")
                    .font(.system(size: 20, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(
                        Color.white
                            .shadow(color: .white.opacity(0.5), radius: 10)
                    )
                    .cornerRadius(25)
            }
            .padding(.top, 30)
        }
        .background(Theme.mainGradient)
        .padding(.horizontal, 30)
    }
}
