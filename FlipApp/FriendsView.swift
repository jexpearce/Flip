// FriendsView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showingSearch = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Friend Requests Section
                if !viewModel.friendRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("FRIEND REQUESTS")
                            .font(.system(size: 14, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.neonYellow)
                        
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
                
                // Find Friends Button
                Button(action: { showingSearch = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                        Text("Find Friends")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(Theme.neonYellow)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.darkGray)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // Friends List
                if viewModel.friends.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "person.2")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.neonYellow)
                        
                        Text("No Friends Yet")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Add friends to see their focus sessions")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.friends) { friend in
                            NavigationLink(destination: UserProfileView(user: friend)) {
                                FriendCard(friend: friend)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            SearchFriendsView()
        }
        .refreshable {
            viewModel.loadFriends()
        }
    }
}

struct FriendRequestCard: View {
    let user: FirebaseManager.FlipUser
    let onResponse: (Bool) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(user.totalSessions) sessions completed")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { onResponse(false) }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: { onResponse(true) }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(Theme.neonYellow)
                        .padding(8)
                        .background(Theme.neonYellow.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Theme.darkGray)
        .cornerRadius(15)
    }
}