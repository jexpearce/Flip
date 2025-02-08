import ActivityKit
import Foundation
import SwiftUI
import UserNotifications

@available(iOS 16.1, *)
public class FlipActivityController {
  public static let shared = FlipActivityController()
  private let notificationCenter = UNUserNotificationCenter.current()

  public init() {}  // Important: Make init public for shared access

  public func pauseSession() {
    print(" pauseSession() called!")
    print("FlipActivityController: pauseSession called")
    // Post notification to main app for pausing
    NotificationCenter.default.post(
      name: Notification.Name("PauseTimerRequest"),
      object: nil
    )

    // Show notification that session is paused
    let content = UNMutableNotificationContent()
    content.title = "Session Paused"
    content.body = "Open app to resume or use lock screen controls"
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    Task {
      do {
        try await notificationCenter.add(request) 
      } catch {
        print("Error showing pause notification: \(error.localizedDescription)")
      }
    }
  }

  public func startResumeCountdown() {
    // Show 5-second countdown notification
    let content = UNMutableNotificationContent()
    content.title = "Resuming Session"
    content.body = "Flip your phone face down within 5 seconds"
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    Task {
      do {
        try await notificationCenter.add(request)
      } catch {
        print(
          "Error showing resume notification: \(error.localizedDescription)")
      }
    }

    NotificationCenter.default.post(
      name: Notification.Name("ResumeTimerRequest"),
      object: nil
    )
  }
}
