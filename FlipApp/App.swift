import BackgroundTasks
import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UserNotifications
import CoreMotion
import FirebaseAuth

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

        // Add auth state listener
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                let defaults = UserDefaults.standard
                let hasCompletedPermissions = defaults.bool(forKey: "hasCompletedPermissionFlow")
                if !hasCompletedPermissions {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowPermissionsFlow"),
                        object: nil
                    )
                }
            }
        }

        // Register tasks first, before scheduling anything
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppManager.backgroundRefreshIdentifier,
            using: nil
        ) { task in AppManager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask) }

        // Schedule background refresh
        AppManager.shared.scheduleBackgroundRefresh()

        // Enhanced detection of first time users or reinstalls
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")
        let isPotentialFirstTimeUser = defaults.bool(forKey: "isPotentialFirstTimeUser")
        let hasCompletedPermissions = defaults.bool(forKey: "hasCompletedPermissionFlow")
        let isResettingPermissions = defaults.bool(forKey: "isResettingPermissions")

        if isFirstLaunch {
            print("🔑 Fresh install detected - forcing sign out")
            
            // Force Firebase sign out
            try? Auth.auth().signOut()
            
            // Clear ALL keychain credentials to ensure complete logout
            let secItemClasses = [
                kSecClassGenericPassword,
                kSecClassInternetPassword,
                kSecClassCertificate,
                kSecClassKey,
                kSecClassIdentity
            ]
            for secItemClass in secItemClasses {
                let query = [kSecClass as String: secItemClass]
                SecItemDelete(query as CFDictionary)
            }
        }

        // Determine if we should show the permission flow
        if isFirstLaunch {
            print("📱 NEW INSTALLATION DETECTED - enabling permission flow")
            defaults.set(true, forKey: "isPotentialFirstTimeUser")
            defaults.set(false, forKey: "hasCompletedPermissionFlow")
            defaults.set(true, forKey: "hasLaunchedBefore")
            showPermissionsFlow = true
        } else if isResettingPermissions {
            print("🔄 PERMISSION RESET REQUESTED - enabling permission flow")
            defaults.set(false, forKey: "hasCompletedPermissionFlow")
            defaults.set(false, forKey: "isResettingPermissions") // Reset the flag
            showPermissionsFlow = true
        } else if isPotentialFirstTimeUser && !hasCompletedPermissions {
            print("👤 FIRST TIME USER DETECTED - enabling permission flow")
            showPermissionsFlow = true
        } else if !hasCompletedPermissions {
            // Double-check permissions status to determine if flow is needed
            let permManager = PermissionManager.shared
            
            // Get current status
            let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
            let motionGranted = (motionAuthStatus == .authorized)
            
            if !motionGranted {
                print("🚨 REQUIRED PERMISSION MISSING - enabling permission flow")
                showPermissionsFlow = true
            } else {
                print("✅ All required permissions already granted")
                defaults.set(true, forKey: "hasCompletedPermissionFlow")
            }
        }
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