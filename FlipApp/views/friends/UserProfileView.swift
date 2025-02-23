import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct UserProfileView: View {
    let user: FirebaseManager.FlipUser
    @State private var showStats = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Header with enhanced styling
                VStack(spacing: 15) {
                    Text(user.username)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

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
                }
                .padding(.top, 20)

                // Stats Cards with animation
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15
                ) {
                    StatCard(
                        title: "TOTAL TIME",
                        value: "\(user.totalFocusTime)",
                        unit: "min"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    
                    StatCard(
                        title: "SESSIONS",
                        value: "\(user.totalSessions)",
                        unit: "total"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    .animation(.spring().delay(0.1), value: showStats)
                    
                    StatCard(
                        title: "AVG LENGTH",
                        value: user.totalSessions > 0 ? "\(user.totalFocusTime / user.totalSessions)" : "0",
                        unit: "min"
                    )
                    .offset(y: showStats ? 0 : 50)
                    .opacity(showStats ? 1 : 0)
                    .animation(.spring().delay(0.2), value: showStats)
                }
                .padding(.horizontal)

                // Enhanced Longest Session Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("LONGEST FLIP")
                                .font(.system(size: 14, weight: .black))
                                .tracking(5)
                                .foregroundColor(.white)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
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

                        Text("\(user.longestSession) min")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    }
                    Spacer()
                }
                .padding(20)
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

                    SessionList(userId: user.id)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring().delay(0.3)) {
                showStats = true
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

struct SessionList: View {
    @StateObject private var viewModel = SessionListViewModel()
    @State private var showingAllSessions = false
    let userId: String
    
    private var displayedSessions: [Session] {
        if showingAllSessions {
            return viewModel.sessions
        } else {
            return Array(viewModel.sessions.prefix(10))
        }
    }

    var body: some View {
        VStack(spacing: 15) {
            ForEach(displayedSessions) { session in
                SessionHistoryCard(session: session)
            }
            
            if viewModel.sessions.count > 10 {
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
                .padding(.top, 10)
            }
        }
        .onAppear {
            viewModel.loadSessions(for: userId)
        }
    }
}
