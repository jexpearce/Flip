import SwiftUI

struct RankPromotionAlert: View {
    @Binding var isPresented: Bool
    let rankName: String
    let rankColor: Color
    @State private var animateShine = false
    @State private var animateGlow = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }

            // Alert container
            VStack(spacing: 25) {
                // Rank badge
                ZStack {
                    // Shimmering background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [rankColor.opacity(0.8), rankColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

                    // Shine effect
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 120, height: 120)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear, .white.opacity(0.1), .white.opacity(0.5),
                                            .white.opacity(0.1), .clear,
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 200, height: 200).rotationEffect(.degrees(45))
                                .offset(x: animateShine ? 200 : -200)
                        )

                    // Rank icon
                    Image(systemName: "trophy.fill").font(.system(size: 50)).foregroundColor(.white)
                        .shadow(color: rankColor.opacity(0.8), radius: animateGlow ? 15 : 5)
                        .animation(
                            Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: animateGlow
                        )
                }
                .padding(20)

                // Promotion text
                VStack(spacing: 8) {
                    Text("PROMOTION!").font(.system(size: 24, weight: .black)).tracking(4)
                        .foregroundColor(.white).shadow(color: rankColor.opacity(0.8), radius: 10)

                    Text("You have achieved the rank of").font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))

                    Text(rankName).font(.system(size: 32, weight: .black))
                        .foregroundColor(rankColor)
                        .shadow(color: rankColor.opacity(0.8), radius: 10).padding(.vertical, 5)

                    // New streaming ribbon behind rank name
                    ZStack {
                        Text("LEVELED UP!").font(.system(size: 14, weight: .black)).tracking(2)
                            .padding(.horizontal, 16).padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                rankColor.opacity(0.8), rankColor.opacity(0.6),
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(color: rankColor.opacity(0.5), radius: 4)
                    }

                    Text("Keep up the discipline!").font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9)).padding(.top, 10)
                }

                // Continue button
                Button(action: { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }) {
                    Text("CONTINUE").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(
                            ZStack {
                                // Vibrant gradient
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                rankColor.opacity(0.9), rankColor.opacity(0.6),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Theme.silveryGradient, lineWidth: 1)
                            }
                        )
                        .shadow(color: rankColor.opacity(0.5), radius: 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(30)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [Theme.mutedPurple, Theme.blueishPurple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Glass effect
                    RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.05))

                    // Border glow
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [rankColor.opacity(0.8), rankColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.5).opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)

            // Confetti effect
            if showConfetti {
                ConfettiView(colors: [rankColor, .white, .yellow, rankColor.opacity(0.5)])
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
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

// Confetti animation for celebration effect
struct ConfettiView: View {
    let colors: [Color]
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(color: colors[index % colors.count], animate: $animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct ConfettiPiece: View {
    let color: Color
    @Binding var animate: Bool

    @State private var xPosition: CGFloat = 0
    @State private var yPosition: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.1

    var body: some View {
        Rectangle().fill(color).frame(width: 8, height: 8).scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(
                x: animate ? xPosition : UIScreen.main.bounds.width / 2,
                y: animate ? yPosition : -20
            )
            .opacity(animate ? 0 : 1)
            .animation(
                Animation.timingCurve(0.17, 0.67, 0.83, 0.67, duration: 3)
                    .delay(Double.random(in: 0...0.5)),
                value: animate
            )
            .onAppear {
                withAnimation {
                    xPosition = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                    yPosition = CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    rotation = Double.random(in: 0...360)
                    scale = CGFloat.random(in: 0.4...1.2)
                }
            }
    }
}

// Usage example - integrate with ScoreManager
extension ScoreManager {
    // Add method to check for rank changes
    func checkForRankPromotion(oldScore: Double) -> (
        isPromoted: Bool, newRank: (name: String, color: Color)
    )? {
        let oldRank = getRankForScore(oldScore).name
        let newRank = getCurrentRank()

        if newRank.name != oldRank { return (true, newRank) }
        return nil
    }

    // Helper to get rank for a specific score (not just current score)
    private func getRankForScore(_ score: Double) -> (name: String, color: Color) {
        switch score {
        case 0.0..<30.0: return ("Novice", Theme.periwinkle)  // Periwinkle
        case 30.0..<60.0: return ("Apprentice", Theme.lightBlue)  // Light blue
        case 60.0..<90.0: return ("Beginner", Theme.standardBlue)  // Blue
        case 90.0..<120.0: return ("Steady", Theme.emeraldGreen)  // Green
        case 120.0..<150.0: return ("Focused", Theme.brightAmber)  // Bright amber
        case 150.0..<180.0: return ("Disciplined", Theme.orange)  // Orange
        case 180.0..<210.0: return ("Resolute", Theme.mutedRed)  // Red
        case 210.0..<240.0: return ("Master", Theme.pink)  // Pink
        case 240.0..<270.0: return ("Guru", Theme.purple)  // Vivid purple
        case 270.0...300.0: return ("Enlightened", Theme.brightFuchsia)  // Bright fuchsia
        default: return ("Unranked", Color.gray)
        }
    }
}
