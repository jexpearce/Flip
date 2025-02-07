import SwiftUI

struct FeedView: View {
  @EnvironmentObject var sessionManager: SessionManager

  var body: some View {
    ScrollView {
      VStack(spacing: 25) {
        Text("FEED").title()
        ForEach(sessionManager.sessions) { session in
          FeedSessionCard(session: session)
        }
      }
      .padding(.horizontal)
    }
  }
}
