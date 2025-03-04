
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
    
    // Private initializer for singleton pattern
    private init() {}
    
    // Set a pending session to join
    func setJoinSession(id: String, name: String) {
        pendingSessionId = id
        pendingSessionName = name
        shouldJoinSession = true
    }
    
    // Clear the pending session
    func clearPendingSession() {
        pendingSessionId = nil
        pendingSessionName = nil
        shouldJoinSession = false
    }
    func getJoinSession() -> (id: String, name: String)? {
        if shouldJoinSession, let id = pendingSessionId, let name = pendingSessionName {
            return (id: id, name: name)
        }
        return nil
    }
}