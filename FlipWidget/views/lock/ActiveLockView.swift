// ActiveLockView.swift
import ActivityKit
import SwiftUI
import WidgetKit

struct ActiveLockView: View {
    let context: ActivityViewContext<FlipActivityAttributes>
    
    private let gradientBackground = LinearGradient(
        colors: [
            Color(red: 20/255, green: 10/255, blue: 40/255),
            Color(red: 35/255, green: 20/255, blue: 90/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let glassEffect = Color.white.opacity(0.05)
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with app name and icon
            HStack {
                Text("Flip")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255)) // Yellow accent
                
                Text("Focus Session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if context.state.isPaused {
                    StatusPill(text: "PAUSED", color: Color(red: 239/255, green: 68/255, blue: 68/255))
                } else {
                    StatusPill(text: "ACTIVE", color: Color(red: 34/255, green: 197/255, blue: 94/255))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical, 4)

            // Timer and Pauses Row
            HStack {
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pauseTime)
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255)) // Yellow accent
                            .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.5), radius: 4)
                            
                        Text("Pause time left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    Text(context.state.remainingTime)
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        .frame(minWidth: 80)
                }

                Spacer()

                // Only show pauses if not paused and there are pauses remaining
                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    HStack(spacing: 4) {
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "pause.circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                }
            }

            // Status Messages
            if let countdownMessage = context.state.countdownMessage {
                StatusMessage(message: countdownMessage)
            } else if let flipBackTime = context.state.flipBackTimeRemaining {
                StatusMessage(message: "\(flipBackTime) seconds to pause or flip back")
            } else if context.state.isPaused, let pauseTime = context.state.pauseTimeRemaining {
                StatusMessage(message: "Session paused. Will resume when timer ends.")
            }

            // Control Buttons
            if context.state.isPaused {
                Button(intent: ResumeIntent()) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 34/255, green: 197/255, blue: 94/255),
                                    Color(red: 22/255, green: 163/255, blue: 74/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            glassEffect
                        }
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.green.opacity(0.3), radius: 8)
                }
            } else if context.state.remainingPauses > 0 {
                Button(intent: PauseIntent()) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                        Text("Pause")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            glassEffect
                        }
                    )
                    .cornerRadius(20)
                    .shadow(color: Color.red.opacity(0.3), radius: 8)
                }
            }
        }
        .padding()
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
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.8))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct StatusMessage: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .multilineTextAlignment(.center)
    }
}