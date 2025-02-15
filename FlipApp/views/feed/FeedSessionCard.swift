import SwiftUI

struct FeedSessionCard: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // User Info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .retroGlow()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Jex Pearce")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .retroGlow()

                    Text(session.formattedStartTime)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: session.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .retroGlow()
            }

            // Session Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.duration) min session")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .retroGlow()

                    if !session.wasSuccessful {
                        Text("Lasted \(session.actualDuration) min")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
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