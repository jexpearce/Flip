//
//  JoinedSessionIndicator.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/28/25.
//

import Foundation
import SwiftUI

struct JoinedSessionIndicator: View {
    @ObservedObject var liveSessionManager = LiveSessionManager.shared
    @EnvironmentObject var appManager: AppManager
    @State private var isGlowing = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    
    private var joinedSession: LiveSessionManager.LiveSessionData? {
        return liveSessionManager.currentJoinedSession
    }
    
    private var formattedElapsedTime: String {
        guard let session = joinedSession else {
            // Fallback to app manager's time if session data isn't available
            let minutes = appManager.selectedMinutes - (appManager.remainingSeconds / 60)
            let seconds = appManager.remainingSeconds % 60
            return String(format: "%d:%02d", minutes, 60 - seconds)
        }
        
        let baseElapsed = session.elapsedSeconds
        let adjustedElapsed = appManager.isPaused ? baseElapsed : baseElapsed + elapsedSeconds
        
        let minutes = adjustedElapsed / 60
        let seconds = adjustedElapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        if appManager.isJoinedSession {
            HStack(spacing: 8) {
                // Live indicator
                Circle()
                    .fill(appManager.isPaused ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: (appManager.isPaused ? Color.orange : Color.green).opacity(0.6), radius: isGlowing ? 4 : 2)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)
                
                // Session info with starter name
                Text(appManager.isPaused ?
                     "PAUSED session with \(joinedSession?.starterUsername ?? "friend")" :
                     "In session with \(joinedSession?.starterUsername ?? "friend")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Elapsed time
                Text(formattedElapsedTime)
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .id(elapsedSeconds) // Force update when timer ticks
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(appManager.isPaused ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        (appManager.isPaused ? Color.orange : Color.green).opacity(0.8),
                                        (appManager.isPaused ? Color.orange : Color.green).opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .onAppear {
                isGlowing = true
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: appManager.isPaused) { _ in
                // Reset the timer when pause state changes
                stopTimer()
                elapsedSeconds = 0
                if !appManager.isPaused {
                    startTimer()
                }
            }
        } else {
            EmptyView()
        }
    }
    
    private func startTimer() {
        guard !appManager.isPaused else { return }
        
        elapsedSeconds = 0
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
        
        // Make sure timer runs during scrolling
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
