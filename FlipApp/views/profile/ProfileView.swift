import SwiftUI

struct ProfileView: View {
  @StateObject private var sessionManager = SessionManager.shared

  var body: some View {
    ScrollView {
      VStack(spacing: 25) {
        Text("PROFILE")
          .font(.system(size: 28, weight: .black))
          .tracking(5)
          .foregroundColor(Theme.neonYellow)
          .padding(.top, 50)

        // Stats Cards
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
          ], spacing: 15
        ) {
          StatCard(
            title: "TOTAL TIME", value: "\(sessionManager.totalFocusTime)",
            unit: "min")
          StatCard(
            title: "SESSIONS",
            value: "\(sessionManager.totalSuccessfulSessions)", unit: "total")
          StatCard(
            title: "AVG LENGTH",
            value: "\(sessionManager.averageSessionLength)", unit: "min")
        }
        .padding(.horizontal)

        // Longest Session Card
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("LONGEST FLIP")
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
              Image(systemName: "crown.fill")
                .font(.system(size: 14))
            }
            .foregroundColor(Theme.neonYellow)

            Text("\(sessionManager.longestSession) min")
              .font(.system(size: 24, weight: .black))
              .foregroundColor(.white)
          }
          Spacer()
        }
        .padding(20)
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
          RoundedRectangle(cornerRadius: 15)
            .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)

        // History Section
        VStack(alignment: .leading, spacing: 15) {
          Text("HISTORY")
            .font(.system(size: 16, weight: .heavy))
            .tracking(4)
            .foregroundColor(Theme.neonYellow)
            .padding(.horizontal)

          ForEach(sessionManager.sessions) { session in
            SessionHistoryCard(session: session)
          }
        }
      }
    }
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let unit: String

  var body: some View {
    VStack(spacing: 8) {
      Text(value)
        .font(.system(size: 28, weight: .black))
        .foregroundColor(.white)

      Text(title)
        .font(.system(size: 10, weight: .heavy))
        .tracking(1)
        .foregroundColor(Theme.neonYellow.opacity(0.7))

      Text(unit)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Theme.lightGray)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 15)
    .background(Theme.darkGray)
    .cornerRadius(15)
  }
}

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
