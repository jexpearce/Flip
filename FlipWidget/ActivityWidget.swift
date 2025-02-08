import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Lock Screen Views
struct LockScreenLiveActivityView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    ZStack {
      Color.black
      VStack(spacing: 12) {
        if context.state.isFailed {
          FailedStateView()
        } else {
          ActiveStateView(context: context)
        }
      }
      .padding()
    }
  }
}

private struct FailedStateView: View {
  var body: some View {
    VStack(spacing: 15) {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 40))
        .foregroundColor(.red)

      Text("Session Failed")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.red)

      Text("Phone was moved too many times")
        .font(.system(size: 16))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
    }
  }
}

private struct ActiveStateView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    VStack(spacing: 12) {
      // Timer and Flips Row
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
      if context.state.isPaused {
        Button(intent: ResumeIntent()) {
          HStack {
            Image(systemName: "play.circle.fill")
            Text("Resume Session")
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

// MARK: - Main Widget Configuration
@available(iOS 16.1, *)
struct ActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FlipActivityAttributes.self) { context in
      LockScreenLiveActivityView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
          HStack {
            Text(context.state.remainingTime)
              .font(.system(size: 24, weight: .bold, design: .monospaced))
              .foregroundColor(.white)

            if !context.state.isPaused {
              Image(systemName: "timer")
                .foregroundColor(Theme.neonYellow)
            }
          }
        }

        DynamicIslandExpandedRegion(.bottom) {
          if context.state.isPaused {
            Button(intent: ResumeIntent()) {
              Label("Resume", systemImage: "play.circle.fill")
                .foregroundColor(Theme.neonYellow)
            }
          } else {
            Button(intent: PauseIntent()) {
              Label("Pause", systemImage: "pause.circle.fill")
                .foregroundColor(Theme.neonYellow)
            }
          }
        }
      } compactLeading: {
        Image(systemName: "timer")
          .foregroundColor(Theme.neonYellow)
      } compactTrailing: {
        Text(context.state.remainingTime)
          .font(.system(.body, design: .monospaced))
          .foregroundColor(.white)
      } minimal: {
        Image(
          systemName: context.state.isPaused ? "pause.circle.fill" : "timer"
        )
        .foregroundColor(Theme.neonYellow)
      }
    }
  }
}
