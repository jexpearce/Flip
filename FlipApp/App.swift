import BackgroundTasks
import SwiftUI
import UserNotifications

@main
struct FlipApp: App {
    @UIApplicationDelegateAdaptor(FlipAppDelegate.self) var delegate

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
