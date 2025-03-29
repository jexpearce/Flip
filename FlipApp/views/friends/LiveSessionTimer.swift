import Foundation
import SwiftUI

class LiveSessionTimer: ObservableObject {
    @Published var currentTick: Int = 0
    @Published var liveSession: LiveSessionManager.LiveSessionData?
    private var timer: Timer?
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 30  // Sync every 30 seconds

    init(initialSession: LiveSessionManager.LiveSessionData? = nil) {
        self.liveSession = initialSession
        startTimer()
        startSyncTimer()
    }

    func updateSession(session: LiveSessionManager.LiveSessionData) { self.liveSession = session }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.currentTick += 1

                // Every 5 seconds, trigger a refresh of live session data
                if self.currentTick % 5 == 0 {
                    NotificationCenter.default.post(
                        name: Notification.Name("RefreshLiveSessions"),
                        object: nil
                    )
                }
            }
        }

        // Make sure timer works during scrolling
        if let timer = timer { RunLoop.current.add(timer, forMode: .common) }
    }

    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) {
            [weak self] _ in self?.synchronizeWithServer()
        }
        RunLoop.current.add(syncTimer!, forMode: .common)
    }

    private func synchronizeWithServer() {
        if let sessionId = liveSession?.id {
            LiveSessionManager.shared.getSessionDetails(sessionId: sessionId) {
                [weak self] updatedSession in
                if let updatedSession = updatedSession {
                    DispatchQueue.main.async { self?.liveSession = updatedSession }
                }
            }
        }
    }

    // Helper method to calculate current elapsed time with drift compensation
    func calculateElapsedTime() -> Int {
        guard let session = liveSession else { return 0 }

        let baseElapsed = session.elapsedSeconds
        let timeSinceUpdate = Int(
            Date().timeIntervalSince1970 - session.lastUpdateTime.timeIntervalSince1970
        )

        // Apply drift correction and limit extreme values
        let correction = min(2, max(-2, timeSinceUpdate / 60))  // ±2 seconds max correction

        // Only add elapsed time if session is active
        let adjustment = session.isPaused ? 0 : min(timeSinceUpdate + correction, 300)  // Cap at 5 minutes

        return baseElapsed + adjustment
    }

    // Format the time as mm:ss
    func getFormattedElapsedTime() -> String {
        let elapsed = calculateElapsedTime()
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Format the remaining time as mm:ss
    func getFormattedRemainingTime() -> String {
        guard let session = liveSession else { return "0:00" }

        let elapsed = calculateElapsedTime()
        let totalSeconds = session.targetDuration * 60
        let remaining = max(0, totalSeconds - elapsed)

        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    deinit {
        timer?.invalidate()
        syncTimer?.invalidate()
        timer = nil
        syncTimer = nil
    }
}

struct LiveSessionTimerView: View {
    @StateObject private var timer = LiveSessionTimer()
    let liveSession: LiveSessionManager.LiveSessionData
    var showRemaining: Bool = false  // Toggle to show remaining instead of elapsed

    var body: some View {
        Text(showRemaining ? timer.getFormattedRemainingTime() : timer.getFormattedElapsedTime())
            .font(.system(size: 16, weight: .bold)).monospacedDigit().foregroundColor(.white)
            .onAppear { timer.updateSession(session: liveSession) }.id(timer.currentTick)  // Force refresh on tick change
    }
}
