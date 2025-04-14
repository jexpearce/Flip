import FirebaseAuth
import SwiftUI

struct GlobalWeeklyLeaderboard: View {
    @ObservedObject var viewModel: GlobalWeeklyLeaderboardViewModel
    @Binding var currentLeaderboard: LeaderboardType
    @State private var showUserProfile = false
    @State private var selectedUserId: String?

    var body: some View {
        VStack(spacing: 12) {
            // Title section with navigation arrows
            VStack(spacing: 4) {
                HStack {
                    // Left arrow to go back to regional
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .regionalAllTime
                        }
                    }) {
                        Image(systemName: "chevron.left").font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7)).padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Spacer()

                    // Main title with icon
                    HStack {
                        Image(systemName: "globe").font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.standardBlue, Theme.blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Theme.standardBlue.opacity(0.5), radius: 4)

                        Text("GLOBAL WEEKLY").font(.system(size: 13, weight: .black)).tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.standardBlue, Theme.blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Theme.standardBlue.opacity(0.5), radius: 4)
                    }

                    Spacer()

                    // Right arrow to go to all time
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .globalAllTime
                        }
                    }) {
                        Image(systemName: "chevron.right").font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7)).padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }

                // Subtitle explaining the leaderboard
                Text("Top players this week worldwide").font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8)).lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Theme.standardBlue.opacity(0.3), Theme.blue.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.silveryGradient5, lineWidth: 1)
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.white).scaleEffect(1.2).padding(.vertical, 25)
                    Spacer()
                }
            }
            else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "globe").font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5)).padding(.bottom, 5)

                    Text("No global data available").font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)

                    Text("Complete sessions to rank globally!").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            }
            else {
                // Column headers for clarity
                HStack {
                    Text("RANK").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(Theme.standardBlue.opacity(0.9))
                        .frame(width: 50, alignment: .center)

                    Text("USER").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(Theme.standardBlue.opacity(0.9)).frame(alignment: .leading)

                    Spacer()

                    Text("MINUTES").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(Theme.standardBlue.opacity(0.9))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries
                    ForEach(
                        Array(viewModel.leaderboardEntries.prefix(10).enumerated()),
                        id: \.element.id
                    ) { index, entry in
                        Button(action: {
                            // Only show profile for non-anonymous users
                            if !entry.isAnonymous {
                                self.selectedUserId = entry.userId
                                self.showUserProfile = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                // Rank with medal for top 3
                                if index < 3 {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                index == 0
                                                    ? Theme.goldColor
                                                    : (index == 1
                                                        ? Theme.silverColor : Theme.bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill").font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.2), radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                }
                                else {
                                    Text("\(index + 1)").font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // Profile with score if available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle().fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?").font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                else if let score = entry.score {
                                    // Show rank for non-anonymous users
                                    RankCircle(score: score, size: 26, showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    if entry.isAnonymous {
                                        DefaultProfileImage(username: "A", size: 32)
                                    }
                                    else {
                                        ProfileImage(userId: entry.userId, size: 32)

                                        // Optional streak indicator
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus == .redFlame
                                                            ? Color.red : Color.orange
                                                    )
                                                    .frame(width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8)).foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username
                                Text(entry.username).font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white).lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .underline(
                                        color: entry.isAnonymous ? .clear : .white.opacity(0.3)
                                    )

                                // Weekly minutes
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.minutes)").font(.system(size: 18, weight: .black))
                                        .foregroundColor(Theme.standardBlue)
                                        .shadow(color: Theme.standardBlue.opacity(0.3), radius: 4)

                                    Text("minutes").font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10).padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3
                                                ? [
                                                    Theme.standardBlue.opacity(0.2),
                                                    Theme.standardBlue.opacity(0.1),
                                                ]
                                                : [
                                                    Color.white.opacity(0.08),
                                                    Color.white.opacity(0.05),
                                                ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                // Highlight current user
                                                Auth.auth().currentUser?.uid == entry.userId
                                                    ? Theme.standardBlue.opacity(0.5)
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth().currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle()).padding(.vertical, 2)  // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }
                }
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Theme.darkBlue.opacity(0.3), Theme.blue800.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.standardBlue.opacity(0.5), Theme.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
        .sheet(
            isPresented: $showUserProfile,
            content: { if let userId = selectedUserId { UserProfileSheet(userId: userId) } }
        )
        .onAppear { viewModel.loadGlobalWeeklyLeaderboard() }
    }
}
