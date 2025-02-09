// FriendsView.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showingSearch = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FRIENDS").title()
            
            Button(action: { showingSearch = true }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Find Friends")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.neonYellow)
                .padding()
                .background(Theme.darkGray)
                .cornerRadius(15)
            }
            
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.friends) { friend in
                        FriendCard(friend: friend)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingSearch) {
            SearchFriendsView()
        }
    }
}

class FriendsViewModel: ObservableObject {
    @Published var friends: [FirebaseManager.FlipUser] = []
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        loadFriends()
    }
    
    func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        firebaseManager.db.collection("users").document(userId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                      let userData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }
                
                // Load friend details
                for friendId in userData.friends {
                    self?.loadFriendDetails(friendId: friendId)
                }
            }
    }
    
    private func loadFriendDetails(friendId: String) {
        firebaseManager.db.collection("users").document(friendId)
            .getDocument { [weak self] document, error in
                guard let document = document,
                      let friendData = try? document.data(as: FirebaseManager.FlipUser.self)
                else { return }
                
                DispatchQueue.main.async {
                    self?.friends.append(friendData)
                }
            }
    }
}
