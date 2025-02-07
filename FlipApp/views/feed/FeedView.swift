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


