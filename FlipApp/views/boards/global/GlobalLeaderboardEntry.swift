struct GlobalLeaderboardEntry {
    let id: String
    let userId: String
    let username: String
    let minutes: Int
    var score: Double? = nil
    var streakStatus: StreakStatus = .none
    var isAnonymous: Bool = false
}
