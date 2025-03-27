import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct FlipActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingTime: String
        var remainingPauses: Int  // Changed from remainingFlips
        var isPaused: Bool
        var isFailed: Bool  // New property
        var wasSuccessful: Bool?  // Add this new property
        var flipBackTimeRemaining: Int?
        var pauseTimeRemaining: String?
        var countdownMessage: String?
        var lastUpdate: Date
    }
}
