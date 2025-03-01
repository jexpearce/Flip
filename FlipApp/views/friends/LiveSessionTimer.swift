//
//  LiveSessionTimer.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/28/25.
//

import Foundation
import SwiftUI


class LiveSessionTimer: ObservableObject {
    @Published var currentTick: Int = 0
    @Published var liveSession: LiveSessionManager.LiveSessionData?
    private var timer: Timer?
    
    init(initialSession: LiveSessionManager.LiveSessionData? = nil) {
            self.liveSession = initialSession
            startTimer()
            startSyncTimer()
        }
    func updateSession(session: LiveSessionManager.LiveSessionData) {
            self.liveSession = session
        }
    
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
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    // Add to LiveSessionTimer class
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 30 // Sync every 30 seconds

    private func startSyncTimer() {
            syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
                self?.synchronizeWithServer()
            }
            RunLoop.current.add(syncTimer!, forMode: .common)
        }

    private func synchronizeWithServer() {
            if let sessionId = liveSession?.id {
                LiveSessionManager.shared.getSessionDetails(sessionId: sessionId) { [weak self] updatedSession in
                    if let updatedSession = updatedSession {
                        DispatchQueue.main.async {
                            self?.liveSession = updatedSession
                        }
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

// Replace the LiveSessionTimerView struct in LiveSessionTimer.swift with this:

struct LiveSessionTimerView: View {
    @StateObject private var timer = LiveSessionTimer()
    let liveSession: LiveSessionManager.LiveSessionData
    
    var body: some View {
            Text(formattedElapsedTime)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundColor(.white)
                .onAppear {
                    timer.updateSession(session: liveSession)
                }
                .id(timer.currentTick)
        }
    
    private var formattedElapsedTime: String {
            let elapsedSeconds = calculateElapsedSeconds()
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    
    private func calculateElapsedSeconds() -> Int {
        let totalSeconds = liveSession.targetDuration * 60
        let originalRemaining = liveSession.remainingSeconds
        
        // Calculate elapsed with drift compensation
        let timeSinceUpdate = Int(Date().timeIntervalSince1970 - liveSession.lastUpdateTime.timeIntervalSince1970)
        
        // Apply drift correction factor (can be tuned based on testing)
        let driftCorrection = min(2, max(-2, timeSinceUpdate / 60)) // ±2 seconds max correction
        
        // Only subtract time if session is active (not paused)
        let adjustment = liveSession.isPaused ? 0 : min(timeSinceUpdate + driftCorrection, originalRemaining)
        
        let currentRemaining = max(0, originalRemaining - adjustment)
        return totalSeconds - currentRemaining
    }
}