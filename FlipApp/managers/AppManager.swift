import ActivityKit
import BackgroundTasks
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import UserNotifications

class AppManager: NSObject, ObservableObject {
    static var backgroundRefreshIdentifier = "com.jexpearce.flip.refresh"
    static let shared = AppManager()

    // MARK: - Published Properties
    @Published var currentState: FlipState = .initial {
        didSet {
            if currentState != .paused {
                updateLiveActivity()
            }
        }
    }
    @Published var selectedMinutes = 1
    @Published var countdownSeconds = 5
    @Published var isFaceDown = false
    @Published var remainingSeconds = 0
    @Published var allowPause = false
    @Published var isPaused = false
    @Published var pausedRemainingSeconds = 0
    @Published var pausedRemainingFlips = 0
    @Published var allowPauses = false
    @Published var maxPauses = 10
    @Published var remainingPauses = 0
    @Published var liveSessionId: String?
    @Published var isJoinedSession: Bool = false
    @Published var originalSessionStarter: String?
    @Published var sessionParticipants: [String] = []

    private var sessionManager = SessionManager.shared
    private var notificationManager = NotificationManager.shared

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

    // MARK: - ActivityKit Properties
    @available(iOS 16.1, *)
    private var activity: Activity<FlipActivityAttributes>?

    // MARK: - Computed Properties
    var remainingTimeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - This is Friend Notification Section
    private var lastFriendNotificationTime: Date?
    private var friendNotificationCount = 0
    private let maxFriendNotifications = 5
    private let friendNotificationCooldown: TimeInterval = 600  // 10 minutes

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

        startLiveActivity()

