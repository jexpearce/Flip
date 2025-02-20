import Foundation

enum FlipState: String, CaseIterable {
    case initial
    case countdown
    case tracking
    case failed
    case completed
    case paused
}
