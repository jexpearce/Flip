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


