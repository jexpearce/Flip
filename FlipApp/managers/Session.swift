import FirebaseFirestore
import Foundation

struct Session: Codable, Identifiable {
    let id: UUID
    let userId: String
    let username: String
    let startTime: Date
    let duration: Int  // in minutes
    let wasSuccessful: Bool
    let actualDuration: Int  // how long they actually lasted
    
    // New fields for custom session notes
    let sessionTitle: String?  // Optional to handle older sessions
    let sessionNotes: String?  // Optional to handle older sessions

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    // Helper initializer for creating a session with notes
    static func createWithNotes(
        id: UUID = UUID(),
        userId: String,
        username: String,
        startTime: Date = Date(),
        duration: Int,
        wasSuccessful: Bool,
        actualDuration: Int,
        sessionTitle: String?,
        sessionNotes: String?
    ) -> Session {
        return Session(
            id: id,
            userId: userId,
            username: username,
            startTime: startTime,
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            sessionTitle: sessionTitle,
            sessionNotes: sessionNotes
        )
    }
}