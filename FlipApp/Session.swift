import FirebaseFirestore
import Foundation

struct Session: Codable, Identifiable {
  let id: UUID
  let userId: String  // Add this
  let username: String  // Add this
  let startTime: Date
  let duration: Int  // in minutes
  let wasSuccessful: Bool
  let actualDuration: Int  // how long they actually lasted

  var formattedStartTime: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: startTime)
  }
}
