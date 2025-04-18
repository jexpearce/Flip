import ActivityKit
import CoreLocation
import CoreMotion
import SwiftUI

class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()

    // Location
    private let locationManager = CLLocationManager()
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @Published var showLocationAlert = false

    // New properties to track specific location permission levels
    @Published var hasFullLocationPermission = false
    @Published var hasLimitedLocationPermission = false

    // Motion
    @Published var motionPermissionGranted = false
    @Published var showMotionAlert = false
    private var motionPromptCompleted = false
    @Published var showMotionSettingsAlert = false

    // Notifications
    @Published var notificationPermissionGranted = false
    @Published var showNotificationAlert = false
    private var notificationPromptCompleted = false

    // Live Activities
    @Published var liveActivitiesEnabled = false

    // Overall permission state
    @Published var allPermissionsGranted = false

    // Alert for missing permissions when Begin is tapped
    @Published var showPermissionRequiredAlert = false

    // Flags to track permission flow state
    private var isProcessingLocationPermission = false
    var isProcessingMotionPermission = false
    private var isProcessingNotificationPermission = false
    private var permissionLockEnabled = true
    var isInitialPermissionFlow = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationAuthStatus = locationManager.authorizationStatus
        checkPermissions()

        // Add notification observers for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    func lockPermissions() {
        print("🔒 Locking permission requests")
        permissionLockEnabled = true
    }

    func unlockPermissions() {
        print("🔓 Unlocking permission requests")
        permissionLockEnabled = false
    }

    func isPermissionLocked() -> Bool {
        // If we're in the initial permission flow, always allow permissions
        if isInitialPermissionFlow { return false }
        // Check if we're in the completed flow
        if UserDefaults.standard.bool(forKey: "hasCompletedPermissionFlow") {
            return false  // Allow permissions if flow is complete
        }
        return permissionLockEnabled
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc func appDidBecomeActive() {
        // Refresh permission status when app becomes active
        // This catches changes made in Settings app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let previousMotionStatus = self.motionPermissionGranted
            self.refreshPermissionStatus()

            // Check if motion permission was granted via Settings
            if !previousMotionStatus && self.motionPermissionGranted {
                print("Motion permission granted via Settings!")
                // Reset settings alert flag
                self.showMotionSettingsAlert = false
                // Post notification to update UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("locationPermissionChanged"),
                    object: nil
                )
            }
        }
    }

    func checkPermissions() {
        // Check location
        locationAuthStatus = locationManager.authorizationStatus

        // Update location permission states
        hasFullLocationPermission = (locationAuthStatus == .authorizedAlways)
        hasLimitedLocationPermission = (locationAuthStatus == .authorizedWhenInUse)

        // Check motion
        let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
        motionPermissionGranted = (motionAuthStatus == .authorized)

        // Check notifications
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.notificationPermissionGranted =
                        (settings.authorizationStatus == .authorized)

                    // Check Live Activities
                    if #available(iOS 16.1, *) {
                        self.liveActivitiesEnabled =
                            ActivityAuthorizationInfo().areActivitiesEnabled
                    }

                    // Update overall permission state
                    self.updatePermissionState()
                }
            }
    }

    func refreshPermissionStatus() {
        print("📱 Refreshing permission status")

        // Get current location auth status
        locationAuthStatus = locationManager.authorizationStatus

        // Update location permission states
        hasFullLocationPermission = (locationAuthStatus == .authorizedAlways)
        hasLimitedLocationPermission = (locationAuthStatus == .authorizedWhenInUse)

        // Get current motion auth status
        let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
        motionPermissionGranted = (motionAuthStatus == .authorized)

        // NEW CODE: Show motion settings alert if motion permission was previously
        // granted but now is denied
        if !motionPermissionGranted && motionPromptCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showMotionSettingsAlert = false
            }
        }
        // Update notification status too
        UNUserNotificationCenter.current()
            .getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.notificationPermissionGranted =
                        (settings.authorizationStatus == .authorized)

                    // Update overall state
                    self.updatePermissionState()
                }
            }

        print("📍 Location status: \(locationAuthStatus.rawValue)")
        print(
            "📍 Full location: \(hasFullLocationPermission), Limited: \(hasLimitedLocationPermission)"
        )
    }

    // Open Settings app to app-specific location settings
    func openLocationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // Store whether we've shown the location upgrade alert
    @AppStorage("hasShownLocationUpgradeAlert") var hasShownLocationUpgradeAlert = false

    // Open Settings app specifically for Motion settings
    func openMotionSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func updatePermissionState() {
        // For app functionality, only motion is truly required
        // Location is now optional but preferred
        allPermissionsGranted = motionPermissionGranted
    }

    // MARK: - Permission Flow

    // MARK: - Location Flow

    // Step 1: Start the location permission flow
    private func startLocationFlow() {
        print("Starting location permission flow")
        // First check if we already have location permission
        if locationAuthStatus == .authorizedWhenInUse || locationAuthStatus == .authorizedAlways {
            // Already authorized, skip to next flow
            print("Location permission already granted, skipping to motion flow")
            startMotionFlow()
            return
        }

        // Prevent duplicate prompts
        if isProcessingLocationPermission {
            print("Already processing location permission, ignoring duplicate request")
            return
        }

        isProcessingLocationPermission = true

        // Only show custom alert if status is notDetermined
        if locationAuthStatus == .notDetermined {
            // Show our custom alert first
            print("Showing custom location alert")
            showLocationAlert = true
            print("Showing enhanced location alert")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowEnhancedLocationAlert"),
                object: nil
            )
        }
        else {
            // If denied, just proceed to motion flow
            startMotionFlow()
        }
    }
    func requestAllPermissions() {
        print("Starting permission flow sequence")
        // Set flag to allow permissions during this flow
        isInitialPermissionFlow = true
        // Reset flow state flags
        isProcessingLocationPermission = false
        isProcessingMotionPermission = false
        isProcessingNotificationPermission = false

        // Start with location
        startLocationFlow()
    }
    // Step 1b: Called when user taps Continue on location alert
    func requestLocationPermission() {
        print("User tapped Continue on location alert")
        // Only request if status is notDetermined
        if locationAuthStatus == .notDetermined {
            // Add a delay to make sure the custom alert is fully dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else { return }

                print("Requesting system location permission after delay")
                // Request the actual system permission
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
        else {
            // If not notDetermined, proceed to motion flow
            startMotionFlow()
        }
    }

    // MARK: - Motion Flow

    // Step 2: Start the motion permission flow
    private func startMotionFlow() {
        print("Starting motion permission flow")
        // First check if we already have motion permission
        let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
        if motionAuthStatus == .authorized {
            // Already authorized, skip to next flow
            print("Motion permission already granted, skipping to notification flow")
            motionPermissionGranted = true
            startNotificationFlow()
            return
        }

        // Prevent duplicate prompts
        if isProcessingMotionPermission {
            print("Already processing motion permission, ignoring duplicate request")
            return
        }

        isProcessingMotionPermission = true

        // Show our custom alert
        print("Showing custom motion alert")
        showMotionAlert = true

        // The system prompt will be triggered when the user taps Continue in the custom alert
        // See requestMotionPermission() method
    }

    // Step 2b: Called when user taps Continue on motion alert
    func requestMotionPermission() {
        print("User tapped Continue on motion alert")
        motionPromptCompleted = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            // Request the system motion permission
            let motionManager = CMMotionActivityManager()
            let today = Date()

            // First check current status
            let currentStatus = CMMotionActivityManager.authorizationStatus()
            if currentStatus == .notDetermined {
                motionManager.queryActivityStarting(from: today, to: today, to: .main) {
                    [weak self] _, _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        // Check status after prompt
                        let updatedStatus = CMMotionActivityManager.authorizationStatus()
                        self.motionPermissionGranted = (updatedStatus == .authorized)
                        print("Motion permission status after request: \(updatedStatus)")

                        // Show settings alert if denied
                        if updatedStatus == .denied { self.showMotionSettingsAlert = false }

                        // Update UI state
                        self.updatePermissionState()
                        // Reset flag and continue to next permission
                        self.isProcessingMotionPermission = false
                        // Post notification for permission change
                        NotificationCenter.default.post(
                            name: NSNotification.Name("locationPermissionChanged"),
                            object: nil
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.showMotionAlert = false
                            self.startNotificationFlow()
                        }
                    }
                }
            }
            else {
                // Already determined, update state immediately
                self.motionPermissionGranted = (currentStatus == .authorized)
                print("Motion permission already determined: \(currentStatus)")
                // Show settings alert if denied
                if currentStatus == .denied { self.showMotionSettingsAlert = false }
                // Update UI state
                self.updatePermissionState()
                // Reset flag and continue to next permission
                self.isProcessingMotionPermission = false
                // Post notification for permission change
                NotificationCenter.default.post(
                    name: NSNotification.Name("locationPermissionChanged"),
                    object: nil
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showMotionAlert = false
                    self.startNotificationFlow()
                }
            }
        }
    }

    // MARK: - Notification Flow

    // Step 3: Start the notification permission flow
    func startNotificationFlow() {
        print("Starting notification permission flow")
        // First check if we already have notification permission
        UNUserNotificationCenter.current()
            .getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if settings.authorizationStatus == .authorized {
                        // Already authorized, all done!
                        print("Notification permission already granted, permission flow complete")
                        self.notificationPermissionGranted = true
                        self.updatePermissionState()
                        return
                    }

                    // Prevent duplicate prompts
                    if self.isProcessingNotificationPermission {
                        print(
                            "Already processing notification permission, ignoring duplicate request"
                        )
                        return
                    }

                    self.isProcessingNotificationPermission = true

                    // Show our custom alert
                    print("Showing custom notification alert")
                    self.showNotificationAlert = true

                    // The system prompt will be triggered when the user taps Continue in the custom alert
                    // See requestNotificationPermission() method
                }
            }
    }

    // Step 3b: Called when user taps Continue on notification alert
    func requestNotificationPermission() {
        print("User tapped Continue on notification alert")
        // Important: mark that we've shown the custom prompt
        notificationPromptCompleted = true

        // Add a delay to make sure the custom alert is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }

            print("Requesting system notification permission after delay")
            // Request the actual system permission
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        self.notificationPermissionGranted = granted
                        print(
                            "Notification permission status after request: \(granted ? "granted" : "denied")"
                        )

                        // Reset flag
                        self.isProcessingNotificationPermission = false

                        // Update overall permission state
                        self.updatePermissionState()
                    }
                }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            print("Location authorization status changed: \(manager.authorizationStatus.rawValue)")

            // Store the previous state to detect changes
            let previousStatus = self.locationAuthStatus

            // Update current status
            self.locationAuthStatus = manager.authorizationStatus

            // Update our permission tracking properties
            self.hasFullLocationPermission = (self.locationAuthStatus == .authorizedAlways)
            self.hasLimitedLocationPermission = (self.locationAuthStatus == .authorizedWhenInUse)

            // Only proceed if:
            // 1. We're actively processing a permission request (isProcessingLocationPermission is true)
            // 2. The status has changed from .notDetermined to something definitive
            // 3. We haven't already moved to the next step
            if self.isProcessingLocationPermission && previousStatus == .notDetermined
                && (self.locationAuthStatus == .authorizedWhenInUse
                    || self.locationAuthStatus == .authorizedAlways
                    || self.locationAuthStatus == .denied)
            {

                print(
                    "Location permission flow complete with status: \(self.locationAuthStatus.rawValue)"
                )

                // Reset flag
                self.isProcessingLocationPermission = false

                // Update permission state
                self.updatePermissionState()

                // Add a delay before moving to next step to ensure
                // the system prompt is fully dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Move to the next step in the flow
                    self.startMotionFlow()
                }
            }
            else {
                // Just update state if not in active permission flow
                self.updatePermissionState()
            }
        }
    }
}

