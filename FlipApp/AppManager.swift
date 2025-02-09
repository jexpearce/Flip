import ActivityKit
import BackgroundTasks
import CoreMotion
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
  @Published var allowedFlips = 0
  @Published var remainingFlips = 0
  @Published var allowPause = false
  @Published var isPaused = false
  @Published var pausedRemainingSeconds = 0
  @Published var pausedRemainingFlips = 0

  private var sessionManager = SessionManager.shared

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

    if #available(iOS 16.1, *) {
      // We only need to check if activities are enabled
      let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
      print("Live Activities enabled: \(enabled)")
    }

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

  // MARK: - Session Management
  func startCountdown() {
    print("Starting countdown")  // Debug

    startLiveActivity()

    currentState = .countdown
    countdownSeconds = 5

    countdownTimer?.invalidate()
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
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
    displayNotification(
      title: "Session Not Started",
      body: "Phone must be face down when timer reaches zero")
  }

  private func startTrackingSession() {
    print("Starting tracking session")

    // 1. Stop existing timers and updates
    countdownTimer?.invalidate()
    sessionTimer?.invalidate()
    motionManager.stopDeviceMotionUpdates()

    currentState = .tracking
    remainingSeconds = selectedMinutes * 60
    remainingFlips = allowedFlips

    saveSessionState()
    print("Basic state set up: \(currentState.rawValue), \(remainingSeconds)s")
    startMotionUpdates()
    startSessionTimer()
    beginBackgroundProcessing()
    scheduleBackgroundRefresh()

    print("Tracking session started successfully")
  }

  func pauseSession() {
    print("Pausing session...")

    displayNotification(
      title: "Session Paused",
      body: "Open app to resume or use lock screen controls"
    )

    // Stop timer first
    sessionTimer?.invalidate()
    sessionTimer = nil

    // Update state
    isPaused = true
    pausedRemainingSeconds = remainingSeconds
    pausedRemainingFlips = remainingFlips
    currentState = .paused

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
          remainingFlips: remainingFlips,
          isPaused: true,
          isFailed: false,
          flipBackTimeRemaining: nil,
          lastUpdate: Date()
        )

        await activity.update(
          ActivityContent(
            state: state,
            staleDate: Calendar.current.date(
              byAdding: .minute, value: selectedMinutes + 1, to: Date())
          ))
        print("Live Activity paused successfully")
      }
    }

    // Add debug print
    print("Session paused. Time remaining: \(remainingTimeString)")
  }

  func startResumeCountdown() {
    isPaused = false  // Reset pause state
    remainingSeconds = pausedRemainingSeconds
    remainingFlips = pausedRemainingFlips

    displayNotification(
      title: "Resuming Session",
      body: "Flip your phone face down within 5 seconds")

    if #available(iOS 16.1, *) {
      Task {
        guard let activity = activity else { return }
        let state = FlipActivityAttributes.ContentState(
          remainingTime: remainingTimeString,
          remainingFlips: remainingFlips,
          isPaused: false,
          isFailed: false,
          flipBackTimeRemaining: nil,
          lastUpdate: Date()
        )

        await activity.update(
          ActivityContent(
            state: state,
            staleDate: Calendar.current.date(
              byAdding: .minute, value: selectedMinutes + 1, to: Date())
          ))
      }
    }

    startCountdown()
  }

  private func startSessionTimer() {
    sessionTimer?.invalidate()
    guard !isPaused else { return }
    sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
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

    flipBackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
      [weak self] timer in
      guard let self = self else { return }

      self.flipBackTimeRemaining -= 1

      if #available(iOS 16.1, *) {
        self.updateLiveActivity()  // Update Live Activity to show countdown
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

    if remainingFlips > 0 {
      remainingFlips -= 1
      notifyFlipUsed()
      if #available(iOS 16.1, *) {
        updateLiveActivity()  // Update activity to show remaining flips
      }
    } else {
      failSession()
    }

    isFaceDown = false
    saveSessionState()
  }

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
        currentState == .tracking,
        activity.stationary
      else { return }

      self.checkCurrentOrientation()
    }
  }

  private func startBackgroundCheckTimer() {
    backgroundCheckTimer?.invalidate()
    backgroundCheckTimer = Timer.scheduledTimer(
      withTimeInterval: 10, repeats: true
    ) { [weak self] _ in
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
        taskRequestWithIdentifier: AppManager.backgroundRefreshIdentifier)
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

    checkCurrentOrientation()
    saveSessionState()
    scheduleBackgroundRefresh()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      task.setTaskCompleted(success: true)
    }
  }

  // MARK: - Session Completion
  private func completeSession() {
    // 1. Handle Live Activity first
    if #available(iOS 16.1, *) {
      Task {
        if let currentActivity = activity {
          let finalState = FlipActivityAttributes.ContentState(
            remainingTime: "0:00",
            remainingFlips: remainingFlips,
            isPaused: false,
            isFailed: false,
            flipBackTimeRemaining: nil,
            lastUpdate: Date()
          )

          await currentActivity.end(
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

  private func failSession() {
    if #available(iOS 16.1, *) {
      let state = FlipActivityAttributes.ContentState(
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
            staleDate: Calendar.current.date(
              byAdding: .minute, value: 1, to: Date())
          )
        )
      }
    }

    endSession()
    saveSessionState()
    notifyFailure()  // Send failure notification

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
        if let currentActivity = activity {
          await currentActivity.end(
            currentActivity.content, dismissalPolicy: .immediate)
          activity = nil
        }

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
          staleDate: Calendar.current.date(
            byAdding: .minute, value: selectedMinutes + 1, to: Date())
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
        remainingFlips: remainingFlips,
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
      return
    }

    Task {
      let state = FlipActivityAttributes.ContentState(
        remainingTime: remainingTimeString,
        remainingFlips: remainingFlips,
        isPaused: currentState == .paused,
        isFailed: currentState == .failed,
        flipBackTimeRemaining: (currentState == .tracking && !isFaceDown)
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
    displayNotification(
      title: "Flip Used",
      body: remainingFlips > 0
        ? "\(remainingFlips) flips remaining, you have \(flipBackTimeRemaining) seconds to pause or flip back over"
        : "No flips remaining, you have \(flipBackTimeRemaining) seconds to pause or flip back over"
    )
  }

  private func notifyCompletion() {
    displayNotification(
      title: "Session Complete!",
      body: "Great job staying focused!",
      categoryIdentifier: "SESSION_END"
    )
  }

  private func notifyFailure() {
    displayNotification(
      title: "Session Failed",
      body: "Your focus session failed because your phone was flipped!",
      categoryIdentifier: <#String#>
    )
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
    currentState =
      FlipState(rawValue: defaults.string(forKey: "currentState") ?? "")
      ?? .initial
    remainingSeconds = defaults.integer(forKey: "remainingSeconds")
    remainingFlips = defaults.integer(forKey: "remainingFlips")
    isFaceDown = defaults.bool(forKey: "isFaceDown")

    if currentState == .tracking {
      startTrackingSession()
    }
  }

  // MARK: - User notifications
  private func setupNotifications() {
    notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
      [weak self] granted, _ in
      guard granted else { return }
      self?.setupNotificationCategories()
    }
  }

  private func setupNotificationCategories() {
    notificationCenter.setNotificationCategories(
      Set([
        UNNotificationCategory(
          identifier: "FLIP_ALERT", actions: [], intentIdentifiers: [],
          options: []),
        UNNotificationCategory(
          identifier: "SESSION_END", actions: [], intentIdentifiers: [],
          options: []),
      ]))
  }

  private func displayNotification(
    title: String, body: String, categoryIdentifier: String = "FLIP_ALERT"
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.categoryIdentifier = categoryIdentifier
    notificationCenter.add(
      UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      ))
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
    print("AppManager: handlePauseRequest received")
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
