import SwiftUI
import FirebaseAuth

struct BlockedUsersView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var blockedUsers: [FirebaseManager.FlipUser] = []
    @State private var isLoading = true
    @State private var showUnblockAlert = false
    @State private var selectedUser: FirebaseManager.FlipUser?
    
    private let cyanBlueAccent = Theme.lightTealBlue
    
    var body: some View {
        ZStack {
            // Background gradient
            Theme.darkPurpleGradient.edgesIgnoringSafeArea(.all)
            
            // Decorative background elements
            Circle()
                .fill(cyanBlueAccent.opacity(0.1))
                .frame(width: 300)
                .offset(x: 150, y: -200)
                .blur(radius: 60)
            
            Circle()
                .fill(cyanBlueAccent.opacity(0.08))
                .frame(width: 250)
                .offset(x: -150, y: 300)
                .blur(radius: 50)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("BLOCKED USERS")
                        .font(.system(size: 28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: cyanBlueAccent.opacity(0.5), radius: 8)
                    
                    Spacer()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(cyanBlueAccent)
                        .scaleEffect(1.5)
                    Spacer()
                } else if blockedUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Blocked Users")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("You haven't blocked any users yet")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(blockedUsers) { user in
                                BlockedUserRow(user: user) {
                                    selectedUser = user
                                    showUnblockAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear(perform: loadBlockedUsers)
        .alert(isPresented: $showUnblockAlert) {
            Alert(
                title: Text("Unblock User"),
                message: Text("Are you sure you want to unblock \(selectedUser?.username ?? "")?"),
                primaryButton: .destructive(Text("Unblock")) {
                    if let user = selectedUser {
                        unblockUser(user)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func loadBlockedUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .getDocument { document, error in
                if let error = error {
                    print("Error getting current user document: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                guard let document = document,
                      let userData = try? document.data(as: FirebaseManager.FlipUser.self) else {
                    isLoading = false
                    return
                }
                
                let blockedUserIds = userData.blockedUsers
                
                if blockedUserIds.isEmpty {
                    isLoading = false
                    return
                }
                
                let group = DispatchGroup()
                var loadedUsers: [FirebaseManager.FlipUser] = []
                
                for userId in blockedUserIds {
                    group.enter()
                    FirebaseManager.shared.db.collection("users").document(userId)
                        .getDocument { document, error in
                            defer { group.leave() }
                            
                            if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                                loadedUsers.append(userData)
                            }
                        }
                }
                
                group.notify(queue: .main) {
                    blockedUsers = loadedUsers.sorted { $0.username < $1.username }
                    isLoading = false
                }
            }
    }
    
    private func unblockUser(_ user: FirebaseManager.FlipUser) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseManager.shared.db.collection("users").document(currentUserId)
            .getDocument { document, error in
                if let error = error {
                    print("Error getting current user document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document,
                      var userData = try? document.data(as: FirebaseManager.FlipUser.self) else {
                    return
                }
                
                // Remove user from blocked list
                userData.blockedUsers.removeAll { $0 == user.id }
                
                // Update the document
                do {
                    try FirebaseManager.shared.db.collection("users").document(currentUserId)
                        .setData(from: userData)
                    
                    // Update local user object
                    DispatchQueue.main.async {
                        FirebaseManager.shared.currentUser = userData
                        // Remove from local blocked users list
                        blockedUsers.removeAll { $0.id == user.id }
                    }
                } catch {
                    print("Error updating user document: \(error.localizedDescription)")
                }
            }
    }
}

struct BlockedUserRow: View {
    let user: FirebaseManager.FlipUser
    let onUnblock: () -> Void
    
    private let cyanBlueAccent = Theme.lightTealBlue
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile picture
            ProfileAvatarView(
                imageURL: user.profileImageURL,
                size: 50,
                username: user.username
            )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Blocked")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
            }
            
            Spacer()
            
            // Unblock button
            Button(action: onUnblock) {
                Text("Unblock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(cyanBlueAccent.opacity(0.3))
                            .overlay(
                                Capsule()
                                    .stroke(cyanBlueAccent.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
} 
