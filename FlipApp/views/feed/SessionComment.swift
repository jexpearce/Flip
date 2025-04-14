import SwiftUI

struct SessionComment: Codable, Identifiable {
    var id: String  // Document ID
    let sessionId: String
    let userId: String
    let username: String
    let comment: String
    let timestamp: Date

    // Computed property for timestamp formatting
    var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: timestamp))"
        }
        else if Calendar.current.isDateInYesterday(timestamp) {
            return "Yesterday"
        }
        else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: timestamp)
        }
    }
}
