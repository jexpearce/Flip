import Foundation
import SwiftUI
import FirebaseFirestore

struct FirstTimeLeaderboard: Identifiable {
    let id: String
    let username: String
    let duration: Int
    let wasSuccessful: Bool
    let timestamp: Date
    let rank: Int
    
    var isCurrentUser: Bool = false
}

class FirstTimeLeaderboardManager: ObservableObject {
    static let shared = FirstTimeLeaderboardManager()
    private let db = Firestore.firestore()
    
    @Published var isLoading = false
    @Published var leaderboardEntries: [FirstTimeLeaderboard] = []
    @Published var userRank: Int = 0
    @Published var totalUsers: Int = 0
    @Published var userEntry: FirstTimeLeaderboard?
    
    // Check if this is a user's first session
    func isFirstSession(userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking first session: \(error)")
                    completion(true) // Default to true on error to show the experience
                    return
                }
                
                // If there are no documents, this is their first session
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    // Save first session to leaderboard
    func saveFirstSession(userId: String, username: String, duration: Int, wasSuccessful: Bool, completion: @escaping (Bool) -> Void) {
        // First check if a first session already exists to prevent duplicates
        db.collection("first_sessions")
            .document(userId)
            .getDocument { [weak self] document, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                // If document already exists, we don't need to save it again
                if let document = document, document.exists {
                    print("First session already exists, not saving again")
                    completion(true)
                    return
                }
                
                // Proceed with saving since it doesn't exist yet
                let firstSessionData: [String: Any] = [
                    "userId": userId,
                    "username": username,
                    "duration": duration,
                    "wasSuccessful": wasSuccessful,
                    "timestamp": FieldValue.serverTimestamp()
                ]
                
                self.db.collection("first_sessions")
                    .document(userId)
                    .setData(firstSessionData) { error in
                        if let error = error {
                            print("Error saving first session: \(error)")
                            completion(false)
                            return
                        }
                        
                        print("First session saved successfully to leaderboard")
                        completion(true)
                        
                        // After saving, recalculate the rankings in the background
                        self.recalculateRankings()
                    }
            }
    }
    
