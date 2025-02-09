import ActivityKit
import AppIntents
import SwiftUI
import UserNotifications

@available(iOS 16.1, *)
struct PauseIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Pause Timer"

  static var parameterSummary: some ParameterSummary {
    Summary("Pause the current focus session")
  }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      print("PauseIntent: perform called")
      FlipActivityController.shared.pauseSession()
    }
    return .result()
  }
}

@available(iOS 16.0, *)
struct ResumeIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Resume Timer"

  static var parameterSummary: some ParameterSummary {
    Summary("Resume the paused focus session")
  }

  func perform() async throws -> some IntentResult {
    await MainActor.run {
      FlipActivityController.shared.startResumeCountdown()
    }
    return .result()
  }
}
