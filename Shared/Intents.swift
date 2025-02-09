import ActivityKit
import AppIntents
import SwiftUI
import UserNotifications

@available(iOS 16.1, *)
struct PauseIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Pause Session"
  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(
        name: Notification.Name("pauseSession"),
        object: nil
      )
    }
    return .result()
  }
}

@available(iOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Resume Session"
  func perform() async throws -> some IntentResult {
    await MainActor.run {
      NotificationCenter.default.post(
        name: Notification.Name("resumeSession"),
        object: nil
      )
    }
    return .result()
  }
}
