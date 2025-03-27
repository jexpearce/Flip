import FirebaseAuth
import Foundation
import SwiftUI

struct StreakAchievementAlert: View {
    @Binding var isPresented: Bool
    let streakStatus: StreakStatus
    let streakCount: Int

    @State private var animateShine = false
    @State private var animateGlow = false
    @State private var showConfetti = false

    // Dynamic title and description based on streak status
    private var title: String {
        switch streakStatus {
        case .orangeFlame:
            return "STREAK IGNITED!"
        case .redFlame:
            return "BLAZING STREAK!"
        default:
            return "STREAK ACHIEVED!"
        }
    }

    private var subtitle: String {
        switch streakStatus {
        case .orangeFlame:
            return "火がついた"
        case .redFlame:
            return "燃え上がる"
        default:
            return "達成した"
        }
    }

    private var description: String {
        switch streakStatus {
        case .orangeFlame:
            return
                "You're on fire! You've completed \(streakCount) successful sessions within 48 hours."
        case .redFlame:
            return
                "You're blazing! You've maintained an exceptional discipline streak of \(streakCount) sessions!"
        default:
            return "You've achieved a streak of \(streakCount) sessions!"
        }
    }

    private var mainColor: Color {
        streakStatus == .redFlame
            ? Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
            :  // Red
            Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)  // Orange
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            // Alert container
            VStack(spacing: 25) {
                // Streak badge
                ZStack {
                    // Animated flame background
                    ZStack {
                        // Base glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        mainColor.opacity(0.7),
                                        mainColor.opacity(0.3),
                                        mainColor.opacity(0.1),
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 120, height: 120)

                        // Animated pulse
                        Circle()
                            .fill(mainColor.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateGlow ? 1.1 : 0.9)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animateGlow)
                    }

                    // Flames icon
                    Image(
                        systemName: streakStatus == .redFlame
                            ? "flame.fill" : "flame"
                    )
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(
                        color: mainColor.opacity(0.8),
                        radius: animateGlow ? 15 : 5
                    )
                    .scaleEffect(animateGlow ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(
                            autoreverses: true), value: animateGlow)

                    // Number badge showing streak count
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.8),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(mainColor, lineWidth: 2)
                            )
                            .shadow(color: mainColor.opacity(0.5), radius: 5)

                        Text("\(streakCount)")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(mainColor)
                    }
                    .position(x: 90, y: 30)
                }
                .padding(20)

                // Achievement text
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: mainColor.opacity(0.8), radius: 10)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 5)

                    Text(description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)

                    // Streak indicator with bonus info
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(mainColor)

                        let bonusText =
                            streakStatus == .redFlame
                            ? "1.8x score bonus" : "1.3x score bonus"
                        Text(bonusText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(mainColor)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(mainColor.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        mainColor.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Text("Keep your streak going to earn more points!")
                        .font(.system(size: 14))
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 10)
                }

                // Continue button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                // Vibrant gradient
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                mainColor.opacity(0.9),
                                                mainColor.opacity(0.6),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: mainColor.opacity(0.5), radius: 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(30)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(
                                        red: 26 / 255, green: 18 / 255,
                                        blue: 47 / 255),
                                    Color(
                                        red: 16 / 255, green: 24 / 255,
                                        blue: 57 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Glass effect
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))

                    // Border glow
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    mainColor.opacity(0.8),
                                    mainColor.opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .frame(maxWidth: 350)
            .shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.5)
            .opacity(isPresented ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8), value: isPresented
            )

            // Confetti effect
            if showConfetti {
                ConfettiView(colors: [
                    mainColor, .white, .yellow, mainColor.opacity(0.5),
                ])
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(
                    Animation.linear(duration: 3).repeatForever(
                        autoreverses: false)
                ) {
                    animateShine = true
                }
                withAnimation {
                    animateGlow = true
                    showConfetti = true
                }
            }
        }
    }
}

// Helper extension for ScoreManager to display achievement alerts
extension ScoreManager {
    // Called after streak status updates to check if we should show the achievement alert
    func checkForStreakAchievement(oldStatus: StreakStatus) -> (
        shouldShow: Bool, newStatus: StreakStatus, count: Int
    )? {
        // Only show the alert when upgrading streak status
        if streakStatus != oldStatus && streakStatus != .none {
            // If going from none to orange, or orange to red
            if (oldStatus == .none && streakStatus == .orangeFlame)
                || (oldStatus == .orangeFlame && streakStatus == .redFlame)
            {
                return (true, streakStatus, currentStreak)
            }
        }
        return nil
    }

    // Updated processSession method to track streak achievement
    func processSessionWithAchievementCheck(
        duration: Int, wasSuccessful: Bool, actualDuration: Int,
        pausesEnabled: Bool
    ) -> (
        rankPromotion: (Bool, (String, Color))?,
        streakAchievement: (Bool, StreakStatus, Int)?
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return (nil, nil)
        }

        let oldScore = currentScore
        let oldStreakStatus = streakStatus

        // Call the regular process session method
        processSession(
            duration: duration, wasSuccessful: wasSuccessful,
            actualDuration: actualDuration, pausesEnabled: pausesEnabled)

        // Check both rank promotion and streak achievement
        let rankPromotion = checkForRankPromotion(
            oldScore: oldScore, newScore: currentScore)

        let streakAchievement: (Bool, StreakStatus, Int)? =
            if let achievement = checkForStreakAchievement(
                oldStatus: oldStreakStatus)
            {
                (
                    achievement.shouldShow, achievement.newStatus,
                    achievement.count
                )
            } else {
                nil
            }

        return (rankPromotion, streakAchievement)
    }
}
