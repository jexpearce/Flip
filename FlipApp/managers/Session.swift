import FirebaseFirestore
import Foundation

struct Session: Identifiable, Codable {
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
    struct Participant: Codable {
        let userId: String
        let joinTime: Date
        let status: String?  // "completed", "failed", "active"
    }
    static func == (lhs: Session, rhs: Session) -> Bool { return lhs.id == rhs.id }
}

extension Session {
    // Convenience computed property to check if this was a joined live session
    var isJoinedLiveSession: Bool { return wasJoinedSession == true && liveSessionId != nil }
    // Convenience property to check if this was a host session with participants
    var isHostedSession: Bool {
        return participants != nil && participants!.count > 1 && originalStarterId == userId
    }
    // Get the icon name for this session
    var iconName: String {
        if isJoinedLiveSession {
            return "person.2.fill"
        }
        else if isHostedSession {
            return "person.2.fill"
        }
        else if wasSuccessful {
            return "checkmark.circle.fill"
        }
        else {
            return "xmark.circle.fill"
        }
    }
    // Get the color for the session icon
    var iconColor: String {
        if isJoinedLiveSession || isHostedSession {
            return "green"
        }
        else if wasSuccessful {
            return "blue"
        }
        else {
            return "red"
        }
    }
}
