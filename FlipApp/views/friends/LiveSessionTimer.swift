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
    private var timer: Timer?
    
    init() {
        startTimer()
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
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// Replace the LiveSessionTimerView struct in LiveSessionTimer.swift with this:

struct LiveSessionTimerView: View {
    @StateObject private var timer = LiveSessionTimer()
    // Change from @ObservedObject to a regular property
    let liveSession: LiveSessionManager.LiveSessionData
    
    var body: some View {
        // Display elapsed time, updating every second
        VStack {
            Text(formattedElapsedTime)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundColor(.white)
        }
        .id(timer.currentTick) // Force refresh on timer tick
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
        
        // Calculate time passed since last update (as Int)
        let timeSinceUpdate = Int(Date().timeIntervalSince1970 - liveSession.lastUpdateTime.timeIntervalSince1970)
        
        // Only subtract time if the session is active (not paused)
        let adjustment = liveSession.isPaused ? 0 : min(timeSinceUpdate, originalRemaining)
        
        // Calculate current remaining and derive elapsed
        let currentRemaining = max(0, originalRemaining - adjustment)
        return totalSeconds - currentRemaining
    }
}