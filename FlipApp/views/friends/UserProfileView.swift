import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct UserProfileView: View {
    let user: FirebaseManager.FlipUser

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Header
                VStack(spacing: 15) {
                    Text(user.username)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .retroGlow()

                    HStack(spacing: 40) {
                        StatBox(title: "SESSIONS", value: "\(user.totalSessions)")
                        StatBox(title: "FOCUS TIME", value: "\(user.totalFocusTime)m")
                    }
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
                    StatCard(title: "TOTAL TIME", value: "\(user.totalFocusTime)", unit: "min")
                    StatCard(title: "SESSIONS", value: "\(user.totalSessions)", unit: "total")
                    StatCard(
                        title: "AVG LENGTH",
                        value: user.totalSessions > 0 ? "\(user.totalFocusTime / user.totalSessions)" : "0",
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

                        Text("\(user.longestSession) min")
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

                // Recent Sessions
                VStack(alignment: .leading, spacing: 15) {
                    Text("RECENT SESSIONS")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(5)
                        .foregroundColor(.white)
                        .retroGlow()
                        .padding(.horizontal)

                    SessionList(userId: user.id)
                }
            }
        }
        .background(Theme.mainGradient)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .retroGlow()

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

struct SessionList: View {
    @StateObject private var viewModel = SessionListViewModel()
    let userId: String

    var body: some View {
        ForEach(viewModel.sessions) { session in
            SessionHistoryCard(session: session)
        }
        .onAppear {
            viewModel.loadSessions(for: userId)
        }
    }
}