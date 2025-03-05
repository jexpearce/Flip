import ActivityKit
import SwiftUI
import WidgetKit

func DynamicIslandView(context: ActivityViewContext<FlipActivityAttributes>) -> DynamicIsland {
    DynamicIsland {
        // Expanded View
        DynamicIslandExpandedRegion(.center) {
            HStack {
                // Icon - different based on state
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.system(size: 16, weight: .bold)) // Reduced from 20 to 16
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                context.state.isPaused ?
                                    Color(red: 239/255, green: 68/255, blue: 68/255) :
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                context.state.isPaused ?
                                    Color(red: 185/255, green: 28/255, blue: 28/255) :
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                
                // Time display - show either session time or pause time
                if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(pauseTime)
                            .font(.system(size: 18, weight: .bold, design: .monospaced)) // Reduced from 20 to 18
                            .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255)) // Yellow accent
                        
                        Text("Pause")
                            .font(.system(size: 9, weight: .medium)) // Reduced from 10 to 9
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    Text(context.state.remainingTime)
                        .font(.system(size: 20, weight: .bold, design: .monospaced)) // Reduced from 24 to 20
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6) // Reduced from 8 to 6
                }

                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    Spacer()
                    HStack(spacing: 2) { // Reduced from 4 to 2
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 14, weight: .bold)) // Reduced from 16 to 14
                        Image(systemName: "pause.circle")
                            .font(.system(size: 12, weight: .bold)) // Reduced from 14 to 12
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 4) // Reduced from 6 to 4
                    .padding(.horizontal, 6) // Reduced from 8 to 6
                    .padding(.vertical, 3) // Reduced from 4 to 3
                    .background(
                        RoundedRectangle(cornerRadius: 8) // Reduced from 10 to 8
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 6) // Reduced from 8 to 6
        }

        DynamicIslandExpandedRegion(.bottom) {
            if let message = context.state.countdownMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium)) // Reduced from 14 to 12
                    .foregroundColor(.white)
                    .padding(.horizontal, 8) // Reduced from 10 to 8
                    .padding(.vertical, 4) // Reduced from 5 to 4
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6) // Reduced from 8 to 6
            } else if let flipBackTime = context.state.flipBackTimeRemaining {
                Text("\(flipBackTime)s to flip")
                    .font(.system(size: 12, weight: .medium)) // Reduced from 14 to 12
                    .foregroundColor(.white)
                    .padding(.horizontal, 8) // Reduced from 10 to 8
                    .padding(.vertical, 4) // Reduced from 5 to 4
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6) // Reduced from 8 to 6
            } else if context.state.isPaused {
                HStack(spacing: 8) { // Reduced from 10 to 8
                    Button(intent: ResumeIntent()) {
                        Label("Resume", systemImage: "play.circle.fill")
                            .font(.system(size: 12, weight: .bold)) // Reduced from 14 to 12
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
                            .padding(.horizontal, 8) // Reduced from 10 to 8
                            .padding(.vertical, 4) // Reduced from 5 to 4
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6) // Reduced from 8 to 6
                            .shadow(color: Color.green.opacity(0.3), radius: 3) // Reduced from 4 to 3
                    }
                    
                    if let pauseTime = context.state.pauseTimeRemaining {
                        Text("Auto: \(pauseTime)")
                            .font(.system(size: 11, weight: .medium)) // Reduced from 12 to 11
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            } else {
                Button(intent: PauseIntent()) {
                    Label("Pause", systemImage: "pause.circle.fill")
                        .font(.system(size: 12, weight: .bold)) // Reduced from 14 to 12
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
                        .padding(.horizontal, 8) // Reduced from 10 to 8
                        .padding(.vertical, 4) // Reduced from 5 to 4
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6) // Reduced from 8 to 6
                        .shadow(color: Color.red.opacity(0.3), radius: 3) // Reduced from 4 to 3
                }
            }
        }
    } compactLeading: {
        if context.state.isPaused {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 14, weight: .bold)) // Reduced from 16 to 14
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 239/255, green: 68/255, blue: 68/255),
                            Color(red: 185/255, green: 28/255, blue: 28/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .bold)) // Reduced from 16 to 14
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    } compactTrailing: {
        if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
            Text(pauseTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 250/255, green: 204/255, blue: 21/255), // Yellow
                            Color(red: 234/255, green: 179/255, blue: 8/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } else {
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
        }
    } minimal: {
        Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
            .font(.system(size: 14, weight: .bold)) // Reduced from 16 to 14
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        context.state.isPaused ?
                            Color(red: 239/255, green: 68/255, blue: 68/255) :
                            Color.white,
                        context.state.isPaused ?
                            Color(red: 185/255, green: 28/255, blue: 28/255) :
                            Color.white.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}