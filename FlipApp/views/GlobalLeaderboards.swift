import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// Enum for tracking which leaderboard is currently displayed
enum LeaderboardType {
    case building
    case regionalWeekly
    case regionalAllTime
    case globalWeekly
    case globalAllTime
}

// Global Weekly Leaderboard Component
struct GlobalWeeklyLeaderboard: View {
    @ObservedObject var viewModel: GlobalWeeklyLeaderboardViewModel
    @Binding var currentLeaderboard: LeaderboardType
    @State private var showUserProfile = false
    @State private var selectedUserId: String?

    // Blue theme colors - different from the red of regional and gold of friends
    private let blueGradient = LinearGradient(
        colors: [
            Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255),  // Blue 500
            Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255),  // Blue 600
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let blueBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255).opacity(0.4),  // Blue 900
            Color(red: 30 / 255, green: 64 / 255, blue: 175 / 255).opacity(0.3),  // Blue 800
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Medal colors
    private let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverColor = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
            Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

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
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    // Main title with icon
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 59 / 255, green: 130 / 255,
                                            blue: 246 / 255),
                                        Color(
                                            red: 37 / 255, green: 99 / 255,
                                            blue: 235 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 59 / 255, green: 130 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5), radius: 4)

                        Text("GLOBAL WEEKLY")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 59 / 255, green: 130 / 255,
                                            blue: 246 / 255),
                                        Color(
                                            red: 37 / 255, green: 99 / 255,
                                            blue: 235 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 59 / 255, green: 130 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5), radius: 4)
                    }

                    Spacer()

                    // Right arrow to go to all time
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .globalAllTime
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                // Subtitle explaining the leaderboard
                Text("Top players this week worldwide")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 59 / 255, green: 130 / 255,
                                    blue: 246 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 37 / 255, green: 99 / 255,
                                    blue: 235 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 5)

                    Text("No global data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("Complete sessions to rank globally!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Column headers for clarity
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 59 / 255, green: 130 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 59 / 255, green: 130 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("MINUTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 59 / 255, green: 130 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries
                    ForEach(
                        Array(
                            viewModel.leaderboardEntries.prefix(10).enumerated()
                        ), id: \.element.id
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
                                                    ? goldColor
                                                    : (index == 1
                                                        ? silverColor
                                                        : bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(
                                                color: Color.black.opacity(0.2),
                                                radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // Profile with score if available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?")
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)
                                    }
                                } else if let score = entry.score {
                                    // Show rank for non-anonymous users
                                    RankCircle(
                                        score: score, size: 26,
                                        showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    if entry.isAnonymous {
                                        DefaultProfileImage(
                                            username: "A", size: 32)
                                    } else {
                                        ProfileImage(
                                            userId: entry.userId, size: 32)

                                        // Optional streak indicator
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus
                                                        == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(
                                                            0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus
                                                            == .redFlame
                                                            ? Color.red
                                                            : Color.orange
                                                    )
                                                    .frame(
                                                        width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(
                                        maxWidth: .infinity, alignment: .leading
                                    )
                                    .underline(
                                        color: entry.isAnonymous
                                            ? .clear : .white.opacity(0.3))

                                // Weekly minutes
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.minutes)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(
                                            Color(
                                                red: 59 / 255, green: 130 / 255,
                                                blue: 246 / 255)
                                        )
                                        .shadow(
                                            color: Color(
                                                red: 59 / 255, green: 130 / 255,
                                                blue: 246 / 255
                                            ).opacity(0.3), radius: 4)

                                    Text("minutes")
                                        .font(
                                            .system(size: 10, weight: .medium)
                                        )
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3
                                                ? [
                                                    Color(
                                                        red: 59 / 255,
                                                        green: 130 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.2),
                                                    Color(
                                                        red: 59 / 255,
                                                        green: 130 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.1),
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
                                                Auth.auth().currentUser?.uid
                                                    == entry.userId
                                                    ? Color(
                                                        red: 59 / 255,
                                                        green: 130 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.5)
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth()
                                                    .currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 30 / 255, green: 58 / 255,
                                    blue: 138 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 30 / 255, green: 64 / 255,
                                    blue: 175 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 59 / 255, green: 130 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5),
                                Color(
                                    red: 37 / 255, green: 99 / 255,
                                    blue: 235 / 255
                                ).opacity(0.2),
                            ],
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
            content: {
                if let userId = selectedUserId {
                    UserProfileSheet(userId: userId)
                }
            }
        )
        .onAppear {
            viewModel.loadGlobalWeeklyLeaderboard()
        }
    }
}

// Global All Time Leaderboard Component
struct GlobalAllTimeLeaderboard: View {
    @ObservedObject var viewModel: GlobalAllTimeLeaderboardViewModel
    @Binding var currentLeaderboard: LeaderboardType
    @State private var showUserProfile = false
    @State private var selectedUserId: String?

    // Purple theme colors - different from the red of regional and blue of weekly
    private let purpleGradient = LinearGradient(
        colors: [
            Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255),  // Purple 500
            Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255),  // Purple 600
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let purpleBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 88 / 255, green: 28 / 255, blue: 135 / 255).opacity(0.4),  // Purple 900
            Color(red: 91 / 255, green: 33 / 255, blue: 182 / 255).opacity(0.3),  // Purple 800
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Medal colors - same across all leaderboards
    private let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverColor = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
            Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 12) {
            // Title section with navigation arrows
            VStack(spacing: 4) {
                HStack {
                    // Left arrow to go back to weekly
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .globalWeekly
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    // Main title with icon
                    HStack {
                        Image(systemName: "infinity")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 139 / 255, green: 92 / 255,
                                            blue: 246 / 255),
                                        Color(
                                            red: 124 / 255, green: 58 / 255,
                                            blue: 237 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5), radius: 4)

                        Text("GLOBAL ALL TIME")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 139 / 255, green: 92 / 255,
                                            blue: 246 / 255),
                                        Color(
                                            red: 124 / 255, green: 58 / 255,
                                            blue: 237 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5), radius: 4)
                    }

                    Spacer()

                    // Empty view to balance the layout
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 34, height: 34)
                }

                // Subtitle explaining the leaderboard
                Text("Most minutes flipped ever")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 124 / 255, green: 58 / 255,
                                    blue: 237 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "infinity")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 5)

                    Text("No global all time data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("Complete sessions to rank globally!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Column headers for clarity
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 139 / 255, green: 92 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 139 / 255, green: 92 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("MINUTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 139 / 255, green: 92 / 255, blue: 246 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries
                    ForEach(
                        Array(
                            viewModel.leaderboardEntries.prefix(10).enumerated()
                        ), id: \.element.id
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
                                                    ? goldColor
                                                    : (index == 1
                                                        ? silverColor
                                                        : bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(
                                                color: Color.black.opacity(0.2),
                                                radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // Profile with score if available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?")
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)
                                    }
                                } else if let score = entry.score {
                                    // Show rank for non-anonymous users
                                    RankCircle(
                                        score: score, size: 26,
                                        showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    if entry.isAnonymous {
                                        DefaultProfileImage(
                                            username: "A", size: 32)
                                    } else {
                                        ProfileImage(
                                            userId: entry.userId, size: 32)

                                        // Optional streak indicator
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus
                                                        == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(
                                                            0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus
                                                            == .redFlame
                                                            ? Color.red
                                                            : Color.orange
                                                    )
                                                    .frame(
                                                        width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(
                                        maxWidth: .infinity, alignment: .leading
                                    )
                                    .underline(
                                        color: entry.isAnonymous
                                            ? .clear : .white.opacity(0.3))

                                // All time minutes
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.minutes)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(
                                            Color(
                                                red: 139 / 255, green: 92 / 255,
                                                blue: 246 / 255)
                                        )
                                        .shadow(
                                            color: Color(
                                                red: 139 / 255, green: 92 / 255,
                                                blue: 246 / 255
                                            ).opacity(0.3), radius: 4)

                                    Text("minutes")
                                        .font(
                                            .system(size: 10, weight: .medium)
                                        )
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3
                                                ? [
                                                    Color(
                                                        red: 139 / 255,
                                                        green: 92 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.2),
                                                    Color(
                                                        red: 139 / 255,
                                                        green: 92 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.1),
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
                                                Auth.auth().currentUser?.uid
                                                    == entry.userId
                                                    ? Color(
                                                        red: 139 / 255,
                                                        green: 92 / 255,
                                                        blue: 246 / 255
                                                    ).opacity(0.5)
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth()
                                                    .currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 88 / 255, green: 28 / 255,
                                    blue: 135 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 91 / 255, green: 33 / 255,
                                    blue: 182 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.5),
                                Color(
                                    red: 124 / 255, green: 58 / 255,
                                    blue: 237 / 255
                                ).opacity(0.2),
                            ],
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
            content: {
                if let userId = selectedUserId {
                    UserProfileSheet(userId: userId)
                }
            }
        )
        .onAppear {
            viewModel.loadGlobalAllTimeLeaderboard()
        }
    }
}

// Data structures for global leaderboards
struct GlobalLeaderboardEntry {
    let id: String
    let userId: String
    let username: String
    let minutes: Int
    var score: Double? = nil
    var streakStatus: StreakStatus = .none
    var isAnonymous: Bool = false
}

// View Model for Global Weekly Leaderboard
class GlobalWeeklyLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    func loadGlobalWeeklyLeaderboard() {
        isLoading = true

        // Calculate the current week's start date
        let calendar = Calendar.current
        let currentDate = Date()
        var components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: currentDate)
        components.weekday = 2  // Monday
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let weekStart = calendar.date(from: components) else {
            self.isLoading = false
            return
        }

        print("🗓️ Global Weekly leaderboard from: \(weekStart)")

        // First, fetch all sessions from this week
        db.collection("sessions")
            .whereField("wasSuccessful", isEqualTo: true)
            .whereField("startTime", isGreaterThan: Timestamp(date: weekStart))
            .getDocuments(source: .default) { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "Error fetching global sessions: \(error.localizedDescription)"
                    )
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                print(
                    "📊 Found \(documents.count) total global sessions this week"
                )

                // Dictionary to track each user's total time
                var userWeeklyData:
                    [String: (userId: String, username: String, minutes: Int)] =
                        [:]

                // Collection of user IDs we need to fetch privacy settings for
                var userIdsToCheck = Set<String>()

                // Process each session document
                for document in documents {
                    let data = document.data()

                    // Extract basic session info
                    guard let userId = data["userId"] as? String,
                        let actualDuration = data["actualDuration"] as? Int
                    else {
                        continue
                    }

                    // Add this user ID to the list we need to check privacy for
                    userIdsToCheck.insert(userId)

                    // Get temp username (will be updated later if needed)
                    let tempUsername = data["username"] as? String ?? "User"

                    // Update the user's total time
                    if let existingData = userWeeklyData[userId] {
                        userWeeklyData[userId] = (
                            userId: userId,
                            username: existingData.username,
                            minutes: existingData.minutes + actualDuration
                        )
                    } else {
                        userWeeklyData[userId] = (
                            userId: userId,
                            username: tempUsername,
                            minutes: actualDuration
                        )
                    }
                }

                // No data found - update UI now
                if userWeeklyData.isEmpty {
                    DispatchQueue.main.async {
                        self.leaderboardEntries = []
                        self.isLoading = false
                    }
                    return
                }

                // Now check privacy settings for all users
                self.fetchUserPrivacySettings(userIds: Array(userIdsToCheck)) {
                    privacySettings in
                    // Get all usernames respecting privacy
                    self.fetchUsernamesRespectingPrivacy(
                        Array(userIdsToCheck), privacySettings: privacySettings
                    ) { usernameMap in
                        // Get scores and streaks
                        self.fetchUserScoresAndStreaks(Array(userIdsToCheck)) {
                            scoresMap, streaksMap in
                            // Now build final entries respecting privacy
                            var entries: [GlobalLeaderboardEntry] = []

                            for (userId, userData) in userWeeklyData {
                                // Skip users who have opted out of leaderboards
                                if let userPrivacy = privacySettings[userId],
                                    userPrivacy.optOut
                                {
                                    continue
                                }

                                // Determine if user should be anonymous
                                let isAnonymous =
                                    privacySettings[userId]?.isAnonymous
                                    ?? false
                                let displayUsername =
                                    isAnonymous
                                    ? "Anonymous"
                                    : (usernameMap[userId] ?? userData.username)

                                let entry = GlobalLeaderboardEntry(
                                    id: UUID().uuidString,  // Unique ID for SwiftUI
                                    userId: userId,
                                    username: displayUsername,
                                    minutes: userData.minutes,
                                    score: scoresMap[userId],
                                    streakStatus: streaksMap[userId] ?? .none,
                                    isAnonymous: isAnonymous
                                )

                                entries.append(entry)
                            }

                            // Sort by minutes
                            entries.sort { $0.minutes > $1.minutes }

                            DispatchQueue.main.async {
                                self.leaderboardEntries = entries
                                self.isLoading = false
                            }
                        }
                    }
                }
            }
    }

    // Helper methods for fetching user data (same as RegionalLeaderboardViewModel)
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) ->
            Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId).getDocument {
                document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    // Get opt-out setting (default to false)
                    let optOut = data["regionalOptOut"] as? Bool ?? false

                    // Get display mode (default to normal)
                    let displayModeString =
                        data["regionalDisplayMode"] as? String ?? "normal"
                    let isAnonymous = displayModeString == "anonymous"

                    result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                } else {
                    // Use defaults if no settings document
                    result[userId] = (optOut: false, isAnonymous: false)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUsernamesRespectingPrivacy(
        _ userIds: [String],
        privacySettings: [String: (optOut: Bool, isAnonymous: Bool)],
        completion: @escaping ([String: String]) -> Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        // First check our cache
        var result: [String: String] = [:]
        var idsToFetch: [String] = []

        for userId in userIds {
            // Check if user is anonymous based on privacy settings
            if let privacySetting = privacySettings[userId],
                privacySetting.isAnonymous
            {
                result[userId] = "Anonymous"
                continue
            }

            if let cachedUser = userCache[userId],
                !cachedUser.username.isEmpty && cachedUser.username != "User"
            {
                result[userId] = cachedUser.username
            } else if let currentUser = FirebaseManager.shared.currentUser,
                currentUser.id == userId, !currentUser.username.isEmpty
            {
                result[userId] = currentUser.username
                // Update cache
                userCache[userId] = UserCacheItem(
                    userId: userId,
                    username: currentUser.username,
                    profileImageURL: currentUser.profileImageURL
                )
            } else {
                idsToFetch.append(userId)
            }
        }

        // If we have all usernames already, return
        if idsToFetch.isEmpty {
            completion(result)
            return
        }

        // Fetch in batches of 10 to avoid Firestore limitations
        let batchSize = 10
        let dispatchGroup = DispatchGroup()

        for i in stride(from: 0, to: idsToFetch.count, by: batchSize) {
            let end = min(i + batchSize, idsToFetch.count)
            let batch = Array(idsToFetch[i..<end])

            dispatchGroup.enter()
            fetchUserBatch(batch) { batchResult in
                // Add this batch to our results
                for (id, username) in batchResult {
                    // Apply privacy settings - override with "Anonymous" if needed
                    if let privacySetting = privacySettings[id],
                        privacySetting.isAnonymous
                    {
                        result[id] = "Anonymous"
                    } else {
                        result[id] = username
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUserBatch(
        _ userIds: [String], completion: @escaping ([String: String]) -> Void
    ) {
        let db = Firestore.firestore()
        var batchResult: [String: String] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                // Try to get username from document
                if let data = document?.data(),
                    let username = data["username"] as? String,
                    !username.isEmpty
                {
                    batchResult[userId] = username

                    // Update our cache
                    self.userCache[userId] = UserCacheItem(
                        userId: userId,
                        username: username,
                        profileImageURL: data["profileImageURL"] as? String
                    )
                } else {
                    batchResult[userId] = "User"
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(batchResult)
        }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    if let score = data["score"] as? Double {
                        scores[userId] = score
                    }
                }
            }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak")
                .document("current").getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] =
                            StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(scores, streaks)
        }
    }
}

// View Model for Global All Time Leaderboard
class GlobalAllTimeLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    func loadGlobalAllTimeLeaderboard() {
        isLoading = true

        // Directly query the users collection to get all users sorted by total focus time
        db.collection("users")
            .order(by: "totalFocusTime", descending: true)
            .limit(to: 100)  // Fetch more than we need in case some users opt out
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "Error fetching global users: \(error.localizedDescription)"
                    )
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                print(
                    "📊 Found \(documents.count) total users for all time leaderboard"
                )

                // Dictionary to store user data with total focus time
                var userData:
                    [(userId: String, username: String, minutes: Int)] = []

                // Collection of user IDs we need to fetch privacy settings for
                var userIdsToCheck = [String]()

                // Process each user document
                for document in documents {
                    let data = document.data()

                    // Skip users with zero totalFocusTime
                    guard let totalFocusTime = data["totalFocusTime"] as? Int,
                        totalFocusTime > 0
                    else {
                        continue
                    }

                    let userId = document.documentID
                    let username = data["username"] as? String ?? "User"

                    userIdsToCheck.append(userId)
                    userData.append(
                        (
                            userId: userId, username: username,
                            minutes: totalFocusTime
                        ))
                }

                // No data found - update UI now
                if userData.isEmpty {
                    DispatchQueue.main.async {
                        self.leaderboardEntries = []
                        self.isLoading = false
                    }
                    return
                }

                // Now check privacy settings for all users
                self.fetchUserPrivacySettings(userIds: userIdsToCheck) {
                    privacySettings in
                    // Get scores and streaks
                    self.fetchUserScoresAndStreaks(userIdsToCheck) {
                        scoresMap, streaksMap in
                        // Now build final entries respecting privacy
                        var entries: [GlobalLeaderboardEntry] = []

                        for userInfo in userData {
                            // Skip users who have opted out of leaderboards
                            if let userPrivacy = privacySettings[
                                userInfo.userId], userPrivacy.optOut
                            {
                                continue
                            }

                            // Determine if user should be anonymous
                            let isAnonymous =
                                privacySettings[userInfo.userId]?.isAnonymous
                                ?? false
                            let displayUsername =
                                isAnonymous ? "Anonymous" : userInfo.username

                            let entry = GlobalLeaderboardEntry(
                                id: UUID().uuidString,  // Unique ID for SwiftUI
                                userId: userInfo.userId,
                                username: displayUsername,
                                minutes: userInfo.minutes,
                                score: scoresMap[userInfo.userId],
                                streakStatus: streaksMap[userInfo.userId]
                                    ?? .none,
                                isAnonymous: isAnonymous
                            )

                            entries.append(entry)
                        }

                        // Sort by minutes (already pre-sorted from Firestore, but just in case)
                        entries.sort { $0.minutes > $1.minutes }

                        DispatchQueue.main.async {
                            self.leaderboardEntries = entries
                            self.isLoading = false
                        }
                    }
                }
            }
    }

    // Helper methods for fetching user data (same implementations as GlobalWeeklyLeaderboardViewModel)
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) ->
            Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId).getDocument {
                document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    // Get opt-out setting (default to false)
                    let optOut = data["regionalOptOut"] as? Bool ?? false

                    // Get display mode (default to normal)
                    let displayModeString =
                        data["regionalDisplayMode"] as? String ?? "normal"
                    let isAnonymous = displayModeString == "anonymous"

                    result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                } else {
                    // Use defaults if no settings document
                    result[userId] = (optOut: false, isAnonymous: false)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    if let score = data["score"] as? Double {
                        scores[userId] = score
                    }
                }
            }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak")
                .document("current").getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] =
                            StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(scores, streaks)
        }
    }
}

