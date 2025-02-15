import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendManager()
    @State private var showingSearch = false

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("FRIENDS")
                    .font(.system(size: 28, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()
                    .padding(.top, 20)

                // Friend Requests Section
                if !viewModel.friendRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("FRIEND REQUESTS")
                            .font(.system(size: 14, weight: .heavy))
                            .tracking(5)
                            .foregroundColor(.white)
                            .retroGlow()

                        ForEach(viewModel.friendRequests) { user in
                            FriendRequestCard(user: user) { accepted in
                                if accepted {
                                    viewModel.acceptFriendRequest(from: user.id)
                                } else {
                                    viewModel.declineFriendRequest(
                                        from: user.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Find Friends Button
                Button(action: { showingSearch = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                        Text("Find Friends")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .background(Theme.darkGray)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(
                                Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .retroGlow()
                }
                .padding(.horizontal)

                // Friends List
                if viewModel.friends.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .retroGlow()

                        Text("No Friends Yet")
                            .font(.title2)
                            .foregroundColor(.white)
                            .retroGlow()

                        Text("Add friends to see their focus sessions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
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
