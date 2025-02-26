import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct UserProfileView: View {
    let user: FirebaseManager.FlipUser
    @State private var showStats = false
    @State private var showDetailedStats = false
    @State private var showRemoveFriendAlert = false
    @StateObject private var weeklyViewModel = WeeklySessionListViewModel()
    @StateObject private var scoreManager = ScoreManager.shared
    @StateObject private var friendManager = FriendManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var userScore: Double = 3.0 // Default starting score
    
    // Check if this is the current user's profile
    private var isCurrentUser: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return user.id == currentUserId
    }
    
    // Check if this user is a friend
    private var isFriend: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return user.friends.contains(currentUserId)
    }
    
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
                    
                    VStack(alignment: .leading, spacing: 12) {
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
                    
                    // Only show remove friend button if this is not the current user's profile
                    // and if they are a friend
                    if !isCurrentUser && isFriend {
                        Button(action: {
                            showRemoveFriendAlert = true
                        }) {
                            Image(systemName: "person.fill.badge.minus")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Stats Summary Card with button to detailed view
                VStack(spacing: 15) {
                    // Quick Stats overview
                    HStack(spacing: 30) {
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
                    .padding(.vertical, 5)
                    
                    // View detailed stats button
                    Button(action: {
                        showDetailedStats = true
                    }) {
                        Text("VIEW DETAILED STATS")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                    }
                }
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.6),
                                        Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.3)
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
                .padding(.horizontal)
                .sheet(isPresented: $showDetailedStats) {
                    FriendStatsView(user: user)
                }

                // Enhanced Longest Session Card - Weekly Stats
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 8) {
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
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.4),
                                        Color(red: 236/255, green: 72/255, blue: 153/255).opacity(0.3)
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
        .overlay(
            Group {
                if showRemoveFriendAlert {
                    RemoveFriendAlert(
                        isPresented: $showRemoveFriendAlert,
                        username: user.username
                    ) {
                        // Handle friend removal
                        friendManager.removeFriend(friendId: user.id)
                        // Navigate back after removing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        )
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
// Detailed stats view popup
struct FriendStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: FirebaseManager.FlipUser
    @State private var animateStats = false
    
    var averageSessionLength: Int {
        if user.totalSessions == 0 {
            return 0
        }
        return user.totalFocusTime / user.totalSessions
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 26/255, green: 14/255, blue: 47/255),
                    Color(red: 16/255, green: 24/255, blue: 57/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(user.username)'s STATS")
                            .font(.system(size: 24, weight: .black))
                            .tracking(6)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        
                        Text("スタッツ")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 40)
                
                // Main stats display
                VStack(spacing: 30) {
                    // Total Focus Time
                    FriendStatCard(
                        title: "TOTAL FOCUS TIME",
                        value: "\(user.totalFocusTime)",
                        unit: "minutes",
                        icon: "clock.fill",
                        color: Color(red: 59/255, green: 130/255, blue: 246/255),
                        delay: 0
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Total Sessions
                    FriendStatCard(
                        title: "TOTAL SESSIONS",
                        value: "\(user.totalSessions)",
                        unit: "completed",
                        icon: "checkmark.circle.fill",
                        color: Color(red: 16/255, green: 185/255, blue: 129/255),
                        delay: 0.1
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Average Session Length
                    FriendStatCard(
                        title: "AVERAGE SESSION LENGTH",
                        value: "\(averageSessionLength)",
                        unit: "minutes",
                        icon: "chart.bar.fill",
                        color: Color(red: 245/255, green: 158/255, blue: 11/255),
                        delay: 0.2
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Longest Session
                    FriendStatCard(
                        title: "LONGEST SESSION",
                        value: "\(user.longestSession)",
                        unit: "minutes",
                        icon: "crown.fill",
                        color: Color(red: 236/255, green: 72/255, blue: 153/255),
                        delay: 0.3
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK TO PROFILE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Theme.buttonGradient)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .opacity(animateStats ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateStats)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateStats = true
                }
            }
        }
    }
}

struct FriendStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            .scaleEffect(animate ? 1 : 0.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 6)
                    
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(animate ? 1 : 0)
                .offset(x: animate ? 0 : -20)
            }
            
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animate = true
                }
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
            
            if viewModel.sessions.isEmpty {
                Text("No sessions recorded yet")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
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
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.5),
                                            Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
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
                        // Only include successful sessions from this week
                        session.wasSuccessful && calendar.isDate(session.startTime, inSameWeekAs: weekStart)
                    } ?? []
                    
                    self?.weeksLongestSession = thisWeeksSessions.max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration ?? 0
                }
            }
    }
}
