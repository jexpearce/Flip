import ActivityKit
import SwiftUI
import WidgetKit

func DynamicIslandView(context: ActivityViewContext<FlipActivityAttributes>)
    -> DynamicIsland
{
    DynamicIsland {
        // Expanded View
        DynamicIslandExpandedRegion(.center) {
            ZStack(alignment: .leading) {
                // Container with fixed height to prevent shifting
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 28)

                HStack {
                    // Icon - different based on state
                    Image(
                        systemName: context.state.isPaused
                            ? "pause.circle.fill" : "timer"
                    )
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                context.state.isPaused
                                    ? Color(
                                        red: 239 / 255, green: 68 / 255,
                                        blue: 68 / 255)
                                    : Color(
                                        red: 56 / 255, green: 189 / 255,
                                        blue: 248 / 255),
                                context.state.isPaused
                                    ? Color(
                                        red: 185 / 255, green: 28 / 255,
                                        blue: 28 / 255)
                                    : Color(
                                        red: 14 / 255, green: 165 / 255,
                                        blue: 233 / 255),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: Color(
                            red: 56 / 255, green: 189 / 255, blue: 248 / 255
                        ).opacity(0.5), radius: 4)

                    // Time display - show either session time or pause time
                    if context.state.isPaused,
                        let pauseTime = context.state.pauseTimeRemaining
                    {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(pauseTime)
                                .font(
                                    .system(
                                        size: 16, weight: .bold,
                                        design: .monospaced)
                                )
                                .foregroundColor(
                                    Color(
                                        red: 250 / 255, green: 204 / 255,
                                        blue: 21 / 255))

                            Text("Pause")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        Text(context.state.remainingTime)
                            .font(
                                .system(
                                    size: 18, weight: .bold, design: .monospaced
                                )
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white, Color.white.opacity(0.8),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 56 / 255, green: 189 / 255,
                                    blue: 248 / 255
                                ).opacity(0.5), radius: 4)
                    }

                    if !context.state.isPaused
                        && context.state.remainingPauses > 0
                    {
                        Spacer()
                        HStack(spacing: 2) {
                            Text("\(context.state.remainingPauses)")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "pause.circle")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white, Color.white.opacity(0.7),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color(
                                red: 56 / 255, green: 189 / 255, blue: 248 / 255
                            ).opacity(0.4), radius: 3
                        )
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }

        DynamicIslandExpandedRegion(.bottom) {
            // Fixed height container to prevent shifting
            ZStack(alignment: .center) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 30)

                if let message = context.state.countdownMessage {
                    Text(message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(5)
                } else if let flipBackTime = context.state.flipBackTimeRemaining
                {
                    Text("\(flipBackTime)s to flip")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(5)
                } else if context.state.isPaused {
                    HStack(spacing: 6) {
                        Button(intent: ResumeIntent()) {
                            Label("Resume", systemImage: "play.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(
                                                red: 34 / 255, green: 197 / 255,
                                                blue: 94 / 255),
                                            Color(
                                                red: 22 / 255, green: 163 / 255,
                                                blue: 74 / 255),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(5)
                                .shadow(
                                    color: Color.green.opacity(0.3), radius: 2)
                        }

                        if let pauseTime = context.state.pauseTimeRemaining {
                            Text("Auto: \(pauseTime)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else {
                    Button(intent: PauseIntent()) {
                        Label("Pause", systemImage: "pause.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 239 / 255, green: 68 / 255,
                                            blue: 68 / 255),
                                        Color(
                                            red: 185 / 255, green: 28 / 255,
                                            blue: 28 / 255),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(5)
                            .shadow(color: Color.red.opacity(0.3), radius: 2)
                    }
                }
            }
        }
    } compactLeading: {
        Image(
            systemName: context.state.isPaused ? "pause.circle.fill" : "timer"
        )
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(
            LinearGradient(
                colors: [
                    context.state.isPaused
                        ? Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
                        : Color.white,
                    context.state.isPaused
                        ? Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255)
                        : Color.white.opacity(0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    } compactTrailing: {
        if context.state.isPaused,
            let pauseTime = context.state.pauseTimeRemaining
        {
            Text(pauseTime)
                .font(.system(size: 13, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 250 / 255, green: 204 / 255, blue: 21 / 255
                            ),
                            Color(
                                red: 234 / 255, green: 179 / 255, blue: 8 / 255),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            Text(context.state.remainingTime)
                .font(.system(size: 13, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    } minimal: {
        Image(
            systemName: context.state.isPaused ? "pause.circle.fill" : "timer"
        )
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(
            LinearGradient(
                colors: [
                    context.state.isPaused
                        ? Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
                        : Color.white,
                    context.state.isPaused
                        ? Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255)
                        : Color.white.opacity(0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
