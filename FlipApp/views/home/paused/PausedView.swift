import SwiftUI

struct PausedView: View {
  @EnvironmentObject var appManager: AppManager

  var body: some View {
    VStack(spacing: 30) {
      Image(systemName: "pause.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      VStack(spacing: 15) {
        Text("Session Paused")
          .font(.title)
          .foregroundColor(.white)

        Text(formatTime(seconds: appManager.pausedRemainingSeconds))
          .font(.system(size: 40, design: .monospaced))
          .foregroundColor(Theme.neonYellow)

        Text("\(appManager.pausedRemainingFlips) retries left")
          .font(.title3)
          .foregroundColor(.white)
      }

      Button(action: {
        appManager.startResumeCountdown()
      }) {
        HStack {
          Image(systemName: "play.circle.fill")
          Text("Resume")
        }
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
  private func formatTime(seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
  }
}