// Regional Weekly Leaderboard Component
struct RegionalWeeklyLeaderboard: View {
    @ObservedObject var viewModel: RegionalWeeklyLeaderboardViewModel
    @Binding var currentLeaderboard: LeaderboardType
    @State private var showUserProfile = false
    @State private var selectedUserId: String?

    // Red theme colors - maintaining original regional theme
    private let redGradient = LinearGradient(
        colors: [
            Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255),  // Red 500
            Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255),  // Red 600
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let redBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 153 / 255, green: 27 / 255, blue: 27 / 255).opacity(0.4),  // Red 900
            Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255).opacity(0.3),  // Red 800
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Medal colors
    private let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverColor = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
            Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 12) {
            // Title section with navigation arrows
            VStack(spacing: 4) {
                HStack {
                    // Left arrow to go back to building
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .building
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    // Main title with icon
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 239 / 255, green: 68 / 255,
                                            blue: 68 / 255),
                                        Color(
                                            red: 220 / 255, green: 38 / 255,
                                            blue: 38 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 239 / 255, green: 68 / 255,
                                    blue: 68 / 255
                                ).opacity(0.5), radius: 4)

                        Text("REGIONAL WEEKLY")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 239 / 255, green: 68 / 255,
                                            blue: 68 / 255),
                                        Color(
                                            red: 220 / 255, green: 38 / 255,
                                            blue: 38 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 239 / 255, green: 68 / 255,
                                    blue: 68 / 255
                                ).opacity(0.5), radius: 4)
                    }

                    Spacer()

                    // Right arrow to go to regional all time
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .regionalAllTime
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                // Subtitle explaining the leaderboard
                Text("Top players this week in \(viewModel.countyName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 239 / 255, green: 68 / 255,
                                    blue: 68 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 220 / 255, green: 38 / 255,
                                    blue: 38 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 5)

                    Text("No regional data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("Complete sessions to rank regionally!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Column headers for clarity
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 239 / 255, green: 68 / 255, blue: 68 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 239 / 255, green: 68 / 255, blue: 68 / 255
                            ).opacity(0.9)
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("MINUTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 239 / 255, green: 68 / 255, blue: 68 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries
                    ForEach(
                        Array(
                            viewModel.leaderboardEntries.prefix(10).enumerated()
                        ), id: \.element.id
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
                                                    ? goldColor
                                                    : (index == 1
                                                        ? silverColor
                                                        : bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(
                                                color: Color.black.opacity(0.2),
                                                radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // Profile with score if available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?")
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)
                                    }
                                } else if let score = entry.score {
                                    // Show rank for non-anonymous users
                                    RankCircle(
                                        score: score, size: 26,
                                        showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    if entry.isAnonymous {
                                        DefaultProfileImage(
                                            username: "A", size: 32)
                                    } else {
                                        ProfileImage(
                                            userId: entry.userId, size: 32)

                                        // Optional streak indicator
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus
                                                        == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(
                                                            0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus
                                                            == .redFlame
                                                            ? Color.red
                                                            : Color.orange
                                                    )
                                                    .frame(
                                                        width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(
                                        maxWidth: .infinity, alignment: .leading
                                    )
                                    .underline(
                                        color: entry.isAnonymous
                                            ? .clear : .white.opacity(0.3))

                                // Weekly minutes
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.minutes)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(
                                            Color(
                                                red: 239 / 255, green: 68 / 255,
                                                blue: 68 / 255)
                                        )
                                        .shadow(
                                            color: Color(
                                                red: 239 / 255, green: 68 / 255,
                                                blue: 68 / 255
                                            ).opacity(0.3), radius: 4)

                                    Text("minutes")
                                        .font(
                                            .system(size: 10, weight: .medium)
                                        )
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3
                                                ? [
                                                    Color(
                                                        red: 239 / 255,
                                                        green: 68 / 255,
                                                        blue: 68 / 255
                                                    ).opacity(0.2),
                                                    Color(
                                                        red: 239 / 255,
                                                        green: 68 / 255,
                                                        blue: 68 / 255
                                                    ).opacity(0.1),
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
                                                Auth.auth().currentUser?.uid
                                                    == entry.userId
                                                    ? Color(
                                                        red: 239 / 255,
                                                        green: 68 / 255,
                                                        blue: 68 / 255
                                                    ).opacity(0.5)
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth()
                                                    .currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 153 / 255, green: 27 / 255,
                                    blue: 27 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 127 / 255, green: 29 / 255,
                                    blue: 29 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 239 / 255, green: 68 / 255,
                                    blue: 68 / 255
                                ).opacity(0.5),
                                Color(
                                    red: 220 / 255, green: 38 / 255,
                                    blue: 38 / 255
                                ).opacity(0.2),
                            ],
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
            content: {
                if let userId = selectedUserId {
                    UserProfileSheet(userId: userId)
                }
            }
        )
        .onAppear {
            viewModel.loadRegionalWeeklyLeaderboard()
        }
    }
}

