// DynamicIslandView function
import ActivityKit
import SwiftUI
import WidgetKit

func DynamicIslandView(context: ActivityViewContext<FlipActivityAttributes>) -> DynamicIsland {
    DynamicIsland {
        DynamicIslandExpandedRegion(.center) {
            HStack {
                Text(context.state.remainingTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .retroGlow()

                if !context.state.isPaused {
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                        .retroGlow()
                }

                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "pause.circle")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .retroGlow()
                }
            }
        }

        DynamicIslandExpandedRegion(.bottom) {
            if let message = context.state.countdownMessage {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .retroGlow()
            } else if let flipBackTime = context.state.flipBackTimeRemaining {
                Text("\(flipBackTime)s to pause/flip")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .retroGlow()
            } else if context.state.isPaused {
                Button(intent: ResumeIntent()) {
                    Label("Resume", systemImage: "play.circle.fill")
                        .foregroundColor(.white)
                        .retroGlow()
                }
            } else {
                Button(intent: PauseIntent()) {
                    Label("Pause", systemImage: "pause.circle.fill")
                        .foregroundColor(.white)
                        .retroGlow()
                }
            }
        }
    } compactLeading: {
        Image(systemName: "timer")
            .foregroundColor(.white)
            .retroGlow()
    } compactTrailing: {
        Text(context.state.remainingTime)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.white)
            .retroGlow()
    } minimal: {
        Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
            .foregroundColor(.white)
            .retroGlow()
    }
}