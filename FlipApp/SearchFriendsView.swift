import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation

struct SearchFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.neonYellow)
                    
                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(FlipTextFieldStyle())
                        .onChange(of: searchText) { query in
                            viewModel.searchUsers(query: query)
                        }
                }
                .padding()
                
                if viewModel.isSearching {
                    ProgressView()
                        .tint(Theme.neonYellow)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.searchResults) { user in
                                UserSearchCard(user: user)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct UserSearchCard: View {
    let user: FirebaseManager.FlipUser
    @StateObject private var viewModel = FriendViewModel()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(user.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(user.totalSessions) sessions")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.addFriend(userId: user.id)
            }) {
                Text(viewModel.isFriend ? "Added" : "Add Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.isFriend ? .gray : Theme.neonYellow)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.isFriend ? Color.gray : Theme.neonYellow, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Theme.darkGray)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

class SearchViewModel: ObservableObject {
    @Published var searchResults: [FirebaseManager.FlipUser] = []
    @Published var isSearching = false
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        FirebaseManager.shared.searchUsers(query: query) { [weak self] users in
            DispatchQueue.main.async {
                self?.searchResults = users
                self?.isSearching = false
            }
        }
    }
}