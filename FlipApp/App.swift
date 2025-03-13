import BackgroundTasks
import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseMessaging

@main
struct FlipApp: App {
    @UIApplicationDelegateAdaptor(FlipAppDelegate.self) var delegate

    init() {
        // Configure Firebase first, before any other initialization
        FirebaseApp.configure()
        
        // Set Firebase Messaging settings
        Messaging.messaging().isAutoInitEnabled = true

        // Register tasks first, before scheduling anything
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppManager.backgroundRefreshIdentifier,
            using: nil
        ) { task in
            // Handle the task here.
            AppManager.shared.handleBackgroundRefresh(
                task: task as! BGAppRefreshTask)
        }

        // Now it's safe to schedule
        AppManager.shared.scheduleBackgroundRefresh()
    }

    @StateObject private var appManager = AppManager.shared
    @StateObject private var sessionManager = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .environmentObject(appManager)
        .environmentObject(sessionManager)
    }
}