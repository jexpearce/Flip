import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var authManager = AuthManager.shared
    @State private var isSigningOut = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header with Title and Sign Out
                HStack {
                    Spacer()
                    
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

                // Stats Cards with enhanced styling
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15
                ) {
                    StatCard(
                        title: "TOTAL TIME",
                        value: "\(sessionManager.totalFocusTime)",
                        unit: "min")
                    StatCard(
                        title: "SESSIONS",
                        value: "\(sessionManager.totalSuccessfulSessions)",
                        unit: "total")
                    StatCard(
                        title: "AVG LENGTH",
                        value: "\(sessionManager.averageSessionLength)",
                        unit: "min")
                }
                .padding(.horizontal)

                // Enhanced Longest Session Card
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
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

                        Text("\(sessionManager.longestSession) min")
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

                // History Section with enhanced styling
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

                    ForEach(sessionManager.sessions) { session in
                        SessionHistoryCard(session: session)
                    }
                }
            }
        }
        .background(Theme.mainGradient)
    }
}
