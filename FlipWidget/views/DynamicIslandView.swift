import ActivityKit
import SwiftUI
import WidgetKit

func DynamicIslandView(context: ActivityViewContext<FlipActivityAttributes>)
  -> DynamicIsland
{
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