        // Only set the state and reset the countdown if not restoring
        if !fromRestoration {
            currentState = .countdown
            countdownSeconds = 5
        }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1, repeats: true
        ) {
            [weak self] timer in
            guard let self = self else { return }

            self.countdownSeconds -= 1
            
            // Save state on each tick to ensure accurate restoration
            self.saveSessionState()

            if self.countdownSeconds <= 0 {
                timer.invalidate()
                print("Countdown finished, starting session")

                // Important: Dispatch to main thread
                DispatchQueue.main.async {
                    self.startTrackingSession()
                }
            }
        }
        
        // Ensure timer runs even during scrolling
        if let timer = countdownTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        // Broadcast session state for live sessions
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
        } else if currentState == .countdown {
            // Generate a new session ID for new sessions
            liveSessionId = UUID().uuidString
            LiveSessionManager.shared.broadcastSessionState(sessionId: liveSessionId!, appManager: self)
        }
    }

    private func notifyCountdownFailed() {
        notificationManager.display(
            title: "Session Not Started",
            body: "Phone must be face down when timer reaches zero")
    }
    func joinLiveSession(sessionId: String, remainingSeconds: Int, totalDuration: Int) {
        // Set up joined session state
        self.liveSessionId = sessionId
        self.isJoinedSession = true
        self.selectedMinutes = totalDuration / 60 // Convert seconds to minutes
        self.remainingSeconds = remainingSeconds
        self.allowPauses = LiveSessionManager.shared.currentJoinedSession?.allowPauses ?? false
        self.maxPauses = LiveSessionManager.shared.currentJoinedSession?.maxPauses ?? 0
        self.remainingPauses = self.maxPauses
        
        // Save current state
        saveSessionState()
        
        // Start countdown to join the session
        startCountdown()
    }

    private func startTrackingSession(isNewSession: Bool = true) {
        print("Starting tracking session")

        // 1. Stop existing timers and updates
        invalidateAllTimers()
        motionManager.stopDeviceMotionUpdates()
        Task { @MainActor in
                LocationHandler.shared.stopLocationUpdates()
                LocationHandler.shared.startLocationUpdates() // Will restart with proper settings
            }
        currentState = .tracking
        if isNewSession {
            // For new sessions, set the full duration
            remainingSeconds = selectedMinutes * 60
            remainingPauses = maxPauses  // Reset pauses for new sessions
        } else {
            // For resumed sessions, restore the paused time
            remainingSeconds = pausedRemainingSeconds
        }

        saveSessionState()
        print(
            "Basic state set up: \(currentState.rawValue), \(remainingSeconds)s"
        )
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
        pausedRemainingSeconds = remainingSeconds
        currentState = .paused

        saveSessionState()

        // Stop motion updates
        motionManager.stopDeviceMotionUpdates()

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
                    flipBackTimeRemaining: nil,
                    lastUpdate: Date()
                )

                await activity.update(
                    ActivityContent(
                        state: state,
                        staleDate: Calendar.current.date(
                            byAdding: .minute, value: selectedMinutes + 1,
                            to: Date())
                    ))
                print("Live Activity paused successfully")
            }
        }
        
        // Broadcast paused state for live sessions
        if let sessionId = liveSessionId {
            LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
        }

        // Add debug print
        print("Session paused. Time remaining: \(remainingTimeString)")
    }

    @objc func resumeSession() {
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
            if #available(iOS 16.1, *) {
                self.startLiveActivity()
            }

            self.countdownTimer?.invalidate()
            self.countdownTimer = Timer.scheduledTimer(
                withTimeInterval: 1, repeats: true
            ) { [weak self] timer in
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
                            flipBackTimeRemaining: nil,
                            countdownMessage:
                                "\(self.countdownSeconds) seconds to flip phone",
                            lastUpdate: Date()
                        )

                        await self.activity?.update(
                            ActivityContent(
                                state: state,
                                staleDate: Calendar.current.date(
                                    byAdding: .minute,
                                    value: self.selectedMinutes + 1, to: Date())
                            )
                        )
                    }
                }
                
                // Broadcast session state for live sessions
                if let sessionId = self.liveSessionId {
                    LiveSessionManager.shared.broadcastSessionState(sessionId: sessionId, appManager: self)
                }

                if self.countdownSeconds <= 0 {
                    timer.invalidate()

                    // Get fresh orientation reading to ensure accurate state
                    self.checkCurrentOrientation()
                    
                    // Check if phone is face down
                    if let motion = self.motionManager.deviceMotion,
                        motion.gravity.z > 0.8
                    {
                        self.startTrackingSession(isNewSession: false)
                    } else {
                        self.failSession()
                    }
                }
            }
            
            // Ensure timer runs even during scrolling
            if let timer = self.countdownTimer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }

    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        guard !isPaused else { return }
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
        { [weak self] _ in
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
                    Task { @MainActor in
                        self.updateLocationDuringSession()
                    }
                }

                if #available(iOS 16.1, *) {
                    self.updateLiveActivity()
                }
            } else {
                self.flipBackTimer?.invalidate()
                self.flipBackTimer = nil
                self.completeSession()
            }
        }

        // Ensure timer stays active
        if let timer = sessionTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        Task { @MainActor in
                self.updateLocationDuringSession()
            }
    }

    // MARK: - Timer Management
    private func invalidateAllTimers() {
        // Invalidate all timers
        countdownTimer?.invalidate()
        sessionTimer?.invalidate()
        flipBackTimer?.invalidate()
        backgroundCheckTimer?.invalidate()
        
        // Set all timers to nil to prevent memory leaks
        countdownTimer = nil
        sessionTimer = nil
        flipBackTimer = nil
        backgroundCheckTimer = nil
        
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
        motionManager.startDeviceMotionUpdates(to: .main) {
            [weak self] motion, error in
            guard let self = self,
                let motion = motion,
                currentState == .tracking
            else { return }

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

        flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.flipBackTimeRemaining -= 1
            self.saveSessionState()

            if #available(iOS 16.1, *) {
                self.updateLiveActivity()
            }

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
                } else {
                    print("Flip back timer ended, but session is not failed: state=\(self.currentState.rawValue), isFaceDown=\(self.isFaceDown), isPaused=\(self.isPaused)")
                }
            }
        }
        
        // Ensure the timer stays active even when scrolling
        if let timer = flipBackTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func handlePhoneLifted() {
        guard currentState == .tracking else { return }

        // Set isFaceDown state immediately for accurate state tracking
        isFaceDown = false
        
        if allowPauses && remainingPauses > 0 {
            // Start 10-second countdown only if pauses are available
            startFlipBackTimer()
            notifyFlipUsed()
            if #available(iOS 16.1, *) {
                updateLiveActivity()
            }
            saveSessionState()
        } else {
            // Immediately fail the session if no pauses available
            print("No pauses available, failing session immediately")
            saveSessionState()
            failSession()
        }
    }

    // MARK: - Background Processing
    private func beginBackgroundProcessing() {
        // Clean up any existing task first
        if backgroundTask != .invalid {
            endBackgroundTask()
        }

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

        activityManager.startActivityUpdates(to: .main) {
            [weak self] activity in
            guard let self = self,
                let activity = activity,
                currentState == .tracking,
                activity.stationary
            else { return }

            self.checkCurrentOrientation()
        }
        
        Task { @MainActor in
            LocationHandler.shared.startLocationUpdates()
        }
    }

    private func startBackgroundCheckTimer() {
        backgroundCheckTimer?.invalidate()
        backgroundCheckTimer = Timer.scheduledTimer(
            withTimeInterval: 5, repeats: true  // Changed from 10 to 5 seconds for more frequent checks
        ) { [weak self] _ in
            guard let self = self, self.currentState == .tracking else { return }
            print("Background check timer firing")
            self.checkCurrentOrientation()
        }
        
        // Make sure the timer fires even during scrolling
        if let timer = backgroundCheckTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func checkCurrentOrientation() {
        guard currentState == .tracking else { return }
        
        guard let motion = motionManager.deviceMotion else {
            print("No motion data available for orientation check")
            return
        }
        
        let currentFaceDown = motion.gravity.z > 0.8
        if currentFaceDown != self.isFaceDown {
            print("Orientation changed: was \(self.isFaceDown ? "face down" : "face up"), now \(currentFaceDown ? "face down" : "face up")")
            handleOrientationChange(isFaceDown: currentFaceDown)
        }
        
        // Update the last check time
        lastOrientationCheck = Date()
    }

    // MARK: - Background Task Registration
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppManager.backgroundRefreshIdentifier,
            using: .main
        ) { [weak self] task in
            self?.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: AppManager.backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            BGTaskScheduler.shared.cancel(
                taskRequestWithIdentifier: AppManager
                    .backgroundRefreshIdentifier)
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Error scheduling background task: \(error)")
        }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            task.setTaskCompleted(success: true)
        }
    }
    
    // MARK: - State Recovery
    // Add a method to handle app being in background for extended periods
    private func handleExtendedBackgroundTime() {
        guard currentState == .tracking else { return }
        // Calculate how long we've been in background
        let now = Date()
        let lastOrientationCheckInterval = now.timeIntervalSince(lastOrientationCheck)

        print("Extended background check - time since last check: \(Int(lastOrientationCheckInterval)) seconds")
        
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
                } else {
                    // Phone is still face down, continue the session
                    print("Phone still face down after extended background time")
                    if !motionManager.isDeviceMotionActive {
                        startMotionUpdates()
                    }
                    if sessionTimer == nil {
                        startSessionTimer()
                    }
                }
            } else {
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

    // MARK: - State Safeguards
    // Add this to reset the app to a clean state if it gets stuck
    func resetAppState() {
        print("Emergency reset of app state")
        
        // Stop all timers and monitoring
        invalidateAllTimers()
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
        
        // End background task if active
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        
        // Reset all state variables
        currentState = .initial
        countdownSeconds = 5
        isFaceDown = false
        remainingSeconds = 0
        isPaused = false
        pausedRemainingSeconds = 0
        flipBackTimeRemaining = 10
        
        // Clear persisted state
        clearSessionState()
        
        // Clean up Live Activities
        if #available(iOS 16.1, *) {
            Task {
                cleanupStaleActivities()
            }
        }
        
        print("App state has been reset")
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
        }
    }

    // MARK: - Session Completion
    private func completeSession() {
        
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
                        flipBackTimeRemaining: nil,
                        lastUpdate: Date()
                    )

                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
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

        clearSessionState()
        
        // 4. Save final state
        saveSessionState()

        // 5. Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 6. Send completion notification
        notifyCompletion()
        Task {@MainActor in
            self.updateLocationDuringSession()
        }
        
        // 7. Record session
        if let sessionId = liveSessionId, isJoinedSession {
            // For joined sessions, need to record all participants
            recordMultiUserSession(wasSuccessful: true)
        } else {
            // Regular single-user session
            sessionManager.addSession(
                duration: selectedMinutes,
                wasSuccessful: true,
                actualDuration: selectedMinutes
            )
        }
        updateUserStats(successful: true)

        // 8. Update UI state - check participant outcomes for joined sessions
        DispatchQueue.main.async {
            if self.isJoinedSession {
                // Determine the appropriate completion view
                _ = self.determineCompletionView()
            } else {
                self.currentState = .completed
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
                        flipBackTimeRemaining: nil,
                        countdownMessage: nil,
                        lastUpdate: Date()
                    )

                    await activity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
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
        
        clearSessionState()
        endSession()
        saveSessionState()
        
        Task { @MainActor in
            self.updateLocationDuringSession()
        }
        
        notifyFailure()
        notifyFriendsOfFailure()
        
        // Calculate actual duration in minutes
        let actualDuration = (selectedMinutes * 60 - remainingSeconds) / 60

        if let sessionId = liveSessionId, isJoinedSession {
            // For joined sessions, need to record all participants
            recordMultiUserSession(wasSuccessful: false)
        } else {
            // Regular single-user session
            sessionManager.addSession(
                duration: selectedMinutes,
                wasSuccessful: false,
                actualDuration: actualDuration
            )
        }
        
        updateUserStats(successful: false)

        // Update UI state - check participant outcomes for joined sessions
        DispatchQueue.main.async {
            if self.isJoinedSession {
                // Determine the appropriate completion view
                _ = self.determineCompletionView()
            } else {
                self.currentState = .failed
            }
        }
    }
    private func recordMultiUserSession(wasSuccessful: Bool) {
        guard let sessionId = liveSessionId,
              let userId = Auth.auth().currentUser?.uid,
              let username = FirebaseManager.shared.currentUser?.username else { return }
        
        // Calculate actual duration in minutes
        let actualDuration = (selectedMinutes * 60 - remainingSeconds) / 60
        
        // Fetch all session participants from Firestore
        LiveSessionManager.shared.db.collection("live_sessions").document(sessionId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let data = document.data(),
                  let participants = data["participants"] as? [String],
                  let joinTimesData = data["joinTimes"] as? [String: Timestamp],
                  let participantStatusData = data["participantStatus"] as? [String: String],
                  let starterId = data["starterId"] as? String,
                  let starterUsername = data["starterUsername"] as? String,
                  let targetDuration = data["targetDuration"] as? Int else {
                
                // Fallback to regular session recording if data is incomplete
                self?.sessionManager.addSession(
                    duration: self?.selectedMinutes ?? 0,
                    wasSuccessful: wasSuccessful,
                    actualDuration: actualDuration
                )
                return
            }
            
            // Create participant records
            var sessionParticipants: [Session.Participant] = []
            
            // Load each participant's username
            let group = DispatchGroup()
            var usernames: [String: String] = [starterId: starterUsername]
            
            for participantId in participants where participantId != starterId && participantId != userId {
                group.enter()
                
                FirebaseManager.shared.db.collection("users").document(participantId).getDocument { document, error in
                    if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                        usernames[participantId] = userData.username
                    } else {
                        usernames[participantId] = "User" // Fallback
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                // Now create all participant records
                for participantId in participants {
                    if let joinTime = joinTimesData[participantId]?.dateValue() {
                        let wasParticipantSuccessful = participantStatusData[participantId] == LiveSessionManager.ParticipantStatus.completed.rawValue
                        
                        // Calculate participant's actual duration based on join time
                        let elapsedSecondsAtJoin = self.selectedMinutes * 60 - (targetDuration * 60)
                        let participantTimeInSession = wasParticipantSuccessful ? (targetDuration * 60 - elapsedSecondsAtJoin) / 60 : actualDuration
                        
                        let participant = Session.Participant(
                            id: participantId,
                            username: usernames[participantId] ?? "User",
                            joinTime: joinTime,
                            wasSuccessful: wasParticipantSuccessful,
                            actualDuration: participantTimeInSession
                        )
                        
                        sessionParticipants.append(participant)
                    }
                }
                
                // Add the session to history
                self.sessionManager.addSession(
                    duration: self.selectedMinutes,
                    wasSuccessful: wasSuccessful,
                    actualDuration: actualDuration,
                    sessionTitle: nil,
                    sessionNotes: nil,
                    participants: sessionParticipants,
                    originalStarterId: starterId,
                    wasJoinedSession: self.isJoinedSession
                )
                
                // End the live session in Firestore if this is the original starter
                if userId == starterId {
                    LiveSessionManager.shared.endSession(sessionId: sessionId, userId: userId, wasSuccessful: wasSuccessful)
                }
            }
        }
    }

    private func endSession() {
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
        
        // Invalidate all timers
        invalidateAllTimers()
        
        endBackgroundTask()
        
        // Since the session is over, we should use regular location settings
        Task { @MainActor in
            LocationHandler.shared.startLocationUpdates() // This will use non-session settings
        }
    }

    @available(iOS 16.1, *)
    private func startLiveActivity() {
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
                    await currentActivity.end(
                        currentActivity.content, dismissalPolicy: .immediate)
                    activity = nil
                }
                for existingActivity in Activity<FlipActivityAttributes>.activities {
                                await existingActivity.end(
                                    existingActivity.content, dismissalPolicy: .immediate)
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
                        byAdding: .minute, value: selectedMinutes + 1,
                        to: Date())
                )
                let attributes = FlipActivityAttributes()

                activity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: nil
                )
                print("Live Activity started successfully")
            } catch {
                print("Activity Error: \(error)")
            }
        }
    }

    @available(iOS 16.1, *)
    private func endLiveActivity() {
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
                } catch {
                    print("Error ending Live Activity: \(error)")
                }
                
                // Reset our activity reference
                activity = nil
            }
            
            // 2. Forcefully end ALL activities to ensure cleanup
            for activity in Activity<FlipActivityAttributes>.activities {
                do {
                    await activity.end(
                        activity.content,
                        dismissalPolicy: .immediate
                    )
                    print("Successfully ended stale Live Activity")
                } catch {
                    print("Error ending stale Live Activity: \(error)")
                }
            }
            
            // 3. Double-check after a short delay to make sure nothing persisted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    if Activity<FlipActivityAttributes>.activities.count > 0 {
                        print("Still found \(Activity<FlipActivityAttributes>.activities.count) activities - forcing termination")
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

    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard currentState != .completed && currentState != .failed else {
            return
        }
        
        guard let activity = activity else {
            print("No active Live Activity to update")
            // Only start new activity if in a valid state
            if currentState != .completed && currentState != .failed {
                startLiveActivity()
            }
            return
        }

        Task {
            let state = FlipActivityAttributes.ContentState(
                remainingTime: remainingTimeString,
                remainingPauses: remainingPauses,
                isPaused: currentState == .paused,
                isFailed: currentState == .failed,
                flipBackTimeRemaining: (currentState == .tracking
                    && !isFaceDown)
                    ? flipBackTimeRemaining : nil,
                lastUpdate: Date()
            )

            let content = ActivityContent(
                state: state,
                staleDate: Calendar.current.date(
                    byAdding: .minute, value: 1, to: Date())
            )

            await activity.update(content)
            print("Live Activity updated successfully")
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
                    
                    if successful {
                        totalSessions += 1
                    }
                    
                    if actualSessionDuration > longestSession {
                        longestSession = actualSessionDuration
                    }
                    
                    // Write updates back to Firestore
                    userRef.updateData([
                        "totalFocusTime": totalFocusTime,
                        "totalSessions": totalSessions,
                        "longestSession": longestSession
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
                        await activity.end(
                            activity.content,
                            dismissalPolicy: .immediate
                        )
                    }
                }
            }
        }

        // MARK: - State Preservation
    private func saveSessionState() {
        let defaults = UserDefaults.standard
        defaults.set(currentState.rawValue, forKey: "currentState")
        defaults.set(remainingSeconds, forKey: "remainingSeconds")
        defaults.set(remainingPauses, forKey: "remainingPauses")
        defaults.set(isFaceDown, forKey: "isFaceDown")
        
        // Save live session info
        defaults.set(liveSessionId, forKey: "liveSessionId")
        defaults.set(isJoinedSession, forKey: "isJoinedSession")
        defaults.set(originalSessionStarter, forKey: "originalSessionStarter")
        
        // Save countdown seconds if we're in countdown state
        if currentState == .countdown {
            defaults.set(countdownSeconds, forKey: "countdownSeconds")
        }
        
        // If we're in paused state, save paused remaining seconds
        if currentState == .paused {
            defaults.set(pausedRemainingSeconds, forKey: "pausedRemainingSeconds")
        }
        
        // Save flip back timer state if active
        if flipBackTimer != nil && currentState == .tracking && !isFaceDown {
            defaults.set(flipBackTimeRemaining, forKey: "flipBackTimeRemaining")
        }
    }

    private func restoreSessionState() {
        let defaults = UserDefaults.standard
        currentState =
            FlipState(rawValue: defaults.string(forKey: "currentState") ?? "")
            ?? .initial
        
        // Restore live session info
        liveSessionId = defaults.string(forKey: "liveSessionId")
        isJoinedSession = defaults.bool(forKey: "isJoinedSession")
        originalSessionStarter = defaults.string(forKey: "originalSessionStarter")
        
        // If the session was completed or failed, clear state and return
        if currentState == .completed || currentState == .failed {
            clearSessionState()
            currentState = .initial
            return
        }
        
        // Restore other state variables
        remainingSeconds = defaults.integer(forKey: "remainingSeconds")
        remainingPauses = defaults.integer(forKey: "remainingPauses")
        isFaceDown = defaults.bool(forKey: "isFaceDown")
        
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
                print("Restoring from countdown state - continuing from \(countdownSeconds) seconds")
            } else {
                // Otherwise, restart with the default countdown time
                countdownSeconds = 5
                print("Restoring from countdown state - restarting countdown")
            }
            
            // Restart the countdown timer
            startCountdown(fromRestoration: true)
            
        case .paused:
            // If the app was closed while paused, maintain paused state
            // The user will need to manually resume
            pausedRemainingSeconds = defaults.integer(forKey: "pausedRemainingSeconds")
            isPaused = true
            
        default:
            // For any other state (.initial, etc), do nothing special
            break
        }
    }
    func determineCompletionView() -> FlipState {
        // If not a joined session, use standard completion
        if !isJoinedSession {
            return currentState // Either .completed or .failed as appropriate
        }
        
        // For joined sessions, we need to check all participant statuses
        guard let sessionId = liveSessionId else {
            return currentState // Fallback to current state
        }
        
        // We'll check the session outcomes and route accordingly
        var shownState = currentState
        
        LiveSessionManager.shared.db.collection("live_sessions").document(sessionId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let data = document.data(),
                  let participantStatus = data["participantStatus"] as? [String: String] else {
                return
            }
            
            // Count success/failure states
            var completedCount = 0
            var failedCount = 0
            var activeCount = 0
            
            for (_, status) in participantStatus {
                if status == LiveSessionManager.ParticipantStatus.completed.rawValue {
                    completedCount += 1
                } else if status == LiveSessionManager.ParticipantStatus.failed.rawValue {
                    failedCount += 1
                } else {
                    activeCount += 1
                }
            }
            
            // Determine appropriate view
            if completedCount > 0 && failedCount > 0 {
                // Mixed outcomes - use MixedOutcomeView
                shownState = .mixedOutcome
            } else if failedCount > 0 {
                // All failures
                shownState = .failed
            } else if completedCount > 0 && activeCount == 0 {
                // All success - use JoinedCompletionView
                shownState = .joinedCompleted
            } else {
                // Default to current state
                shownState = self.currentState
            }
            
            // Update the state on main thread
            DispatchQueue.main.async {
                self.currentState = shownState
            }
        }
        
        return shownState
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
        
        // Clear live session info
        defaults.removeObject(forKey: "liveSessionId")
        defaults.removeObject(forKey: "isJoinedSession")
        defaults.removeObject(forKey: "originalSessionStarter")
        
        // Reset live session properties
        liveSessionId = nil
        isJoinedSession = false
        originalSessionStarter = nil
        sessionParticipants = []
        
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
                    await activity.end(
                        activity.content,
                        dismissalPolicy: .immediate
                    )
                }
            }
        }
        
        DispatchQueue.main.async {
            self.currentState = .initial
        }
    }
        
        private func notifyFriendsOfFailure() {
            // Check rate limiting
            let now = Date()
            if let lastTime = lastFriendNotificationTime {
                if now.timeIntervalSince(lastTime) < friendNotificationCooldown {
                    // Still in cooldown period
                    if friendNotificationCount >= maxFriendNotifications {
                        return  // Skip if exceeded max notifications
                    }
                } else {
                    // Reset counter after cooldown
                    friendNotificationCount = 0
                }
            }

            guard let userId = Auth.auth().currentUser?.uid else { return }

            // Get current user's username and friends
            FirebaseManager.shared.db.collection("users").document(userId)
                .getDocument { [weak self] document, error in
                    guard
                        let userData = try? document?.data(
                            as: FirebaseManager.FlipUser.self),
                        !userData.friends.isEmpty
                    else { return }

                    // Create notification content
                    let notificationData: [String: Any] = [
                        "type": "session_failure",
                        "fromUserId": userId,
                        "fromUsername": userData.username,
                        "timestamp": Date(),
                        "silent": true,
                    ]

                    // Send to each friend
                    for friendId in userData.friends {
                        FirebaseManager.shared.db.collection("users")
                            .document(friendId)
                            .collection("notifications")
                            .addDocument(data: notificationData)
                    }

                    // Update rate limiting
                    self?.lastFriendNotificationTime = now
                    self?.friendNotificationCount += 1
                }
        }
    @MainActor
    func updateLocationDuringSession() {
        // This gets called periodically from your tracking methods
        guard LocationHandler.shared.lastLocation.horizontalAccuracy >= 0 else { return }
        let location = LocationHandler.shared.lastLocation
        
        // Get current user ID and username
        let userId = Auth.auth().currentUser?.uid ?? ""
        let username = FirebaseManager.shared.currentUser?.username ?? "User"
        
        // Create location data for current session
        let locationData: [String: Any] = [
            "userId": userId,
            "username": username,
            "currentLocation": GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            "isCurrentlyFlipped": currentState == .tracking && isFaceDown,
            "lastFlipTime": Timestamp(date: Date()),
            "lastFlipWasSuccessful": currentState != .failed,
            "sessionDuration": selectedMinutes,
            "sessionStartTime": Timestamp(date: Date().addingTimeInterval(-Double(remainingSeconds))),
            "locationUpdatedAt": Timestamp(date: Date())
        ]
        
        // Update location data for current session
        FirebaseManager.shared.db.collection("locations").document(userId).setData(locationData, merge: true)
        
        // If session completed or failed, also store as a session location for historical tracking
        if currentState == .completed || currentState == .failed {
            // Calculate actual duration for the session
            let actualDuration = (selectedMinutes * 60 - remainingSeconds) / 60
            
            // Create a document ID using timestamp to ensure uniqueness
            let sessionId = "\(userId)_\(Int(Date().timeIntervalSince1970))"
            
            // Store historical session data
            let sessionData: [String: Any] = [
                "userId": userId,
                "username": username,
                "location": GeoPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ),
                "isCurrentlyFlipped": false,
                "lastFlipTime": Timestamp(date: Date()),
                "lastFlipWasSuccessful": currentState == .completed,
                "sessionDuration": selectedMinutes,
                "actualDuration": actualDuration,
                "sessionStartTime": Timestamp(date: Date().addingTimeInterval(-Double(selectedMinutes * 60 - remainingSeconds))),
                "sessionEndTime": Timestamp(date: Date()),
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // We set this in both collections to ensure availability
            FirebaseManager.shared.db.collection("session_locations").document(sessionId).setData(sessionData)
            
            // This is an important change - also update the locations collection with the final state
            // This ensures historical data is available even if session_locations isn't checked
            FirebaseManager.shared.db.collection("locations").document(userId).setData([
                "isCurrentlyFlipped": false,
                "lastFlipWasSuccessful": currentState == .completed,
                "lastFlipTime": Timestamp(date: Date()),
                "sessionEndTime": Timestamp(date: Date())
            ], merge: true)
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
        } else {
            // If not in a session, completely stop location tracking
            // This is crucial to prevent the blue indicator from showing
            Task { @MainActor in
                LocationHandler.shared.completelyStopLocationUpdates()
            }
        }
    }

    @objc private func appDidBecomeActive() {
        print("App did become active - refreshing state")
        isInBackground = false
        
        // Check for extended background time
        handleExtendedBackgroundTime()
        
        // Validate state for consistency
        validateCurrentState()
        
        // Check orientation regardless of state to ensure accuracy
        checkCurrentOrientation()
        
        // Start or restart location updates with appropriate settings
        Task { @MainActor in
            if currentState == .tracking || currentState == .countdown {
                // We're in a session, start with session settings
                LocationHandler.shared.startLocationUpdates()
            } else {
                // We're just browsing the app, start with regular settings
                LocationHandler.shared.startLocationUpdates()
            }
        }
        
        // Update UI appropriately
        if currentState == .tracking {
            if #available(iOS 16.1, *) {
                Task {
                    updateLiveActivity()
                }
            }
        }
    }

        // MARK: - Cleanup
        deinit {
            NotificationCenter.default.removeObserver(self)
            endSession()
        }
    }