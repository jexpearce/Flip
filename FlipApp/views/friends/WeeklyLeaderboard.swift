import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct WeeklyLeaderboard: View {
    @ObservedObject var viewModel: LeaderboardViewModel
    @State private var isShowingAll = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Rich golden title with icon
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 250/255, green: 204/255, blue: 21/255),
                                Color(red: 234/255, green: 179/255, blue: 8/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6), radius: 8)
                
                Text("WEEKLY CHAMPIONS")
                    .font(.system(size: 18, weight: .black))
                    .tracking(2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 250/255, green: 204/255, blue: 21/255),
                                Color(red: 234/255, green: 179/255, blue: 8/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6), radius: 8)
                
                Spacer()
                
                // Show more/less toggle
                Button(action: {
                    withAnimation(.spring()) {
                        isShowingAll.toggle()
                    }
                }) {
                    Text(isShowingAll ? "Show Less" : "Show All")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .opacity(viewModel.leaderboardEntries.count > 3 ? 1 : 0)
            }
            .padding(.horizontal, 6)
            
            if viewModel.isLoading {
                // Loading indicator
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color(red: 250/255, green: 204/255, blue: 21/255))
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else {
                // Column Headers
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                        .frame(width: 50, alignment: .center)
                    
                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                        .frame(alignment: .leading)
                    
                    Spacer()
                    
                    Text("TIME")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
                        .frame(width: 70, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                
                if viewModel.leaderboardEntries.isEmpty {
                    // Empty State
                    VStack(spacing: 15) {
                        Image(systemName: "crown")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 250/255, green: 204/255, blue: 21/255),
                                        Color(red: 234/255, green: 179/255, blue: 8/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6), radius: 8)
                        
                        Text("No sessions recorded this week")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    // Users List with rich styling
                    LazyVStack(spacing: 10) {
                        let displayEntries = isShowingAll ?
                                             viewModel.leaderboardEntries :
                                             Array(viewModel.leaderboardEntries.prefix(3))
                        
                        ForEach(Array(displayEntries.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                // Rank with medal for top 3
                                if index < 3 {
                                    medalView(for: index)
                                        .frame(width: 50, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, alignment: .center)
                                }
                                
                                // Username
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Focus time
                                Text("\(entry.totalTime)m")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                ZStack {
                                    // Different background for top 3
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: index < 3 ? [
                                                    Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3),
                                                    Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.1)
                                                ] : [
                                                    Color.white.opacity(0.08),
                                                    Color.white.opacity(0.05)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    
                                    // Highlight for current user
                                    if Auth.auth().currentUser?.uid == entry.id {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.7),
                                                        Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.3)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                // Rich golden gradient background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 133/255, green: 77/255, blue: 14/255).opacity(0.3),
                                Color(red: 113/255, green: 63/255, blue: 18/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Glass effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                // Glowing golden border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.6),
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.2), radius: 10)
        .onAppear {
            viewModel.loadLeaderboard()
        }
    }
    
    // Medal view for top 3
    private func medalView(for index: Int) -> some View {
        ZStack {
            // Medal color based on rank
            Image(systemName: "medal.fill")
                .font(.system(size: 22))
                .foregroundStyle(
                    medalGradient(for: index)
                )
                .shadow(color: medalShadowColor(for: index), radius: 4)
        }
    }
    
    // Medal gradients
    private func medalGradient(for index: Int) -> LinearGradient {
        switch index {
        case 0: // Gold
            return LinearGradient(
                colors: [
                    Color(red: 253/255, green: 224/255, blue: 71/255),
                    Color(red: 234/255, green: 179/255, blue: 8/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 1: // Silver
            return LinearGradient(
                colors: [
                    Color(red: 226/255, green: 232/255, blue: 240/255),
                    Color(red: 148/255, green: 163/255, blue: 184/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case 2: // Bronze
            return LinearGradient(
                colors: [
                    Color(red: 217/255, green: 119/255, blue: 6/255),
                    Color(red: 180/255, green: 83/255, blue: 9/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [Color.gray, Color.gray.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // Medal shadow colors
    private func medalShadowColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6)
        case 1: return Color(red: 148/255, green: 163/255, blue: 184/255).opacity(0.6)
        case 2: return Color(red: 180/255, green: 83/255, blue: 9/255).opacity(0.6)
        default: return Color.gray.opacity(0.6)
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
