import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 28, weight: .black)).foregroundColor(.white)
                .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)

            Text(title).font(.system(size: 10, weight: .heavy)).tracking(2)
                .foregroundColor(.white.opacity(0.7))

            Text(unit).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .background(
            ZStack {
                // Base glass effect
                RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient).opacity(0.1)

                // Frosted overlay
                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                // Top edge highlight
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                // Inner glow
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Theme.lightTealBlue.opacity(0.3), lineWidth: 1).blur(radius: 2)
                    .offset(y: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
