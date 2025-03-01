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
    
    // New fields for multi-user sessions
    let participants: [Participant]?  // List of session participants
    let originalStarterId: String?    // Who started the session
    let wasJoinedSession: Bool?       // Whether this was a joined session
    
    // New field for comments
    let comment: String?        // Optional comment on the session
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    // Helper struct for participant data
    struct Participant: Codable, Identifiable {
        let id: String
        let username: String
        let joinTime: Date
        let wasSuccessful: Bool
        let actualDuration: Int
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
        sessionNotes: String?,
        participants: [Participant]? = nil,
        originalStarterId: String? = nil,
        wasJoinedSession: Bool? = nil,
        comment: String? = nil
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
            sessionNotes: sessionNotes,
            participants: participants,
            originalStarterId: originalStarterId,
            wasJoinedSession: wasJoinedSession,
            comment: comment
        )
    }
    
    // Method to update comment
    func withUpdatedComment(_ newComment: String) -> Session {
        return Session(
            id: id,
            userId: userId,
            username: username,
            startTime: startTime,
            duration: duration,
            wasSuccessful: wasSuccessful,
            actualDuration: actualDuration,
            sessionTitle: sessionTitle,
            sessionNotes: sessionNotes,
            participants: participants,
            originalStarterId: originalStarterId,
            wasJoinedSession: wasJoinedSession,
            comment: newComment
        )
    }
}