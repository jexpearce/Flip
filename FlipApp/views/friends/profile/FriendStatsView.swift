import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct FriendStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: FirebaseManager.FlipUser
    @State private var animateStats = false

    // Cyan-midnight theme colors
    private let cyanBlueAccent = Theme.lightTealBlue
    private let cyanBlueGlow = Theme.lightTealBlue.opacity(0.5)

    var averageSessionLength: Int {
        if user.totalSessions == 0 { return 0 }
        return user.totalFocusTime / user.totalSessions
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Theme.deepMidnightPurple,  // Deep midnight purple
                    Theme.mediumMidnightPurple,  // Medium midnight purple
                    Theme.darkCyanBlue.opacity(0.7),  // Dark cyan blue
                    Theme.deeperCyanBlue.opacity(0.6),  // Deeper cyan blue
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.2), cyanBlueAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300).offset(x: 150, y: -150).blur(radius: 50)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()

                    VStack(spacing: 4) {
                        Text("\(user.username)'s STATS").font(.system(size: 24, weight: .black))
                            .tracking(6).foregroundColor(.white)
                            .shadow(color: cyanBlueGlow, radius: 8)

                        Text("スタッツ").font(.system(size: 12)).tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Close button
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                            Image(systemName: "xmark.circle.fill").font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 40)

                // Main stats display
                VStack(spacing: 30) {
                    // Total Focus Time
                    FriendStatCard(
                        title: "TOTAL FOCUS TIME",
                        value: "\(user.totalFocusTime)",
                        unit: "minutes",
                        icon: "clock.fill",
                        color: cyanBlueAccent,
                        delay: 0
                    )
                    .scaleEffect(animateStats ? 1 : 0.8).opacity(animateStats ? 1 : 0)

                    // Total Sessions
                    FriendStatCard(
                        title: "TOTAL SESSIONS",
                        value: "\(user.totalSessions)",
                        unit: "completed",
                        icon: "checkmark.circle.fill",
                        color: Theme.emeraldGreen,
                        delay: 0.1
                    )
                    .scaleEffect(animateStats ? 1 : 0.8).opacity(animateStats ? 1 : 0)

                    // Average Session Length
                    FriendStatCard(
                        title: "AVERAGE SESSION LENGTH",
                        value: "\(averageSessionLength)",
                        unit: "minutes",
                        icon: "chart.bar.fill",
                        color: Theme.saturatedOrange,
                        delay: 0.2
                    )
                    .scaleEffect(animateStats ? 1 : 0.8).opacity(animateStats ? 1 : 0)

                    // Longest Session
                    FriendStatCard(
                        title: "LONGEST SESSION",
                        value: "\(user.longestSession)",
                        unit: "minutes",
                        icon: "crown.fill",
                        color: Theme.pink,
                        delay: 0.3
                    )
                    .scaleEffect(animateStats ? 1 : 0.8).opacity(animateStats ? 1 : 0)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Back button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("BACK TO PROFILE").font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cyanBlueAccent.opacity(0.7),
                                                cyanBlueAccent.opacity(0.4),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Theme.silveryGradient, lineWidth: 1)
                            }
                        )
                        .shadow(color: cyanBlueGlow, radius: 8)
                }
                .padding(.horizontal, 30).padding(.bottom, 40).opacity(animateStats ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateStats)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animateStats = true }
            }
        }
    }
}
