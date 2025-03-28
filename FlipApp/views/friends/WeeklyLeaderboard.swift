import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct WeeklyLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var isShowingAll = false

    var body: some View {
        VStack(spacing: 8) {
            // Rich golden title with icon
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.yellow,
                                Color(
                                    red: 234 / 255, green: 179 / 255,
                                    blue: 8 / 255),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: Color(
                            red: 234 / 255, green: 179 / 255, blue: 8 / 255
                        ).opacity(0.6), radius: 8)

                Text("WEEKLY CHAMPIONS")
                    .font(.system(size: 18, weight: .black))
                    .tracking(2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.yellow,
                                Color(
                                    red: 234 / 255, green: 179 / 255,
                                    blue: 8 / 255),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: Color(
                            red: 234 / 255, green: 179 / 255, blue: 8 / 255
                        ).opacity(0.6), radius: 8)

                Spacer()

                // Show more/less toggle
                Button(action: {
                    withAnimation(.spring()) {
                        isShowingAll.toggle()
                    }
                }) {
                    Text(isShowingAll ? "Show Less" : "Show All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(
                            Theme.yellow
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    Color(
                                        red: 234 / 255, green: 179 / 255,
                                        blue: 8 / 255
                                    ).opacity(0.15)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color(
                                                red: 234 / 255,
                                                green: 179 / 255, blue: 8 / 255
                                            ).opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .opacity(viewModel.leaderboardEntries.count > 3 ? 1 : 0)
            }
            .padding(.horizontal, 6)

            if viewModel.isLoading {
                // Loading indicator
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(
                            Theme.yellow
                        )
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else {
                // Column Headers
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Theme.yellow
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Theme.yellow
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("TIME")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            Theme.yellow
                        )
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

                if viewModel.leaderboardEntries.isEmpty {
                    // Empty State
                    VStack(spacing: 15) {
                        Image(systemName: "crown")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.yellow,
                                        Color(
                                            red: 234 / 255, green: 179 / 255,
                                            blue: 8 / 255),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Color(
                                    red: 234 / 255, green: 179 / 255,
                                    blue: 8 / 255
                                ).opacity(0.6), radius: 8)

                        Text("No sessions recorded this week")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    // Users List with rich styling
                    LazyVStack(spacing: 10) {
                        let displayEntries =
                            isShowingAll
                            ? viewModel.leaderboardEntries
                            : Array(viewModel.leaderboardEntries.prefix(3))

                        ForEach(
                            Array(displayEntries.enumerated()), id: \.element.id
                        ) { index, entry in
                            EnhancedLeaderboardRow(
                                rank: index + 1,
                                entry: entry,
                                isCurrentUser: Auth.auth().currentUser?.uid
                                    == entry.id
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                // Rich golden gradient background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 133 / 255, green: 77 / 255,
                                    blue: 14 / 255
                                ).opacity(0.3),
                                Color(
                                    red: 113 / 255, green: 63 / 255,
                                    blue: 18 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glass effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))

                // Glowing golden border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.yellow.opacity(0.6),
                                Color(
                                    red: 234 / 255, green: 179 / 255,
                                    blue: 8 / 255
                                ).opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(
            color: Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255)
                .opacity(0.2), radius: 10
        )
        .onAppear {
            viewModel.loadLeaderboard()
        }
    }

    // Medal view for top 3
    private func medalView(for index: Int) -> some View {
        ZStack {
            // Medal color based on rank
            Image(systemName: "medal.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    medalGradient(for: index)
                )
                .shadow(color: medalShadowColor(for: index), radius: 4)
        }
    }

    // Medal gradients
    private func medalGradient(for index: Int) -> LinearGradient {
        switch index {
        case 0:  // Gold
            return LinearGradient(
                colors: [
                    Color(red: 253 / 255, green: 224 / 255, blue: 71 / 255),
                    Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 1:  // Silver
            return LinearGradient(
                colors: [
                    Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
                    Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:  // Bronze
            return LinearGradient(
                colors: [
                    Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255),
                    Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Medal shadow colors
    private func medalShadowColor(for index: Int) -> Color {
        switch index {
        case 0:
            return Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255)
                .opacity(0.6)
        case 1:
            return Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
                .opacity(0.6)
        case 2:
            return Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255)
                .opacity(0.6)
        default: return Color.gray.opacity(0.6)
        }
    }
}

// NEW: Enhanced leaderboard row with streak indicators
struct EnhancedLeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    @State private var streakStatus: StreakStatus = .none

    var body: some View {
        HStack {
            // Rank with medal for top 3
            if rank <= 3 {
                medalView(for: rank - 1)
                    .frame(width: 40, alignment: .center)
            } else {
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, alignment: .center)
            }

            // User info with streak
            HStack(spacing: 10) {
                // Score circle if available
                if let score = entry.score {
                    RankCircle(
                        score: score, size: 26, showStreakIndicator: false)
                }

                // Profile picture
                ZStack {
                    ProfileImage(userId: entry.id, size: 32)

                    // Streak indicator if active
                    if streakStatus != .none {
                        Circle()
                            .stroke(
                                streakStatus == .redFlame
                                    ? Color.red.opacity(0.8)
                                    : Color.orange.opacity(0.8),
                                lineWidth: 2
                            )
                            .frame(width: 32, height: 32)

                        // Flame icon
                        ZStack {
                            Circle()
                                .fill(
                                    streakStatus == .redFlame
                                        ? Color.red : Color.orange
                                )
                                .frame(width: 12, height: 12)

                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                        .position(x: 24, y: 8)
                    }
                }

                Text(entry.username)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .frame(width: 150, alignment: .leading)

            Spacer()

            // Focus time
            Text("\(entry.totalTime)m")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                // Different background for top 3
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: rank <= 3
                                ? [
                                    Color(
                                        red: 234 / 255, green: 179 / 255,
                                        blue: 8 / 255
                                    ).opacity(0.3),
                                    Color(
                                        red: 234 / 255, green: 179 / 255,
                                        blue: 8 / 255
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

                // Highlight for current user
                if isCurrentUser {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.yellow.opacity(0.7),
                                    Theme.yellow.opacity(0.3),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
        )
        .onAppear {
            // Load streak status when row appears
            loadStreakStatus()
        }
    }

    // Helper method to load streak status
    private func loadStreakStatus() {
        FirebaseManager.shared.db.collection("users").document(entry.id)
            .collection("streak").document("current")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(),
                    let statusString = data["streakStatus"] as? String,
                    let status = StreakStatus(rawValue: statusString)
                {

                    DispatchQueue.main.async {
                        self.streakStatus = status
                    }
                }
            }
    }

    // Medal view for top 3
    private func medalView(for index: Int) -> some View {
        ZStack {
            // Medal color based on rank
            Image(systemName: "medal.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    medalGradient(for: index)
                )
                .shadow(color: medalShadowColor(for: index), radius: 4)
        }
    }

    // Medal gradients
    private func medalGradient(for index: Int) -> LinearGradient {
        switch index {
        case 0:  // Gold
            return LinearGradient(
                colors: [
                    Color(red: 253 / 255, green: 224 / 255, blue: 71 / 255),
                    Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 1:  // Silver
            return LinearGradient(
                colors: [
                    Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
                    Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2:  // Bronze
            return LinearGradient(
                colors: [
                    Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255),
                    Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Medal shadow colors
    private func medalShadowColor(for index: Int) -> Color {
        switch index {
        case 0:
            return Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255)
                .opacity(0.6)
        case 1:
            return Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
                .opacity(0.6)
        case 2:
            return Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255)
                .opacity(0.6)
        default: return Color.gray.opacity(0.6)
        }
    }
}

// Updated data model for leaderboard entries
struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let totalTime: Int
    var score: Double? = nil  // NEW: Add score for rank circle
}

// Fixed ViewModel for Leaderboard
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading = false

    private let firebaseManager = FirebaseManager.shared

    func loadLeaderboard() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        print("Loading weekly leaderboard for user: \(currentUserId)")

        // First get the user's friends list
        firebaseManager.db.collection("users").document(currentUserId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "Error fetching user data: \(error.localizedDescription)"
                    )
                    self.isLoading = false
                    return
                }

                guard
                    let userData = try? document?.data(
                        as: FirebaseManager.FlipUser.self)
                else {
                    print("Failed to decode user data")
                    self.isLoading = false
                    return
                }

                // Include user's own ID in the list
                var userIds = userData.friends
                userIds.append(currentUserId)

                print(
                    "Fetching data for \(userIds.count) users (self + friends)")
                self.fetchWeeklyTotalFocusTime(for: userIds)
            }
    }

    private func fetchWeeklyTotalFocusTime(for userIds: [String]) {
        let calendar = Calendar.current
        let currentDate = Date()

        // Calculate week start - more robust method
        var components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: currentDate)
        components.weekday = 1  // Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let weekStart = calendar.date(from: components) else {
            print("Error calculating week start")
            self.isLoading = false
            return
        }

        // For debugging
        print("Current date: \(currentDate)")
        print("Week start: \(weekStart)")

        // First fetch all users to make sure we have usernames and scores
        var usernames: [String: String] = [:]
        var userScores: [String: Double] = [:]
        let group = DispatchGroup()

        for userId in userIds {
            group.enter()

            firebaseManager.db.collection("users").document(userId).getDocument
            { document, error in
                defer { group.leave() }

                if let document = document, let data = document.data() {
                    if let username = data["username"] as? String {
                        usernames[userId] = username
                    }

                    if let score = data["score"] as? Double {
                        userScores[userId] = score
                    }

                    print(
                        "Fetched user data for \(userId): name=\(usernames[userId] ?? "unknown"), score=\(userScores[userId] ?? 0)"
                    )
                } else {
                    print("Failed to fetch user data for \(userId)")
                }
            }
        }

        group.notify(queue: .main) {
            // Fetch all sessions from this week for these users
            self.firebaseManager.db.collection("sessions")
                .whereField("userId", in: userIds)
                .whereField("wasSuccessful", isEqualTo: true)
                .order(by: "startTime", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }

                    if let error = error {
                        print(
                            "Error fetching sessions: \(error.localizedDescription)"
                        )
                        self.isLoading = false
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("No documents found")
                        self.isLoading = false
                        return
                    }

                    print("Fetched \(documents.count) total sessions")

                    // Process sessions with better error handling
                    var allSessions: [Session] = []
                    for document in documents {
                        do {
                            if let session = try? document.data(
                                as: Session.self)
                            {
                                allSessions.append(session)
                            } else {
                                print(
                                    "Failed to decode session: \(document.documentID)"
                                )
                            }
                        }
                    }

                    print("Successfully decoded \(allSessions.count) sessions")

                    // Filter for this week's sessions with more debugging
                    let thisWeeksSessions = allSessions.filter { session in
                        let isThisWeek = calendar.isDate(
                            session.startTime, inSameWeekAs: weekStart)
                        if isThisWeek {
                            print(
                                "Session \(session.id) from \(session.startTime) is in this week"
                            )
                        }
                        return isThisWeek
                    }

                    print(
                        "Found \(thisWeeksSessions.count) sessions from this week"
                    )

                    // Group by user, sum up total time for each
                    var userTotalTimes: [String: Int] = [:]

                    for session in thisWeeksSessions {
                        let userId = session.userId
                        let sessionTime = session.actualDuration

                        if let existingTime = userTotalTimes[userId] {
                            // Add to existing total
                            userTotalTimes[userId] = existingTime + sessionTime
                        } else {
                            // Create new entry
                            userTotalTimes[userId] = sessionTime
                        }
                    }

                    // Even if no sessions this week, include all users with zero time
                    for userId in userIds {
                        if userTotalTimes[userId] == nil {
                            userTotalTimes[userId] = 0
                        }
                    }

                    // Convert to leaderboard entries and sort
                    var entries: [LeaderboardEntry] = []

                    for (userId, totalTime) in userTotalTimes {
                        // Use username from our cache, or fallback to user ID
                        let username =
                            usernames[userId] ?? "User \(userId.prefix(5))"

                        // Include score if available
                        entries.append(
                            LeaderboardEntry(
                                id: userId,
                                username: username,
                                totalTime: totalTime,
                                score: userScores[userId]
                            ))
                    }

                    // Sort by total time (descending)
                    entries.sort { $0.totalTime > $1.totalTime }

                    print("Final leaderboard entries: \(entries.count)")

                    DispatchQueue.main.async {
                        self.leaderboardEntries = entries
                        self.isLoading = false
                    }
                }
        }
    }
}
