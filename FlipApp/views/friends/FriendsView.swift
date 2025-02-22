import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendManager()
    @State private var showingSearch = false
    @State private var isButtonPressed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("FRIENDS")
                    .font(.system(size: 28, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                    .padding(.top, 20)

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
                    .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.friends) { friend in
                            NavigationLink(
                                destination: UserProfileView(user: friend)
                            ) {
                                FriendCard(friend: friend)
                            }
                        }
                    }
                }
            }
        }
        .background(Theme.mainGradient)
        .sheet(isPresented: $showingSearch) {
            FriendsSearchView()
        }
        .refreshable {
            viewModel.loadFriends()
        }
    }
}