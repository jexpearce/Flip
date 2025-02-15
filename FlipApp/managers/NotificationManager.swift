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
            ]))
    }

    func display(
        title: String, body: String, categoryIdentifier: String = "FLIP_ALERT"
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            ))
    }
}
