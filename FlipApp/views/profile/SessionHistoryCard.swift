import SwiftUI

struct SessionHistoryCard: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.formattedStartTime)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text("\(session.actualDuration) min")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .retroGlow()
            }

            Spacer()

            Image(
                systemName: session.wasSuccessful
                    ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .foregroundColor(.white)
            .font(.system(size: 24))
            .retroGlow()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
