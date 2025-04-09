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

    deinit {
        timer?.invalidate()
        syncTimer?.invalidate()
        timer = nil
        syncTimer = nil
    }
}
