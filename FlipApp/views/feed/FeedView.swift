import SwiftUI

struct FeedView: View {
  @StateObject private var sessionManager = SessionManager.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 25) {
        Text("FEED")
          .font(.system(size: 28, weight: .black))
          .tracking(5)
          .foregroundColor(Theme.neonYellow)
          .padding(.top, 50)

        ForEach(sessionManager.sessions) { session in
          FeedSessionCard(session: session)
        }
      }
      .padding(.horizontal)
    }
  }
}

struct FeedSessionCard: View {
  let session: Session

  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
      // User Info
      HStack(spacing: 12) {
        Image(systemName: "person.circle.fill")
          .font(.system(size: 32))
          .foregroundColor(Theme.neonYellow)

        VStack(alignment: .leading, spacing: 4) {
          Text("Jex Pearce")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)

          Text(session.formattedStartTime)
            .font(.system(size: 12))
            .foregroundColor(.gray)
        }

        Spacer()

        Image(
          systemName: session.wasSuccessful
            ? "checkmark.circle.fill" : "xmark.circle.fill"
        )
        .foregroundColor(session.wasSuccessful ? Theme.neonYellow : .red)
        .font(.system(size: 24))
      }

      // Session Info
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("\(session.duration) min session")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)

          if !session.wasSuccessful {
            Text("Lasted \(session.actualDuration) min")
              .font(.system(size: 14))
              .foregroundColor(Theme.neonYellow.opacity(0.7))
          }
        }

        Spacer()
      }
    }
    .padding()
    .background(Theme.darkGray)
    .cornerRadius(15)
    .overlay(
      RoundedRectangle(cornerRadius: 15)
        .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
    )
  }
}
