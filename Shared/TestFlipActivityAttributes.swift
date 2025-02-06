import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct FlipActivityAttributes: ActivityAttributes {
    public typealias ContentState = FlipContentState
    
    public struct FlipContentState: Codable, Hashable {
        var remainingTime: String
        var remainingFlips: Int
        var isPaused: Bool
        var isFailed: Bool // New property
        var flipBackTimeRemaining: Int? // New property for 10-second countdown
        var lastUpdate: Date
    }
}

