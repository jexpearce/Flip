// ActiveLockView.swift
import ActivityKit
import SwiftUI
import WidgetKit

struct ActiveLockView: View {
    let context: ActivityViewContext<FlipActivityAttributes>

    private let gradientBackground = LinearGradient(
        colors: [Theme.deepMidnightPurple, Theme.darkPurpleBlue],
        startPoint: .top,
        endPoint: .bottom
    )

    private let glassEffect = Color.white.opacity(0.05)

    var body: some View {
        VStack(spacing: 10) {  // Reduced spacing from 12 to 10
            // Header with app name and icon
            HStack {
                Text("Flip").font(.system(size: 18, weight: .black))  // Reduced from 20 to 18
                    .foregroundColor(Theme.yellow)  // Yellow accent

                Text("Focus").font(.system(size: 14, weight: .medium))  // Reduced from 16 to 14
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if context.state.isPaused {
                    StatusPill(text: "PAUSED", color: Theme.mutedRed)
                }
                else {
                    StatusPill(text: "ACTIVE", color: Theme.mutedGreen)
                }
            }

            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 2)  // Reduced from 4 to 2

            // Timer and Pauses Row
            HStack {
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.system(size: 18, weight: .bold))  // Reduced from 20 to 18
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)

                if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
                    VStack(alignment: .leading, spacing: 0) {  // Reduced spacing from 2 to 0
                        Text(pauseTime)
                            .font(.system(size: 22, weight: .black, design: .monospaced))  // Reduced from 24 to 22
                            .foregroundColor(Theme.yellow)  // Yellow accent
                            .shadow(color: Theme.yellow.opacity(0.5), radius: 4)

                        Text("Pause").font(.system(size: 10, weight: .medium))  // Reduced from 12 to 10
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                else {
                    Text(context.state.remainingTime)
                        .font(.system(size: 22, weight: .black, design: .monospaced))  // Reduced from 24 to 22
                        .foregroundColor(.white)
                        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                        .frame(minWidth: 70)  // Reduced from 80 to 70
                }

                Spacer()

                // Only show pauses if not paused and there are pauses remaining
                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    HStack(spacing: 2) {  // Reduced spacing from 4 to 2
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 16, weight: .bold))  // Reduced from 18 to 16
                            .foregroundColor(.white)
                        Image(systemName: "pause.circle").font(.system(size: 14, weight: .bold))  // Reduced from 16 to 14
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)  // Reduced from 10 to 8
                    .padding(.vertical, 4)  // Reduced from 5 to 4
                    .background(
                        RoundedRectangle(cornerRadius: 10)  // Reduced from 12 to 10
                            .fill(Color.white.opacity(0.1))
                    )
                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)
                }
            }

            // Status Messages - Condensed
            if let countdownMessage = context.state.countdownMessage {
                StatusMessage(message: countdownMessage)
            }
            else if let flipBackTime = context.state.flipBackTimeRemaining {
                StatusMessage(message: "\(flipBackTime)s to pause/flip")
            }
            else if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
                StatusMessage(message: "Paused: \(pauseTime) remaining")
            }

            // Control Buttons - More compact
            if context.state.isPaused {
                Button(intent: ResumeIntent()) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 14, weight: .bold))  // Reduced from 16 to 14
                    .foregroundColor(.white).padding(.horizontal, 16)  // Reduced from 20 to 16
                    .padding(.vertical, 6)  // Reduced from 8 to 6
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [Theme.mutedGreen, Theme.darkerGreen],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            glassEffect
                        }
                    )
                    .cornerRadius(16)  // Reduced from 20 to 16
                    .shadow(color: Color.green.opacity(0.3), radius: 6)  // Reduced from 8 to 6
                }
            }
            else if context.state.remainingPauses > 0 {
                Button(intent: PauseIntent()) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                        Text("Pause")
                    }
                    .font(.system(size: 14, weight: .bold))  // Reduced from 16 to 14
                    .foregroundColor(.white).padding(.horizontal, 16)  // Reduced from 20 to 16
                    .padding(.vertical, 6)  // Reduced from 8 to 6
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Theme.mutedRed,
                                    Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            glassEffect
                        }
                    )
                    .cornerRadius(16)  // Reduced from 20 to 16
                    .shadow(color: Color.red.opacity(0.3), radius: 6)  // Reduced from 8 to 6
                }
            }
        }
        .padding(10)  // Reduced from standard padding
        .background(
            ZStack {
                gradientBackground
                glassEffect
            }
        )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text).font(.system(size: 10, weight: .bold))  // Reduced from 12 to 10
            .tracking(1).foregroundColor(.white).padding(.horizontal, 8)  // Reduced from 10 to 8
            .padding(.vertical, 3)  // Reduced from 4 to 3
            .background(
                Capsule().fill(color.opacity(0.8))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            )
    }
}

struct StatusMessage: View {
    let message: String

    var body: some View {
        Text(message).font(.system(size: 13, weight: .medium))  // Reduced from 16 to 13
            .foregroundColor(.white).padding(.horizontal, 8)  // Reduced from 12 to 8
            .padding(.vertical, 5)  // Reduced from 8 to 5
            .background(
                RoundedRectangle(cornerRadius: 10)  // Reduced from 12 to 10
                    .fill(Color.white.opacity(0.08))
            )
            .multilineTextAlignment(.center).lineLimit(1)  // Ensure it stays on one line
    }
}
