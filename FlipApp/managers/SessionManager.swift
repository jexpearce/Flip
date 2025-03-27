import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    @Published private(set) var sessions: [Session] = []
    @Published var showPromotionAlert = false
    @Published var promotionRankName = ""
    @Published var promotionRankColor = Color.blue
    @Published var showStreakAchievement = false
    @Published var streakAchievementStatus: StreakStatus = .none
    @Published var streakCount: Int = 0

    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "flipSessions"
    private let scoreManager = ScoreManager.shared

    init() {
        loadSessions()
    }

    // Standard session method with streak achievement check
    func addSession(
        duration: Int, wasSuccessful: Bool, actualDuration: Int,
        sessionTitle: String? = nil, sessionNotes: String? = nil
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let newSession = Session(
            id: UUID(),
            userId: userId,
            username: FirebaseManager.shared.currentUser?.username ?? "",
            startTime: Date(),
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            sessionTitle: sessionTitle,
            sessionNotes: sessionNotes,
            participants: nil,
            originalStarterId: nil,
            wasJoinedSession: nil,
            comment: nil,
            commentorId: nil,
            commentorName: nil,
            commentTime: nil,
            liveSessionId: nil
        )

        sessions.insert(newSession, at: 0)  // Add to beginning of array
        saveSessions()

        // Upload to Firebase
        uploadSession(newSession)

        // Process session with achievement checks
        processCompletedSession(
            duration: duration, wasSuccessful: wasSuccessful,
            actualDuration: actualDuration)
    }

    // New method for multi-user sessions with streak achievement check
    func addSession(
        duration: Int,
        wasSuccessful: Bool,
        actualDuration: Int,
        sessionTitle: String? = nil,
        sessionNotes: String? = nil,
        participants: [Session.Participant]? = nil,
        originalStarterId: String? = nil,
        wasJoinedSession: Bool? = nil,
        liveSessionId: String? = nil
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let newSession = Session(
            id: UUID(),
            userId: userId,
            username: FirebaseManager.shared.currentUser?.username ?? "",
            startTime: Date(),
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            sessionTitle: sessionTitle,
            sessionNotes: sessionNotes,
            participants: participants,
            originalStarterId: originalStarterId,
            wasJoinedSession: wasJoinedSession,
            comment: nil,
            commentorId: nil,
            commentorName: nil,
            commentTime: nil,
            liveSessionId: liveSessionId
        )

        sessions.insert(newSession, at: 0)  // Add to beginning of array
        saveSessions()

        // Upload to Firebase
        uploadSession(newSession)

        // Process session with achievement checks
        processCompletedSession(
            duration: duration, wasSuccessful: wasSuccessful,
            actualDuration: actualDuration)
    }

    // New central method to process achievements for completed sessions
    private func processCompletedSession(
        duration: Int, wasSuccessful: Bool, actualDuration: Int
    ) {
        let pausesEnabled = AppManager.shared.allowPauses

        // Use the new combined achievement check method
        let result = scoreManager.processSessionWithAchievementCheck(
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            pausesEnabled: pausesEnabled
        )

        // Handle rank promotion
        if let rankPromotion = result.rankPromotion, rankPromotion.0 {
            DispatchQueue.main.async {
                self.promotionRankName = rankPromotion.1.0
                self.promotionRankColor = rankPromotion.1.1
                self.showPromotionAlert = true
            }
        }

        // Handle streak achievement
        if let streakAchievement = result.streakAchievement, streakAchievement.0
        {
            DispatchQueue.main.async {
                self.streakAchievementStatus = streakAchievement.1
                self.streakCount = streakAchievement.2

                // Delay showing streak achievement if there's a rank promotion
                // to avoid multiple alerts at once
                if self.showPromotionAlert {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.showStreakAchievement = true
                    }
                } else {
                    self.showStreakAchievement = true
                }

                // Also post notification for other views that might need to know
                NotificationCenter.default.post(
                    name: Notification.Name("StreakAchievementEarned"),
                    object: nil,
                    userInfo: [
                        "status": streakAchievement.1.rawValue,
                        "count": streakAchievement.2,
                    ]
                )
            }
        }
    }

    // This method is now redundant with the updated addSession
    // But we'll keep it for backward compatibility if needed
    func addSessionWithNotes(
        duration: Int,
        wasSuccessful: Bool,
        actualDuration: Int,
        sessionTitle: String?,
        sessionNotes: String?
    ) {
        addSession(
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            sessionTitle: sessionTitle,
            sessionNotes: sessionNotes,
            participants: nil,
            originalStarterId: nil,
            wasJoinedSession: nil,
            liveSessionId: nil
        )
    }

    private func uploadSession(_ session: Session) {
        try? FirebaseManager.shared.db.collection("sessions")
            .document(session.id.uuidString)
            .setData(from: session)
    }

    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
            let decodedSessions = try? JSONDecoder().decode(
                [Session].self, from: data)
        {
            sessions = decodedSessions
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }

    // Analytics methods
    var totalSuccessfulSessions: Int {
        sessions.filter { $0.wasSuccessful }.count
    }

    var totalFocusTime: Int {
        sessions.reduce(0) { $0 + $1.actualDuration }
    }

    var averageSessionLength: Int {
        guard !sessions.isEmpty else { return 0 }
        return totalFocusTime / sessions.count
    }

    var longestSession: Int {
        sessions.reduce(0) { max($0, $1.actualDuration) }
    }
}
