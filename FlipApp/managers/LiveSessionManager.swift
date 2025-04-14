import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import SwiftUI

class LiveSessionManager: ObservableObject {
    private let updateQueue = DispatchQueue(
        label: "com.flipapp.sessionUpdateQueue",
        attributes: .concurrent
    )
    private let updateSemaphore = DispatchSemaphore(value: 1)
    private static let _shared = LiveSessionManager()
    static var shared: LiveSessionManager { return _shared }

    let db: Firestore
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

        let sessionData: [String: Any] = [
            "starterId": starterId, "starterUsername": starterUsername, "participants": [starterId],
            "startTime": Timestamp(date: now), "targetDuration": targetDuration,
            "remainingSeconds": remainingSeconds, "isPaused": isPaused, "allowPauses": allowPauses,
            "maxPauses": maxPauses, "joinTimes": [starterId: Timestamp(date: now)],
            "participantStatus": [starterId: ParticipantStatus.active.rawValue],
            "lastUpdateTime": Timestamp(date: now),
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
    func joinSession(sessionId: String, completion: @escaping (Bool, Int, Int) -> Void) {
        // Ensure Firebase is initialized
        if FirebaseApp.app() == nil {
            print("Firebase not initialized. Attempting to configure.")
            FirebaseApp.configure()
        }

        guard let userId = Auth.auth().currentUser?.uid,
            let username = FirebaseManager.shared.currentUser?.username
        else {
            print("User not authenticated, cannot join session")
            completion(false, 0, 0)
            return
        }

        isJoiningSession = true

        // Get the session first with better error handling
        db.collection("live_sessions").document(sessionId)
            .getDocument { [weak self] document, error in
                guard let self = self else {
                    print("Self reference lost")
                    completion(false, 0, 0)
                    return
                }

                if let error = error {
                    print("Error fetching session: \(error.localizedDescription)")
                    self.isJoiningSession = false
                    completion(false, 0, 0)
                    return
                }

                guard let document = document, document.exists else {
                    print("Session document doesn't exist")
                    self.isJoiningSession = false
                    completion(false, 0, 0)
                    return
                }

                guard let sessionData = self.parseLiveSessionDocument(document) else {
                    print("Failed to parse session document")
                    self.isJoiningSession = false
                    completion(false, 0, 0)
                    return
                }

                // Check if session can be joined
                if !sessionData.canJoin {
                    print(
                        "Session cannot be joined: full=\(sessionData.isFull), time_remaining=\(sessionData.remainingSeconds)"
                    )
                    self.isJoiningSession = false
                    completion(false, 0, 0)
                    return
                }

                // Proceed with joining (rest of the existing code...)
                // Update session with new participant
                var updatedParticipants = sessionData.participants
                if !updatedParticipants.contains(userId) { updatedParticipants.append(userId) }

                let now = Date()

                let updateData: [String: Any] = [
                    "participants": updatedParticipants,
                    "joinTimes.\(userId)": Timestamp(date: now),
                    "participantStatus.\(userId)": ParticipantStatus.active.rawValue,
                    "lastUpdateTime": FieldValue.serverTimestamp(),
                ]

                self.db.collection("live_sessions").document(sessionId)
                    .updateData(updateData) { error in
                        if let error = error {
                            print("Error joining session: \(error.localizedDescription)")
                            self.isJoiningSession = false
                            completion(false, 0, 0)
                        }
                        else {
                            print("Successfully joined session")

                            // Listen for updates to this session
                            self.listenToJoinedSession(sessionId: sessionId)

                            // Get a fresh copy of the session data
                            self.getSessionDetails(sessionId: sessionId) { updatedData in
                                if let data = updatedData {
                                    // Pass current data to completion handler
                                    DispatchQueue.main.async {
                                        self.isJoiningSession = false
                                        completion(true, data.remainingSeconds, data.targetDuration)
                                    }
                                }
                                else {
                                    self.isJoiningSession = false
                                    completion(
                                        true,
                                        sessionData.remainingSeconds,
                                        sessionData.targetDuration
                                    )
                                }
                            }
                        }
                    }
            }
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
            if let listener = sessionListeners[sessionId] {
                listener.remove()
                sessionListeners.removeValue(forKey: sessionId)
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
        // Remove any existing listener
        if let existingListener = sessionListeners[sessionId] {
            existingListener.remove()
            sessionListeners.removeValue(forKey: sessionId)
        }

        // Create new listener
        let listener = db.collection("live_sessions").document(sessionId)
            .addSnapshotListener { [weak self] document, error in
                guard let document = document, document.exists,
                    let sessionData = self?.parseLiveSessionDocument(document)
                else {
                    DispatchQueue.main.async { self?.currentJoinedSession = nil }
                    return
                }

                DispatchQueue.main.async {
                    self?.currentJoinedSession = sessionData
                    self?.objectWillChange.send()
                }
            }

        // Store the listener
        sessionListeners[sessionId] = listener
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
                    // Session is complete, can be removed after a delay to allow UI views to finish
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        self?.db.collection("live_sessions").document(sessionId).delete()
                    }
                }
            }
    }
    func getSessionDetails(sessionId: String, completion: @escaping (LiveSessionData?) -> Void) {
        db.collection("live_sessions").document(sessionId)
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let sessionData = self.parseLiveSessionDocument(document) {
                        DispatchQueue.main.async { completion(sessionData) }
                    }
                    else {
                        completion(nil)
                    }
                }
                else {
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
        // Remove the session from active tracking
        activeFriendSessions.removeValue(forKey: sessionId)
        currentJoinedSession = nil

        // Remove any listeners for this session
        if let listener = sessionListeners[sessionId] {
            listener.remove()
            sessionListeners.removeValue(forKey: sessionId)
        }

        // Force update UI
        objectWillChange.send()
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
        for (_, listener) in sessionListeners { listener.remove() }
        sessionListeners.removeAll()
    }
}
