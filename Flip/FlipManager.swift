import SwiftUI
import CoreMotion
import UserNotifications
import BackgroundTasks
import ActivityKit

class FlipManager: NSObject, ObservableObject {
    static let shared = FlipManager()
    
    // MARK: - Published Properties
    @Published var currentState: FlipState = .initial {
        didSet {
            updateLiveActivity()
        }
    }
    @Published var selectedMinutes = 1
    @Published var countdownSeconds = 5
    @Published var isFaceDown = false
    @Published var remainingSeconds = 0
    @Published var allowedFlips = 0
    @Published var remainingFlips = 0
    @Published var allowPause = false
    @Published var isPaused = false
    @Published var pausedRemainingSeconds = 0
    @Published var pausedRemainingFlips = 0
    
    // MARK: - Motion Properties
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private var lastOrientationCheck = Date()
    
    // MARK: - Background Task Properties
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundCheckTimer: Timer?
    
    // MARK: - Timer Properties
    private var countdownTimer: Timer?
    private var sessionTimer: Timer?
    private var flipBackTimer: Timer?
    @Published var flipBackTimeRemaining: Int = 10
    
    // MARK: - ActivityKit Properties
    @available(iOS 16.1, *)
    private var activity: Activity<FlipActivityAttributes>?
    
    // MARK: - Notification Center
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Computed Properties
    var remainingTimeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupMotionManager()
        setupNotifications()
        restoreSessionState()
        addObservers()
    }
    
    // MARK: - Setup Methods
    private func setupMotionManager() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.1
    }
    
    private func setupNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            guard granted else { return }
            self?.setupNotificationCategories()
        }
    }
    
    private func setupNotificationCategories() {
        let categories = [
            UNNotificationCategory(identifier: "FLIP_ALERT", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "SESSION_END", actions: [], intentIdentifiers: [], options: [])
        ]
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    // MARK: - Session Management
    func startCountdown() {
            currentState = .countdown
            countdownSeconds = 5
            
            countdownTimer?.invalidate()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                
                self.countdownSeconds -= 1
                
                // Check if phone is face down during countdown
                if let motion = self.motionManager.deviceMotion {
                    self.isFaceDown = motion.gravity.z > 0.8
                }
                
                if self.countdownSeconds <= 0 {
                    timer.invalidate()
                    
                    // Only start session if phone is face down
                    if self.isFaceDown {
                        self.startTrackingSession()
                    } else {
                        // Reset state and notify user
                        self.currentState = .initial
                        self.notifyCountdownFailed()
                    }
                }
            }
        }
    private func notifyCountdownFailed() {
            let content = UNMutableNotificationContent()
            content.title = "Session Not Started"
            content.body = "Phone must be face down when timer reaches zero"
            content.sound = .default
            
            notificationCenter.add(UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            ))
        }
    


    private func startTrackingSession() {
        if countdownTimer?.isValid == true {
            countdownTimer?.invalidate()
        }
        
        if #available(iOS 16.1, *) {
            Task {
                if let existingActivity = activity {
                    let finalState = FlipActivityAttributes.ContentState(
                        remainingTime: remainingTimeString,
                        remainingFlips: remainingFlips,
                        isPaused: false,
                        isFailed: false,
                        flipBackTimeRemaining: nil,
                        lastUpdate: Date()
                    )
                    await existingActivity.end(
                        ActivityContent(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    activity = nil
                }
                
                // Set up session state
                currentState = .tracking
                remainingSeconds = selectedMinutes * 60
                remainingFlips = allowedFlips
                
                saveSessionState()
                
                // Start background tasks
                beginBackgroundProcessing()
                startMotionUpdates()
                scheduleBackgroundRefresh()
                startSessionTimer()
                
                // Start new activity after cleanup
                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    print("Live Activities not enabled")
                    return
                }
                
                let attributes = FlipActivityAttributes()
                let state = FlipActivityAttributes.ContentState(
                    remainingTime: remainingTimeString,
                    remainingFlips: remainingFlips,
                    isPaused: false,
                    isFailed: false,
                    flipBackTimeRemaining: nil,
                    lastUpdate: Date()
                )
                
                do {
                    let activityContent = ActivityContent(
                        state: state,
                        staleDate: Calendar.current.date(byAdding: .minute, value: selectedMinutes + 5, to: Date())
                    )
                    
                    activity = try Activity.request(
                        attributes: attributes,
                        content: activityContent,
                        pushType: nil
                    )
                    print("Live Activity started successfully")
                } catch {
                    print("Error starting live activity: \(error.localizedDescription)")
                }
            }
        } else {
            // Non-Live Activity setup
            currentState = .tracking
            remainingSeconds = selectedMinutes * 60
            remainingFlips = allowedFlips
            
            saveSessionState()
            beginBackgroundProcessing()
            startMotionUpdates()
            scheduleBackgroundRefresh()
            startSessionTimer()
        }
    }
    
    func pauseSession() {
        isPaused = true
        pausedRemainingSeconds = remainingSeconds
        pausedRemainingFlips = remainingFlips
        
        sessionTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
        currentState = .paused
        
        if #available(iOS 16.1, *) {
            updateLiveActivity()
        }
    }
    
    func startResumeCountdown() {
        remainingSeconds = pausedRemainingSeconds
        remainingFlips = pausedRemainingFlips
        startCountdown()
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.remainingSeconds -= 1
            self.saveSessionState()
            
            // Update Live Activity every second
            if #available(iOS 16.1, *) {
                self.updateLiveActivity()
            }
            
            if self.remainingSeconds <= 0 {
                self.completeSession()
            }
        }
    }
    
    // MARK: - Motion Handling
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self,
                  let motion = motion,
                  self.currentState == .tracking else { return }
            
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
            
            flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                
                self.flipBackTimeRemaining -= 1
                
                if #available(iOS 16.1, *) {
                    self.updateLiveActivity() // Update Live Activity to show countdown
                }
                
                if self.flipBackTimeRemaining <= 0 {
                    timer.invalidate()
                    if !self.isFaceDown {
                        if self.remainingFlips > 0 {
                            self.remainingFlips -= 1
                            self.notifyFlipUsed()
                        } else {
                            self.failSession()
                        }
                    }
                }
            }
        }
    
    private func handlePhoneLifted() {
            guard currentState == .tracking else { return }
            
            startFlipBackTimer() // This starts the 10-second countdown
            isFaceDown = false
            saveSessionState()
        }
    
    // MARK: - Background Processing
    // MARK: - Background Processing
    private func beginBackgroundProcessing() {
        // Clean up any existing task first
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        
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
            self?.endBackgroundTask()
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
            guard let self = self,
                  let activity = activity,
                  self.currentState == .tracking,
                  activity.stationary else { return }
            
            self.checkCurrentOrientation()
        }
    }
    
    private func startBackgroundCheckTimer() {
        backgroundCheckTimer?.invalidate()
        backgroundCheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkCurrentOrientation()
        }
    }
    
    func checkCurrentOrientation() {
        guard let motion = motionManager.deviceMotion else { return }
        let currentFaceDown = motion.gravity.z > 0.8
        if currentFaceDown != self.isFaceDown {
            handleOrientationChange(isFaceDown: currentFaceDown)
        }
    }
    
    // MARK: - Background Task Registration
    func registerBackgroundTasks() {
        let identifier = "com.jexpearce.Flip.refresh"
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: identifier,
            using: .main) { [weak self] task in
                self?.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.jexpearce.Flip.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        
        do {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.jexpearce.Flip.refresh")
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Error scheduling background task: \(error)")
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = { [weak self] in
            self?.saveSessionState()
            task.setTaskCompleted(success: false)
        }
        
        checkCurrentOrientation()
        saveSessionState()
        scheduleBackgroundRefresh()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            task.setTaskCompleted(success: true)
        }
    }
    
    // MARK: - Session Completion
    private func completeSession() {
            if #available(iOS 16.1, *) {
                endLiveActivity()
                activity = nil  // Important: Clear the activity reference
            }
            endSession()
            saveSessionState()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            notifyCompletion()
            
            SessionManager.shared.addSession(
                duration: selectedMinutes,
                wasSuccessful: true,
                actualDuration: selectedMinutes
            )
            
            DispatchQueue.main.async {
                self.currentState = .completed
            }
        }
    
    private func failSession() {
        if #available(iOS 16.1, *) {
            let state = FlipActivityAttributes.FlipContentState(
                remainingTime: remainingTimeString,
                remainingFlips: 0,
                isPaused: false,
                isFailed: true,
                flipBackTimeRemaining: nil,
                lastUpdate: Date()
            )
            
            Task {
                await activity?.update(
                    ActivityContent(
                        state: state,
                        staleDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())
                    )
                )
            }
        }
        
        endSession()
        saveSessionState()
        notifyFailure()
        
        SessionManager.shared.addSession(
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
        backgroundCheckTimer?.invalidate()
        endBackgroundTask()
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
                for activity in Activity<FlipActivityAttributes>.activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
                
                let attributes = FlipActivityAttributes()
                let state = FlipActivityAttributes.ContentState(
                    remainingTime: remainingTimeString,
                    remainingFlips: remainingFlips,
                    isPaused: false,
                    isFailed: false,
                    flipBackTimeRemaining: nil,
                    lastUpdate: Date()
                )
                
                let activityContent = ActivityContent(
                    state: state,
                    staleDate: nil  // Try without stale date first
                )
                
                activity = try await Activity.request(
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
                let finalContent = ActivityContent(
                    state: FlipActivityAttributes.ContentState(
                        remainingTime: remainingTimeString,
                        remainingFlips: remainingFlips,
                        isPaused: false,
                        isFailed: currentState == .failed,
                        flipBackTimeRemaining: nil,
                        lastUpdate: Date()
                    ),
                    staleDate: nil
                )
                
                await activity?.end(
                    finalContent,
                    dismissalPolicy: .immediate
                )
                activity = nil
            }
        }

    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard let activity = activity else { return }
        
        let state = FlipActivityAttributes.FlipContentState(
            remainingTime: remainingTimeString,
            remainingFlips: remainingFlips,
            isPaused: currentState == .paused,
            isFailed: currentState == .failed,
            flipBackTimeRemaining: currentState == .tracking && !isFaceDown ? flipBackTimeRemaining : nil,
            lastUpdate: Date()
        )
        
        Task {
            await activity.update(
                ActivityContent(
                    state: state,
                    staleDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())
                )
            )
        }
    }
    
    // MARK: - Notifications
    private func notifyFlipUsed() {
            let content = UNMutableNotificationContent()
            content.title = "Flip Used"
            content.body = remainingFlips > 0 ?
                "\(remainingFlips) flips remaining, you have \(flipBackTimeRemaining) seconds to pause or flip back over" :
                "No flips remaining, you have \(flipBackTimeRemaining) seconds to pause or flip back over"
            content.sound = .default
            content.categoryIdentifier = "FLIP_ALERT"
            
            notificationCenter.add(UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            ))
        }
    
    private func notifyCompletion() {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = "Great job staying focused!"
        content.sound = .default
        content.categoryIdentifier = "SESSION_END"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        notificationCenter.add(request)
    }
    
    private func notifyFailure() {
        let content = UNMutableNotificationContent()
        content.title = "Session Failed"
        content.body = "Phone was moved too many times"
        content.sound = .default
        content.categoryIdentifier = "SESSION_END"
        
        notificationCenter.add(UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        ))
    }
    
    // MARK: - State Preservation
    private func saveSessionState() {
        let defaults = UserDefaults.standard
        defaults.set(currentState.rawValue, forKey: "currentState")
        defaults.set(remainingSeconds, forKey: "remainingSeconds")
        defaults.set(remainingFlips, forKey: "remainingFlips")
        defaults.set(isFaceDown, forKey: "isFaceDown")
    }
    
    private func restoreSessionState() {
        let defaults = UserDefaults.standard
        currentState = FlipState(rawValue: defaults.string(forKey: "currentState") ?? "") ?? .initial
        remainingSeconds = defaults.integer(forKey: "remainingSeconds")
        remainingFlips = defaults.integer(forKey: "remainingFlips")
        isFaceDown = defaults.bool(forKey: "isFaceDown")
        
        if currentState == .tracking {
            startTrackingSession()
        }
    }
    
    // MARK: - App Lifecycle
    private func addObservers() {
            // Add existing observers
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
            
            // Add new observers for widget actions
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePauseRequest),
                name: Notification.Name("PauseTimerRequest"),
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleResumeRequest),
                name: Notification.Name("ResumeTimerRequest"),
                object: nil
            )
        }
        
        @objc private func handlePauseRequest() {
            pauseSession()
        }
        
        @objc private func handleResumeRequest() {
            startResumeCountdown()
        }
    
    @objc private func appWillResignActive() {
        saveSessionState()
    }
    
    @objc private func appDidBecomeActive() {
        if currentState == .tracking {
            startTrackingSession()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
        endSession()
    }
}
