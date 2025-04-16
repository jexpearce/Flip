import SwiftUI

struct FriendRequestView: View {
    let username: String
    let userId: String
    @Binding var isPresented: Bool
    @State private var isAddingFriend = false
    @State private var showProfile = false
    @State private var requestSucceeded = false
    @State private var user: FirebaseManager.FlipUser?
    @State private var isLoadingUser = false
    @StateObject private var searchManager = SearchManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with nice session completion message
            VStack(spacing: 8) {
                Text("Nice session with")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text(username)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Theme.yellow.opacity(0.5), radius: 6)
            }
            .padding(.top, 12)
            
            Spacer(minLength: 16)
            
            // Buttons with nice styling
            VStack(spacing: 14) {
                Button(action: {
                    isAddingFriend = true
                    searchManager.sendFriendRequest(to: userId)
                    isAddingFriend = false
                    requestSucceeded = true
                            
                    // Show success feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                            
                    // Dismiss after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 12) {
                        if isAddingFriend {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else if requestSucceeded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "person.badge.plus.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text(requestSucceeded ? "Friend Request Sent" : "Add Friend")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Theme.vibrantPurple, Theme.deepPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Theme.vibrantPurple.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .disabled(isAddingFriend || requestSucceeded)
                
                Button(action: {
                    // Load user details if not already loaded
                    loadUserDetails {
                        showProfile = true
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 12) {
                        if isLoadingUser {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text("View Profile")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Theme.blue, Theme.blue800],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Theme.blue.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .disabled(isLoadingUser)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer(minLength: 20)
        }
        .padding(20)
        .frame(width: min(UIScreen.main.bounds.width - 60, 320))
        .background(
            ZStack {
                // Gradient background with glass effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.darkBlue.opacity(0.9),
                                Theme.deepPurple.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        // Navigate to profile if requested using a full-screen cover
        .fullScreenCover(isPresented: $showProfile) {
            if let userDetails = user {
                NavigationView {
                    UserProfileView(user: userDetails)
                        .navigationBarItems(leading: Button(action: {
                            showProfile = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .clipShape(Circle())
                        })
                }
                .accentColor(.white)
            }
        }
    }
    
    private func loadUserDetails(completion: @escaping () -> Void) {
        // Don't reload if we already have the user
        if user != nil {
            completion()
            return
        }
        
        isLoadingUser = true
        FirebaseManager.shared.db.collection("users").document(userId).getDocument { snapshot, error in
            isLoadingUser = false
            if let error = error {
                print("Error loading user details: \(error.localizedDescription)")
                return
            }
            
            if let userData = try? snapshot?.data(as: FirebaseManager.FlipUser.self) {
                self.user = userData
                completion()
            }
        }
    }
} 