import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()

    private init() { setupNotificationCategories() }

    private func setupNotificationCategories() {
        UNUserNotificationCenter.current()
            .setNotificationCategories(
                Set([
                    UNNotificationCategory(
                        identifier: "FLIP_ALERT",
                        actions: [],
                        intentIdentifiers: [],
                        options: []
                    ),
                    UNNotificationCategory(
                        identifier: "SESSION_END",
                        actions: [],
                        intentIdentifiers: [],
                        options: []
                    ),
                    UNNotificationCategory(
                        identifier: "LIVE_SESSION",
                        actions: [],
                        intentIdentifiers: [],
                        options: []
                    ),
                ])
            )
    }

    func display(
        title: String,
        body: String,
        categoryIdentifier: String = "FLIP_ALERT",
        silent: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if !silent { content.sound = .default }
        content.categoryIdentifier = categoryIdentifier
        UNUserNotificationCenter.current()
            .add(
                UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            )
    }
}
