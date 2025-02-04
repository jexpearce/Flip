import Foundation

struct FlipSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let duration: Int // in minutes
    let wasSuccessful: Bool
    let actualDuration: Int // how long they actually lasted
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}
