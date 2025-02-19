import ActivityKit
import CoreMotion
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import UserNotifications

class AppManager: NSObject, ObservableObject {
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

    private var sessionManager = SessionManager.shared
    private var notificationManager = NotificationManager.shared

    // MARK: - Motion Properties
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private var lastOrientationCheck = Date()

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
    func startCountdown() {
        print("Starting countdown")  // Debug

        startLiveActivity()

        currentState = .countdown
        countdownSeconds = 5

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1, repeats: true
        ) {
            [weak self] timer in
            guard let self = self else { return }

            self.countdownSeconds -= 1

            if self.countdownSeconds <= 0 {
                timer.invalidate()
                print("Countdown finished, starting session")  // Debug

                // Important: Dispatch to main thread
                DispatchQueue.main.async {
                    self.startTrackingSession()
                }
            }
        }
    }

    private func notifyCountdownFailed() {
        notificationManager.display(
            title: "Session Not Started",
            body: "Phone must be face down when timer reaches zero")
    }

    private func startTrackingSession(isNewSession: Bool = true) {
        print("Starting tracking session")
        
        
        Task { @MainActor in
            LocationHandler.shared.startLocationUpdates(heartbeat)
        }

        // 1. Stop existing timers and updates
        countdownTimer?.invalidate()
        sessionTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()

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

        print("Tracking session started successfully")
    }

    @objc func pauseSession() {
        print("Pausing session...")
        guard allowPauses && remainingPauses > 0 else { return }

        notificationManager.display(
            title: "Session Paused",
            body: "Open app to resume or use lock screen controls"
        )

        // Stop timer first
        countdownTimer?.invalidate()
        sessionTimer?.invalidate()
        flipBackTimer?.invalidate()
        //countdownTimer = nil
        sessionTimer = nil
        //flipBackTimer = nil

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

        // Add debug print
        print("Session paused. Time remaining: \(remainingTimeString)")
    }

    @objc func resumeSession() {
        startMotionUpdates()
        isPaused = false
        remainingSeconds = pausedRemainingSeconds

        // Start 5-second countdown
        currentState = .countdown
        countdownSeconds = 5

        // Start new Live Activity
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }

        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1, repeats: true
        ) {
            [weak self] timer in
            guard let self = self else { return }

            self.countdownSeconds -= 1

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

            if self.countdownSeconds <= 0 {
                timer.invalidate()

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

        notificationManager.display(
            title: "Resuming Session",
            body: "Flip your phone face down within 5 seconds")
    }

    private func startSessionTimer() {
        sessionTimer?.invalidate()
        guard !isPaused else { return }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
        {
            [weak self] _ in
            guard let self = self else { return }

            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.saveSessionState()

                if #available(iOS 16.1, *) {
                    self.updateLiveActivity()
                }
            } else {
                self.completeSession()
            }
        }

        // Ensure timer stays active
        RunLoop.current.add(sessionTimer!, forMode: .common)
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
        flipBackTimer?.invalidate()
        flipBackTimeRemaining = 10

        flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)
        {
            [weak self] timer in
            guard let self = self else { return }

            self.flipBackTimeRemaining -= 1

            if #available(iOS 16.1, *) {
                self.updateLiveActivity()
            }

            if self.flipBackTimeRemaining <= 0 {
                timer.invalidate()
                if !self.isFaceDown && !self.isPaused {
                    // Only fail if phone isn't face down and not paused
                    self.failSession()
                }
            }
        }
    }

    private func handlePhoneLifted() {
        guard currentState == .tracking else { return }

        if allowPauses && remainingPauses > 0 {
            // Start 10-second countdown
            startFlipBackTimer()
            notifyFlipUsed()
            if #available(iOS 16.1, *) {
                updateLiveActivity()
            }
            isFaceDown = false
            saveSessionState()
        } else {
            isFaceDown = false
            saveSessionState()
            failSession()
        }

    }


    func heartbeat() {
        print("heartbeat")
    }

    func checkCurrentOrientation() {
        guard let motion = motionManager.deviceMotion else { return }
        let currentFaceDown = motion.gravity.z > 0.8
        if currentFaceDown != self.isFaceDown {
            handleOrientationChange(isFaceDown: currentFaceDown)
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

        // 2. Clean up session
        endSession()

        // 3. Save final state
        saveSessionState()

        // 4. Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 5. Send completion notification
        notifyCompletion()

        // 6. Record session
        sessionManager.addSession(
            duration: selectedMinutes,
            wasSuccessful: true,
            actualDuration: selectedMinutes
        )

        // 7. Update UI state
        DispatchQueue.main.async {
            self.currentState = .completed
        }
    }

    func failSession() {
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

        endSession()
        saveSessionState()
        notifyFailure()
        notifyFriendsOfFailure()

        sessionManager.addSession(
            duration: selectedMinutes,
            wasSuccessful: false,
            actualDuration: (selectedMinutes * 60 - remainingSeconds) / 60
        )

        DispatchQueue.main.async {
            self.currentState = .failed
        }
    }

    private func endSession() {
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
        sessionTimer?.invalidate()
        countdownTimer?.invalidate()

        Task { @MainActor in
            LocationHandler.shared.stopLocationUpdates()
        }

        currentState = .initial
    }

    @available(iOS 16.1, *)
    private func startLiveActivity() {

        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
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
            guard let currentActivity = activity else { return }
            let finalState = FlipActivityAttributes.ContentState(
                remainingTime: remainingTimeString,
                remainingPauses: remainingPauses,
                isPaused: false,
                isFailed: currentState == .failed,
                flipBackTimeRemaining: nil,
                lastUpdate: Date()
            )
            await currentActivity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            activity = nil
            print("Live Activity ended")
        }
    }

    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard let activity = activity else {
            print("No active Live Activity to update")
            startLiveActivity()
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

    // MARK: - State Preservation
    private func saveSessionState() {
        let defaults = UserDefaults.standard
        defaults.set(currentState.rawValue, forKey: "currentState")
        defaults.set(remainingSeconds, forKey: "remainingSeconds")
        defaults.set(remainingPauses, forKey: "remainingPauses")
        defaults.set(isFaceDown, forKey: "isFaceDown")

    }

    private func restoreSessionState() {
        let defaults = UserDefaults.standard
        currentState =
            FlipState(rawValue: defaults.string(forKey: "currentState") ?? "")
            ?? .initial
        remainingSeconds = defaults.integer(forKey: "remainingSeconds")
        remainingPauses = defaults.integer(forKey: "remainingPauses")
        isFaceDown = defaults.bool(forKey: "isFaceDown")

        if currentState == .tracking {
            startTrackingSession()
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
        saveSessionState()
    }

    @objc private func appDidBecomeActive() {
        if currentState == .tracking {
            // Just update the LiveActivity instead of restarting session
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
