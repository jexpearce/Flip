import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct EnhancedWeeklyStatsView: View {
    let user: FirebaseManager.FlipUser
    let weeksLongestSession: Int?
    let cyanBlueAccent: Color
    let cyanBlueGlow: Color
    @State private var animate = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    Text("\(user.username)'s LONGEST FLIP").font(.system(size: 14, weight: .black))
                        .tracking(2).foregroundColor(.white)

                    Text("THIS WEEK").font(.system(size: 12, weight: .bold)).tracking(1)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6).fill(cyanBlueAccent.opacity(0.3))
                        )
                        .foregroundColor(.white.opacity(0.9))

                    Image(systemName: "crown.fill").font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.orange.opacity(0.7), radius: 4)
                        .rotationEffect(Angle(degrees: animate ? 5 : -5))
                        .animation(
                            Animation.easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                            value: animate
                        )
                }

                Text(
                    weeksLongestSession != nil
                        ? "\(weeksLongestSession!) min" : "No sessions yet this week"
                )
                .font(.system(size: 32, weight: .black)).foregroundColor(.white)
                .shadow(color: cyanBlueGlow, radius: 8).opacity(animate ? 1 : 0.7)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: animate
                )
            }
            Spacer()
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [cyanBlueAccent.opacity(0.4), cyanBlueAccent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle pattern overlay
                HStack(spacing: 0) {
                    ForEach(0..<20) { i in
                        Rectangle().fill(Color.white).frame(width: 1, height: 100).opacity(0.03)
                            .offset(x: CGFloat(i * 15))
                    }
                }
                .mask(RoundedRectangle(cornerRadius: 18))

                RoundedRectangle(cornerRadius: 18).stroke(Theme.silveryGradient3, lineWidth: 1.5)
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4).padding(.horizontal)
        .onAppear { withAnimation { animate = true } }
    }
}
