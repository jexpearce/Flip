import ActivityKit
import SwiftUI
import WidgetKit

struct ActiveLockView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    VStack(spacing: 12) {
      // Timer and Pauses Row
      HStack {
        Image(
          systemName: context.state.isPaused ? "pause.circle.fill" : "timer"
        )
        .font(.system(size: 20))
        .foregroundColor(Theme.neonYellow)

        Text(context.state.remainingTime)
          .font(.system(size: 24, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
          .frame(minWidth: 80)

        Spacer()

        // Show remaining pauses
        if !context.state.isPaused && context.state.remainingPauses > 0 {
          HStack(spacing: 4) {
            Text("\(context.state.remainingPauses)")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(Theme.neonYellow)
            Image(systemName: "pause.circle")
              .font(.system(size: 16))
              .foregroundColor(Theme.neonYellow)
          }
        }
      }

      // Show flip back timer or resume countdown
      if let countdownMessage = context.state.countdownMessage {
        Text(countdownMessage)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Theme.neonYellow)
      } else if let flipBackTime = context.state.flipBackTimeRemaining {
        Text("\(flipBackTime) seconds to pause or flip back")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Theme.neonYellow)
      }

      // Pause/Resume Button
      if context.state.isPaused {
        Button(intent: ResumeIntent()) {
          HStack {
            Image(systemName: "play.circle.fill")
            Text("Resume")
          }
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Theme.neonYellow)
          .padding(.horizontal, 20)
          .padding(.vertical, 8)
          .background(Color.black.opacity(0.5))
          .cornerRadius(20)
        }
      } else {
        Button(intent: PauseIntent()) {
          HStack {
            Image(systemName: "pause.circle.fill")
            Text("Pause")
          }
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Theme.neonYellow)
          .padding(.horizontal, 20)
          .padding(.vertical, 8)
          .background(Color.black.opacity(0.5))
          .cornerRadius(20)
        }
      }
    }
  }
}
