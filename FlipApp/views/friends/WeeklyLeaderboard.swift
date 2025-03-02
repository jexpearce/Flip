import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WeeklyLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    
    // Medal colors
    private let goldColor = LinearGradient(
        colors: [Color(red: 255/255, green: 215/255, blue: 0/255), Color(red: 212/255, green: 175/255, blue: 55/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let silverColor = LinearGradient(
        colors: [Color(red: 192/255, green: 192/255, blue: 192/255), Color(red: 169/255, green: 169/255, blue: 169/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let bronzeColor = LinearGradient(
        colors: [Color(red: 205/255, green: 127/255, blue: 50/255), Color(red: 165/255, green: 113/255, blue: 78/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        VStack(spacing: 12) {
            // Title
            HStack {
                Text("WEEKLY LEADERBOARD")
                    .font(.system(size: 14, weight: .black))
                    .tracking(3)
                    .foregroundColor(Color(red: 234/255, green: 179/255, blue: 8/255))
                    .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5), radius: 6)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 234/255, green: 179/255, blue: 8/255),
                                Color(red: 253/255, green: 224/255, blue: 71/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5), radius: 4)
                
                Spacer()
                
                Text("TOTAL FOCUS TIME")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                Text("No sessions recorded this week")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            } else {
                // Leaderboard entries
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.leaderboardEntries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            // Rank with medal indicator
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.white)
                                    .frame(width: 24)
                                
                                // Medal for top 3
                                if index < 3 {
                                    ZStack {
                                        Circle()
                                            .fill(index == 0 ? goldColor : (index == 1 ? silverColor : bronzeColor))
                                            .frame(width: 22, height: 22)
                                        
                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.2), radius: 1)
                                    }
                                }
                            }
                            
                            // Username
                            Text(entry.username)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Duration - now shows total time
                            Text("\(entry.totalTime) min")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color(red: 234/255, green: 179/255, blue: 8/255))
                                .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3), radius: 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 161/255, green: 98/255, blue: 7/255).opacity(0.4),
                                Color(red: 133/255, green: 77/255, blue: 14/255).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .onAppear {
            viewModel.loadLeaderboard()
        }
    }
}

// Updated data model for leaderboard entries
struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let totalTime: Int
}

// ViewModel for Leaderboard
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadLeaderboard() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        // First get the user's friends list
        firebaseManager.db.collection("users").document(currentUserId)
            .getDocument { [weak self] document, error in
                guard let self = self,
                      let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                else {
                    self?.isLoading = false
                    return
                }
                
                // Include user's own ID in the list
                var userIds = userData.friends
                userIds.append(currentUserId)
                
                self.fetchWeeklyTotalFocusTime(for: userIds)
            }
    }
    
    private func fetchWeeklyTotalFocusTime(for userIds: [String]) {
        let calendar = Calendar.current
        let currentDate = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        // Fetch all sessions from this week for these users
        firebaseManager.db.collection("sessions")
            .whereField("userId", in: userIds)
            .whereField("wasSuccessful", isEqualTo: true)
            .order(by: "startTime", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents
                else {
                    self?.isLoading = false
                    return
                }
                
                // Process sessions
                let allSessions = documents.compactMap { document -> Session? in
                    try? document.data(as: Session.self)
                }
                
                // Filter for this week's sessions
                let thisWeeksSessions = allSessions.filter { session in
                    calendar.isDate(session.startTime, inSameWeekAs: weekStart)
                }
                
                // Group by user, sum up total time for each
                var userTotalTimes: [String: (username: String, totalTime: Int)] = [:]
                
                for session in thisWeeksSessions {
                    let userId = session.userId
                    let username = session.username
                    let sessionTime = session.actualDuration
                    
                    if let existingData = userTotalTimes[userId] {
                        // Add to existing total
                        userTotalTimes[userId] = (username, existingData.totalTime + sessionTime)
                    } else {
                        // Create new entry
                        userTotalTimes[userId] = (username, sessionTime)
                    }
                }
                
                // Convert to leaderboard entries and sort
                let entries = userTotalTimes.map { userId, details in
                    LeaderboardEntry(id: userId, username: details.username, totalTime: details.totalTime)
                }.sorted { $0.totalTime > $1.totalTime }
                
                DispatchQueue.main.async {
                    self.leaderboardEntries = entries
                    self.isLoading = false
                }
            }
    }
}