// Regional All Time Leaderboard Component
struct RegionalAllTimeLeaderboard: View {
    @ObservedObject var viewModel: RegionalAllTimeLeaderboardViewModel
    @Binding var currentLeaderboard: LeaderboardType
    @State private var showUserProfile = false
    @State private var selectedUserId: String?

    // Amber/Gold theme colors - distinctive from the others
    private let amberGradient = LinearGradient(
        colors: [
            Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255),  // Amber 500
            Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255),  // Amber 600
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let amberBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255).opacity(0.4),  // Amber 900
            Color(red: 146 / 255, green: 64 / 255, blue: 14 / 255).opacity(0.3),  // Amber 800
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Medal colors - same across all leaderboards
    private let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverColor = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
            Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 12) {
            // Title section with navigation arrows
            VStack(spacing: 4) {
                HStack {
                    // Left arrow to go back to regional weekly
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .regionalWeekly
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }

                    Spacer()

                    // Main title with icon
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 245 / 255, green: 158 / 255,
                                            blue: 11 / 255),
                                        Color(
                                            red: 217 / 255, green: 119 / 255,
                                            blue: 6 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 245 / 255, green: 158 / 255,
                                    blue: 11 / 255
                                ).opacity(0.5), radius: 4)

                        Text("REGIONAL ALL TIME")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(
                                            red: 245 / 255, green: 158 / 255,
                                            blue: 11 / 255),
                                        Color(
                                            red: 217 / 255, green: 119 / 255,
                                            blue: 6 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 245 / 255, green: 158 / 255,
                                    blue: 11 / 255
                                ).opacity(0.5), radius: 4)
                    }

                    Spacer()

                    // Right arrow to go to global weekly
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentLeaderboard = .globalWeekly
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                // Subtitle explaining the leaderboard
                Text("Most minutes flipped ever in \(viewModel.countyName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 245 / 255, green: 158 / 255,
                                    blue: 11 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 217 / 255, green: 119 / 255,
                                    blue: 6 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 5)

                    Text("No regional all time data available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Text("Complete sessions to rank regionally!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Column headers for clarity
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 245 / 255, green: 158 / 255, blue: 11 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 245 / 255, green: 158 / 255, blue: 11 / 255
                            ).opacity(0.9)
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("MINUTES")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Color(
                                red: 245 / 255, green: 158 / 255, blue: 11 / 255
                            ).opacity(0.9)
                        )
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries
                    ForEach(
                        Array(
                            viewModel.leaderboardEntries.prefix(10).enumerated()
                        ), id: \.element.id
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
                                                    ? goldColor
                                                    : (index == 1
                                                        ? silverColor
                                                        : bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(
                                                color: Color.black.opacity(0.2),
                                                radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // Profile with score if available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?")
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)
                                    }
                                } else if let score = entry.score {
                                    // Show rank for non-anonymous users
                                    RankCircle(
                                        score: score, size: 26,
                                        showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    if entry.isAnonymous {
                                        DefaultProfileImage(
                                            username: "A", size: 32)
                                    } else {
                                        ProfileImage(
                                            userId: entry.userId, size: 32)

                                        // Optional streak indicator
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus
                                                        == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(
                                                            0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus
                                                            == .redFlame
                                                            ? Color.red
                                                            : Color.orange
                                                    )
                                                    .frame(
                                                        width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(
                                        maxWidth: .infinity, alignment: .leading
                                    )
                                    .underline(
                                        color: entry.isAnonymous
                                            ? .clear : .white.opacity(0.3))

                                // All time minutes
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.minutes)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(
                                            Color(
                                                red: 245 / 255,
                                                green: 158 / 255, blue: 11 / 255
                                            )
                                        )
                                        .shadow(
                                            color: Color(
                                                red: 245 / 255,
                                                green: 158 / 255, blue: 11 / 255
                                            ).opacity(0.3), radius: 4)

                                    Text("minutes")
                                        .font(
                                            .system(size: 10, weight: .medium)
                                        )
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: index < 3
                                                ? [
                                                    Color(
                                                        red: 245 / 255,
                                                        green: 158 / 255,
                                                        blue: 11 / 255
                                                    ).opacity(0.2),
                                                    Color(
                                                        red: 245 / 255,
                                                        green: 158 / 255,
                                                        blue: 11 / 255
                                                    ).opacity(0.1),
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
                                                Auth.auth().currentUser?.uid
                                                    == entry.userId
                                                    ? Color(
                                                        red: 245 / 255,
                                                        green: 158 / 255,
                                                        blue: 11 / 255
                                                    ).opacity(0.5)
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth()
                                                    .currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 120 / 255, green: 53 / 255,
                                    blue: 15 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 146 / 255, green: 64 / 255,
                                    blue: 14 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 245 / 255, green: 158 / 255,
                                    blue: 11 / 255
                                ).opacity(0.5),
                                Color(
                                    red: 217 / 255, green: 119 / 255,
                                    blue: 6 / 255
                                ).opacity(0.2),
                            ],
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
            content: {
                if let userId = selectedUserId {
                    UserProfileSheet(userId: userId)
                }
            }
        )
        .onAppear {
            viewModel.loadRegionalAllTimeLeaderboard()
        }
    }
}

