import ActivityKit
import BackgroundTasks
import CoreMotion
import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) {
            [weak self] granted, _ in
            guard granted else { return }
            self?.setupNotificationCategories()
        }
    }

    private func setupNotificationCategories() {
        UNUserNotificationCenter.current().setNotificationCategories(
            Set([
                UNNotificationCategory(
                    identifier: "FLIP_ALERT", actions: [],
                    intentIdentifiers: [],
                    options: []),
                UNNotificationCategory(
                    identifier: "SESSION_END", actions: [],
                    intentIdentifiers: [],
                    options: []),
                UNNotificationCategory(
                    identifier: "LIVE_SESSION", actions: [],
                    intentIdentifiers: [],
                    options: []),
            ]))
    }
    func notifySessionJoined(username: String) {
        display(
            title: "Session Joined",
            body: "\(username) joined your focus session",
            categoryIdentifier: "LIVE_SESSION"
        )
    }

    func notifyParticipantCompleted(username: String) {
        display(
            title: "Session Update",
            body: "\(username) successfully completed the session",
            categoryIdentifier: "LIVE_SESSION"
        )
    }

    func notifyParticipantFailed(username: String) {
        display(
            title: "Session Update",
            body: "\(username) failed to complete the session",
            categoryIdentifier: "LIVE_SESSION"
        )
    }

    func display(title: String, body: String, categoryIdentifier: String = "FLIP_ALERT", silent: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if !silent {
            content.sound = .default
        }
        content.categoryIdentifier = categoryIdentifier
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            ))
    }
}
