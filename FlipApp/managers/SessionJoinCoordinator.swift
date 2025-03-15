
import Foundation
import SwiftUI

// This class coordinates joining live sessions between different parts of the app
class SessionJoinCoordinator: ObservableObject {
    // Singleton instance
    static let shared = SessionJoinCoordinator()
    
    // Published properties to track pending session join requests
    @Published var pendingSessionId: String? = nil
    @Published var pendingSessionName: String? = nil
    @Published var shouldJoinSession = false
    @Published var pendingTimestamp: Date? = nil  // Track when the request was made for timeout
    
    // Timeout constants
    private let joinTimeout: TimeInterval = 60 // 60 seconds timeout for joining
    private var cleanupTimer: Timer?
    
    // Private initializer for singleton pattern
    private init() {
        // Start cleanup timer to prevent lingering join requests
        startCleanupTimer()
    }
    
    // Set a pending session to join
    func setJoinSession(id: String, name: String) {
        // Clear any existing pending session first
        clearPendingSession()
        
        pendingSessionId = id
        pendingSessionName = name
        pendingTimestamp = Date()
        shouldJoinSession = true
        
        print("Set pending join for session: \(id) (user: \(name))")
    }
    
    // Clear the pending session
    func clearPendingSession() {
        print("Clearing pending session join request")
        pendingSessionId = nil
        pendingSessionName = nil
        pendingTimestamp = nil
        shouldJoinSession = false
    }
    
    // Get the current join session if valid
    func getJoinSession() -> (id: String, name: String)? {
        if shouldJoinSession, let id = pendingSessionId, let name = pendingSessionName {
            // Check for timeout
            if let timestamp = pendingTimestamp,
               Date().timeIntervalSince(timestamp) < joinTimeout {
                return (id: id, name: name)
            } else {
                // Clear if timed out
                clearPendingSession()
                return nil
            }
        }
        return nil
    }
    
    // Start cleanup timer to prevent stale join requests
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.checkForStaleRequests()
        }
        RunLoop.current.add(cleanupTimer!, forMode: .common)
    }
    
    // Check for and clean up stale join requests
    private func checkForStaleRequests() {
        if let timestamp = pendingTimestamp,
           Date().timeIntervalSince(timestamp) >= joinTimeout,
           shouldJoinSession {
            print("Join session request timed out after \(joinTimeout) seconds")
            clearPendingSession()
        }
    }
    
    deinit {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
}