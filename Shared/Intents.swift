import ActivityKit
import AppIntents
import SwiftUI
import UserNotifications

@available(iOS 16.1, *)
struct PauseIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Pause Timer"
  func perform() async throws -> some IntentResult {
    await MainActor.run {
//      FlipActivityController.shared.pauseSession()
      NotificationCenter.default.post(
        name: Notification.Name("PauseTimerRequest"),
        object: nil
      )
    }
    return .result()
  }
}

@available(iOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Resume Timer"
  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(
        name: Notification.Name("ResumeTimerRequest"),
        object: nil
      )
//      FlipActivityController.shared.startResumeCountdown()
    }
    return .result()
  }
}
