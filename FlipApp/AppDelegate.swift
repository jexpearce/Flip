import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import UIKit
import UserNotifications

@UIApplicationMain
class FlipAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate,
    MessagingDelegate
{

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")

        if isFirstLaunch {
            // Force sign out on fresh install
            try? Auth.auth().signOut()
            defaults.set(true, forKey: "isPotentialFirstTimeUser")

            // Clear keychain data to ensure credentials are removed
            let secItemClasses = [
                kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate,
                kSecClassKey, kSecClassIdentity,
            ]
            for secItemClass in secItemClasses {
                let query = [kSecClass as String: secItemClass]
                SecItemDelete(query as CFDictionary)
            }

            defaults.set(true, forKey: "hasLaunchedBefore")
        }

        // Set up push notifications
        UNUserNotificationCenter.current().delegate = self

        application.registerForRemoteNotifications()

        // Set up FCM
        Messaging.messaging().delegate = self

        // Location handling
        let locationHandler = LocationHandler.shared
        // Only restart location if actually in a session
        let appManager = AppManager.shared
        if appManager.currentState == .tracking || appManager.currentState == .countdown {
            if locationHandler.updatesStarted {
                if PermissionManager.shared.locationAuthStatus == .authorizedWhenInUse
                    || PermissionManager.shared.locationAuthStatus == .authorizedAlways
                {
                    // Start location updates
                    locationHandler.startLocationUpdates()
                }
            }
            // If a background activity session was previously active, reinstantiate it
            if locationHandler.backgroundActivity { locationHandler.backgroundActivity = true }
        }

        // Create test session to ensure collection exists - call after a delay
        // to allow Firebase auth to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.ensureSessionLocationCollectionExists()
        }

        // Set up weekly data cleanup
        scheduleWeeklyDataCleanup()

        // Start notification listener if user is logged in
        if Auth.auth().currentUser != nil {
            NotificationListener.shared.startListening()
            NotificationListener.shared.updateBadgeCount()
        }
        if Auth.auth().currentUser != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                FirebaseManager.shared.inspectUserData()
            }
        }

        return true
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        // Store the token in Firestore for this user
        if let token = fcmToken, let userId = Auth.auth().currentUser?.uid {
            let dataDict: [String: Any] = [
                "fcmToken": token, "updatedAt": FieldValue.serverTimestamp(),
            ]

            // Save token to Firestore
            FirebaseManager.shared.db.collection("users").document(userId)
                .updateData(dataDict) { error in
                    if let error = error {
                        print("Error updating FCM token: \(error.localizedDescription)")
                    }
                    else {
                        print("FCM token successfully stored in Firestore")
                    }
                }
        }
    }
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool { return GIDSignIn.sharedInstance.handle(url) }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken

        // Convert token to string for logging
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) { print("Failed to register for remote notifications: \(error.localizedDescription)") }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap/interaction
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with userInfo: \(userInfo)")
        completionHandler()
    }

    // Add these lifecycle methods
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Check if in an active session
        let appManager = AppManager.shared
        if appManager.currentState != .tracking && appManager.currentState != .countdown {
            // Not in an active session, so completely stop location tracking
            Task { @MainActor in LocationHandler.shared.completelyStopLocationUpdates() }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Always stop location tracking when app terminates
        Task { @MainActor in LocationHandler.shared.completelyStopLocationUpdates() }

        // Stop notification listener
        NotificationListener.shared.stopListening()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart notification listener if needed
        if Auth.auth().currentUser != nil {
            // Reset all notifications and badge count on app launch
            NotificationListener.shared.resetAllNotifications()

            // Then start the listener for new notifications
            NotificationListener.shared.startListening()
            NotificationListener.shared.updateBadgeCount()
        }

        // Check if we need to update building
        if AppManager.shared.currentState != .tracking
            && AppManager.shared.currentState != .countdown
        {
            // Not in an active session, check for new buildings
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                RegionalViewModel.shared.refreshCurrentBuilding()
            }
        }
    }

    func ensureSessionLocationCollectionExists() {
        guard Auth.auth().currentUser != nil else {
            // User not logged in yet, try again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.ensureSessionLocationCollectionExists()
            }
            return
        }

        FirebaseManager.shared.createTestSessionLocation()
    }
}
extension FlipAppDelegate {
    func scheduleWeeklyDataCleanup() {
        // Set up a weekly timer for data cleanup
        let calendar = Calendar.current
        let now = Date()

        // Schedule for Sunday at 3 AM
        var nextCleanupComponents = DateComponents()
        nextCleanupComponents.weekday = 1  // Sunday
        nextCleanupComponents.hour = 3  // 3 AM
        nextCleanupComponents.minute = 0

        guard
            let nextCleanup = calendar.nextDate(
                after: now,
                matching: nextCleanupComponents,
                matchingPolicy: .nextTime
            )
        else {
            print("Could not schedule next cleanup")
            return
        }

        let timeInterval = nextCleanup.timeIntervalSince(now)

        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            FirebaseManager.shared.cleanupOldLocationData()

            // Schedule the next cleanup
            self?.scheduleWeeklyDataCleanup()
        }

        print("Scheduled next data cleanup for \(nextCleanup)")
    }
}
