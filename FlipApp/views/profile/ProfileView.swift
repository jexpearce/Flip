import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Title with Japanese
                VStack(spacing: 4) {
                    Text("PROFILE")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .retroGlow()

                    Text("プロフィール")
                        .font(.system(size: 12))
                        .tracking(4)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)

                // Stats Cards
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15
                ) {
                    StatCard(
                        title: "TOTAL TIME",
                        value: "\(sessionManager.totalFocusTime)", unit: "min")
                    StatCard(
                        title: "SESSIONS",
                        value: "\(sessionManager.totalSuccessfulSessions)",
                        unit: "total")
                    StatCard(
                        title: "AVG LENGTH",
                        value: "\(sessionManager.averageSessionLength)",
                        unit: "min")
                }
                .padding(.horizontal)

                // Longest Session Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LONGEST FLIP")
                                .font(.system(size: 14, weight: .heavy))
                                .tracking(5)
                                .foregroundColor(.white)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                        .retroGlow()

                        Text("\(sessionManager.longestSession) min")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .retroGlow()
                    }
                    Spacer()
                }
                .padding(20)
                .background(Color.black.opacity(0.3))
                .background(Theme.darkGray)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)

                // History Section
                VStack(alignment: .leading, spacing: 15) {
                    VStack(spacing: 4) {
                        Text("HISTORY")
                            .font(.system(size: 16, weight: .heavy))
                            .tracking(5)
                            .foregroundColor(.white)
                            .retroGlow()

                        Text("セッション履歴")
                            .font(.system(size: 12))
                            .tracking(2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    ForEach(sessionManager.sessions) { session in
                        SessionHistoryCard(session: session)
                    }
                }
            }
        }
        .background(Theme.mainGradient)
    }
}