struct MotionPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Motion icon with animation
                    ZStack {
                        // Outer pulse
                        Circle().fill(Theme.softViolet.opacity(0.3)).frame(width: 90, height: 90)
                            .scaleEffect(animateContent ? 1.3 : 0.8)
                            .opacity(animateContent ? 0.0 : 0.5)

                        // Inner circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.softViolet, Theme.electricViolet],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 70, height: 70)

                        // Icon
                        Image(systemName: "figure.walk").font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }

                    Text("MOTION ACCESS").font(.system(size: 20, weight: .black)).tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Theme.softViolet.opacity(0.6), radius: 8)

                }
                .padding(.top, 10)

                // Explanation text
                VStack(spacing: 15) {
                    infoRow(
                        icon: "arrow.2.squarepath",
                        title: "Detect Phone Flipping",
                        description: "Motion data is used to know when your phone is face down"
                    )

                    infoRow(
                        icon: "exclamationmark.bubble.fill",
                        title: "Critical Feature",
                        description: "The core focus tracking feature requires motion detection"
                    )

                    infoRow(
                        icon: "lock.shield.fill",
                        title: "Privacy Protected",
                        description:
                            "Motion data is only processed on your device, never sent to our servers"
                    )
                }
                .padding(.horizontal, 5)

                // Important note
                Text(
                    "FLIP requires motion access to detect when your phone is flipped. Without this permission, the app cannot function properly."
                )
                .font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center).padding(.horizontal, 10).padding(.top, 5)

                // Continue button
                Button(action: {
                    isPresented = false
                    PermissionManager.shared.showMotionAlert = false
                    onContinue()
                }) {
                    Text("CONTINUE").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient)

                                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Theme.silveryGradient, lineWidth: 1)
                            }
                        )
                        .shadow(color: Theme.softViolet.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 20).padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [Theme.mutedPurple, Theme.blueishPurple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Glass effect
                    RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.05))

                    // Border
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Theme.silveryGradient3, lineWidth: 1.5)
                }
            )
            .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.8).opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon in circle
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)

                Text(description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Notification icon with pulse animation
                    ZStack {
                        // Outer pulse
                        Circle().fill(Theme.lightTealBlue.opacity(0.3)).frame(width: 90, height: 90)
                            .scaleEffect(animateContent ? 1.3 : 0.8)
                            .opacity(animateContent ? 0.0 : 0.5)

                        // Inner circle
                        Circle().fill(Theme.tealyGradient).frame(width: 70, height: 70)

                        // Icon
                        Image(systemName: "bell.fill").font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }

                    Text("NOTIFICATIONS").font(.system(size: 20, weight: .black)).tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 8)

                }
                .padding(.top, 10)

                // Explanation text
                VStack(spacing: 15) {
                    infoRow(
                        icon: "clock.fill",
                        title: "Session Alerts",
                        description: "Get notified when you finish or fail your Flip session"
                    )

                    infoRow(
                        icon: "bell.badge.fill",
                        title: "Session Reminders",
                        description: "Receive reminders on pause durations"
                    )
                    infoRow(
                        icon: "bell.badge.fill",
                        title: "Social",
                        description: "Know when someone comments on your session, or fails!"
                    )
                }
                .padding(.horizontal, 5)

                // Important note
                Text(
                    "FLIP uses notifications to keep you updated on your focus sessions and social activities."
                )
                .font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center).padding(.horizontal, 10).padding(.top, 5)

                // Continue button
                Button(action: {
                    isPresented = false
                    PermissionManager.shared.showNotificationAlert = false
                    onContinue()
                }) {
                    Text("CONTINUE").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient)

                                RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Theme.silveryGradient, lineWidth: 1)
                            }
                        )
                        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 20).padding(.top, 10)

                // Small print
                Text("You can change notification settings later in settings")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 15)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [Theme.mutedPurple, Theme.blueishPurple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Glass effect
                    RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.05))

                    // Border
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Theme.silveryGradient3, lineWidth: 1.5)
                }
            )
            .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.8).opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon in circle
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)

                Text(description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct MotionSettingsAlert: View {
    @Binding var isPresented: Bool
    @State private var isPrimaryCTA = false
    @State private var isSecondaryCTA = false
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Warning icon
                ZStack {
                    Circle().fill(Color.red.opacity(0.3)).frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40))
                        .foregroundColor(.red).shadow(color: Color.red.opacity(0.5), radius: 6)
                }

                // Title
                Text("MOTION ACCESS REQUIRED").font(.system(size: 22, weight: .black)).tracking(1)
                    .foregroundColor(.white).shadow(color: Color.red.opacity(0.4), radius: 4)
                    .multilineTextAlignment(.center)

                // Description
                Text(
                    "Flip needs Motion & Fitness access to detect phone flipping. Without this permission, you cannot use Flip sessions."
                )
                .font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center).padding(.horizontal, 20)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring()) { isPrimaryCTA = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            permissionManager.openMotionSettings()
                            isPresented = false
                        }
                    }) {
                        Text("OPEN SETTINGS").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(width: 250, height: 50)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Theme.silveryGradient, lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.red.opacity(0.4), radius: 8)
                            .scaleEffect(isPrimaryCTA ? 0.95 : 1.0)
                    }

                    Button(action: {
                        withAnimation(.spring()) { isSecondaryCTA = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                permissionManager.isProcessingMotionPermission = false
                                permissionManager.startNotificationFlow()
                            }
                        }
                    }) {
                        Text("MAYBE LATER").font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7)).padding(.vertical, 10)
                            .scaleEffect(isSecondaryCTA ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25).fill(Theme.darkGray)

                    RoundedRectangle(cornerRadius: 25).fill(Color.black.opacity(0.3))

                    RoundedRectangle(cornerRadius: 25).stroke(Theme.silveryGradient2, lineWidth: 1)
                }
            )
            .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
