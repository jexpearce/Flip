import FirebaseAuth
import FirebaseFirestore
import Foundation

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    @Published private(set) var sessions: [Session] = []

    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "flipSessions"
    private let scoreManager = ScoreManager.shared
    init() {
        loadSessions()
    }

    func addSession(duration: Int, wasSuccessful: Bool, actualDuration: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let newSession = Session(
            id: UUID(),
            userId: userId,
            username: FirebaseManager.shared.currentUser?.username ?? "",
            startTime: Date(),
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration
        )

        sessions.insert(newSession, at: 0)  // Add to beginning of array
        saveSessions()

        // Upload to Firebase
        uploadSession(newSession)
        let pausesEnabled = AppManager.shared.allowPauses
                
                // Process the session in ScoreManager to update the score
                scoreManager.processSession(
                    duration: duration,
                    wasSuccessful: wasSuccessful,
                    actualDuration: actualDuration,
                    pausesEnabled: pausesEnabled
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
