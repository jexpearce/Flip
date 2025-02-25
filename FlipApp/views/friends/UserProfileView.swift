import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct UserProfileView: View {
    let user: FirebaseManager.FlipUser
    @State private var showStats = false
    @StateObject private var weeklyViewModel = WeeklySessionListViewModel()
    @StateObject private var scoreManager = ScoreManager.shared
    @State private var userScore: Double = 3.0 // Default starting score
    
    private var weeksLongestSession: Int? {
        return weeklyViewModel.weeksLongestSession > 0 ? weeklyViewModel.weeksLongestSession : nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header with enhanced styling and rank wheel
                HStack(alignment: .top, spacing: 15) {
                    // Rank Circle
                    RankCircle(score: userScore)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text(user.username)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        
                        // Display rank name
                        let rank = getRank(for: userScore)
                        Text(rank.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(rank.color)
                            .shadow(color: rank.color.opacity(0.5), radius: 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Session stats
                HStack(spacing: 40) {
                    StatBox(
                        title: "SESSIONS",
                        value: "\(user.totalSessions)",
                        icon: "timer"
                    )
                    StatBox(
                        title: "FOCUS TIME",
                        value: "\(user.totalFocusTime)m",
                        icon: "clock.fill"
                    )
                }

                // Stats Cards with animation - condensed height
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15
                ) {
                    CondensedStatCard(
                        title: "TOTAL TIME",
                        value: "\(user.totalFocusTime)",
                        unit: "min"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    
                    CondensedStatCard(
                        title: "SESSIONS",
                        value: "\(user.totalSessions)",
                        unit: "total"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    .animation(.spring().delay(0.1), value: showStats)
                    
                    CondensedStatCard(
                        title: "AVG LENGTH",
                        value: user.totalSessions > 0 ? "\(user.totalFocusTime / user.totalSessions)" : "0",
                        unit: "min"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    .animation(.spring().delay(0.2), value: showStats)
                }
                .padding(.horizontal)

                // Enhanced Longest Session Card - Weekly Stats
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("\(user.username)'s LONGEST FLIP OF THE WEEK")
                                .font(.system(size: 12, weight: .black))
                                .tracking(3)
                                .foregroundColor(.white)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
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
                        }

                        Text(weeksLongestSession != nil ? "\(weeksLongestSession!) min" : "No sessions yet this week")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Theme.buttonGradient)
                            .opacity(0.15)
                        
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
                .padding(.horizontal)

                // Recent Sessions
                VStack(alignment: .leading, spacing: 15) {
                    Text("RECENT SESSIONS")
                        .font(.system(size: 16, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
                        .padding(.horizontal)

                    // Using the WeeklySessionList component
                    WeeklySessionList(userId: user.id, viewModel: weeklyViewModel)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring().delay(0.3)) {
                showStats = true
            }
            // Load sessions data
            weeklyViewModel.loadSessions(for: user.id)
            
            // Load user's score
            loadUserScore()
        }
    }
    
    // Function to load user's score from Firebase
    private func loadUserScore() {
        FirebaseManager.shared.db.collection("users").document(user.id).getDocument { snapshot, error in
            if let data = snapshot?.data(), let score = data["score"] as? Double {
                DispatchQueue.main.async {
                    self.userScore = score
                }
            }
        }
    }
    
    // Helper function to get rank
    private func getRank(for score: Double) -> (name: String, color: Color) {
        switch score {
            case 0.0..<30.0:
                return ("Novice", Color(red: 156/255, green: 163/255, blue: 175/255))
            case 30.0..<60.0:
                return ("Apprentice", Color(red: 96/255, green: 165/255, blue: 250/255))
            case 60.0..<90.0:
                return ("Beginner", Color(red: 59/255, green: 130/255, blue: 246/255))
            case 90.0..<120.0:
                return ("Steady", Color(red: 16/255, green: 185/255, blue: 129/255))
            case 120.0..<150.0:
                return ("Focused", Color(red: 245/255, green: 158/255, blue: 11/255))
            case 150.0..<180.0:
                return ("Disciplined", Color(red: 249/255, green: 115/255, blue: 22/255))
            case 180.0..<210.0:
                return ("Resolute", Color(red: 239/255, green: 68/255, blue: 68/255))
            case 210.0..<240.0:
                return ("Master", Color(red: 236/255, green: 72/255, blue: 153/255))
            case 240.0..<270.0:
                return ("Guru", Color(red: 139/255, green: 92/255, blue: 246/255))
            case 270.0...300.0:
                return ("Enlightened", Color(red: 217/255, green: 70/255, blue: 239/255))
            default:
                return ("Unranked", Color.gray)
        }
    }
}

struct WeeklySessionList: View {
    @ObservedObject var viewModel: WeeklySessionListViewModel
    @State private var showingAllSessions = false
    let userId: String
    
    init(userId: String, viewModel: WeeklySessionListViewModel = WeeklySessionListViewModel()) {
        self.userId = userId
        self.viewModel = viewModel
    }
    
    private var displayedSessions: [Session] {
        if showingAllSessions {
            return viewModel.sessions
        } else {
            return Array(viewModel.sessions.prefix(5))
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            ForEach(displayedSessions) { session in
                SessionHistoryCard(session: session)
            }
            
            if viewModel.sessions.count > 5 {
                Button(action: {
                    withAnimation(.spring()) {
                        showingAllSessions.toggle()
                    }
                }) {
                    HStack {
                        Text(showingAllSessions ? "Show Less" : "Show More")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: showingAllSessions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.buttonGradient)
                                .opacity(0.1)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                            
                            RoundedRectangle(cornerRadius: 12)
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
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 6)
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.loadSessions(for: userId)
        }
    }
}

class WeeklySessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var weeksLongestSession: Int = 0
    private let firebaseManager = FirebaseManager.shared

    func loadSessions(for userId: String) {
        firebaseManager.db.collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self?.sessions = documents.compactMap { document in
                        try? document.data(as: Session.self)
                    }
                    
                    // Calculate this week's longest session
                    let calendar = Calendar.current
                    let currentDate = Date()
                    let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
                    
                    let thisWeeksSessions = self?.sessions.filter { session in
                        calendar.isDate(session.startTime, inSameWeekAs: weekStart)
                    } ?? []
                    
                    self?.weeksLongestSession = thisWeeksSessions.max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration ?? 0
                }
            }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Theme.buttonGradient)
                    .frame(width: 44, height: 44)
                    .opacity(0.2)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 4)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}