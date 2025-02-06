import AppIntents
import SwiftUI
import UserNotifications
import ActivityKit

@available(iOS 16.0, *)
struct PauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Pause the current focus session")
    }
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FlipActivityController.shared.pauseSession()
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct ResumeIntent: AppIntent {
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

