import ActivityKit
import SwiftUI
import WidgetKit

func DynamicIslandView(context: ActivityViewContext<FlipActivityAttributes>) -> DynamicIsland {
    DynamicIsland {
        // Expanded View
        DynamicIslandExpandedRegion(.center) {
            HStack {
                // Time display with enhanced styling
                Text(context.state.remainingTime)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                if !context.state.isPaused {
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                }

                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "pause.circle")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
                }
            }
            .padding(.horizontal, 8)
        }

        DynamicIslandExpandedRegion(.bottom) {
            if let message = context.state.countdownMessage {
                Text(message)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
            } else if let flipBackTime = context.state.flipBackTimeRemaining {
                Text("\(flipBackTime)s to pause/flip")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4)
            } else if context.state.isPaused {
                Button(intent: ResumeIntent()) {
                    Label("Resume", systemImage: "play.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 4)
                }
            } else {
                Button(intent: PauseIntent()) {
                    Label("Pause", systemImage: "pause.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 4)
                }
            }
        }
    } compactLeading: {
        Image(systemName: "timer")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    } compactTrailing: {
        Text(context.state.remainingTime)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    } minimal: {
        Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}