// View Model for Regional Weekly Leaderboard
class RegionalWeeklyLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var countyName: String = "Your Area"
    private let regionRadiusInMiles: Double = 15.0  // ~15 mile radius

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    func loadRegionalWeeklyLeaderboard() {
        isLoading = true
        Task { @MainActor in
            // Get the current user's location
            let location = LocationHandler.shared.lastLocation

            // Determine the county name for display
            determineCountyName(from: location) { [weak self] countyName in
                guard let self = self else { return }

                // Update the county name for display
                DispatchQueue.main.async {
                    self.countyName = countyName
                }

                // Calculate the current week's start date
                let calendar = Calendar.current
                let currentDate = Date()
                var components = calendar.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear], from: currentDate)
                components.weekday = 2  // Monday
                components.hour = 0
                components.minute = 0
                components.second = 0

                guard let weekStart = calendar.date(from: components) else {
                    self.isLoading = false
                    return
                }

                print("🗓️ Regional Weekly leaderboard from: \(weekStart)")

                // Convert miles to meters for geoqueries
                let regionRadiusInMeters = self.regionRadiusInMiles * 1609.34

                // First, fetch all sessions from this week in the region
                self.db.collection("sessions")
                    .whereField("wasSuccessful", isEqualTo: true)
                    .whereField(
                        "startTime", isGreaterThan: Timestamp(date: weekStart)
                    )
                    .getDocuments(source: .default) {
                        [weak self] snapshot, error in
                        guard let self = self else { return }

                        if let error = error {
                            print(
                                "Error fetching regional sessions: \(error.localizedDescription)"
                            )
                            DispatchQueue.main.async {
                                self.isLoading = false
                            }
                            return
                        }

                        guard let documents = snapshot?.documents else {
                            DispatchQueue.main.async {
                                self.isLoading = false
                            }
                            return
                        }

                        print(
                            "📊 Found \(documents.count) total sessions this week"
                        )

                        // Filter sessions by distance if location is available
                        var filteredDocuments = documents

                        // If we have valid location, filter by distance using session_locations collection
                        if location.horizontalAccuracy > 0 {
                            // We'll need to fetch location data for each session to filter by region
                            let dispatchGroup = DispatchGroup()
                            var sessionsInRegion: Set<String> = []

                            for document in documents {
                                if let userId = document.data()["userId"]
                                    as? String
                                {
                                    dispatchGroup.enter()

                                    // Use session_locations collection to get location data
                                    self.db.collection("session_locations")
                                        .whereField("userId", isEqualTo: userId)
                                        .getDocuments { snapshot, error in
                                            defer { dispatchGroup.leave() }

                                            if let locationDocs = snapshot?
                                                .documents
                                            {
                                                for locationDoc in locationDocs
                                                {
                                                    if let geoPoint =
                                                        locationDoc.data()[
                                                            "location"]
                                                        as? GeoPoint
                                                    {
                                                        let sessionLocation =
                                                            CLLocation(
                                                                latitude:
                                                                    geoPoint
                                                                    .latitude,
                                                                longitude:
                                                                    geoPoint
                                                                    .longitude
                                                            )

                                                        // Check if within region radius
                                                        let distance =
                                                            location.distance(
                                                                from:
                                                                    sessionLocation
                                                            )
                                                        if distance
                                                            <= regionRadiusInMeters
                                                        {
                                                            sessionsInRegion
                                                                .insert(
                                                                    document
                                                                        .documentID
                                                                )
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                }
                            }

                            dispatchGroup.notify(queue: .main) {
                                // Filter documents to only those in region
                                filteredDocuments = documents.filter {
                                    sessionsInRegion.contains($0.documentID)
                                }
                                print(
                                    "📍 Found \(filteredDocuments.count) sessions in \(self.regionRadiusInMiles) mile radius"
                                )

                                // Process the filtered sessions
                                self.processSessions(
                                    documents: filteredDocuments)
                            }
                        } else {
                            // If location is not available, just use all sessions
                            self.processSessions(documents: filteredDocuments)
                        }
                    }
            }
        }
    }

    private func processSessions(documents: [QueryDocumentSnapshot]) {
        // Dictionary to track each user's total time
        var userWeeklyData:
            [String: (userId: String, username: String, minutes: Int)] = [:]

        // Collection of user IDs we need to fetch privacy settings for
        var userIdsToCheck = Set<String>()

        // Process each session document
        for document in documents {
            let data = document.data()

            // Extract basic session info
            guard let userId = data["userId"] as? String,
                let actualDuration = data["actualDuration"] as? Int
            else {
                continue
            }

            // Add this user ID to the list we need to check privacy for
            userIdsToCheck.insert(userId)

            // Get temp username (will be updated later if needed)
            let tempUsername = data["username"] as? String ?? "User"

            // Update the user's total time
            if let existingData = userWeeklyData[userId] {
                userWeeklyData[userId] = (
                    userId: userId,
                    username: existingData.username,
                    minutes: existingData.minutes + actualDuration
                )
            } else {
                userWeeklyData[userId] = (
                    userId: userId,
                    username: tempUsername,
                    minutes: actualDuration
                )
            }
        }

        // No data found - update UI now
        if userWeeklyData.isEmpty {
            DispatchQueue.main.async {
                self.leaderboardEntries = []
                self.isLoading = false
            }
            return
        }

        // Now check privacy settings for all users
        fetchUserPrivacySettings(userIds: Array(userIdsToCheck)) {
            privacySettings in
            // Get all usernames respecting privacy
            self.fetchUsernamesRespectingPrivacy(
                Array(userIdsToCheck), privacySettings: privacySettings
            ) { usernameMap in
                // Get scores and streaks
                self.fetchUserScoresAndStreaks(Array(userIdsToCheck)) {
                    scoresMap, streaksMap in
                    // Now build final entries respecting privacy
                    var entries: [GlobalLeaderboardEntry] = []

                    for (userId, userData) in userWeeklyData {
                        // Skip users who have opted out of leaderboards
                        if let userPrivacy = privacySettings[userId],
                            userPrivacy.optOut
                        {
                            continue
                        }

                        // Determine if user should be anonymous
                        let isAnonymous =
                            privacySettings[userId]?.isAnonymous ?? false
                        let displayUsername =
                            isAnonymous
                            ? "Anonymous"
                            : (usernameMap[userId] ?? userData.username)

                        let entry = GlobalLeaderboardEntry(
                            id: UUID().uuidString,  // Unique ID for SwiftUI
                            userId: userId,
                            username: displayUsername,
                            minutes: userData.minutes,
                            score: scoresMap[userId],
                            streakStatus: streaksMap[userId] ?? .none,
                            isAnonymous: isAnonymous
                        )

                        entries.append(entry)
                    }

                    // Sort by minutes
                    entries.sort { $0.minutes > $1.minutes }

                    DispatchQueue.main.async {
                        self.leaderboardEntries = entries
                        self.isLoading = false
                    }
                }
            }
        }
    }

    // Helper method to determine county/region name
    private func determineCountyName(
        from location: CLLocation, completion: @escaping (String) -> Void
    ) {
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            var regionName = "Your Area"

            if let placemark = placemarks?.first {
                // Try to get the most specific name available
                if let locality = placemark.locality {
                    // City/town name
                    regionName = locality
                } else if let subAdministrativeArea = placemark
                    .subAdministrativeArea
                {
                    // County/district name
                    regionName = subAdministrativeArea
                } else if let administrativeArea = placemark.administrativeArea
                {
                    // State/province name
                    regionName = administrativeArea
                }
            }

            completion(regionName)
        }
    }

    // Helper methods (same as GlobalLeaderboardViewModel)
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) ->
            Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId).getDocument {
                document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    // Get opt-out setting (default to false)
                    let optOut = data["regionalOptOut"] as? Bool ?? false

                    // Get display mode (default to normal)
                    let displayModeString =
                        data["regionalDisplayMode"] as? String ?? "normal"
                    let isAnonymous = displayModeString == "anonymous"

                    result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                } else {
                    // Use defaults if no settings document
                    result[userId] = (optOut: false, isAnonymous: false)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUsernamesRespectingPrivacy(
        _ userIds: [String],
        privacySettings: [String: (optOut: Bool, isAnonymous: Bool)],
        completion: @escaping ([String: String]) -> Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        // First check our cache
        var result: [String: String] = [:]
        var idsToFetch: [String] = []

        for userId in userIds {
            // Check if user is anonymous based on privacy settings
            if let privacySetting = privacySettings[userId],
                privacySetting.isAnonymous
            {
                result[userId] = "Anonymous"
                continue
            }

            if let cachedUser = userCache[userId],
                !cachedUser.username.isEmpty && cachedUser.username != "User"
            {
                result[userId] = cachedUser.username
            } else if let currentUser = FirebaseManager.shared.currentUser,
                currentUser.id == userId, !currentUser.username.isEmpty
            {
                result[userId] = currentUser.username
                // Update cache
                userCache[userId] = UserCacheItem(
                    userId: userId,
                    username: currentUser.username,
                    profileImageURL: currentUser.profileImageURL
                )
            } else {
                idsToFetch.append(userId)
            }
        }

        // If we have all usernames already, return
        if idsToFetch.isEmpty {
            completion(result)
            return
        }

        // Fetch in batches of 10 to avoid Firestore limitations
        let batchSize = 10
        let dispatchGroup = DispatchGroup()

        for i in stride(from: 0, to: idsToFetch.count, by: batchSize) {
            let end = min(i + batchSize, idsToFetch.count)
            let batch = Array(idsToFetch[i..<end])

            dispatchGroup.enter()
            fetchUserBatch(batch) { batchResult in
                // Add this batch to our results
                for (id, username) in batchResult {
                    // Apply privacy settings - override with "Anonymous" if needed
                    if let privacySetting = privacySettings[id],
                        privacySetting.isAnonymous
                    {
                        result[id] = "Anonymous"
                    } else {
                        result[id] = username
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUserBatch(
        _ userIds: [String], completion: @escaping ([String: String]) -> Void
    ) {
        let db = Firestore.firestore()
        var batchResult: [String: String] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                // Try to get username from document
                if let data = document?.data(),
                    let username = data["username"] as? String,
                    !username.isEmpty
                {
                    batchResult[userId] = username

                    // Update our cache
                    self.userCache[userId] = UserCacheItem(
                        userId: userId,
                        username: username,
                        profileImageURL: data["profileImageURL"] as? String
                    )
                } else {
                    batchResult[userId] = "User"
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(batchResult)
        }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    if let score = data["score"] as? Double {
                        scores[userId] = score
                    }
                }
            }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak")
                .document("current").getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] =
                            StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(scores, streaks)
        }
    }
}

// View Model for Regional All Time Leaderboard
class RegionalAllTimeLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [GlobalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var countyName: String = "Your Area"
    private let regionRadiusInMiles: Double = 15.0  // ~15 mile radius

    private let db = Firestore.firestore()
    var userCache: [String: UserCacheItem] = [:]

    @MainActor func loadRegionalAllTimeLeaderboard() {
        isLoading = true

        // Get the current user's location
        let location = LocationHandler.shared.lastLocation

        // Determine the county name for display
        determineCountyName(from: location) { [weak self] countyName in
            guard let self = self else { return }

            // Update the county name for display
            DispatchQueue.main.async {
                self.countyName = countyName
            }

            // Convert miles to meters for geoqueries
            let regionRadiusInMeters = self.regionRadiusInMiles * 1609.34

            // Directly query the users collection to get all users
            self.db.collection("users")
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }

                    if let error = error {
                        print(
                            "Error fetching users: \(error.localizedDescription)"
                        )
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                        return
                    }

                    print("👥 Found \(documents.count) total users")

                    // Extract user IDs and initial data
                    var userIds: [String] = []
                    var userData:
                        [String: (
                            userId: String, username: String, minutes: Int
                        )] = [:]

                    for document in documents {
                        let data = document.data()
                        let userId = document.documentID
                        let totalFocusTime = data["totalFocusTime"] as? Int ?? 0
                        let username = data["username"] as? String ?? "User"

                        // Skip users with zero time
                        if totalFocusTime > 0 {
                            userIds.append(userId)
                            userData[userId] = (
                                userId: userId, username: username,
                                minutes: totalFocusTime
                            )
                        }
                    }

                    // Now filter by location - check if each user has sessions in the region
                    if location.horizontalAccuracy > 0 {
                        self.filterUsersByRegion(
                            userIds: userIds, location: location,
                            regionRadius: regionRadiusInMeters
                        ) { usersInRegion in
                            // Filter the user data to only those in region
                            let filteredUserData = userData.filter {
                                usersInRegion.contains($0.key)
                            }
                            print(
                                "📍 Found \(filteredUserData.count) users with sessions in \(self.regionRadiusInMiles) mile radius"
                            )

                            // Process the filtered users
                            self.processUsers(userData: filteredUserData)
                        }
                    } else {
                        // If location is not available, use all users
                        self.processUsers(userData: userData)
                    }
                }
        }
    }

    private func filterUsersByRegion(
        userIds: [String], location: CLLocation, regionRadius: Double,
        completion: @escaping (Set<String>) -> Void
    ) {
        var usersInRegion = Set<String>()
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Check session_locations for this user to see if any are in our region
            db.collection("session_locations")
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }

                    var userHasSessionInRegion = false

                    if let documents = snapshot?.documents {
                        for document in documents {
                            if let geoPoint = document.data()["location"]
                                as? GeoPoint
                            {
                                let sessionLocation = CLLocation(
                                    latitude: geoPoint.latitude,
                                    longitude: geoPoint.longitude
                                )

                                // Check if within region radius
                                let distance = location.distance(
                                    from: sessionLocation)
                                if distance <= regionRadius {
                                    userHasSessionInRegion = true
                                    break
                                }
                            }
                        }
                    }

                    if userHasSessionInRegion {
                        usersInRegion.insert(userId)
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(usersInRegion)
        }
    }

    private func processUsers(
        userData: [String: (userId: String, username: String, minutes: Int)]
    ) {
        // No data found - update UI now
        if userData.isEmpty {
            DispatchQueue.main.async {
                self.leaderboardEntries = []
                self.isLoading = false
            }
            return
        }

        // Get the user IDs to check privacy settings
        let userIds = Array(userData.keys)

        // Check privacy settings for all users
        fetchUserPrivacySettings(userIds: userIds) { privacySettings in
            // Get scores and streaks
            self.fetchUserScoresAndStreaks(userIds) { scoresMap, streaksMap in
                // Now build final entries respecting privacy
                var entries: [GlobalLeaderboardEntry] = []

                for (userId, userInfo) in userData {
                    // Skip users who have opted out of leaderboards
                    if let userPrivacy = privacySettings[userId],
                        userPrivacy.optOut
                    {
                        continue
                    }

                    // Determine if user should be anonymous
                    let isAnonymous =
                        privacySettings[userId]?.isAnonymous ?? false
                    let displayUsername =
                        isAnonymous ? "Anonymous" : userInfo.username

                    let entry = GlobalLeaderboardEntry(
                        id: UUID().uuidString,  // Unique ID for SwiftUI
                        userId: userId,
                        username: displayUsername,
                        minutes: userInfo.minutes,
                        score: scoresMap[userId],
                        streakStatus: streaksMap[userId] ?? .none,
                        isAnonymous: isAnonymous
                    )

                    entries.append(entry)
                }

                // Sort by minutes
                entries.sort { $0.minutes > $1.minutes }

                DispatchQueue.main.async {
                    self.leaderboardEntries = entries
                    self.isLoading = false
                }
            }
        }
    }

    // Helper method to determine county/region name
    private func determineCountyName(
        from location: CLLocation, completion: @escaping (String) -> Void
    ) {
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            var regionName = "Your Area"

            if let placemark = placemarks?.first {
                // Try to get the most specific name available
                if let locality = placemark.locality {
                    // City/town name
                    regionName = locality
                } else if let subAdministrativeArea = placemark
                    .subAdministrativeArea
                {
                    // County/district name
                    regionName = subAdministrativeArea
                } else if let administrativeArea = placemark.administrativeArea
                {
                    // State/province name
                    regionName = administrativeArea
                }
            }

            completion(regionName)
        }
    }

    // Helper methods (same as GlobalLeaderboardViewModel)
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) ->
            Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId).getDocument {
                document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    // Get opt-out setting (default to false)
                    let optOut = data["regionalOptOut"] as? Bool ?? false

                    // Get display mode (default to normal)
                    let displayModeString =
                        data["regionalDisplayMode"] as? String ?? "normal"
                    let isAnonymous = displayModeString == "anonymous"

                    result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                } else {
                    // Use defaults if no settings document
                    result[userId] = (optOut: false, isAnonymous: false)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    if let score = data["score"] as? Double {
                        scores[userId] = score
                    }
                }
            }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak")
                .document("current").getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] =
                            StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(scores, streaks)
        }
    }
}

// Navigation arrow button reusable component
struct NavigationArrowButton: View {
    let direction: Edge
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(
                systemName: direction == .leading
                    ? "chevron.left" : "chevron.right"
            )
            .font(.system(size: 18))
            .foregroundColor(.white.opacity(0.7))
            .padding(8)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}
