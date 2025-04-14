import SwiftUI

struct EnhancedStatsCardView: View {
    let user: FirebaseManager.FlipUser
    let cyanBlueAccent: Color
    @Binding var showDetailedStats: Bool
    @State private var animatePulse = false

    var body: some View {
        VStack(spacing: 15) {
            // Quick Stats overview
            HStack(spacing: 30) {
                EnhancedStatBox(
                    title: "SESSIONS",
                    value: "\(user.totalSessions)",
                    icon: "timer",
                    accentColor: cyanBlueAccent
                )

                EnhancedStatBox(
                    title: "FOCUS TIME",
                    value: "\(user.totalFocusTime)m",
                    icon: "clock.fill",
                    accentColor: cyanBlueAccent
                )
            }
            .padding(.vertical, 5)

            // View detailed stats button
            Button(action: { showDetailedStats = true }) {
                HStack {
                    Text("VIEW DETAILED STATS").font(.system(size: 15, weight: .bold)).tracking(1)
                        .foregroundColor(.white)

                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7)).padding(.leading, 4)
                        .offset(x: animatePulse ? 4 : 0)
                        .animation(
                            Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                            value: animatePulse
                        )
                }
                .padding(.vertical, 9).frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        cyanBlueAccent.opacity(0.4), cyanBlueAccent.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.silveryGradient5, lineWidth: 1)
                    }
                )
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [cyanBlueAccent.opacity(0.5), cyanBlueAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18).stroke(Theme.silveryGradient3, lineWidth: 1.5)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4).padding(.horizontal)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { animatePulse = true } }
    }
}
