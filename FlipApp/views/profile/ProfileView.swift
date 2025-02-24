import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var scoreManager = ScoreManager.shared
    @State private var isSigningOut = false
    @State private var showAllSessions = false
    @State private var username = FirebaseManager.shared.currentUser?.username ?? "User"
    
    private var displayedSessions: [Session] {
        if showAllSessions {
            return sessionManager.sessions
        } else {
            return Array(sessionManager.sessions.prefix(5))
        }
    }
    
    private var weeksLongestSession: Int? {
        let calendar = Calendar.current
        let currentDate = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        return sessionManager.sessions
            .filter { session in
                calendar.isDate(session.startTime, inSameWeekAs: weekStart)
            }
            .max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Title and Sign Out
                HStack {
                    // Add rank circle
                    RankCircle(score: scoreManager.currentScore)
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 4) {
                        Text("PROFILE")
                            .font(.system(size: 28, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                        Text("プロフィール")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Enhanced Sign Out Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isSigningOut = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            authManager.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(0.8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                            .scaleEffect(isSigningOut ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Add discipline rank card
                DisciplineRankCard(scoreManager: scoreManager)
                    .padding(.horizontal)

                // Stats Cards with condensed styling
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15
                ) {
                    CondensedStatCard(
                        title: "TOTAL TIME",
                        value: "\(sessionManager.totalFocusTime)",
                        unit: "min")
                    CondensedStatCard(
                        title: "SESSIONS",
                        value: "\(sessionManager.totalSuccessfulSessions)",
                        unit: "total")
                    CondensedStatCard(
                        title: "AVG LENGTH",
                        value: "\(sessionManager.averageSessionLength)",
                        unit: "min")
                }
                .padding(.horizontal)

                // Enhanced Longest Session Card - Weekly Stats
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("\(username)'s LONGEST FLIP OF THE WEEK")
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

                // History Section with Show More functionality
                VStack(alignment: .leading, spacing: 15) {
                    VStack(spacing: 4) {
                        Text("HISTORY")
                            .font(.system(size: 16, weight: .black))
                            .tracking(5)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                        Text("セッション履歴")
                            .font(.system(size: 12))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal)

                    ForEach(displayedSessions) { session in
                        SessionHistoryCard(session: session)
                    }
                    
                    if sessionManager.sessions.count > 5 {
                        Button(action: {
                            withAnimation(.spring()) {
                                showAllSessions.toggle()
                            }
                        }) {
                            HStack {
                                Text(showAllSessions ? "Show Less" : "Show More")
                                    .font(.system(size: 16, weight: .bold))
                                Image(systemName: showAllSessions ? "chevron.up" : "chevron.down")
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
            }
            .onAppear {
                if let currentUser = FirebaseManager.shared.currentUser {
                    self.username = currentUser.username
                }
            }
        }
    }
}

struct CondensedStatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))

            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12) // Reduced from 15
        .background(
            ZStack {
                // Base glass effect
                RoundedRectangle(cornerRadius: 15)
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
                // Frosted overlay
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                // Top edge highlight
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
                
                // Inner glow
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(y: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}