import SwiftUI

struct PausedView: View {
  @EnvironmentObject var flipManager: Manager

  var body: some View {
    VStack(spacing: 30) {
      Image(systemName: "pause.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      VStack(spacing: 15) {
        Text("Session Paused")
          .font(.title)
          .foregroundColor(.white)

        Text(
          "\(flipManager.pausedRemainingSeconds / 60):\(String(format: "%02d", flipManager.pausedRemainingSeconds % 60)) remaining"
        )
        .font(.system(size: 40, design: .monospaced))
        .foregroundColor(Theme.neonYellow)

        Text("\(flipManager.pausedRemainingFlips) retries left")
          .font(.title3)
          .foregroundColor(.white)
      }

      Button(action: {
        flipManager.startResumeCountdown()
      }) {
        Text("Resume")
          .font(.system(size: 24, weight: .black))
          .foregroundColor(.black)
          .frame(width: 200, height: 50)
          .background(Theme.neonYellow)
          .cornerRadius(25)
      }
    }
    .padding()
    .background(Theme.mainGradient)
  }
}
