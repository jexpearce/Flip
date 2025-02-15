import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 25) {
            // Title
            Text("GET READY")
                .font(.system(size: 28, weight: .black))
                .tracking(8)
                .foregroundColor(.white)
                .retroGlow()

            // Countdown Number
            Text("\(appManager.countdownSeconds)")
                .font(.system(size: 120, weight: .black))
                .foregroundColor(.white)
                .animation(.spring(), value: appManager.countdownSeconds)
                .scaleEffect(1.2)
                .retroGlow()

            // Instructions
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    Text("1")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .retroGlow()

                    Text("TURN OFF PHONE")
                        .font(.system(size: 20, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(.white)
                        .retroGlow()
                }

                HStack(spacing: 15) {
                    Text("2")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .retroGlow()

                    Text("FLIP!")
                        .font(.system(size: 20, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(.white)
                        .retroGlow()
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.mainGradient)
    }
}
