// ActiveLockView.swift
import ActivityKit
import SwiftUI
import WidgetKit


struct ActiveLockView: View {
    let context: ActivityViewContext<FlipActivityAttributes>
    
    private let gradientBackground = LinearGradient(
        colors: [
            Color(red: 26/255, green: 14/255, blue: 47/255),
            Color(red: 30/255, green: 58/255, blue: 138/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let glassEffect = Color.white.opacity(0.05)
    
    var body: some View {
        VStack(spacing: 12) {
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

                Text(context.state.remainingTime)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    .frame(minWidth: 80)

                Spacer()

                if !context.state.isPaused && context.state.remainingPauses > 0 {
                    HStack(spacing: 4) {
                        Text("\(context.state.remainingPauses)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "pause.circle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                }
            }

            // Status Messages
            if let countdownMessage = context.state.countdownMessage {
                Text(countdownMessage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
            } else if let flipBackTime = context.state.flipBackTimeRemaining {
                Text("\(flipBackTime) seconds to pause or flip back")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
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
            } else {
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