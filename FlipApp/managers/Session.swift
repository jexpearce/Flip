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
    let originalStarterId: String?  // Who started the session
    let wasJoinedSession: Bool?  // Whether this was a joined session

    // New fields for comments
    let comment: String?  // Optional comment on the session
    let commentorId: String?  // Who made the comment
    let commentorName: String?  // Username of the commentor
    let commentTime: Date?  // When the comment was made
    let liveSessionId: String?  // Add this property for linking sessions

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
    static func == (lhs: Session, rhs: Session) -> Bool { return lhs.id == rhs.id }

}
