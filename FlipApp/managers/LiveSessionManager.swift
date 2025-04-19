import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI

class LiveSessionManager: ObservableObject {
    // Queue for handling Firestore updates safely
    private let updateQueue = DispatchQueue(
        label: "com.flipapp.sessionUpdateQueue",
        attributes: .concurrent
    )
    private let updateSemaphore = DispatchSemaphore(value: 1)
    
    // NEW: Dedicated serial queue for managing session listeners dictionary
    private let listenerQueue = DispatchQueue(label: "com.flipapp.listenerQueue")

    private static let _shared = LiveSessionManager()
    static var shared: LiveSessionManager { return _shared }

    let db: Firestore
    // Protected by listenerQueue
    private var sessionListeners: [String: ListenerRegistration] = [:]

    // Published properties for UI updates
    @Published var activeFriendSessions: [String: LiveSessionData] = [:]
    @Published var currentJoinedSession: LiveSessionData?
    @Published var isJoiningSession = false

    // MARK: - Initialization

    private init() {
        // Safety check - verify Firebase is initialized
        if FirebaseApp.app() == nil {
            print("WARNING: Firebase not initialized when LiveSessionManager is created")
            FirebaseApp.configure()
        }

        // Get Firestore after ensuring Firebase is configured
        self.db = Firestore.firestore()
        startCleanupTimer()
        // Add observer for refresh requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshNotification),
            name: Notification.Name("RefreshLiveSessions"),
            object: nil
        )
    }

    // MARK: - Model Structs

    struct LiveSessionData: Identifiable, Equatable {
        let id: String
        let starterId: String
        let starterUsername: String
        var participants: [String]
        let startTime: Date
        let targetDuration: Int
        var remainingSeconds: Int
        var isPaused: Bool
        var allowPauses: Bool
        var maxPauses: Int
        var joinTimes: [String: Date]
        var participantStatus: [String: ParticipantStatus]
        var lastUpdateTime: Date

        // Add constant inside the struct
        private let minRemainingTimeToJoin = 3 * 60  // 3 minutes in seconds

        var elapsedSeconds: Int {
            let totalSeconds = targetDuration * 60
            return totalSeconds - remainingSeconds
        }

        var isFull: Bool { return participants.count >= 4 }

        var canJoin: Bool { return !isFull && remainingSeconds > minRemainingTimeToJoin }
        static func == (lhs: LiveSessionData, rhs: LiveSessionData) -> Bool {
            return lhs.id == rhs.id && lhs.starterId == rhs.starterId
                && lhs.starterUsername == rhs.starterUsername
                && lhs.participants == rhs.participants && lhs.targetDuration == rhs.targetDuration
                && lhs.remainingSeconds == rhs.remainingSeconds && lhs.isPaused == rhs.isPaused
                && lhs.lastUpdateTime == rhs.lastUpdateTime
        }
    }

    enum ParticipantStatus: String, Codable, Equatable {
        case active
        case paused
        case completed
        case failed
    }

    // MARK: - Initialization

    // MARK: - Session Management

    func broadcastSessionState(sessionId: String, appManager: AppManager) {
        guard let userId = Auth.auth().currentUser?.uid,
            let username = FirebaseManager.shared.currentUser?.username
        else { return }

        // Get current state from AppManager
        let remainingSeconds = appManager.remainingSeconds
        let isPaused = appManager.isPaused
        let allowPauses = appManager.allowPauses
        let maxPauses = appManager.maxPauses
        let targetDuration = appManager.selectedMinutes

        // Check if this is a new session or update
        db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] snapshot, error in
                if let document = snapshot, document.exists {
                    // Update existing session
                    self?
                        .updateExistingSession(
                            sessionId: sessionId,
                            remainingSeconds: remainingSeconds,
                            isPaused: isPaused,
                            userId: userId
                        )
                }
                else {
                    // Create new session
                    self?
                        .createNewSession(
                            sessionId: sessionId,
                            starterId: userId,
                            starterUsername: username,
                            targetDuration: targetDuration,
                            remainingSeconds: remainingSeconds,
                            isPaused: isPaused,
                            allowPauses: allowPauses,
                            maxPauses: maxPauses
                        )
                }
            }
    }

    private func createNewSession(
        sessionId: String,
        starterId: String,
        starterUsername: String,
        targetDuration: Int,
        remainingSeconds: Int,
        isPaused: Bool,
        allowPauses: Bool,
        maxPauses: Int
    ) {
        let now = Date()
        let pauseDuration = AppManager.shared.pauseDuration

        let sessionData: [String: Any] = [
            "starterId": starterId, "starterUsername": starterUsername, "participants": [starterId],
            "startTime": Timestamp(date: now), "targetDuration": targetDuration,
            "remainingSeconds": remainingSeconds, "isPaused": isPaused, "allowPauses": allowPauses,
            "maxPauses": maxPauses, "joinTimes": [starterId: Timestamp(date: now)],
            "participantStatus": [starterId: ParticipantStatus.active.rawValue],
            "lastUpdateTime": Timestamp(date: now), "pauseDuration": pauseDuration,
        ]

        db.collection("live_sessions").document(sessionId)
            .setData(sessionData) { error in
                if let error = error {
                    print("Error creating live session: \(error.localizedDescription)")
                }
                else {
                    print("Live session created successfully")
                }
            }
    }

    func updateExistingSession(
        sessionId: String,
        remainingSeconds: Int,
        isPaused: Bool,
        userId: String
    ) {
        // Use semaphore to prevent race conditions
        updateQueue.async {
            self.updateSemaphore.wait()

            let updateData: [String: Any] = [
                "remainingSeconds": remainingSeconds, "isPaused": isPaused,
                "participantStatus.\(userId)": isPaused
                    ? ParticipantStatus.paused.rawValue : ParticipantStatus.active.rawValue,
                "lastUpdateTime": FieldValue.serverTimestamp(),
            ]

            self.db.collection("live_sessions").document(sessionId)
                .updateData(updateData) { error in
                    self.updateSemaphore.signal()

                    if let error = error {
                        print("Error updating live session: \(error.localizedDescription)")
                    }
                }
        }
    }

    func listenForFriendSessions() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // First get user's friends
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self),
                    let self = self
                else { return }

                // Get all friend IDs
                let friendIds = userData.friends

                // Skip if no friends
                if friendIds.isEmpty { return }

                // Keep track of sessions we've seen to detect removed ones
                var foundSessionIds = Set<String>()

                // Create a more robust listener
                self.db.collection("live_sessions")
                    .whereField("participants", arrayContainsAny: friendIds)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print(
                                "Error fetching live sessions: \(error?.localizedDescription ?? "Unknown error")"
                            )
                            return
                        }

                        print("Received \(documents.count) live sessions from query")

                        // Process session documents on main thread
                        DispatchQueue.main.async {
                            let validSessions = documents.compactMap {
                                doc -> (String, LiveSessionData)? in
                                guard let sessionData = self.parseLiveSessionDocument(doc) else {
                                    return nil
                                }

                                // Filter sessions based on validity criteria
                                let isSessionTooOld =
                                    Date().timeIntervalSince(sessionData.lastUpdateTime) > 120  // 2 minutes
                                let sessionEndTime = sessionData.startTime.addingTimeInterval(
                                    TimeInterval(sessionData.targetDuration * 60)
                                )
                                let isSessionEnded = Date() > sessionEndTime

                                if !isSessionTooOld && !isSessionEnded
                                    && sessionData.remainingSeconds > 0
                                {
                                    foundSessionIds.insert(doc.documentID)
                                    return (doc.documentID, sessionData)
                                }

                                return nil
                            }

                            // First, handle sessions that need to be removed
                            let sessionsToRemove = Set(self.activeFriendSessions.keys)
                                .subtracting(foundSessionIds)
                            for sessionId in sessionsToRemove {
                                print("Removing session \(sessionId) - not in query results")
                                self.activeFriendSessions.removeValue(forKey: sessionId)
                            }

                            // Now add/update valid sessions
                            for (id, session) in validSessions {
                                self.activeFriendSessions[id] = session
                            }

                            // Force a UI update
                            self.objectWillChange.send()
                        }
                    }
            }
    }
    private func parseLiveSessionDocument(_ document: DocumentSnapshot) -> LiveSessionData? {
        guard document.exists else { return nil }

        let data = document.data() ?? [:]

        // Required fields with strong validation
        guard let starterId = data["starterId"] as? String, !starterId.isEmpty,
            let participants = data["participants"] as? [String], !participants.isEmpty,
            let startTimestamp = data["startTime"] as? Timestamp,
            let targetDuration = data["targetDuration"] as? Int, targetDuration > 0
        else {
            print("Missing or invalid required fields in session document \(document.documentID)")
            return nil
        }

        // Get starter username with fallback
        let starterUsername = (data["starterUsername"] as? String) ?? "User"

        // For remaining fields, use safe defaults with nil coalescing
        let remainingSeconds = (data["remainingSeconds"] as? Int) ?? (targetDuration * 60)
        let isPaused = (data["isPaused"] as? Bool) ?? false
        let allowPauses = (data["allowPauses"] as? Bool) ?? false
        let maxPauses = (data["maxPauses"] as? Int) ?? 0

        // Safely handle join times with defaults
        let joinTimesData =
            (data["joinTimes"] as? [String: Timestamp]) ?? [starterId: startTimestamp]
        let participantStatusData =
            (data["participantStatus"] as? [String: String]) ?? [
                starterId: ParticipantStatus.active.rawValue
            ]
        let lastUpdateTimestamp = (data["lastUpdateTime"] as? Timestamp) ?? startTimestamp

        // Convert join times
        var joinTimes: [String: Date] = [:]
        for (userId, timestamp) in joinTimesData { joinTimes[userId] = timestamp.dateValue() }

        // Convert participant status
        var participantStatus: [String: ParticipantStatus] = [:]
        for (userId, status) in participantStatusData {
            if let statusEnum = ParticipantStatus(rawValue: status) {
                participantStatus[userId] = statusEnum
            }
            else {
                // Default to active if invalid status
                participantStatus[userId] = .active
            }
        }

        return LiveSessionData(
            id: document.documentID,
            starterId: starterId,
            starterUsername: starterUsername,
            participants: participants,
            startTime: startTimestamp.dateValue(),
            targetDuration: targetDuration,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused,
            allowPauses: allowPauses,
            maxPauses: maxPauses,
            joinTimes: joinTimes,
            participantStatus: participantStatus,
            lastUpdateTime: lastUpdateTimestamp.dateValue()
        )
    }
    // In LiveSessionManager.swift, improve the joinSession method
    // REFACTORED joinSession method
    func joinSession(sessionId: String, completion: @escaping (Bool, Int, Int) -> Void) {
        // Ensure Firebase is initialized (redundant check, but safe)
        if FirebaseApp.app() == nil {
            print("Firebase not initialized. Attempting to configure.")
            FirebaseApp.configure()
        }

        // 1. Check Authentication State
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated, cannot join session")
            DispatchQueue.main.async {
                self.isJoiningSession = false // Ensure flag is reset
                completion(false, 0, 0)
            }
            return
        }

        // Set joining flag immediately on main thread
        DispatchQueue.main.async {
            self.isJoiningSession = true
        }

        // 2. Fetch Session Document
        db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let self = self else {
                    // If self is nil, reset flag and complete
                    DispatchQueue.main.async {
                        // Assuming isJoiningSession is static or accessed via shared instance if self is nil
                        // LiveSessionManager.shared.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Handle fetch errors
                if let error = error {
                    print("Error fetching session document: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Check if document exists
                guard let document = document, document.exists else {
                    print("Session document doesn't exist: \(sessionId)")
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // 3. Parse Session Data (Safely)
                guard let sessionData = self.parseLiveSessionDocument(document) else {
                    print("Failed to parse session document: \(sessionId)")
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Store necessary values locally before async checks
                let safeStarterId = sessionData.starterId
                let safeStarterUsername = sessionData.starterUsername
                let safeSessionId = sessionData.id // Use ID from parsed data

                // 4. Perform Join Checks (Cannot join own, Stale, Joinable, Friend Restriction)

                // Cannot join own session
                if safeStarterId == userId {
                    print("Cannot join your own session (starterId == userId)")
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Session is stale (last update > 2 mins ago)
                let lastUpdateTime = sessionData.lastUpdateTime
                if Date().timeIntervalSince(lastUpdateTime) > 120 {
                    print("Session is stale - last update was too long ago")
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Session not joinable (full or time too low)
                if !sessionData.canJoin {
                    print(
                        "Session cannot be joined: full=\(sessionData.isFull), time_remaining=\(sessionData.remainingSeconds)"
                    )
                    DispatchQueue.main.async {
                        self.isJoiningSession = false
                        completion(false, 0, 0)
                    }
                    return
                }

                // Check friend restriction asynchronously
                self.checkFriendRestriction(starterId: safeStarterId) { isAllowed in
                    if !isAllowed {
                        print("Session is restricted to friends only and user is not a friend")
                        DispatchQueue.main.async {
                            self.isJoiningSession = false
                            completion(false, 0, 0)
                        }
                        return
                    }

                    // --- All Checks Passed ---

                    print("Checks passed for session \(safeSessionId), proceeding to join.")

                    // 5. Call Completion Immediately on Main Thread
                    // Create copies of necessary data for the completion handler
                    let finalRemainingSeconds = sessionData.remainingSeconds
                    let finalTargetDuration = sessionData.targetDuration // AppManager needs this? Or calculates based on remaining? Let's pass original for now.
                    let finalSessionData = sessionData // Pass the whole data for AppManager

                    DispatchQueue.main.async {
                        // Set AppManager properties needed before calling completion
                        AppManager.shared.shouldShowFriendRequestName = safeStarterUsername
                        AppManager.shared.originalSessionStarter = safeStarterId

                        // Update local state
                        self.currentJoinedSession = finalSessionData // Update with the validated data
                        self.listenToJoinedSession(sessionId: safeSessionId) // Start listener

                        // Reset joining flag
                        self.isJoiningSession = false
                        self.objectWillChange.send() // Notify UI

                        // Post notification
                        NotificationCenter.default.post(
                            name: Notification.Name("LiveSessionJoined"),
                            object: nil
                        )

                        // Call completion to trigger AppManager state change
                        completion(
                            true,
                            finalRemainingSeconds,
                            finalTargetDuration // Pass original duration
                        )
                        print("Completion handler called for session join.")
                    }

                    // 6. Update Firestore Asynchronously in Background
                    DispatchQueue.global(qos: .background).async {
                        // Get fresh user ID inside background task
                        guard let backgroundUserId = Auth.auth().currentUser?.uid else {
                            print("Background Task: User ID became nil, cannot update Firestore.")
                            return
                        }

                        var updatedParticipants = sessionData.participants
                        if !updatedParticipants.contains(backgroundUserId) {
                            updatedParticipants.append(backgroundUserId)
                        }

                        let now = Date()
                        let updateData: [String: Any] = [
                            "participants": updatedParticipants,
                            "joinTimes.\(backgroundUserId)": Timestamp(date: now),
                            "participantStatus.\(backgroundUserId)": ParticipantStatus.active.rawValue,
                            "lastUpdateTime": FieldValue.serverTimestamp(), // Use server time for consistency
                        ]

                        self.db.collection("live_sessions").document(safeSessionId)
                            .updateData(updateData) { error in
                                if let error = error {
                                    print(
                                        "Background Task: Error updating session \(safeSessionId): \(error.localizedDescription)"
                                    )
                                } else {
                                    print(
                                        "Background Task: Successfully updated session \(safeSessionId) for user \(backgroundUserId)"
                                    )
                                }
                            }
                    }
                } // End of checkFriendRestriction completion
            } // End of getDocument completion
    }
    private var cleanupTimer: Timer?

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.cleanupStaleSessions()
        }
        RunLoop.current.add(cleanupTimer!, forMode: .common)
    }

    private func cleanupStaleSessions() {
        // Find sessions that should be ended based on time
        let staleSessions = activeFriendSessions.filter { _, session in
            // A session is stale if:
            // 1. It's over (remaining time ≤ 0)
            // 2. Last update was more than 1 minute ago (reduced from 2 minutes)
            // 3. If all participants have completed or failed status
            // 4. If the session end time has passed

            let timeThreshold = Date().addingTimeInterval(-60)  // 1 minute ago

            // Check if all participants have completed or failed
            let allParticipantsFinished = session.participants.allSatisfy { participantId in
                if let status = session.participantStatus[participantId] {
                    return status == .completed || status == .failed
                }
                return false
            }

            // Calculate if session has naturally ended based on duration
            let sessionEndTime = session.startTime.addingTimeInterval(
                TimeInterval(session.targetDuration * 60)
            )
            let isSessionEnded = Date() > sessionEndTime

            return session.remainingSeconds <= 0 || session.lastUpdateTime < timeThreshold
                || allParticipantsFinished || isSessionEnded
        }

        // Remove stale sessions from the local map
        for (sessionId, _) in staleSessions {
            print("Removing stale session: \(sessionId)")
            DispatchQueue.main.async { self.activeFriendSessions.removeValue(forKey: sessionId) }

            // Also remove any session listeners for this session
            // Use listenerQueue for safe access
            listenerQueue.async { // Use async to avoid blocking the cleanup timer thread
                if let listener = self.sessionListeners.removeValue(forKey: sessionId) {
                    listener.remove()
                    print("Removed listener via cleanup for session: \(sessionId)")
                }
            }

            // Also remove from Firestore if it appears to be completed
            db.collection("live_sessions").document(sessionId)
                .delete { error in
                    if let error = error {
                        print("Error deleting stale session: \(error.localizedDescription)")
                    }
                    else {
                        print("Successfully deleted stale session: \(sessionId)")
                    }
                }
        }

        // Force UI update after cleaning up
        if !staleSessions.isEmpty { DispatchQueue.main.async { self.objectWillChange.send() } }
    }

    func listenToJoinedSession(sessionId: String) {
        print("Setting up listener for session: \(sessionId)")
        
        // CRITICAL: Safety check - don't proceed with empty session ID
        guard !sessionId.isEmpty else {
            print("ERROR: Cannot listen to session with empty ID")
            return
        }
        
        // Use the instance listenerQueue for thread safety
        listenerQueue.sync { // Use sync to ensure listener is setup before function returns? Or async? Let's try sync first.
            // Remove any existing listener for this specific session ID
            if let existingListener = self.sessionListeners.removeValue(forKey: sessionId) {
                existingListener.remove()
                print("Removed existing listener before adding new one for session: \(sessionId)")
            }
            
            // Create new listener with robust error handling
            // No need for try-catch here, addSnapshotListener doesn't throw Swift errors directly
            let listener = db.collection("live_sessions").document(sessionId)
                .addSnapshotListener { [weak self] document, error in
                    guard let self = self else {
                        print("Self reference lost in session listener for \(sessionId)")
                        // Consider removing the listener if self is gone? Might require accessing sessionListeners again.
                        return
                    }

                    // Process all Firestore results on a background queue first
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Handle errors
                        if let error = error {
                            print("Error listening to session \(sessionId): \(error.localizedDescription)")
                            // Check if the error indicates the document was deleted
                            if let firestoreError = error as NSError?, firestoreError.code == FirestoreErrorCode.notFound.rawValue {
                                print("Session document \(sessionId) not found (deleted?). Removing listener.")
                                self.stopTrackingSession(sessionId: sessionId) // Stop tracking if doc deleted
                            } else {
                                // For other errors, maybe just clear the session data?
                                DispatchQueue.main.async {
                                    if self.currentJoinedSession?.id == sessionId {
                                        self.currentJoinedSession = nil
                                        self.objectWillChange.send()
                                    }
                                }
                            }
                            return
                        }

                        // Check document exists
                        guard let document = document, document.exists else {
                            print("Session document no longer exists: \(sessionId). Removing listener.")
                            self.stopTrackingSession(sessionId: sessionId) // Stop tracking if doc deleted
                            return
                        }

                        // Parse document on background thread with better error handling
                        let optionalSessionData = self.parseLiveSessionDocument(document)
                        guard let sessionData = optionalSessionData else {
                            print("Failed to parse session document for \(sessionId).")
                            // Don't clear currentJoinedSession here, maybe just log?
                            // Or clear if parsing consistently fails?
                            return
                        }

                        // Make a thread-safe copy
                        let safeCopy = sessionData

                        // Update UI on main thread
                        DispatchQueue.main.async {
                            // Only update if this is still the session we care about
                            guard self.currentJoinedSession?.id == sessionId else {
                                // No longer tracking this session, maybe listener removal was delayed?
                                print("Listener update received for \(sessionId), but no longer the current joined session.")
                                // Attempt to remove listener again just in case
                                self.listenerQueue.async {
                                    if let listener = self.sessionListeners[sessionId] {
                                        listener.remove()
                                        self.sessionListeners.removeValue(forKey: sessionId)
                                        print("Cleaned up listener for non-current session \(sessionId)")
                                    }
                                }
                                return
                            }
                            
                            // Check if session is stale before updating
                            // Use a shorter timeout within the listener? Maybe 60s?
                            let isStale = Date().timeIntervalSince(safeCopy.lastUpdateTime) > 120 // Keep 2 mins for now

                            if isStale {
                                print("Session \(sessionId) is stale (listener update). Stopping tracking.")
                                self.stopTrackingSession(sessionId: sessionId) // Also removes listener internally
                            } else {
                                // Update with our safe copy
                                if self.currentJoinedSession != safeCopy { // Avoid redundant updates
                                    self.currentJoinedSession = safeCopy
                                    self.objectWillChange.send()
                                    print("Updated currentJoinedSession for \(sessionId)")
                                }
                            }
                        }
                    }
                } // End of addSnapshotListener closure

            // Store the listener safely using the instance queue
            // No nested sync needed here.
            self.sessionListeners[sessionId] = listener
            print("Successfully set up listener using instance queue for session: \(sessionId)")

        } // End of listenerQueue.sync
    }

    func updateParticipantStatus(sessionId: String, userId: String, status: ParticipantStatus) {
        let updateData: [String: Any] = [
            "participantStatus.\(userId)": status.rawValue,
            "lastUpdateTime": FieldValue.serverTimestamp(),
        ]

        db.collection("live_sessions").document(sessionId).updateData(updateData)
    }

    func endSession(sessionId: String, userId: String, wasSuccessful: Bool) {
        // Update participant status first
        let status: ParticipantStatus = wasSuccessful ? .completed : .failed
        updateParticipantStatus(sessionId: sessionId, userId: userId, status: status)
        print("Setting participant \(userId) status to \(status.rawValue) for session \(sessionId)")

        // Check if all participants have completed/failed
        db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let document = document, document.exists,
                    let sessionData = self?.parseLiveSessionDocument(document)
                else { return }

                // Check if all participants have a terminal status
                let allCompleted = sessionData.participants.allSatisfy { participantId in
                    if let status = sessionData.participantStatus[participantId] {
                        return status == .completed || status == .failed
                    }
                    return false
                }

                // If everyone is done, clean up the session
                if allCompleted {
                    print("All participants have finished session \(sessionId), scheduling cleanup")
                    // Session is complete, can be removed after a delay to allow UI views to finish
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        print("Removing completed session \(sessionId) from Firestore")
                        self?.db.collection("live_sessions").document(sessionId)
                            .delete { error in
                                if let error = error {
                                    print(
                                        "Error deleting completed session: \(error.localizedDescription)"
                                    )
                                }
                                else {
                                    print("Successfully deleted completed session \(sessionId)")
                                }
                            }
                    }
                }
                else {
                    print("Some participants still active in session \(sessionId)")
                    // Log who is still active
                    for participantId in sessionData.participants {
                        let status =
                            sessionData.participantStatus[participantId]?.rawValue ?? "unknown"
                        print("Participant \(participantId): \(status)")
                    }
                }
            }
    }
    func getSessionDetails(sessionId: String, completion: @escaping (LiveSessionData?) -> Void) {
        db.collection("live_sessions").document(sessionId)
            .getDocument { document, error in
                if let error = error {
                    print("Error fetching session details: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                if let document = document, document.exists {
                    if let sessionData = self.parseLiveSessionDocument(document) {
                        // Check if the session is valid (has actually started)
                        let data = document.data() ?? [:]
                        // Check for "isComplete" field that indicates session ended
                        if let isComplete = data["isComplete"] as? Bool, isComplete {
                            print("Session \(sessionId) is marked as complete, cannot join")
                            completion(nil)
                            return
                        }
                        // Calculate if session has naturally ended based on duration
                        let sessionEndTime = sessionData.startTime.addingTimeInterval(
                            TimeInterval(sessionData.targetDuration * 60)
                        )
                        let isSessionEnded = Date() > sessionEndTime
                        // Check how old the last update is
                        let isSessionStale =
                            Date().timeIntervalSince(sessionData.lastUpdateTime) > 60  // Over 1 minute

                        // Check if session ended or is stale
                        if isSessionEnded || isSessionStale || sessionData.remainingSeconds <= 0 {
                            print(
                                "Session \(sessionId) is no longer active: ended=\(isSessionEnded), stale=\(isSessionStale), remaining=\(sessionData.remainingSeconds)"
                            )
                            completion(nil)
                            return
                        }
                        DispatchQueue.main.async { completion(sessionData) }
                    }
                    else {
                        print("Failed to parse session data for \(sessionId)")
                        completion(nil)
                    }
                }
                else {
                    print("Session document doesn't exist: \(sessionId)")
                    completion(nil)
                }
            }
    }

    func refreshLiveSessions() {
        print("Refreshing live sessions...")

        // Clean up stale sessions first
        cleanupStaleSessions()

        // Re-fetch active sessions with a fresh query
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID available for refreshing sessions")
            return
        }

        // Get user's friends
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self),
                    let self = self
                else {
                    print("Could not load user data for refreshing sessions")
                    return
                }

                // Get all friend IDs
                let friendIds = userData.friends

                if friendIds.isEmpty {
                    print("No friends to refresh sessions for")
                    DispatchQueue.main.async {
                        self.activeFriendSessions = [:]
                        self.objectWillChange.send()
                    }
                    return
                }

                print("Refreshing sessions for \(friendIds.count) friends")

                // Force a new query instead of relying solely on listeners
                self.db.collection("live_sessions")
                    .whereField("participants", arrayContainsAny: friendIds)
                    .getDocuments { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print(
                                "Error fetching live sessions: \(error?.localizedDescription ?? "Unknown error")"
                            )
                            return
                        }

                        // Process session documents
                        DispatchQueue.main.async {
                            var newActiveSessions: [String: LiveSessionData] = [:]

                            for document in documents {
                                if let sessionData = self.parseLiveSessionDocument(document) {
                                    // Filter out sessions that have ended or are too old
                                    let sessionEndTime = sessionData.startTime.addingTimeInterval(
                                        TimeInterval(sessionData.targetDuration * 60)
                                    )
                                    let isSessionOver = Date() > sessionEndTime
                                    let isSessionTooOld =
                                        Date().timeIntervalSince(sessionData.lastUpdateTime) > 300  // 5 minutes

                                    if !isSessionOver && !isSessionTooOld
                                        && sessionData.remainingSeconds > 0
                                    {
                                        newActiveSessions[document.documentID] = sessionData
                                        print(
                                            "Added active session: \(document.documentID), remaining: \(sessionData.remainingSeconds)s"
                                        )
                                    }
                                    else {
                                        print(
                                            "Filtered out session \(document.documentID): over=\(isSessionOver), tooOld=\(isSessionTooOld)"
                                        )
                                    }
                                }
                            }

                            // Update sessions and notify observers
                            self.activeFriendSessions = newActiveSessions
                            self.objectWillChange.send()
                            print("Updated to \(newActiveSessions.count) active friend sessions")
                        }
                    }
            }

        // If we're in a session, ensure it's still updated
        if let sessionId = currentJoinedSession?.id { listenToJoinedSession(sessionId: sessionId) }
    }

    func stopTrackingSession(sessionId: String) {
        print("Explicitly stopping tracking for session: \(sessionId)")
        DispatchQueue.main.async { // UI updates on main thread
            // Reset current joined session if it matches
            if self.currentJoinedSession?.id == sessionId {
                self.currentJoinedSession = nil
                print("Cleared currentJoinedSession")
            }
            // Remove the session from active tracking (if it was a friend's session)
            if self.activeFriendSessions.removeValue(forKey: sessionId) != nil {
                 print("Removed session from activeFriendSessions")
            }
            // Force update UI
            self.objectWillChange.send()
        }

        // Remove listener using the dedicated queue
        listenerQueue.async { // Use async to avoid blocking caller
            if let listener = self.sessionListeners.removeValue(forKey: sessionId) {
                listener.remove()
                print("Removed listener via stopTrackingSession for session: \(sessionId)")
            } else {
                print("No listener found to remove for session \(sessionId) in stopTrackingSession")
            }
        }
    }

    // 5. Set up notification handler for refresh
    @objc private func handleRefreshNotification() { refreshLiveSessions() }

    // Make sure to update deinit
    deinit {
        cleanupListeners()
        cleanupTimer?.invalidate()
        cleanupTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    func cleanupListeners() {
        print("Cleaning up all live session listeners using listenerQueue")
        // Use the queue to safely access and remove listeners
        listenerQueue.sync { // Use sync here as it's part of deinit
            for (id, listener) in self.sessionListeners {
                listener.remove()
                print("Removed listener for session: \(id) during cleanup")
            }
            self.sessionListeners.removeAll()
        }
        // Reset tracked sessions (safe to do outside queue as it's UI related)
        DispatchQueue.main.async {
             self.currentJoinedSession = nil
             self.activeFriendSessions = [:]
             self.objectWillChange.send() // Notify UI if needed during cleanup phase
        }
    }
    // NEW: Check if user is allowed to join a session based on friend restrictions
    private func checkFriendRestriction(starterId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        // Always allow if it's your own session
        if starterId == currentUserId {
            completion(true)
            return
        }
        // Get session starter's settings to check if they've restricted sessions to friends
        db.collection("user_settings").document(starterId)
            .getDocument { document, error in
                // Default to allowing if there's an error or settings don't exist
                guard let data = document?.data() else {
                    completion(true)
                    return
                }
                // Check if starter has restricted sessions to friends
                let restrictedToFriends = data["restrictLiveSessionsToFriends"] as? Bool ?? false
                if restrictedToFriends {
                    // If restricted, check if current user is a friend of the starter
                    self.db.collection("users").document(starterId)
                        .getDocument { document, error in
                            guard
                                let userData = try? document?
                                    .data(as: FirebaseManager.FlipUser.self)
                            else {
                                completion(false)
                                return
                            }
                            // Allow if current user is in the starter's friends list
                            let isFriend = userData.friends.contains(currentUserId)
                            completion(isFriend)
                        }
                }
                else {
                    // Not restricted, allow anyone to join
                    completion(true)
                }
            }
    }

    // Method to get live sessions for a specific building
    func getBuildingLiveSessions(
        buildingId: String,
        completion: @escaping ([LiveSessionData]) -> Void
    ) {
        // Prevent retrieving sessions if building ID is empty
        guard !buildingId.isEmpty else {
            completion([])
            return
        }
        // Get current user ID to filter out own sessions
        let currentUserId = Auth.auth().currentUser?.uid
        // Query sessions by building ID
        let query = db.collection("live_sessions").whereField("buildingId", isEqualTo: buildingId)
            .whereField("status", isEqualTo: "active")
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion([])
                return
            }
            if let error = error {
                print("Error fetching building live sessions: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            // Parse the session documents
            let sessions = documents.compactMap { document -> LiveSessionData? in
                guard let session = self.parseLiveSessionDocument(document) else { return nil }
                // Skip first-time users' sessions and own sessions
                if session.starterId == currentUserId { return nil }
                // Check if session can be joined
                if !session.canJoin { return nil }
                // Return valid session
                return session
            }
            print("Found \(sessions.count) live sessions in building \(buildingId)")
            // Sort by start time (most recent first)
            let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }
            completion(sortedSessions)
        }
    }
    // Update session creation to include building information
    func startSession(sessionId: String, appManager: AppManager, building: BuildingInfo?) {
        guard let userId = Auth.auth().currentUser?.uid,
            let username = FirebaseManager.shared.currentUser?.username
        else { return }
        let now = Date()
        // Get values from AppManager
        let targetDuration = appManager.selectedMinutes
        let remainingSeconds =
            appManager.remainingSeconds > 0 ? appManager.remainingSeconds : targetDuration * 60
        let isPaused = appManager.isPaused
        let allowPauses = appManager.allowPauses
        let maxPauses = appManager.maxPauses
        let pauseDuration = appManager.pauseDuration
        // Create base session data
        var sessionData: [String: Any] = [
            "starterId": userId, "starterUsername": username, "participants": [userId],
            "startTime": Timestamp(date: now), "targetDuration": targetDuration,
            "remainingSeconds": remainingSeconds, "isPaused": isPaused, "allowPauses": allowPauses,
            "maxPauses": maxPauses, "pauseDuration": pauseDuration,
            "joinTimes": [userId: Timestamp(date: now)],
            "participantStatus": [userId: ParticipantStatus.active.rawValue],
            "lastUpdateTime": Timestamp(date: now), "status": "active",
        ]
        // Add building information if available
        if let building = building {
            sessionData["buildingId"] = building.id
            sessionData["buildingName"] = building.name
            sessionData["buildingLatitude"] = building.coordinate.latitude
            sessionData["buildingLongitude"] = building.coordinate.longitude
        }
        // Create session in Firestore
        db.collection("live_sessions").document(sessionId)
            .setData(sessionData) { error in
                if let error = error {
                    print(
                        "Error creating live session with building info: \(error.localizedDescription)"
                    )
                }
                else {
                    print("Live session created successfully with building info")
                }
            }
    }
}
