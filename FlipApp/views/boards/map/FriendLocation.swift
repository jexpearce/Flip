import CoreLocation
import SwiftUI

struct FriendLocation: Identifiable, Equatable {
    let id: String
    let username: String
    let coordinate: CLLocationCoordinate2D
    let isCurrentlyFlipped: Bool
    let lastFlipTime: Date
    let lastFlipWasSuccessful: Bool
    let sessionDuration: Int  // in minutes
    let sessionStartTime: Date
    let isHistorical: Bool  // Flag to indicate if this is a past session
    let sessionIndex: Int  // Index to track which historical session (0 = current, 1 = most recent, etc.)
    let participants: [String]?  // User IDs of participants
    let participantNames: [String]?  // Names of participants

    // Computed properties for UI
    var sessionMinutesElapsed: Int {
        if isHistorical {
            // For historical sessions, return the actual duration that was completed
            let seconds = lastFlipTime.timeIntervalSince(sessionStartTime)
            return Int(seconds / 60)
        }
        else {
            // For current sessions, calculate from current time
            let seconds = Date().timeIntervalSince(sessionStartTime)
            return Int(seconds / 60)
        }
    }

    var sessionTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: sessionStartTime, relativeTo: Date())
    }

    // Required for Equatable conformance - needed for proper map view refreshing
    static func == (lhs: FriendLocation, rhs: FriendLocation) -> Bool {
        return lhs.id == rhs.id && lhs.username == rhs.username
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.isCurrentlyFlipped == rhs.isCurrentlyFlipped
            && lhs.lastFlipTime == rhs.lastFlipTime
            && lhs.lastFlipWasSuccessful == rhs.lastFlipWasSuccessful
            && lhs.sessionDuration == rhs.sessionDuration
            && lhs.sessionStartTime == rhs.sessionStartTime && lhs.isHistorical == rhs.isHistorical
            && lhs.sessionIndex == rhs.sessionIndex
    }
}