    // Recalculate all rankings (this would be better handled by a server function)
    private func recalculateRankings() {
        db.collection("first_sessions")
            .order(by: "duration", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    return
                }
                
                // This is a basic client-side ranking. In a production app,
                // you'd want to do this on the server side with Cloud Functions.
                var batch = self.db.batch()
                var count = 0
                
                for (index, doc) in documents.enumerated() {
                    let rank = index + 1
                    batch.updateData(["rank": rank], forDocument: doc.reference)
                    
                    count += 1
                    
                    // Firestore limits batches to 500 operations
                    if count >= 450 {
                        // Commit batch and create a new one
                        batch.commit()
                        batch = self.db.batch()
                        count = 0
                    }
                }
                
                // Commit final batch
                if count > 0 {
                    batch.commit()
                }
            }
    }
    
    // Fetch leaderboard entries surrounding the user's position
    func fetchLeaderboardAroundUser(userId: String, range: Int = 3, completion: @escaping (Bool) -> Void) {
        self.isLoading = true
        print("Fetching leaderboard data for user: \(userId)")
        
        // First get the user's entry to find their rank
        db.collection("first_sessions")
            .document(userId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching user rank: \(error)")
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let duration = data["duration"] as? Int,
                      let username = data["username"] as? String,
                      let wasSuccessful = data["wasSuccessful"] as? Bool else {
                    print("No user data found in first_sessions or missing required fields")
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                print("Found user data in first_sessions: \(data)")
                
                // Query to get the total count of users
                self.db.collection("first_sessions").getDocuments { [weak self] countSnapshot, countError in
                    guard let self = self else { return }
                    
                    if let countError = countError {
                        print("Error getting total count: \(countError)")
                    } else {
                        self.totalUsers = countSnapshot?.documents.count ?? 0
                        print("Total users in leaderboard: \(self.totalUsers)")
                    }
                    
                    // If we don't have a rank calculated yet, we need to calculate based on duration
                    let userDuration = duration
                    
                    // Query to get users with higher durations (to calculate rank)
                    self.db.collection("first_sessions")
                        .whereField("duration", isGreaterThan: userDuration)
                        .getDocuments { [weak self] higherSnapshot, higherError in
                            guard let self = self else { return }
                            
                            if let higherError = higherError {
                                print("Error calculating rank: \(higherError)")
                                self.isLoading = false
                                completion(false)
                                return
                            }
                            
                            // User's rank is number of users with higher duration + 1
                            let higherCount = higherSnapshot?.documents.count ?? 0
                            let userRank = higherCount + 1
                            self.userRank = userRank
                            print("Calculated user rank: \(userRank)")
                            
                            // Create the user's entry
                            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            let userEntry = FirstTimeLeaderboard(
                                id: userId,
                                username: username,
                                duration: duration,
                                wasSuccessful: wasSuccessful,
                                timestamp: timestamp,
                                rank: userRank,
                                isCurrentUser: true
                            )
                            self.userEntry = userEntry
                            
                            // Now fetch entries around the user's rank
                            self.fetchEntriesAroundRank(userRank: userRank, range: range) { success in
                                self.isLoading = false
                                completion(success)
                            }
                        }
                }
            }
    }
    
    // Helper method to fetch entries around a specific rank
    private func fetchEntriesAroundRank(userRank: Int, range: Int, completion: @escaping (Bool) -> Void) {
        // This is a simplified approach. In a real app with many users,
        // you'd want a more efficient query strategy.
        
        // Get entries ordered by duration (highest first)
        db.collection("first_sessions")
            .order(by: "duration", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching leaderboard: \(error)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in leaderboard query")
                    completion(false)
                    return
                }
                
                print("Fetched \(documents.count) entries for leaderboard")
                
                var entries: [FirstTimeLeaderboard] = []
                var userIndex = -1
                
                // Create entries and find user's position
                for (index, document) in documents.enumerated() {
                    guard let data = document.data() as [String: Any]?,
                          let username = data["username"] as? String,
                          let duration = data["duration"] as? Int,
                          let wasSuccessful = data["wasSuccessful"] as? Bool else {
                        continue
                    }
                    
                    let rank = index + 1
                    let userId = document.documentID
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    
                    // Check if this is our user
                    let isCurrentUser = (rank == userRank)
                    if isCurrentUser {
                        userIndex = index
                    }
                    
                    let entry = FirstTimeLeaderboard(
                        id: userId,
                        username: username,
                        duration: duration,
                        wasSuccessful: wasSuccessful,
                        timestamp: timestamp,
                        rank: rank,
                        isCurrentUser: isCurrentUser
                    )
                    
                    entries.append(entry)
                }
                
                // If we found the user, extract the range around them
                if userIndex >= 0 {
                    let startIndex = max(0, userIndex - range)
                    let endIndex = min(entries.count - 1, userIndex + range)
                    
                    self.leaderboardEntries = Array(entries[startIndex...endIndex])
                    print("Found user at index \(userIndex), showing entries \(startIndex) to \(endIndex)")
                } else if !entries.isEmpty {
                    // If we didn't find the user but have entries, just take the top ones
                    self.leaderboardEntries = Array(entries.prefix(range * 2 + 1))
                    print("User not found in entries, showing top \(self.leaderboardEntries.count) entries")
                }
                
                completion(true)
            }
    }
}

struct FirstTimeLeaderboardView: View {
    @ObservedObject private var leaderboardManager = FirstTimeLeaderboardManager.shared
    @State private var showEntries = false
    @State private var slideInUser = false
    @State private var glowUser = false
    
    let userId: String
    let username: String
    let duration: Int
    let wasSuccessful: Bool
    
