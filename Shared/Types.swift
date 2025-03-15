import Foundation

enum FlipState: String, CaseIterable {
    case initial
    case countdown
    case tracking
    case failed
    case completed
    case paused
    case joinedCompleted = "joinedCompleted"  // New state for successful group sessions
    case mixedOutcome = "mixedOutcome"
    case othersActive // New state for when user is done but others are still active
}
