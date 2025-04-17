import FirebaseAuth
import SwiftUI

class SessionJoinCoordinator: ObservableObject {
    // Singleton instance
    static let shared = SessionJoinCoordinator()

    // Published properties to track pending session join requests
    @Published var pendingSessionId: String? = nil
    @Published var pendingSessionName: String? = nil
    @Published var shouldJoinSession = false
    @Published var pendingTimestamp: Date? = nil  // Track when the request was made for timeout
    @Published var showFirstSessionRequiredAlert = false
    // Add error handling
    @Published var showJoinErrorAlert = false
    @Published var joinErrorMessage = ""

    // Timeout constants - reduce from 60 to 30 seconds for better UX
    private let joinTimeout: TimeInterval = 30  // 30 seconds timeout for joining
    private var cleanupTimer: Timer?

    // Private initializer for singleton pattern
    private init() {
        // Start cleanup timer to prevent lingering join requests
        startCleanupTimer()
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
            if let timestamp = pendingTimestamp, Date().timeIntervalSince(timestamp) < joinTimeout {
                // Validate against joining your own session
                if id.contains(Auth.auth().currentUser?.uid ?? "") {
                    print("Preventing join of own session during getJoinSession check")
                    clearPendingSession()
                    return nil
                }
                return (id: id, name: name)
            }
            else {
                // Clear if timed out
                clearPendingSession()
                return nil
            }
        }
        return nil
    }
    // Show error when join fails
    func showError(message: String) {
        joinErrorMessage = message
        showJoinErrorAlert = true
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.showJoinErrorAlert = false }
    }

    // Start cleanup timer to prevent stale join requests
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkForStaleRequests()
        }
        RunLoop.current.add(cleanupTimer!, forMode: .common)
    }

    // Check for and clean up stale join requests
    private func checkForStaleRequests() {
        if let timestamp = pendingTimestamp, Date().timeIntervalSince(timestamp) >= joinTimeout,
            shouldJoinSession
        {
            print("Join session request timed out after \(joinTimeout) seconds")
            clearPendingSession()
            // Show error alert
            showError(message: "Join request timed out. Please try again.")
        }
    }

    deinit {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
}
