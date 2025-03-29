import SwiftUI

struct SessionHistoryCard: View {
    let session: Session

    private var statusColor: LinearGradient {
        session.wasSuccessful
            ? LinearGradient(
                colors: [
                    Theme.mutedGreen,  // Success green
                    Theme.darkerGreen,  // Darker success green
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            : LinearGradient(
                colors: [
                    Theme.mutedRed,  // Failure red
                    Theme.darkerRed,  // Darker failure red
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.formattedStartTime).font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text("\(session.actualDuration) min").font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Theme.lightTealBlue.opacity(0.3), radius: 4)
            }

            Spacer()

            // Status Icon with enhanced styling
            ZStack {
                Circle().fill(statusColor).frame(width: 40, height: 40)
                    .shadow(
                        color: session.wasSuccessful
                            ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                        radius: 8
                    )

                Circle().fill(Color.white.opacity(0.1)).frame(width: 40, height: 40)

                Image(
                    systemName: session.wasSuccessful
                        ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 1)
            }
        }
        .padding()
        .background(
            ZStack {
                // Base layer with glass effect
                RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient).opacity(0.1)

                // Frosted overlay
                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                // Gradient border
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
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2).padding(.horizontal)
    }
}
