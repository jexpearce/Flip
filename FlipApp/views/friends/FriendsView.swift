import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendManager()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var liveSessionManager = LiveSessionManager.shared
    @State private var showingSearch = false
    @State private var isButtonPressed = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isJoiningSession = false
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Text("FRIENDS")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        .padding(.top, 20)
                    
                    // Weekly Leaderboard - NEW COMPONENT
                    WeeklyLeaderboard(viewModel: leaderboardViewModel)
                        .padding(.horizontal)

                    // Friend Requests Section
                    if !viewModel.friendRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("FRIEND REQUESTS")
                                .font(.system(size: 14, weight: .black))
                                .tracking(5)
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

                            ForEach(viewModel.friendRequests) { user in
                                FriendRequestCard(user: user) { accepted in
                                    if accepted {
                                        viewModel.acceptFriendRequest(from: user.id)
                                    } else {
                                        viewModel.declineFriendRequest(from: user.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Enhanced Find Friends Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isButtonPressed = true
                            showingSearch = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isButtonPressed = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 20))
                            Text("Find Friends")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Theme.buttonGradient)
                                    .opacity(0.3)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 8)
                        .scaleEffect(isButtonPressed ? 0.95 : 1.0)
                    }
                    .padding(.horizontal)

                    // Friends list title
                    if !viewModel.friends.isEmpty {
                        Text("YOUR FRIENDS")
                            .font(.system(size: 14, weight: .black))
                            .tracking(5)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    // Friends List
                    if viewModel.friends.isEmpty {
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Theme.buttonGradient)
                                    .frame(width: 80, height: 80)
                                    .opacity(0.2)
                                
                                Image(systemName: "person.2")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                            }

                            Text("No Friends Yet")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.4), radius: 6)

                            Text("Add friends to see their focus sessions")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                    } else {
                        LazyVStack(spacing: 15) {
                            // Sort friends - live sessions first, then normal friends
                            ForEach(sortedFriends) { friend in
                                // Create a ZStack where the NavigationLink is behind but covers most of the card
                                ZStack(alignment: .topTrailing) {
                                    // NavigationLink for profile view - make it disabled when joining
                                    NavigationLink(destination: UserProfileView(user: friend.user)) {
                                        FriendCard(
                                            friend: friend.user,
                                            liveSession: friend.sessionData
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(isNavigationBlocked)
                                    
                                    // If this friend has a live session, add the join button on top
                                    if friend.sessionData != nil && friend.sessionData?.canJoin == true {
                                        // This button is positioned at the top right over the card
                                        // but outside the NavigationLink's tap area
                                        Button {
                                            handleJoinSession(sessionId: friend.sessionId)
                                        } label: {
                                            Text("JOIN LIVE")
                                                .font(.system(size: 16, weight: .heavy))
                                                .tracking(1)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color.green.opacity(0.4))
                                                        
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.green.opacity(0.8), lineWidth: 1.5)
                                                    }
                                                )
                                                .shadow(color: Color.green.opacity(0.5), radius: 6)
                                        }
                                        .padding(.trailing, 24)
                                        .padding(.top, 16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingSearch) {
                FriendsSearchView()
            }
            .refreshable {
                viewModel.loadFriends()
                leaderboardViewModel.loadLeaderboard()
                liveSessionManager.listenForFriendSessions()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Join Session"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                liveSessionManager.listenForFriendSessions()
            }
            .onChange(of: liveSessionManager.activeFriendSessions) { _ in
                // Force view refresh when live sessions change
                viewModel.objectWillChange.send()
            }
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Block navigation when joining session
    private var isNavigationBlocked: Bool {
        return isJoiningSession || liveSessionManager.isJoiningSession
    }
    
    // Computed property to sort friends with live sessions first
    private var sortedFriends: [FriendWithSession] {
        var result: [FriendWithSession] = []
        
        // First add friends with live sessions
        for friend in viewModel.friends {
            // Check if this friend has an active session
            let session = liveSessionManager.activeFriendSessions.first { sessionId, sessionData in
                return sessionData.participants.contains(friend.id)
            }
            
            if let (sessionId, sessionData) = session {
                result.append(FriendWithSession(
                    user: friend,
                    sessionId: sessionId,
                    sessionData: sessionData
                ))
            } else {
                result.append(FriendWithSession(
                    user: friend,
                    sessionId: nil,
                    sessionData: nil
                ))
            }
        }
        
        // Sort with live sessions first
        return result.sorted { a, b in
            if a.sessionData != nil && b.sessionData == nil {
                return true
            } else if a.sessionData == nil && b.sessionData != nil {
                return false
            } else {
                return a.user.username < b.user.username
            }
        }
    }
    
    // Helper struct to combine friend with session data
    struct FriendWithSession: Identifiable {
        let user: FirebaseManager.FlipUser
        let sessionId: String?
        let sessionData: LiveSessionManager.LiveSessionData?
        
        var id: String {
            return user.id
        }
    }
    
    // Handle join session logic
    private func handleJoinSession(sessionId: String?) {
        guard let sessionId = sessionId else { return }
        
        // Block if user is already in a session
        if appManager.currentState != .initial {
            alertMessage = "You're already in a session. Please complete or cancel it before joining another."
            showAlert = true
            return
        }
        
        isJoiningSession = true
        
        // Try to join the session
        LiveSessionManager.shared.joinSession(sessionId: sessionId) { success, remainingSeconds, totalDuration in
            DispatchQueue.main.async {
                isJoiningSession = false
                
                if success {
                    // Start the joined session
                    appManager.joinLiveSession(
                        sessionId: sessionId,
                        remainingSeconds: remainingSeconds,
                        totalDuration: totalDuration
                    )
                } else {
                    // Show error
                    alertMessage = "Unable to join the session. It may be full or no longer available."
                    showAlert = true
                }
            }
        }
    }
}