    init(userId: String, username: String, duration: Int, wasSuccessful: Bool) {
        self.userId = userId
        self.username = username
        self.duration = duration
        self.wasSuccessful = wasSuccessful
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Title
            VStack(spacing: 4) {
                Text("FIRST SESSION ACHIEVEMENT")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                
                Text("GLOBAL FIRST FLIP LEADERBOARD")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            
            if leaderboardManager.isLoading {
                // Loading state
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                        .padding(.bottom, 8)
                    
                    Text("Ranking your achievement...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(height: 180)
            } else {
                // User's rank summary
                VStack(spacing: 8) {
                    Text("Your First Flip")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        // Trophy or medal icon
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 250/255, green: 204/255, blue: 21/255),
                                        Color(red: 220/255, green: 170/255, blue: 0/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.5), radius: 5)
                        
                        // Rank text with colorful gradient
                        Text("#\(leaderboardManager.userRank)")
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 250/255, green: 204/255, blue: 21/255),
                                        Color(red: 220/255, green: 170/255, blue: 0/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.5), radius: 5)
                    }
                    
                    Text("out of \(leaderboardManager.totalUsers) Flippers")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 4)
                
                // Leaderboard entries
                VStack(spacing: 0) {
                    // Column headers
                    HStack {
                        Text("RANK")
                            .frame(width: 50, alignment: .center)
                        
                        Text("USER")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("TIME")
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                    
                    // Leaderboard rows
                    ForEach(Array(leaderboardManager.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                        LeaderboardRow(entry: entry, index: index, slideInUser: $slideInUser, glowUser: $glowUser)
                            .opacity(showEntries ? 1 : 0)
                            .offset(y: showEntries ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5)
                                .delay(Double(index) * 0.1),
                                value: showEntries
                            )
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 60/255, green: 30/255, blue: 110/255).opacity(0.4),
                                Color(red: 40/255, green: 20/255, blue: 80/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8)
        .onAppear {
            print("FirstTimeLeaderboardView appeared for user \(userId)")
            
            // Only fetch leaderboard data, don't try to save session again
            // Session has already been saved by FirebaseManager.recordFirstSession in the parent view
            leaderboardManager.fetchLeaderboardAroundUser(userId: userId) { success in
                if success {
                    print("Successfully fetched leaderboard data")
                    // Animate the entries in sequence
                    withAnimation(.easeOut(duration: 0.5)) {
                        showEntries = true
                    }
                    
                    // Add a slight delay before animating the user's entry
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            slideInUser = true
                        }
                        
                        // Start the glow animation after sliding in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                glowUser = true
                            }
                        }
                    }
                } else {
                    print("Failed to fetch leaderboard data")
                }
            }
        }
    }
}

struct LeaderboardRow: View {
    let entry: FirstTimeLeaderboard
    let index: Int
    @Binding var slideInUser: Bool
    @Binding var glowUser: Bool
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.system(size: 14, weight: entry.isCurrentUser ? .black : .bold))
                .foregroundColor(entry.isCurrentUser ? Color(red: 250/255, green: 204/255, blue: 21/255) : .white)
                .frame(width: 50, alignment: .center)
            
            // Username
            Text(entry.username)
                .font(.system(size: 14, weight: entry.isCurrentUser ? .black : .medium))
                .foregroundColor(entry.isCurrentUser ? .white : .white.opacity(0.9))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Duration (time)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.duration)")
                    .font(.system(size: 16, weight: entry.isCurrentUser ? .black : .bold))
                
                Text("min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(entry.isCurrentUser ? .white.opacity(0.9) : .white.opacity(0.7))
            }
            .foregroundColor(entry.isCurrentUser ? Color(red: 250/255, green: 204/255, blue: 21/255) : .white)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            ZStack {
                if entry.isCurrentUser {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 168/255, green: 85/255, blue: 247/255).opacity(0.3),
                                    Color(red: 128/255, green: 65/255, blue: 217/255).opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 250/255, green: 204/255, blue: 21/255).opacity(glowUser ? 0.7 : 0.4),
                                            Color(red: 220/255, green: 170/255, blue: 0/255).opacity(glowUser ? 0.5 : 0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .shadow(
                                    color: Color(red: 250/255, green: 204/255, blue: 21/255).opacity(glowUser ? 0.5 : 0.2),
                                    radius: glowUser ? 6 : 3
                                )
                        )
                        .offset(x: slideInUser ? 0 : 300)
                } else if index % 2 == 1 {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                }
            }
        )
    }
}