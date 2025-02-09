import ActivityKit
import SwiftUI
import WidgetKit

struct ActiveLockView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    let isPaused = context.state.isPaused

    VStack(spacing: 12) {
      // Timer and Flips Row
      HStack {
        Image(
          systemName: isPaused ? "pause.circle.fill" : "timer"
        )
        .font(.system(size: 20))
        .foregroundColor(Theme.neonYellow)

        Text(context.state.remainingTime)
          .font(.system(size: 24, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
          .frame(minWidth: 80)

        Spacer()

        if context.state.remainingFlips > 0 {
          HStack(spacing: 4) {
            Text("\(context.state.remainingFlips)")
              .font(.system(size: 18, weight: .medium))
            Image(systemName: "arrow.2.squarepath")
              .font(.system(size: 16))
          }
          .foregroundColor(Theme.neonYellow)
        }
      }

      // Flip Back Counter if active
      if let flipBackTime = context.state.flipBackTimeRemaining {
        Text("\(flipBackTime) seconds to flip back")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Theme.neonYellow)
      }

      // Pause/Resume Button
      (isPaused
        ? Button(intent: ResumeIntent()) {
          HStack {
            Image(systemName: "play.circle.fill")
            Text("Resume")
          }
        }
        : Button(intent: PauseIntent()) {
          HStack {
            Image(systemName: "pause.circle.fill")
            Text("Pause")
          }
        })
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Theme.neonYellow)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
    }
  }
}
