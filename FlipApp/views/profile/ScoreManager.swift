import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class ScoreManager: ObservableObject {
    // Use a static property with a delayed initialization
    static let shared = ScoreManager()

    // Score constants
    private let initialScore: Double = 3.0
    private let maxScore: Double = 300.0
    private let minScore: Double = 0.0

    // UPDATED: Reduced penalties, increased rewards
    private let noPauseMultiplier: Double = 1.8  // Increased from 1.5
    private let failurePenaltyMultiplier: Double = 1.2  // Reduced from 2.0
    private let noPauseFailureReduction: Double = 0.6  // Increased reduction (was 0.8)

    // UPDATED: Base points (increased for faster progression)
    private let baseSuccessPoints: Double = 0.01  // Doubled from 0.005
    private let baseFailurePoints: Double = 0.015  // Reduced from 0.025

    // Duration scaling factors for non-linear growth based on session length
    private let durationScalingFactor: Double = 1.3  // Slightly increased from 1.2

    // Threshold below which sessions earn minimal points (to prevent spamming short sessions)
    private let minEffectiveSessionDuration: Int = 5  // Minutes (unchanged)

    // NEW: Streak system properties
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var streakStatus: StreakStatus = .none
    @Published private(set) var streakSessionsTime: Int = 0  // Total minutes in current streak
    @Published private(set) var lastSuccessfulSession: Date?

    // NEW: Streak constants
    private let streakTimeWindow: TimeInterval = 48 * 3600  // 48 hours in seconds
    private let orangeStreakRequiredSessions: Int = 3
    private let orangeStreakRequiredTime: Int = 120  // 2 hours (in minutes)
    private let redStreakRequiredSessions: Int = 7
    private let redStreakRequiredTime: Int = 300  // 5 hours (in minutes)
    private let streakExpiryTime: TimeInterval = 72 * 3600  // 72 hours in seconds

    // NEW: Streak bonus multiplier
    private let streakBonus: [Double] = [
        1.0,  // No streak
        1.1,  // 1 session streak
        1.2,  // 2 session streak
        1.3,  // 3 session streak
        1.4,  // 4 session streak
        1.5,  // 5 session streak
        1.6,  // 6 session streak
        1.8,  // 7+ session streak
    ]

    @Published private(set) var currentScore: Double = 3.0
    @Published private(set) var scoreHistory: [ScoreChange] = []

    // Use a computed property for db to ensure it's only created when needed
    private var db: Firestore { return Firestore.firestore() }

    // Initialize without immediately accessing Firebase
    private init() {
        // We'll load score explicitly when needed
    }

    // New method to explicitly load score and streak data
    func initialize() {
        loadScore()
        loadStreakData()
    }

    // Calculate points for a completed session
    func processSession(
        duration: Int,
        wasSuccessful: Bool,
        actualDuration: Int,
        pausesEnabled: Bool
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        var pointChange: Double = 0
        var reason: String

        if wasSuccessful {
            // For successful sessions, calculate points based on duration
            // Use the actual duration to calculate the value

            // Apply duration scaling function - longer sessions earn more per minute
            let effectiveDuration = max(actualDuration - minEffectiveSessionDuration, 0)
            let durationFactor = pow(Double(effectiveDuration), durationScalingFactor) / 100.0 + 1.0

            // Calculate base points
            pointChange = baseSuccessPoints * Double(actualDuration) * durationFactor

            // Apply streak bonus if applicable
            let streakMultiplier = getStreakMultiplier()
            pointChange *= streakMultiplier

            // Apply no-pause multiplier if pauses were disabled
            if !pausesEnabled {
                pointChange *= noPauseMultiplier

                if streakMultiplier > 1.0 {
                    reason =
                        "Completed \(actualDuration)min session (no pauses, \(String(format: "%.1fx", streakMultiplier)) streak bonus)"
                }
                else {
                    reason = "Completed \(actualDuration)min session (no pauses)"
                }
            }
            else {
                if streakMultiplier > 1.0 {
                    reason =
                        "Completed \(actualDuration)min session (\(String(format: "%.1fx", streakMultiplier)) streak bonus)"
                }
                else {
                    reason = "Completed \(actualDuration)min session"
                }
            }

            // Update streak data
            updateStreak(wasSuccessful: true, duration: actualDuration)
        }
        else {
            // For failed sessions, apply a penalty (reduced from before)
            let failurePenalty = baseFailurePoints * Double(duration)

            // Apply penalty reduction if no pauses were enabled (acknowledging the higher difficulty)
            if !pausesEnabled {
                pointChange = -failurePenalty * noPauseFailureReduction
                reason = "Failed \(duration)min session (no pauses)"
            }
            else {
                pointChange = -failurePenalty * failurePenaltyMultiplier
                reason = "Failed \(duration)min session"
            }

            // Update streak data - failure breaks streak
            updateStreak(wasSuccessful: false, duration: actualDuration)
        }

        // Apply point change to current score
        let oldScore = currentScore
        currentScore = min(maxScore, max(minScore, currentScore + pointChange))

        // Create record for history
        let scoreChange = ScoreChange(
            date: Date(),
            oldScore: oldScore,
            newScore: currentScore,
            change: pointChange,
            reason: reason
        )

        // Add to local history
        scoreHistory.insert(scoreChange, at: 0)

        // Save to Firebase
        saveScore(userId: userId, score: currentScore, scoreChange: scoreChange)
        saveStreakData(userId: userId)
    }

    // NEW: Get appropriate streak multiplier based on current streak
    private func getStreakMultiplier() -> Double {
        // Cap at the maximum multiplier in our array
        let index = min(currentStreak, streakBonus.count - 1)
        return streakBonus[index]
    }

    // NEW: Update streak status after a session
    private func updateStreak(wasSuccessful: Bool, duration: Int) {
        let now = Date()

        if wasSuccessful {
            if let lastSession = lastSuccessfulSession {
                // Check if the last session was within the streak window
                if now.timeIntervalSince(lastSession) <= streakTimeWindow {
                    // Continue the streak
                    currentStreak += 1
                    streakSessionsTime += duration
                }
                else {
                    // Streak window expired, start a new streak
                    currentStreak = 1
                    streakSessionsTime = duration
                }
            }
            else {
                // First successful session
                currentStreak = 1
                streakSessionsTime = duration
            }

            // Update last successful session time
            lastSuccessfulSession = now

            // Determine streak status based on count and total time
            updateStreakStatus()
        }
        else {
            // Failed session - reset streak
            currentStreak = 0
            streakSessionsTime = 0

            // But we don't reset the streak status immediately
            // Check if we should downgrade or lose streak status
            if streakStatus == .redFlame {
                // Downgrade to orange if we still meet those criteria
                if meetOrangeStreakCriteria() {
                    streakStatus = .orangeFlame
                }
                else {
                    streakStatus = .none
                }
            }
            else if streakStatus == .orangeFlame {
                // Lose streak entirely
                streakStatus = .none
            }
        }
    }

    // NEW: Check and update streak status based on current streak data
    private func updateStreakStatus() {
        if currentStreak >= redStreakRequiredSessions && streakSessionsTime >= redStreakRequiredTime
        {
            streakStatus = .redFlame
        }
        else if currentStreak >= orangeStreakRequiredSessions
            && streakSessionsTime >= orangeStreakRequiredTime
        {
            streakStatus = .orangeFlame
        }
    }

    // NEW: Check if user still meets orange streak criteria
    private func meetOrangeStreakCriteria() -> Bool {
        return currentStreak >= orangeStreakRequiredSessions
            && streakSessionsTime >= orangeStreakRequiredTime
    }

    // NEW: Check if streak has expired (for app startup)
    private func checkStreakExpiry() {
        guard let lastSession = lastSuccessfulSession else {
            // No previous successful session
            streakStatus = .none
            currentStreak = 0
            return
        }

        if Date().timeIntervalSince(lastSession) > streakExpiryTime {
            // Streak has expired
            streakStatus = .none
            currentStreak = 0
            streakSessionsTime = 0
        }
    }

    // NEW: Load streak data from Firebase
    private func loadStreakData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).collection("streak").document("current")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        self.currentStreak = data["currentStreak"] as? Int ?? 0
                        self.streakSessionsTime = data["streakSessionsTime"] as? Int ?? 0

                        if let statusString = data["streakStatus"] as? String {
                            self.streakStatus = StreakStatus(rawValue: statusString) ?? .none
                        }

                        if let lastSessionTimestamp = data["lastSuccessfulSession"] as? Timestamp {
                            self.lastSuccessfulSession = lastSessionTimestamp.dateValue()

                            // Check if streak has expired
                            self.checkStreakExpiry()
                        }
                    }
                }
            }
    }

    // NEW: Save streak data to Firebase
    private func saveStreakData(userId: String) {
        let streakData: [String: Any] = [
            "currentStreak": currentStreak, "streakSessionsTime": streakSessionsTime,
            "streakStatus": streakStatus.rawValue,
            "lastSuccessfulSession": lastSuccessfulSession.map { Timestamp(date: $0) }
                ?? FieldValue.serverTimestamp(), "updatedAt": FieldValue.serverTimestamp(),
        ]

        db.collection("users").document(userId).collection("streak").document("current")
            .setData(streakData) { error in
                if let error = error {
                    print("Error saving streak data: \(error.localizedDescription)")
                }
            }
    }

    // Load score from Firebase
    private func loadScore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Default to initial score if not logged in
            currentScore = initialScore
            return
        }

        db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists, let data = document.data() {
                    if let score = data["score"] as? Double {
                        DispatchQueue.main.async { self.currentScore = score }
                    }
                    else {
                        // Initialize score if not present
                        DispatchQueue.main.async {
                            self.currentScore = self.initialScore
                            self.saveScore(
                                userId: userId,
                                score: self.initialScore,
                                scoreChange: nil
                            )
                        }
                    }

                    // Load score history
                    self.loadScoreHistory(userId: userId)
                }
                else {
                    // User document doesn't exist yet
                    DispatchQueue.main.async { self.currentScore = self.initialScore }
                }
            }
    }

    // Load score history from Firebase
    private func loadScoreHistory(userId: String) {
        db.collection("users").document(userId).collection("scoreHistory")
            .order(by: "date", descending: true).limit(to: 50)  // Limit to recent history
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }

                let history = documents.compactMap { document -> ScoreChange? in
                    let data = document.data()

                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                        let oldScore = data["oldScore"] as? Double,
                        let newScore = data["newScore"] as? Double,
                        let change = data["change"] as? Double,
                        let reason = data["reason"] as? String
                    else { return nil }

                    return ScoreChange(
                        id: document.documentID,
                        date: date,
                        oldScore: oldScore,
                        newScore: newScore,
                        change: change,
                        reason: reason
                    )
                }

                DispatchQueue.main.async { self.scoreHistory = history }
            }
    }

    // Save score to Firebase
    private func saveScore(userId: String, score: Double, scoreChange: ScoreChange?) {
        // Update the user's current score
        db.collection("users").document(userId)
            .updateData(["score": score]) { error in
                if let error = error {
                    print("Error updating score: \(error.localizedDescription)")
                }
            }

        // Add to score history if there's a change to record
        if let scoreChange = scoreChange {
            let historyData: [String: Any] = [
                "date": Timestamp(date: scoreChange.date), "oldScore": scoreChange.oldScore,
                "newScore": scoreChange.newScore, "change": scoreChange.change,
                "reason": scoreChange.reason,
            ]

            db.collection("users").document(userId).collection("scoreHistory")
                .addDocument(data: historyData) { error in
                    if let error = error {
                        print("Error saving score history: \(error.localizedDescription)")
                    }
                }
        }
    }

    // Get rank name based on current score
    func getCurrentRank() -> (name: String, color: Color) {
        switch currentScore {
        case 0.0..<30.0:
            return ("Novice", Color(red: 156 / 255, green: 163 / 255, blue: 231 / 255))  // Periwinkle
        case 30.0..<60.0:
            return ("Apprentice", Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255))  // Light blue
        case 60.0..<90.0:
            return ("Beginner", Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255))  // Blue
        case 90.0..<120.0:
            return ("Steady", Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255))  // Green
        case 120.0..<150.0:
            return ("Focused", Color(red: 249 / 255, green: 180 / 255, blue: 45 / 255))  // Bright amber
        case 150.0..<180.0: return ("Disciplined", Theme.orange)  // Orange
        case 180.0..<210.0: return ("Resolute", Theme.mutedRed)  // Red
        case 210.0..<240.0:
            return ("Master", Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255))  // Pink
        case 240.0..<270.0:
            return ("Guru", Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255))  // Vivid purple
        case 270.0...300.0:
            return ("Enlightened", Color(red: 236 / 255, green: 64 / 255, blue: 255 / 255))  // Bright fuchsia
        default: return ("Unranked", Color.gray)
        }
    }

    // Helper to calculate how many points needed for next rank
    func pointsToNextRank() -> Double? {
        let ranks = [30.0, 60.0, 90.0, 120.0, 150.0, 180.0, 210.0, 240.0, 270.0, 300.0]
        let current = currentScore

        for rank in ranks { if current < rank { return rank - current } }

        return nil  // Already at max rank
    }

    // Reset score to initial value (for testing)
    func resetScore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        currentScore = initialScore
        saveScore(userId: userId, score: initialScore, scoreChange: nil)
    }

    // NEW: Reset streak (for testing)
    func resetStreak() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        currentStreak = 0
        streakSessionsTime = 0
        streakStatus = .none
        lastSuccessfulSession = nil
        saveStreakData(userId: userId)
    }

    // NEW: Get streak description for info panel
    func getStreakDescription() -> String {
        switch streakStatus {
        case .orangeFlame:
            return
                "🔥 ON FIRE! You're on a streak of \(currentStreak) successful sessions totaling \(streakSessionsTime) minutes."
        case .redFlame:
            return
                "🔥🔥 BLAZING! You're on an intense streak of \(currentStreak) successful sessions totaling \(streakSessionsTime) minutes!"
        case .none:
            if currentStreak > 0 {
                return "You're building a streak with \(currentStreak) successful sessions so far."
            }
            else {
                return "Complete successful sessions in a row to build a streak!"
            }
        }
    }
}

// Model for recording score changes
struct ScoreChange: Identifiable {
    var id: String = UUID().uuidString
    let date: Date
    let oldScore: Double
    let newScore: Double
    let change: Double
    let reason: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var isPositive: Bool { return change > 0 }
}

// NEW: Streak status enum
enum StreakStatus: String, Codable {
    case none = "none"
    case orangeFlame = "orangeFlame"
    case redFlame = "redFlame"
}

// SwiftUI Color extension for Firestore compatibility
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        #if canImport(UIKit)
            typealias NativeColor = UIColor
        #elseif canImport(AppKit)
            typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            return (0, 0, 0, 0)
        }

        return (Double(r), Double(g), Double(b), Double(o))
    }
}
