import SwiftUI

struct SessionHistoryCard: View {
  let session: Session

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 8) {
        Text(session.formattedStartTime)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Theme.lightGray)

        Text("\(session.actualDuration) min")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.white)
      }

      Spacer()

      Image(
        systemName: session.wasSuccessful
          ? "checkmark.circle.fill" : "xmark.circle.fill"
      )
      .foregroundColor(session.wasSuccessful ? Theme.neonYellow : .red)
      .font(.system(size: 24))
    }
    .padding()
    .background(Theme.darkGray)
    .cornerRadius(15)
    .padding(.horizontal)
  }
}
