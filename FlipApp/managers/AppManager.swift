import ActivityKit
import BackgroundTasks
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class AppManager: NSObject, ObservableObject {
    static var backgroundRefreshIdentifier = "com.jexpearce.flip.refresh"
    static let shared = AppManager()

    // MARK: - Published Properties
    @Published var currentState: FlipState = .initial {
        didSet { if currentState != .paused { updateLiveActivity() } }
    }
    @Published var selectedMinutes = 1
    @Published var countdownSeconds = 5
    @Published var isFaceDown = false
    @Published var remainingSeconds = 0
    @Published var isPaused = false
    @Published var pausedRemainingSeconds = 0
    @Published var allowPauses = true
    @Published var maxPauses = 10
    @Published var remainingPauses = 0
    @Published var liveSessionId: String?
    @Published var isJoinedSession: Bool = false
    @Published var originalSessionStarter: String?
    @Published var sessionParticipants: [String] = []
    @Published var pauseDuration = 5  // Default pause duration in minutes
    @Published var remainingPauseSeconds = 0  // Remaining seconds in current pause
    @Published var isPauseTimerActive = false  // Whether pause timer is active
    @Published var sessionAlreadyRecorded: Bool = false
    @Published var usingLimitedLocationPermission = false

    private var pauseEndTime: Date?
    private var sessionManager = SessionManager.shared
    private var notificationManager = NotificationManager.shared
    private var locationSessionSaved = false
    // MARK: - Motion Properties
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private var lastOrientationCheck = Date()

    // MARK: - Background Task Properties
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundCheckTimer: Timer?
    private var isInBackground = false

    // MARK: - Timer Properties
    private var countdownTimer: Timer?
    private var sessionTimer: Timer?
    private var flipBackTimer: Timer?
    @Published var flipBackTimeRemaining: Int = 10
    private var pauseTimer: Timer?

    // MARK: - ActivityKit Properties
    @available(iOS 16.1, *) private var activity: Activity<FlipActivityAttributes>?

    // MARK: - Computed Properties
    var remainingTimeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - This is Friend Notification Section
    private var lastFriendNotificationTime: Date?
    private var friendNotificationCount = 0
    private let maxFriendNotifications = 3
    private let friendNotificationCooldown: TimeInterval = 6000  // 10 minutes

    // MARK: - Initialization
    private override init() {
        super.init()
        cleanupStaleActivities()

        if #available(iOS 16.1, *) {
            // We only need to check if activities are enabled
            let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
            print("Live Activities enabled: \(enabled)")
        }

        setupMotionManager()
        restoreSessionState()
        addObservers()
    }

    // MARK: - Setup Methods
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1
    }

    // MARK: - Session Management
    func startCountdown(fromRestoration: Bool = false) {
        print("Starting countdown" + (fromRestoration ? " (from restoration)" : ""))

        // Check permission manager for location status
        let permissionManager = PermissionManager.shared

        // Only consider limited permission if permission is completely denied
        usingLimitedLocationPermission = permissionManager.locationAuthStatus == .denied

        startLiveActivity()

        // Only set the state and reset the countdown if not restoring
        if !fromRestoration {
            currentState = .countdown
            countdownSeconds = 5
        }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] timer in
            guard let self = self else { return }

            self.countdownSeconds -= 1

            // Save state on each tick to ensure accurate restoration
            self.saveSessionState()

            if self.countdownSeconds <= 0 {
                timer.invalidate()
                print("Countdown finished, starting session")

                // IMPORTANT: Check orientation BEFORE starting session
                // Give the motion manager a moment to get fresh data
                currentState = .tracking
                self.startMotionUpdates()  // Make sure we're getting motion data

                // Add a short delay to get accurate orientation data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.checkCurrentOrientation()  // Get fresh orientation reading

                    if let motion = self.motionManager.deviceMotion, motion.gravity.z > 0.8 {
                        // Phone is face down, start the session
                        self.startTrackingSession()
                    }
                    else {
                        // Phone is not face down, fail the session
                        self.notifyCountdownFailed()
                        if #available(iOS 16.1, *) { self.endLiveActivity() }
                        self.currentState = .initial
                    }
                }
            }
        }

        // Ensure timer runs even during scrolling
        if let timer = countdownTimer { RunLoop.current.add(timer, forMode: .common) }

        // Broadcast session state for live sessions
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
        }
        else if currentState == .countdown {
            // Generate a new session ID for new sessions
            liveSessionId = UUID().uuidString
            LiveSessionManager.shared.broadcastSessionState(
                sessionId: liveSessionId!,
                appManager: self
            )
        }
    }

    private func notifyCountdownFailed() {
        notificationManager.display(
            title: "Session Not Started",
            body: "Phone must be face down when timer reaches zero"
        )
    }
    func joinLiveSession(sessionId: String, remainingSeconds: Int, totalDuration: Int) {
        print(
            "Joining live session: \(sessionId), remaining: \(remainingSeconds)s, duration: \(totalDuration)min"
        )

        // Initialize all values first BEFORE changing state
        self.liveSessionId = sessionId
        self.isJoinedSession = true
        self.selectedMinutes = totalDuration  // Use the correct total duration from the session
        self.remainingSeconds = remainingSeconds

        // Get joined session data to properly set all parameters
        LiveSessionManager.shared.getSessionDetails(sessionId: sessionId) { sessionData in
            if let session = sessionData {
                DispatchQueue.main.async {
                    // Set pause settings based on the original session's settings
                    self.allowPauses = session.allowPauses
                    self.maxPauses = session.maxPauses
                    self.remainingPauses = session.maxPauses
                    self.originalSessionStarter = session.starterId

                    // Save the list of participants for display in completion screens
                    self.sessionParticipants = session.participants

                    // Make sure we're properly setting LiveSessionManager's currentJoinedSession
                    LiveSessionManager.shared.listenToJoinedSession(sessionId: sessionId)

                    // Save state to ensure persistence across app restarts
                    self.saveSessionState()
                }
            }
            else {
                // Safety fallback if we can't get session details
                DispatchQueue.main.async {
                    // Default values if joined session data isn't available yet
                    self.allowPauses = false
                    self.maxPauses = 0
                    self.remainingPauses = 0

                    // Save state to ensure persistence
                    self.saveSessionState()
                }
            }
        }

        // Save state to ensure persistence
        saveSessionState()

        // Now that all values are set, start the countdown properly
        countdownSeconds = 5
        currentState = .countdown  // Set state after other values

        // IMPORTANT: Actually start the countdown timer
        startCountdown(fromRestoration: false)
    }

    private func startTrackingSession(isNewSession: Bool = true) {
        print("Starting tracking session")

        // 1. Stop existing timers and updates
        invalidateAllTimers()
        motionManager.stopDeviceMotionUpdates()
        Task { @MainActor in
            LocationHandler.shared.stopLocationUpdates()
            LocationHandler.shared.startLocationUpdates()  // Will restart with proper settings
        }
        currentState = .tracking
        if isNewSession {
            // For new sessions, set the full duration
            remainingSeconds = selectedMinutes * 60
            remainingPauses = maxPauses  // Reset pauses for new sessions

            // IMMEDIATELY increment the leaderboard when session starts
            if let building = RegionalViewModel.shared.selectedBuilding {
                print(
                    "🏢 Incrementing leaderboard for building: \(building.name) [ID: \(building.id)]"
                )
                // Create a session document immediately
                let userId = Auth.auth().currentUser?.uid ?? ""
                let username = FirebaseManager.shared.currentUser?.username ?? "User"
                let sessionData: [String: Any] = [
                    "userId": userId, "username": username,
                    "location": GeoPoint(
                        latitude: building.coordinate.latitude,
                        longitude: building.coordinate.longitude
                    ), "isCurrentlyFlipped": true, "lastFlipTime": Timestamp(date: Date()),
                    "lastFlipWasSuccessful": true, "sessionDuration": selectedMinutes,
                    "actualDuration": 0,  // Will be updated when session ends
                    "sessionStartTime": Timestamp(date: Date()),
                    "sessionEndTime": Timestamp(date: Date()), "includeInLeaderboards": true,  // Always include for now
                    "buildingId": building.id, "buildingName": building.name,
                    "buildingLatitude": building.coordinate.latitude,
                    "buildingLongitude": building.coordinate.longitude,
                ]
                // Save to Firestore
                FirebaseManager.shared.db.collection("session_locations")
                    .document("\(userId)_\(Int(Date().timeIntervalSince1970))")
                    .setData(sessionData) { error in
                        if let error = error {
                            print("❌ Error saving session start: \(error.localizedDescription)")
                        }
                        else {
                            print("✅ Successfully saved session start to leaderboard")
                        }
                    }
            }
        }
        else {
            // For resumed sessions, restore the paused time
            remainingSeconds = pausedRemainingSeconds
        }

        saveSessionState()
        print("Basic state set up: \(currentState.rawValue), \(remainingSeconds)s")
        startMotionUpdates()
        startSessionTimer()
        beginBackgroundProcessing()
        scheduleBackgroundRefresh()

        // Broadcast session state for live sessions
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
        }

        print("Tracking session started successfully")
    }

    @objc func pauseSession() {
        print("Pausing session...")
        guard allowPauses && remainingPauses > 0 else { return }

        // Stop all timers first
        invalidateAllTimers()

        // Update state
        remainingPauses -= 1
        isPaused = true
        isPauseTimerActive = true
        pausedRemainingSeconds = remainingSeconds
        currentState = .paused

        // Set the pause countdown
        let pauseDurationSeconds = pauseDuration * 60
        pauseStartTime = Date()
        pauseEndTime = Date().addingTimeInterval(TimeInterval(pauseDurationSeconds))
        remainingPauseSeconds = pauseDurationSeconds

        // Save these values to UserDefaults for persistence and widget access
        let defaults = UserDefaults.standard
        defaults.set(pauseStartTime?.timeIntervalSince1970, forKey: "pauseStartTime")
        defaults.set(pauseEndTime?.timeIntervalSince1970, forKey: "pauseEndTime")
        defaults.set(true, forKey: "isPauseTimerActive")
        defaults.set(pausedRemainingSeconds, forKey: "pausedRemainingSeconds")

        // Start the pause timer
        startPauseTimer()

        saveSessionState()

        // Stop motion updates
        motionManager.stopDeviceMotionUpdates()
        scheduleAutoResumeNotification()

        if #available(iOS 16.1, *) { updateLiveActivity() }

        // Update Live Activity with paused state
        if #available(iOS 16.1, *) {
            Task {
                guard let activity = activity else {
                    print("No activity to pause")
                    return
                }

                print("Updating Live Activity to paused state")
                let state = FlipActivityAttributes.ContentState(
                    remainingTime: remainingTimeString,
                    remainingPauses: remainingPauses,
                    isPaused: true,
                    isFailed: false,
                    wasSuccessful: nil,
                    flipBackTimeRemaining: nil,
                    pauseTimeRemaining: formatPauseTimeRemaining(),
                    countdownMessage: nil,
                    lastUpdate: Date()
                )

                await activity.update(
                    ActivityContent(
                        state: state,
                        staleDate: Calendar.current.date(
                            byAdding: .minute,
                            value: selectedMinutes + 1,
                            to: Date()
                        )
                    )
                )
                print("Live Activity paused successfully")
            }
        }

        // Broadcast paused state for live sessions
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
        }

        // Send notification for pause
        let plural = remainingPauses == 1 ? "" : "s"
        notificationManager.display(
            title: "Session Paused",
            body:
                "Pause timer started for \(pauseDuration) minutes. \(remainingPauses) pause\(plural) remaining.",
            silent: true
        )
    }
    private var pauseStartTime: Date?
    private func startPauseTimer() {
        pauseTimer?.invalidate()
        pauseTimer = nil
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPauseTimerActive else { return }

            // Calculate remaining time based on absolute end time, not a counter
            if let endTime = self.pauseEndTime {
                let now = Date()
                let remainingSeconds = max(0, Int(endTime.timeIntervalSince(now)))
                self.remainingPauseSeconds = remainingSeconds

                if remainingSeconds > 0 {
                    // Normal countdown behavior
                    self.saveSessionState()

                    // Update Live Activity every 5 seconds or at specific thresholds
                    if #available(iOS 16.1, *) { self.updateLiveActivity() }

                    // Send notifications at key thresholds
                    if self.remainingPauseSeconds == 60 {
                        self.notificationManager.display(
                            title: "Pause Ending Soon",
                            body: "1 minute left in your pause.",
                            silent: true
                        )
                    }
                }
                else {
                    // Pause time is up, resume the session
                    self.isPauseTimerActive = false
                    self.pauseTimer?.invalidate()
                    self.pauseTimer = nil
                    self.pauseStartTime = nil
                    self.pauseEndTime = nil

                    // Auto-resume the session
                    self.autoResumeSession()
                }
            }
        }

        // Ensure timer runs even during scrolling
        if let timer = pauseTimer { RunLoop.current.add(timer, forMode: .common) }
    }
    private func scheduleAutoResumeNotification() {
        guard let pauseEndTime = pauseEndTime else { return }

        // Cancel any existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Create a notification to trigger when pause ends
        let content = UNMutableNotificationContent()
        content.title = "Pause Time Ended"
        content.body = "Your \(pauseDuration)-minute pause has ended. Open the app to resume."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "PAUSE_END"

        // Create trigger based on pauseEndTime
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: pauseEndTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "pauseEndNotification",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        UNUserNotificationCenter.current()
            .add(request) { error in
                if let error = error {
                    print("Error scheduling auto-resume notification: \(error)")
                }
            }
    }
    private func autoResumeSession() {
        // Send notification that pause is over
        notificationManager.display(
            title: "Pause Time Ended",
            body: "Your \(pauseDuration)-minute pause has ended. Session will resume."
        )

        // Force resume the session
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.resumeSession() }
    }

    // Add a helper method to format pause time remaining:
    func formatPauseTimeRemaining() -> String {
        let minutes = remainingPauseSeconds / 60
        let seconds = remainingPauseSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    @objc func resumeSession() {
        // Cancel any active pause timer
        pauseTimer?.invalidate()
        pauseTimer = nil
        isPauseTimerActive = false
        cancelPendingNotifications()

        // Start motion updates first to get accurate device orientation
        startMotionUpdates()

        // Short delay to ensure we have valid motion data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            self.isPaused = false
            self.remainingSeconds = self.pausedRemainingSeconds

            // Start 5-second countdown
            self.currentState = .countdown
            self.countdownSeconds = 5

            // Start new Live Activity
            if #available(iOS 16.1, *) { self.startLiveActivity() }

            self.countdownTimer?.invalidate()
            self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                [weak self] timer in
                guard let self = self else { return }

                self.countdownSeconds -= 1

                // Save state on each tick
                self.saveSessionState()

                // Update the Live Activity with countdown
                if #available(iOS 16.1, *) {
                    Task {
                        let state = FlipActivityAttributes.ContentState(
                            remainingTime: self.remainingTimeString,
                            remainingPauses: self.remainingPauses,
                            isPaused: false,
                            isFailed: false,
                            wasSuccessful: nil,
                            flipBackTimeRemaining: nil,
                            pauseTimeRemaining: nil,
                            countdownMessage: "\(self.countdownSeconds) seconds to flip phone",
                            lastUpdate: Date()
                        )

                        await self.activity?
                            .update(
                                ActivityContent(
                                    state: state,
                                    staleDate: Calendar.current.date(
                                        byAdding: .minute,
                                        value: self.selectedMinutes + 1,
                                        to: Date()
                                    )
                                )
                            )
                    }
                }

                // Broadcast session state for live sessions
                if let sessionId = self.liveSessionId {
                    LiveSessionManager.shared.broadcastSessionState(
                        sessionId: sessionId,
                        appManager: self
                    )
                }

                if self.countdownSeconds <= 0 {
                    timer.invalidate()

                    // Get fresh orientation reading to ensure accurate state
                    self.checkCurrentOrientation()

                    // Check if phone is face down
                    if let motion = self.motionManager.deviceMotion, motion.gravity.z > 0.8 {
                        self.startTrackingSession(isNewSession: false)
                    }
                    else {
                        self.failSession()
                    }
                }
            }

            // Ensure timer runs even during scrolling
            if let timer = self.countdownTimer { RunLoop.current.add(timer, forMode: .common) }
        }
    }

    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil

        guard !isPaused else { return }

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.saveSessionState()

                // Broadcast session state every 5 seconds
                if self.remainingSeconds % 5 == 0 && self.liveSessionId != nil {
                    LiveSessionManager.shared.broadcastSessionState(
                        sessionId: self.liveSessionId!,
                        appManager: self
                    )
                }

                if self.remainingSeconds % 30 == 0 {
                    Task { @MainActor in self.updateLocationDuringSession() }
                }

                if #available(iOS 16.1, *) { self.updateLiveActivity() }
            }
            else {
                self.flipBackTimer?.invalidate()
                self.flipBackTimer = nil
                self.completeSession()
            }
        }

        // Ensure timer stays active
        if let timer = sessionTimer { RunLoop.current.add(timer, forMode: .common) }
        Task { @MainActor in self.updateLocationDuringSession() }
    }

    // MARK: - Timer Management
    private func invalidateAllTimers() {
        // Invalidate all timers
        countdownTimer?.invalidate()
        sessionTimer?.invalidate()
        flipBackTimer?.invalidate()
        backgroundCheckTimer?.invalidate()
        pauseTimer?.invalidate()

        // Set all timers to nil to prevent memory leaks
        countdownTimer = nil
        sessionTimer = nil
        flipBackTimer = nil
        backgroundCheckTimer = nil
        pauseTimer = nil

        print("All timers invalidated and set to nil")
    }

    // MARK: - Motion Handling
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }

        // Stop any existing updates first
        motionManager.stopDeviceMotionUpdates()

        // Configure and start motion updates
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, currentState == .tracking else { return }

            let newFaceDown = motion.gravity.z > 0.8
            if newFaceDown != self.isFaceDown {
                self.handleOrientationChange(isFaceDown: newFaceDown)
            }
        }
    }

    private func handleOrientationChange(isFaceDown: Bool) {
        isFaceDown ? handlePhonePlacedDown() : handlePhoneLifted()
    }

    private func handlePhonePlacedDown() {
        isFaceDown = true
        saveSessionState()
    }

    private func startFlipBackTimer() {
        // First clean up any existing timer
        flipBackTimer?.invalidate()
        flipBackTimer = nil

        // Initialize the timer with default value
        flipBackTimeRemaining = 10

        flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.flipBackTimeRemaining -= 1
            self.saveSessionState()

            if #available(iOS 16.1, *) { self.updateLiveActivity() }

            // When timer runs out
            if self.flipBackTimeRemaining <= 0 {
                timer.invalidate()
                self.flipBackTimer = nil

                // Check current state to make proper decision
                if self.currentState == .tracking && !self.isFaceDown && !self.isPaused {
                    // Only fail if:
                    // 1. We're still in tracking mode
                    // 2. Phone isn't face down
                    // 3. Session isn't paused
                    self.failSession()
                }
                else {
                    print(
                        "Flip back timer ended, but session is not failed: state=\(self.currentState.rawValue), isFaceDown=\(self.isFaceDown), isPaused=\(self.isPaused)"
                    )
                }
            }
        }

        // Ensure the timer stays active even when scrolling
        if let timer = flipBackTimer { RunLoop.current.add(timer, forMode: .common) }
    }

    private func handlePhoneLifted() {
        guard currentState == .tracking else { return }

        // Set isFaceDown state immediately for accurate state tracking
        isFaceDown = false

        if allowPauses && remainingPauses > 0 {
            // Start 10-second countdown only if pauses are available
            startFlipBackTimer()
            notifyFlipUsed()
            if #available(iOS 16.1, *) { updateLiveActivity() }
            saveSessionState()
        }
        else {
            // Immediately fail the session if no pauses available
            print("No pauses available, failing session immediately")
            saveSessionState()
            failSession()
        }
    }

    // MARK: - Background Processing
    private func beginBackgroundProcessing() {
        // Clean up any existing task first
        if backgroundTask != .invalid { endBackgroundTask() }

        print("Beginning background task")
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("Background task expired")
            self?.endBackgroundTask()
            self?.scheduleBackgroundRefresh()
        }

        // Start monitoring
        startBackgroundCheckTimer()
        startActivityMonitoring()

        // Auto-end after 25 seconds (before 30s limit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            guard let self = self, self.backgroundTask != .invalid else { return }

            print("Auto-ending background task after 25 seconds")
            self.endBackgroundTask()

            // Chain a new background task if still in tracking state
            if self.currentState == .tracking {
                print("Still tracking, beginning a new background task")
                self.beginBackgroundProcessing()
            }
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }

        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        print("Background task ended successfully")
    }

    private func startActivityMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity, currentState == .tracking,
                activity.stationary
            else { return }

            self.checkCurrentOrientation()
        }

        Task { @MainActor in
            // Only start if permission flow is complete
            LocationHandler.shared.startLocationUpdates()
        }
    }

    private func startBackgroundCheckTimer() {
        backgroundCheckTimer?.invalidate()
        backgroundCheckTimer = Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: true  // Changed from 10 to 5 seconds for more frequent checks
        ) { [weak self] _ in
            guard let self = self, self.currentState == .tracking else { return }
            print("Background check timer firing")
            self.checkCurrentOrientation()
        }

        // Make sure the timer fires even during scrolling
        if let timer = backgroundCheckTimer { RunLoop.current.add(timer, forMode: .common) }
    }

    func checkCurrentOrientation() {
        guard currentState == .tracking else { return }

        guard let motion = motionManager.deviceMotion else {
            print("No motion data available for orientation check")
            return
        }

        let currentFaceDown = motion.gravity.z > 0.8
        if currentFaceDown != self.isFaceDown {
            print(
                "Orientation changed: was \(self.isFaceDown ? "face down" : "face up"), now \(currentFaceDown ? "face down" : "face up")"
            )
            handleOrientationChange(isFaceDown: currentFaceDown)
        }

        // Update the last check time
        lastOrientationCheck = Date()
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: AppManager.backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            BGTaskScheduler.shared.cancel(
                taskRequestWithIdentifier: AppManager.backgroundRefreshIdentifier
            )
            try BGTaskScheduler.shared.submit(request)
        }
        catch { print("Error scheduling background task: \(error)") }
    }

    func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = { [weak self] in
            self?.saveSessionState()
            task.setTaskCompleted(success: false)
        }

        // Check for extended background time
        handleExtendedBackgroundTime()

        // Normal orientation check
        checkCurrentOrientation()
        saveSessionState()
        scheduleBackgroundRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { task.setTaskCompleted(success: true) }
    }

    // MARK: - State Recovery
    // Add a method to handle app being in background for extended periods
    private func handleExtendedBackgroundTime() {
        guard currentState == .tracking else { return }
        // Calculate how long we've been in background
        let now = Date()
        let lastOrientationCheckInterval = now.timeIntervalSince(lastOrientationCheck)

        print(
            "Extended background check - time since last check: \(Int(lastOrientationCheckInterval)) seconds"
        )

        // If it's been more than 5 minutes since the last check, consider potential state inconsistency
        if lastOrientationCheckInterval > 300 {
            print("Background time exceeded 5 minutes - checking device state")

            // First, try to get a fresh device motion reading
            if let motion = motionManager.deviceMotion {
                let currentFaceDown = motion.gravity.z > 0.8

                // If the phone is face up after a long background time, fail the session
                if !currentFaceDown && !isPaused {
                    print("Phone detected face up after extended background time")
                    failSession()
                }
                else {
                    // Phone is still face down, continue the session
                    print("Phone still face down after extended background time")
                    if !motionManager.isDeviceMotionActive { startMotionUpdates() }
                    if sessionTimer == nil { startSessionTimer() }
                }
            }
            else {
                // Can't get device motion, restart motion updates
                print("Cannot get device motion after extended background time")
                startMotionUpdates()

                // Give it a moment to initialize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.checkCurrentOrientation()
                }
            }
        }
    }

    // Add a check to detect and recover from inconsistent states
    private func validateCurrentState() {
        // This is a sanity check function to ensure state is consistent
        switch currentState {
        case .countdown:
            if countdownSeconds <= 0 || countdownSeconds > 10 {
                print("Invalid countdown seconds: \(countdownSeconds), resetting to 5")
                countdownSeconds = 5
            }

            // Ensure countdown timer is actually running
            if countdownTimer == nil {
                print("Countdown state with no timer, restarting timer")
                startCountdown(fromRestoration: true)
            }

        case .tracking:
            // Ensure session timer is running
            if sessionTimer == nil && !isPaused {
                print("Tracking state with no session timer, restarting timer")
                startSessionTimer()
            }

            // Ensure motion updates are active
            if !motionManager.isDeviceMotionActive {
                print("Tracking state with no motion updates, restarting updates")
                startMotionUpdates()
            }

        case .paused:
            // Ensure we actually have the paused time saved
            if pausedRemainingSeconds <= 0 {
                print("Paused state with invalid remaining time: \(pausedRemainingSeconds)")
                // Restore a reasonable default if needed
                pausedRemainingSeconds = max(1, remainingSeconds)
            }

        case .failed, .completed:
            // These are terminal states, ensure we've cleaned up
            if sessionTimer != nil || countdownTimer != nil || flipBackTimer != nil {
                print("Terminal state with active timers, cleaning up")
                invalidateAllTimers()
            }

        case .initial:
            // Initial state should be clean
            if sessionTimer != nil || countdownTimer != nil || flipBackTimer != nil {
                print("Initial state with active timers, cleaning up")
                invalidateAllTimers()
            }

        case .joinedCompleted, .mixedOutcome:
            // These are also terminal states, similar to .completed and .failed
            if sessionTimer != nil || countdownTimer != nil || flipBackTimer != nil {
                print("Terminal state with active timers, cleaning up")
                invalidateAllTimers()
            }
        case .othersActive:
            // Add this case to make the switch exhaustive
            // Similar to other terminal states
            if sessionTimer != nil || countdownTimer != nil || flipBackTimer != nil {
                print("Terminal state with active timers, cleaning up")
                invalidateAllTimers()
            }
        }
    }

    // MARK: - Session Completion
    private func completeSession() {
        if currentState == .completed || currentState == .failed {
            print("Session already in terminal state: \(currentState)")
            return
        }

        // 1. Handle Live Activity first
        if #available(iOS 16.1, *) {
            Task {
                // End all activities to ensure cleanup
                for activity in Activity<FlipActivityAttributes>.activities {
                    let finalState = FlipActivityAttributes.ContentState(
                        remainingTime: "0:00",
                        remainingPauses: remainingPauses,
                        isPaused: false,
                        isFailed: false,
                        wasSuccessful: true,  // Mark as successful
                        flipBackTimeRemaining: nil,
                        lastUpdate: Date()
                    )

                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .after(Date().addingTimeInterval(5))  // Show for 5 seconds
                    )
                }
                activity = nil
            }
        }

        // 2. Update live session status if part of a multi-user session
        if let sessionId = liveSessionId {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            LiveSessionManager.shared.updateParticipantStatus(
                sessionId: sessionId,
                userId: userId,
                status: .completed
            )
        }

        // 3. Clean up session
        endSession()

        // 5. Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 6. Send completion notification
        notifyCompletion()

        Task { @MainActor in
            let currentBuildingId = RegionalViewModel.shared.selectedBuilding?.id
            let currentBuildingName = RegionalViewModel.shared.selectedBuilding?.name
            print(
                "🏢 Current building at session completion: \(currentBuildingName ?? "None") [ID: \(currentBuildingId ?? "None")]"
            )
        }

        if !sessionAlreadyRecorded {
            sessionAlreadyRecorded = true

            // Save the user's stats
            updateUserStats(successful: true)

            // Only record ONE session - either through recordMultiUserSession or directly
            if liveSessionId != nil, isJoinedSession {
                recordMultiUserSession(wasSuccessful: true)
            }
            else {
                sessionManager.addSession(
                    duration: selectedMinutes,
                    wasSuccessful: true,
                    actualDuration: selectedMinutes
                )
            }

            // Update location data AFTER recording session to ensure we don't double-save
            Task { @MainActor in self.updateLocationDuringSession() }
        }

        saveSessionState()

        // 8. Update UI state - check participant outcomes for joined sessions
        DispatchQueue.main.async {
            if self.isJoinedSession {
                // Determine the appropriate completion view
                self.determineCompletionView { state in
                    self.currentState = state
                    // Reset join state after setting final state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.resetJoinState() }
                }
            }
            else {
                self.currentState = .completed  // or .failed depending on the method
            }
        }
    }

    func failSession() {
        // Don't fail a session that's already in a terminal state
        if currentState == .completed || currentState == .failed {
            print("Attempted to fail a session already in terminal state: \(currentState.rawValue)")
            return
        }

        print("Failing session - previous state: \(currentState.rawValue)")

        if #available(iOS 16.1, *) {
            Task {
                // End ALL activities
                for activity in Activity<FlipActivityAttributes>.activities {
                    let finalState = FlipActivityAttributes.ContentState(
                        remainingTime: remainingTimeString,
                        remainingPauses: remainingPauses,
                        isPaused: false,
                        isFailed: true,
                        wasSuccessful: false,
                        flipBackTimeRemaining: nil,
                        countdownMessage: nil,
                        lastUpdate: Date()
                    )

                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .after(Date().addingTimeInterval(5))  // Show for 5 seconds
                    )
                }
                activity = nil  // Important: set to nil after ending
            }
        }

        // Update live session status if part of a multi-user session
        if let sessionId = liveSessionId {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            LiveSessionManager.shared.updateParticipantStatus(
                sessionId: sessionId,
                userId: userId,
                status: .failed
            )
        }

        endSession()
        notifyFailure()
        notifyFriendsOfFailure()
        //
        // Calculate actual duration in minutes
        let actualDuration = (selectedMinutes * 60 - remainingSeconds) / 60
        //        _
        if !sessionAlreadyRecorded {
            sessionAlreadyRecorded = true

            // Save the user's stats
            updateUserStats(successful: false)

            // Only record ONE session - either through recordMultiUserSession or directly
            if liveSessionId != nil, isJoinedSession {
                recordMultiUserSession(wasSuccessful: false)
            }
            else {
                sessionManager.addSession(
                    duration: selectedMinutes,
                    wasSuccessful: false,
                    actualDuration: actualDuration
                )
            }

            // Update location data AFTER recording session to ensure we don't double-save
            Task { @MainActor in self.updateLocationDuringSession() }
        }
        saveSessionState()

        // Update UI state - check participant outcomes for joined sessions
        DispatchQueue.main.async { [self] in
            if isJoinedSession {
                // Determine the appropriate completion view
                determineCompletionView { state in
                    self.currentState = state
                    // Reset join state after setting final state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.resetJoinState() }
                }
            }
            else {
                self.currentState = .failed  // or .failed depending on the method
            }
        }
    }
    private func recordMultiUserSession(wasSuccessful: Bool) {
        guard let sessionId = liveSessionId, let userId = Auth.auth().currentUser?.uid,
            let username = FirebaseManager.shared.currentUser?.username
        else { return }

        // Calculate actual duration in minutes
        let actualDuration = (selectedMinutes * 60 - remainingSeconds) / 60

        // Fetch all session participants from Firestore
        LiveSessionManager.shared.db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let self = self, let document = document, document.exists,
                    let data = document.data()
                else {

                    // Fallback to regular session recording if data is incomplete
                    self?.sessionManager
                        .addSession(
                            duration: self?.selectedMinutes ?? 0,
                            wasSuccessful: wasSuccessful,
                            actualDuration: actualDuration
                        )
                    return
                }

                // Get participant data with safe fallbacks for older sessions
                let participants = data["participants"] as? [String] ?? []
                let joinTimesData = data["joinTimes"] as? [String: Timestamp] ?? [:]
                let participantStatusData = data["participantStatus"] as? [String: String] ?? [:]
                let starterId = data["starterId"] as? String ?? userId
                let starterUsername = data["starterUsername"] as? String ?? username
                let targetDuration = data["targetDuration"] as? Int ?? self.selectedMinutes

                // Create participant records
                var sessionParticipants: [Session.Participant] = []

                // Load each participant's username
                let group = DispatchGroup()
                var usernames: [String: String] = [starterId: starterUsername]

                for participantId in participants
                where participantId != starterId && participantId != userId {
                    group.enter()

                    FirebaseManager.shared.db.collection("users").document(participantId)
                        .getDocument { document, error in
                            if let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                            {
                                usernames[participantId] = userData.username
                            }
                            else {
                                usernames[participantId] = "User"  // Fallback
                            }
                            group.leave()
                        }
                }

                group.notify(queue: .main) {
                    // Now create all participant records
                    for participantId in participants {
                        // Default join time to session start if not available
                        let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
                        let joinTime = joinTimesData[participantId]?.dateValue() ?? startTime

                        let wasParticipantSuccessful =
                            participantStatusData[participantId]
                            == LiveSessionManager.ParticipantStatus.completed.rawValue

                        // Calculate participant's actual duration based on join time
                        let elapsedSecondsAtJoin = self.selectedMinutes * 60 - (targetDuration * 60)
                        let participantTimeInSession =
                            wasParticipantSuccessful
                            ? (targetDuration * 60 - elapsedSecondsAtJoin) / 60 : actualDuration

                        let participant = Session.Participant(
                            id: participantId,
                            username: usernames[participantId] ?? "User",
                            joinTime: joinTime,
                            wasSuccessful: wasParticipantSuccessful,
                            actualDuration: participantTimeInSession
                        )

                        sessionParticipants.append(participant)
                    }

                    // Add the session to history with explicit session ID for linking
                    self.sessionManager.addSession(
                        duration: self.selectedMinutes,
                        wasSuccessful: wasSuccessful,
                        actualDuration: actualDuration,
                        sessionTitle: nil,
                        sessionNotes: nil,
                        participants: sessionParticipants,
                        originalStarterId: starterId,
                        wasJoinedSession: self.isJoinedSession,
                        liveSessionId: sessionId  // Add this parameter to your Session struct
                    )

                    // End the live session in Firestore if this is the original starter
                    if userId == starterId {
                        LiveSessionManager.shared.endSession(
                            sessionId: sessionId,
                            userId: userId,
                            wasSuccessful: wasSuccessful
                        )
                    }
                }
            }
    }

    private func endSession() {
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()

        // Invalidate all timers
        invalidateAllTimers()
        cancelPendingNotifications()
        endBackgroundTask()

        // Reset join state when ending a session
        if isJoinedSession { resetJoinState() }

        // Since the session is over, we should use regular location settings
        Task { @MainActor in LocationHandler.shared.startLocationUpdates()  // This will use non-session settings
        }
    }

    @available(iOS 16.1, *) private func startLiveActivity() {
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        guard currentState == .countdown || currentState == .tracking else {
            print("Not starting Live Activity - no active session")
            return
        }

        guard currentState != .completed && currentState != .failed else {
            print("Not starting Live Activity - session already ended")
            return
        }

        Task { @MainActor in  // Ensure we're on main thread
            do {
                // End any existing activities first
                if let currentActivity = activity {
                    await currentActivity.end(currentActivity.content, dismissalPolicy: .immediate)
                    activity = nil
                }
                for existingActivity in Activity<FlipActivityAttributes>.activities {
                    await existingActivity.end(
                        existingActivity.content,
                        dismissalPolicy: .immediate
                    )
                }

                let state = FlipActivityAttributes.ContentState(
                    remainingTime: remainingTimeString,
                    remainingPauses: remainingPauses,
                    isPaused: false,
                    isFailed: false,
                    flipBackTimeRemaining: nil,
                    lastUpdate: Date()
                )

                let activityContent = ActivityContent(
                    state: state,
                    staleDate: Calendar.current.date(
                        byAdding: .minute,
                        value: selectedMinutes + 1,
                        to: Date()
                    )
                )
                let attributes = FlipActivityAttributes()

                activity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: nil
                )
                print("Live Activity started successfully")
            }
            catch { print("Activity Error: \(error)") }
        }
    }

    @available(iOS 16.1, *) private func endLiveActivity() {
        Task {
            // 1. End the specific activity we're tracking if it exists
            if let currentActivity = activity {
                let finalState = FlipActivityAttributes.ContentState(
                    remainingTime: remainingTimeString,
                    remainingPauses: remainingPauses,
                    isPaused: false,
                    isFailed: currentState == .failed,
                    flipBackTimeRemaining: nil,
                    countdownMessage: nil,
                    lastUpdate: Date()
                )

                do {
                    await currentActivity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    print("Successfully ended current Live Activity")
                }

                // Reset our activity reference
                activity = nil
            }

            // 2. Forcefully end ALL activities to ensure cleanup
            for activity in Activity<FlipActivityAttributes>.activities {
                do {
                    await activity.end(activity.content, dismissalPolicy: .immediate)
                    print("Successfully ended stale Live Activity")
                }
            }

            // 3. Double-check after a short delay to make sure nothing persisted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    if Activity<FlipActivityAttributes>.activities.count > 0 {
                        print(
                            "Still found \(Activity<FlipActivityAttributes>.activities.count) activities - forcing termination"
                        )
                        for activity in Activity<FlipActivityAttributes>.activities {
                            await activity.end(
                                ActivityContent(
                                    state: FlipActivityAttributes.ContentState(
                                        remainingTime: "0:00",
                                        remainingPauses: 0,
                                        isPaused: false,
                                        isFailed: false,
                                        flipBackTimeRemaining: nil,
                                        countdownMessage: nil,
                                        lastUpdate: Date()
                                    ),
                                    staleDate: nil
                                ),
                                dismissalPolicy: .immediate
                            )
                        }
                    }
                }
            }
        }
    }

    @available(iOS 16.1, *) private func updateLiveActivity() {
        guard currentState != .completed && currentState != .failed else { return }

        guard let activity = activity else {
            print("No active Live Activity to update")
            // Only start new activity if in a valid state
            if currentState != .completed && currentState != .failed { startLiveActivity() }
            return
        }

        Task {
            let state = FlipActivityAttributes.ContentState(
                remainingTime: remainingTimeString,
                remainingPauses: remainingPauses,
                isPaused: currentState == .paused,
                isFailed: currentState == .failed,
                wasSuccessful: currentState == .completed,
                flipBackTimeRemaining: (currentState == .tracking && !isFaceDown)
                    ? flipBackTimeRemaining : nil,
                pauseTimeRemaining: (currentState == .paused && isPauseTimerActive)
                    ? formatPauseTimeRemaining() : nil,
                countdownMessage: currentState == .countdown
                    ? "\(countdownSeconds) seconds to flip phone" : nil,
                lastUpdate: Date()
            )

            let content = ActivityContent(
                state: state,
                staleDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())
            )

            await activity.update(content)
        }
    }
    private func updateUserStats(successful: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Update relevant user statistics
        let db = FirebaseManager.shared.db
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            guard let document = document, document.exists else { return }

            if let userData = try? document.data(as: FirebaseManager.FlipUser.self) {
                var totalFocusTime = userData.totalFocusTime
                var totalSessions = userData.totalSessions
                var longestSession = userData.longestSession

                // Update values based on current session
                let actualSessionDuration = (self.selectedMinutes * 60 - self.remainingSeconds) / 60
                totalFocusTime += actualSessionDuration

                if successful { totalSessions += 1 }

                if actualSessionDuration > longestSession { longestSession = actualSessionDuration }

                // Write updates back to Firestore
                userRef.updateData([
                    "totalFocusTime": totalFocusTime, "totalSessions": totalSessions,
                    "longestSession": longestSession,
                ])
            }
        }
    }

    // MARK: - Notifications
    private func notifyFlipUsed() {
        notificationManager.display(
            title: "Phone Flipped",
            body: remainingPauses > 0
                ? "\(remainingPauses) pauses remaining, you have \(flipBackTimeRemaining) seconds to pause or flip back over"
                : "No pauses remaining, you have \(flipBackTimeRemaining) seconds to flip back over"
        )
    }

    private func notifyCompletion() {
        notificationManager.display(
            title: "Session Complete!",
            body: "Great job staying focused!",
            categoryIdentifier: "SESSION_END"
        )
    }

    private func notifyFailure() {
        notificationManager.display(
            title: "Session Failed",
            body: "Your focus session failed because your phone was flipped!",
            categoryIdentifier: "SESSION_END"
        )
    }

    private func cleanupStaleActivities() {
        if #available(iOS 16.1, *) {
            Task {
                // Clean up any potentially stale activities from previous runs
                for activity in Activity<FlipActivityAttributes>.activities {
                    print("Cleaning up stale Live Activity")
                    await activity.end(activity.content, dismissalPolicy: .immediate)
                }
            }
        }
    }

    // MARK: - State Preservation
    func saveSessionState() {
        let defaults = UserDefaults.standard
        defaults.set(currentState.rawValue, forKey: "currentState")
        defaults.set(remainingSeconds, forKey: "remainingSeconds")
        defaults.set(remainingPauses, forKey: "remainingPauses")
        defaults.set(isFaceDown, forKey: "isFaceDown")
        defaults.set(pauseDuration, forKey: "pauseDuration")

        let isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            // This is a fresh install or reinstall, clear all state
            clearSessionState()
            defaults.set(true, forKey: "hasLaunchedBefore")
            print("First launch detected - starting with clean state")
            return
        }

        if let pauseStartTime = pauseStartTime {
            defaults.set(pauseStartTime.timeIntervalSince1970, forKey: "pauseStartTime")
        }
        else {
            defaults.removeObject(forKey: "pauseStartTime")
        }

        if let pauseEndTime = pauseEndTime {
            defaults.set(pauseEndTime.timeIntervalSince1970, forKey: "pauseEndTime")
        }
        else {
            defaults.removeObject(forKey: "pauseEndTime")
        }

        // Enhanced validation for live session info
        if liveSessionId != nil && isJoinedSession {
            // Double check that session still exists before saving
            LiveSessionManager.shared.getSessionDetails(sessionId: liveSessionId!) { sessionData in
                if sessionData != nil {
                    // Session exists, save the info
                    defaults.set(self.liveSessionId, forKey: "liveSessionId")
                    defaults.set(self.isJoinedSession, forKey: "isJoinedSession")
                    defaults.set(self.originalSessionStarter, forKey: "originalSessionStarter")
                }
                else {
                    // Session doesn't exist, clear the data
                    defaults.removeObject(forKey: "liveSessionId")
                    defaults.removeObject(forKey: "isJoinedSession")
                    defaults.removeObject(forKey: "originalSessionStarter")

                    // Also reset local state
                    DispatchQueue.main.async {
                        self.liveSessionId = nil
                        self.isJoinedSession = false
                        self.originalSessionStarter = nil
                    }
                }
            }
        }
        else if !isJoinedSession {
            // Clear live session info if not joined
            defaults.removeObject(forKey: "liveSessionId")
            defaults.removeObject(forKey: "isJoinedSession")
            defaults.removeObject(forKey: "originalSessionStarter")
        }

        // Save countdown seconds if we're in countdown state
        if currentState == .countdown { defaults.set(countdownSeconds, forKey: "countdownSeconds") }

        if currentState == .paused {
            defaults.set(pausedRemainingSeconds, forKey: "pausedRemainingSeconds")
            defaults.set(remainingPauseSeconds, forKey: "remainingPauseSeconds")
            defaults.set(isPauseTimerActive, forKey: "isPauseTimerActive")
        }

        // Save flip back timer state if active
        if flipBackTimer != nil && currentState == .tracking && !isFaceDown {
            defaults.set(flipBackTimeRemaining, forKey: "flipBackTimeRemaining")
        }
    }

    private func restoreSessionState() {
        let defaults = UserDefaults.standard
        currentState =
            FlipState(rawValue: defaults.string(forKey: "currentState") ?? "") ?? .initial

        // Restore live session info with validation
        liveSessionId = defaults.string(forKey: "liveSessionId")
        isJoinedSession = defaults.bool(forKey: "isJoinedSession")
        originalSessionStarter = defaults.string(forKey: "originalSessionStarter")

        // If we have a session ID, verify it still exists
        if let sessionId = liveSessionId, isJoinedSession {
            LiveSessionManager.shared.getSessionDetails(sessionId: sessionId) { sessionData in
                if sessionData == nil {
                    // Session doesn't exist anymore, reset join state
                    DispatchQueue.main.async { self.resetJoinState() }
                }
                else {
                    // Session exists, listen to updates
                    LiveSessionManager.shared.listenToJoinedSession(sessionId: sessionId)
                }
            }
        }

        // If the session was completed or failed, clear state and return
        if currentState == .completed || currentState == .failed || currentState == .joinedCompleted
            || currentState == .mixedOutcome
        {
            clearSessionState()
            currentState = .initial
            return
        }

        // Restore other state variables
        remainingSeconds = defaults.integer(forKey: "remainingSeconds")
        remainingPauses = defaults.integer(forKey: "remainingPauses")
        isFaceDown = defaults.bool(forKey: "isFaceDown")
        pauseDuration = defaults.integer(forKey: "pauseDuration")

        if let pauseStartTimeInterval = defaults.object(forKey: "pauseStartTime") as? TimeInterval {
            pauseStartTime = Date(timeIntervalSince1970: pauseStartTimeInterval)
        }
        else {
            pauseStartTime = nil
        }
        if let pauseEndTimeInterval = defaults.object(forKey: "pauseEndTime") as? TimeInterval {
            pauseEndTime = Date(timeIntervalSince1970: pauseEndTimeInterval)
        }
        else {
            pauseEndTime = nil
        }

        if currentState == .paused {
            pausedRemainingSeconds = defaults.integer(forKey: "pausedRemainingSeconds")

            // Calculate remaining time based on end time
            let now = Date()
            if let endTime = pauseEndTime, endTime > now {
                // Pause is still valid
                remainingPauseSeconds = Int(endTime.timeIntervalSince(now))
                isPauseTimerActive = true

                // Start the pause timer
                startPauseTimer()
            }
            else if pauseEndTime != nil {
                // Pause has expired while app was closed
                isPauseTimerActive = false
                remainingPauseSeconds = 0

                // Schedule auto-resume
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.resumeSession() }
            }
            else {
                // Fall back to old behavior if no end time
                remainingPauseSeconds = defaults.integer(forKey: "remainingPauseSeconds")
                isPauseTimerActive = defaults.bool(forKey: "isPauseTimerActive")
                if isPauseTimerActive { startPauseTimer() }
            }
        }

        // If pauseDuration is 0 (not set previously), set it to default
        if pauseDuration == 0 {
            pauseDuration = 5  // Default to 5 minutes
        }

        // Handle different states appropriately
        switch currentState {
        case .tracking:
            // Check if we were in the middle of a flip back timer
            let savedFlipBackTime = defaults.integer(forKey: "flipBackTimeRemaining")
            if !isFaceDown && savedFlipBackTime > 0 {
                // Restore flip back time state
                flipBackTimeRemaining = savedFlipBackTime
                // Start the timer with the saved time
                startFlipBackTimer()
            }

            // Continue tracking session from where it left off
            startTrackingSession()

        case .countdown:
            // If we were in countdown state, restart the countdown
            let savedCountdown = defaults.integer(forKey: "countdownSeconds")
            // If we have a saved countdown value and it's valid, use it
            if savedCountdown > 0 && savedCountdown <= 5 {
                countdownSeconds = savedCountdown
                print(
                    "Restoring from countdown state - continuing from \(countdownSeconds) seconds"
                )
            }
            else {
                // Otherwise, restart with the default countdown time
                countdownSeconds = 5
                print("Restoring from countdown state - restarting countdown")
            }

            // Restart the countdown timer
            startCountdown(fromRestoration: true)

        case .paused:
            // If the app was closed while paused, maintain paused state
            pausedRemainingSeconds = defaults.integer(forKey: "pausedRemainingSeconds")
            remainingPauseSeconds = defaults.integer(forKey: "remainingPauseSeconds")
            isPauseTimerActive = defaults.bool(forKey: "isPauseTimerActive")
            isPaused = true

            // IMPORTANT: Recalculate pause time if needed
            if isPauseTimerActive && pauseStartTime != nil {
                recalculatePauseTime()
            }
            else if isPauseTimerActive && remainingPauseSeconds > 0 {
                // Fallback: If we have no start time but active timer, start fresh
                pauseStartTime = Date()
                    .addingTimeInterval(-Double(pauseDuration * 60 - remainingPauseSeconds))
                startPauseTimer()
            }

        default:
            // For any other state (.initial, etc), do nothing special
            break
        }
    }

    // Modify determineCompletionView in AppManager.swift
    func determineCompletionView(completion: @escaping (FlipState) -> Void) {
        // If not a joined session, use standard completion
        if !isJoinedSession {
            completion(currentState)
            return
        }

        // For joined sessions, check all participant statuses
        guard let sessionId = liveSessionId else {
            completion(currentState)
            return
        }

        LiveSessionManager.shared.db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error fetching session data: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(self.currentState) }
                    return
                }

                guard let document = document, document.exists, let data = document.data(),
                    let participantStatus = data["participantStatus"] as? [String: String]
                else {
                    DispatchQueue.main.async { completion(self.currentState) }
                    return
                }

                // Count different status types
                var completedCount = 0
                var failedCount = 0
                var activeCount = 0

                for (_, status) in participantStatus {
                    if status == LiveSessionManager.ParticipantStatus.completed.rawValue {
                        completedCount += 1
                    }
                    else if status == LiveSessionManager.ParticipantStatus.failed.rawValue {
                        failedCount += 1
                    }
                    else {
                        activeCount += 1
                    }
                }

                // Determine the appropriate view state
                let shownState: FlipState

                // Check if any participants are still active
                if activeCount > 0 {
                    // If we have active participants, use the new state
                    shownState = .othersActive
                }
                else if completedCount > 0 && failedCount > 0 {
                    shownState = .mixedOutcome
                }
                else if failedCount > 0 {
                    shownState = .failed
                }
                else if completedCount > 0 {
                    shownState = .joinedCompleted
                }
                else {
                    shownState = self.currentState
                }

                DispatchQueue.main.async {
                    completion(shownState)

                    // IMPORTANT: Reset join state after a delay to allow view transition
                    let shouldResetState =
                        shownState == .joinedCompleted || shownState == .mixedOutcome
                        || shownState == .failed

                    if shouldResetState {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.resetJoinState()
                        }
                    }
                }
            }
    }
    // Add this function to AppManager.swift
    private func cancelPendingNotifications() {
        // Cancel specifically the pause notification instead of all notifications
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pauseEndNotification"])
    }

    private func clearSessionState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "currentState")
        defaults.removeObject(forKey: "remainingSeconds")
        defaults.removeObject(forKey: "remainingPauses")
        defaults.removeObject(forKey: "isFaceDown")
        defaults.removeObject(forKey: "countdownSeconds")
        defaults.removeObject(forKey: "pausedRemainingSeconds")
        defaults.removeObject(forKey: "flipBackTimeRemaining")
        defaults.removeObject(forKey: "remainingPauseSeconds")
        defaults.removeObject(forKey: "isPauseTimerActive")
        defaults.removeObject(forKey: "pauseStartTime")
        defaults.removeObject(forKey: "pauseEndTime")

        // Clear live session info
        defaults.removeObject(forKey: "liveSessionId")
        defaults.removeObject(forKey: "isJoinedSession")
        defaults.removeObject(forKey: "originalSessionStarter")

        // Reset live session properties
        liveSessionId = nil
        isJoinedSession = false
        originalSessionStarter = nil
        sessionParticipants = []

        // Make sure to clean up any live session listeners
        LiveSessionManager.shared.cleanupListeners()
        // Reset pause timer state
        pauseStartTime = nil
        pauseEndTime = nil

        sessionAlreadyRecorded = false
        // Add aggressive Live Activity cleanup to ensure widgets don't remain on lock screen
        if #available(iOS 16.1, *) {
            Task {
                // End activity if it exists
                if let currentActivity = activity {
                    print("Ending current Live Activity during clearSessionState")
                    await currentActivity.end(
                        ActivityContent(
                            state: FlipActivityAttributes.ContentState(
                                remainingTime: "0:00",
                                remainingPauses: 0,
                                isPaused: false,
                                isFailed: currentState == .failed,
                                flipBackTimeRemaining: nil,
                                lastUpdate: Date()
                            ),
                            staleDate: nil
                        ),
                        dismissalPolicy: .immediate
                    )
                    activity = nil
                }

                // Then manually clean any stragglers
                for activity in Activity<FlipActivityAttributes>.activities {
                    print("Cleaning up straggler Live Activity during clearSessionState")
                    await activity.end(activity.content, dismissalPolicy: .immediate)
                }
            }
        }

        DispatchQueue.main.async { self.currentState = .initial }
    }
    func resetJoinState() {
        print("Resetting join state")
        isJoinedSession = false
        liveSessionId = nil
        originalSessionStarter = nil
        sessionParticipants = []

        // Clear any session-related data from UserDefaults to ensure it doesn't persist
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "liveSessionId")
        defaults.removeObject(forKey: "isJoinedSession")
        defaults.removeObject(forKey: "originalSessionStarter")

        // Also clean up any live session listeners
        LiveSessionManager.shared.cleanupListeners()

        // Explicitly tell LiveSessionManager to stop tracking this session
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.stopTrackingSession(sessionId: sessionId)
        }

        // Save state to persist these changes
        saveSessionState()

        // Force update the UI
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    private func notifyFriendsOfFailure() {
        // Check if notifications are enabled in user settings
        if !UserSettingsManager.shared.areFriendFailureNotificationsEnabled {
            print("Friend failure notifications disabled in settings")
            return
        }

        // Check rate limiting
        let now = Date()
        if let lastTime = lastFriendNotificationTime {
            if now.timeIntervalSince(lastTime) < friendNotificationCooldown {
                // Still in cooldown period
                if friendNotificationCount >= maxFriendNotifications {
                    return  // Skip if exceeded max notifications
                }
            }
            else {
                // Reset counter after cooldown
                friendNotificationCount = 0
            }
        }

        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Get current user's username and friends
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self),
                    !userData.friends.isEmpty
                else { return }

                // Filter friends who have notifications enabled
                let batch = FirebaseManager.shared.db.batch()
                var notifiedFriendsCount = 0

                // First, query for friends with notifications enabled
                let group = DispatchGroup()
                var friendsToNotify: [String] = []

                for friendId in userData.friends {
                    group.enter()

                    FirebaseManager.shared.db.collection("user_settings").document(friendId)
                        .getDocument { document, error in
                            defer { group.leave() }

                            if let data = document?.data(),
                                let notificationsEnabled = data["friendFailureNotifications"]
                                    as? Bool, notificationsEnabled
                            {
                                friendsToNotify.append(friendId)
                            }
                        }
                }

                group.notify(queue: .main) {
                    // Create notification content
                    let notificationData: [String: Any] = [
                        "type": "session_failure", "fromUserId": userId,
                        "fromUsername": userData.username, "timestamp": Timestamp(date: now),
                        "message": "\(userData.username) just failed a session!", "read": false,
                        "silent": false,  // Changed from true to false
                    ]

                    // Send to each friend who has notifications enabled
                    for friendId in friendsToNotify {
                        let notificationRef = FirebaseManager.shared.db.collection("users")
                            .document(friendId).collection("notifications").document()

                        batch.setData(notificationData, forDocument: notificationRef)
                        notifiedFriendsCount += 1
                    }

                    // Commit the batch if we have friends to notify
                    if notifiedFriendsCount > 0 {
                        batch.commit { error in
                            if let error = error {
                                print(
                                    "Error sending friend notifications: \(error.localizedDescription)"
                                )
                            }
                            else {
                                print(
                                    "Sent failure notifications to \(notifiedFriendsCount) friends"
                                )

                                // Update rate limiting
                                self?.lastFriendNotificationTime = now
                                self?.friendNotificationCount += 1
                            }
                        }
                    }
                }
            }
    }

    @MainActor func updateLocationDuringSession() {
        guard LocationHandler.shared.lastLocation.horizontalAccuracy >= 0 else {
            print("⚠️ No valid location available for session")
            return
        }
        let location = LocationHandler.shared.lastLocation

        // Get current user ID and username
        let userId = Auth.auth().currentUser?.uid ?? ""
        let username = FirebaseManager.shared.currentUser?.username ?? "User"

        // Get current building information if available
        let currentBuilding = RegionalViewModel.shared.selectedBuilding

        if let building = currentBuilding {
            print("📍 Found building for session: \(building.name) [ID: \(building.id)]")
        }
        else {
            print("⚠️ No building selected for this session")
        }

        // Calculate elapsed time and accurate duration
        let elapsedSeconds = selectedMinutes * 60 - remainingSeconds
        let actualDuration = max(1, elapsedSeconds / 60)  // Ensure at least 1 minute

        // Debug logs for duration calculation
        print(
            "🕙 Duration calculation: selectedMinutes=\(selectedMinutes), remainingSeconds=\(remainingSeconds)"
        )
        print("🕙 Elapsed seconds: \(elapsedSeconds), actual duration in minutes: \(actualDuration)")

        // Check if leaderboard consent has been given
        let hasConsent = LeaderboardConsentManager.shared.canAddToLeaderboard()
        print("📊 Leaderboard consent status: \(hasConsent ? "Granted" : "Not granted")")

        // Create common location data with more accurate duration info
        var locationData: [String: Any] = [
            "userId": userId, "username": username,
            "currentLocation": GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ), "isCurrentlyFlipped": currentState == .tracking && isFaceDown,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": currentState != .failed, "sessionDuration": selectedMinutes,
            "actualDuration": actualDuration,
            "sessionStartTime": Timestamp(date: Date().addingTimeInterval(-Double(elapsedSeconds))),
            "sessionEndTime": Timestamp(date: Date()), "locationUpdatedAt": Timestamp(date: Date()),
            "includeInLeaderboards": hasConsent,
        ]

        // Add building information if available - use standardized building ID
        if let building = currentBuilding {
            // Generate standardized building ID to ensure consistency
            let standardizedBuildingId = String(
                format: "building-%.6f-%.6f",
                building.coordinate.latitude,
                building.coordinate.longitude
            )
            locationData["buildingId"] = standardizedBuildingId
            locationData["buildingName"] = building.name
            locationData["buildingLatitude"] = building.coordinate.latitude
            locationData["buildingLongitude"] = building.coordinate.longitude
            print(
                "🏢 Adding building data to session: ID=\(standardizedBuildingId), Name=\(building.name)"
            )
        }

        // Update location data for current session
        FirebaseManager.shared.db.collection("locations").document(userId)
            .setData(locationData, merge: true) { error in
                if let error = error {
                    print("❌ Error updating location data: \(error.localizedDescription)")
                }
                else {
                    print("✅ Updated location data with duration: \(actualDuration) minutes")
                }
            }

        // Only save completed session data if session completed or failed and not already saved
        if (currentState == .completed || currentState == .failed) && !locationSessionSaved {
            locationSessionSaved = true
            // Create completed session data
            let completedSession = CompletedSession(
                userId: userId,
                username: username,
                location: location.coordinate,
                duration: selectedMinutes,
                actualDuration: actualDuration,
                wasSuccessful: currentState == .completed,
                startTime: Date().addingTimeInterval(-Double(elapsedSeconds)),
                endTime: Date(),
                building: currentBuilding
            )

            // Use FirebaseManager to save
            FirebaseManager.shared.saveSessionLocation(session: completedSession)
            // Force a leaderboard refresh after a short delay
            if let building = currentBuilding, hasConsent {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🔄 Forced leaderboard refresh after session completion")
                    RegionalViewModel.shared.leaderboardViewModel.loadBuildingLeaderboard(
                        building: building
                    )
                }
            }
        }
    }

    // MARK: - App Lifecycle
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseSession),
            name: Notification.Name("pauseSession"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resumeSession),
            name: Notification.Name("resumeSession"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appWillResignActive() {
        print("App will resign active - saving state")
        saveSessionState()

        // Only begin background processing if in an active session
        if currentState == .tracking || currentState == .countdown {
            beginBackgroundProcessing()
        }
        else {
            // If not in a session, completely stop location tracking
            // This is crucial to prevent the blue indicator from showing
            Task { @MainActor in LocationHandler.shared.completelyStopLocationUpdates() }
        }
    }

    @objc private func appDidBecomeActive() {
        isInBackground = false
        // Check for extended background time
        handleExtendedBackgroundTime()
        // Validate state for consistency
        validateCurrentState()
        if currentState == .paused && isPauseTimerActive { recalculatePauseTime() }

        // Check orientation regardless of state to ensure accuracy
        checkCurrentOrientation()
        // Start or restart location updates with appropriate settings
        Task { @MainActor in
            // Only proceed if permission flow is complete
            if currentState == .tracking || currentState == .countdown {
                // We're in a session, start with session settings
                LocationHandler.shared.startLocationUpdates()
            }
            else {
                // We're just browsing the app, start with regular settings
                LocationHandler.shared.startLocationUpdates()
            }
        }

        // Update UI appropriately
        if currentState == .tracking || currentState == .paused {
            if #available(iOS 16.1, *) { Task { updateLiveActivity() } }
        }
    }

    private func recalculatePauseTime() {
        let defaults = UserDefaults.standard
        if let storedEndTimeInterval = defaults.object(forKey: "pauseEndTime") as? TimeInterval {
            pauseEndTime = Date(timeIntervalSince1970: storedEndTimeInterval)
        }

        guard let endTime = pauseEndTime else {
            print("Warning: Pause timer active but no pauseEndTime found")
            return
        }
        let now = Date()
        let remainingSeconds = max(0, Int(endTime.timeIntervalSince(now)))
        remainingPauseSeconds = remainingSeconds
        if remainingPauseSeconds <= 0 {
            isPauseTimerActive = false
            pauseTimer?.invalidate()
            pauseTimer = nil
            pauseStartTime = nil
            pauseEndTime = nil
            defaults.removeObject(forKey: "pauseStartTime")
            defaults.removeObject(forKey: "pauseEndTime")
            DispatchQueue.main.async { self.autoResumeSession() }
        }
        else {
            // Otherwise restart the timer
            pauseTimer?.invalidate()
            pauseTimer = nil
            startPauseTimer()
        }
        if #available(iOS 16.1, *) { updateLiveActivity() }
    }

    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        endSession()
    }
}
