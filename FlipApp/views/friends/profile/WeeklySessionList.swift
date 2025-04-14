import SwiftUI

struct WeeklySessionList: View {
    @ObservedObject var viewModel: WeeklySessionListViewModel
    @State private var showingAllSessions = false
    let userId: String

    init(userId: String, viewModel: WeeklySessionListViewModel = WeeklySessionListViewModel()) {
        self.userId = userId
        self.viewModel = viewModel
    }

    private var displayedSessions: [Session] {
        if showingAllSessions {
            return viewModel.sessions
        }
        else {
            return Array(viewModel.sessions.prefix(5))
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            ForEach(displayedSessions) { session in SessionHistoryCard(session: session) }

            if viewModel.sessions.isEmpty {
                Text("No sessions recorded yet").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 20)
            }

            if viewModel.sessions.count > 5 {
                Button(action: { withAnimation(.spring()) { showingAllSessions.toggle() } }) {
                    HStack {
                        Text(showingAllSessions ? "Show Less" : "Show More")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: showingAllSessions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.emeraldGreen.opacity(0.5),
                                            Theme.emeraldGreen.opacity(0.3),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))

                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.silveryGradient2, lineWidth: 1)
                        }
                    )
                    .shadow(color: Theme.lightTealBlue.opacity(0.3), radius: 6)
                }
                .padding(.horizontal).padding(.top, 5)
            }
        }
        .onAppear { viewModel.loadSessions(for: userId) }
    }
}
