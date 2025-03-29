import BackgroundTasks
import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UserNotifications

@main struct FlipApp: App {
    @UIApplicationDelegateAdaptor(FlipAppDelegate.self) var delegate
    @StateObject private var appManager = AppManager.shared
    @StateObject private var sessionManager = SessionManager.shared

    // Add this state to control which view is shown
    @State private var showPermissionsFlow = false

    init() {
        // Configure Firebase first, before any other initialization
        FirebaseApp.configure()

        // Set Firebase Messaging settings
        Messaging.messaging().isAutoInitEnabled = true

        // Register tasks first, before scheduling anything
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppManager.backgroundRefreshIdentifier,
            using: nil
        ) { task in AppManager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask) }

        // Schedule background refresh
        AppManager.shared.scheduleBackgroundRefresh()

        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "isPotentialFirstTimeUser")
            UserDefaults.standard.set(false, forKey: "hasCompletedPermissionFlow")
            print("New installation - forcing permission flow")
        }

        // Determine if we should show permissions flow
        let hasCompletedPermissions = UserDefaults.standard.bool(
            forKey: "hasCompletedPermissionFlow"
        )
        let isFirstTimeUser = UserDefaults.standard.bool(forKey: "isPotentialFirstTimeUser")

        // Show permissions flow for new users or if permissions haven't been completed
        showPermissionsFlow = isFirstTimeUser || !hasCompletedPermissions
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showPermissionsFlow {
                    InitialView().environmentObject(appManager).environmentObject(sessionManager)
                        .onReceive(
                            NotificationCenter.default.publisher(
                                for: NSNotification.Name("ProceedToMainApp")
                            )
                        ) { _ in
                            // When the InitialView sends notification to proceed, show MainView
                            withAnimation { showPermissionsFlow = false }
                        }
                }
                else {
                    MainView().environmentObject(appManager).environmentObject(sessionManager)
                }
            }  // Add observer for resetting permissions from Settings
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSNotification.Name("ShowPermissionsFlow")
                )
            ) { _ in withAnimation { showPermissionsFlow = true } }
        }
    }
}
