import SwiftUI

struct UserFriendsListView: View {
    let user: FirebaseManager.FlipUser
    @Binding var isPresented: Bool
    let mutualFriends: [FirebaseManager.FlipUser]
    let userFriends: [FirebaseManager.FlipUser]
    let loadingFriends: Bool

    // Colors
    private let cyanBlueAccent = Theme.lightTealBlue
    private let cyanBlueGlow = Theme.lightTealBlue.opacity(0.5)

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }

            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(user.username)'s FRIENDS").font(.system(size: 22, weight: .black))
                            .tracking(3).foregroundColor(.white)
                            .shadow(color: cyanBlueGlow, radius: 8)

                        Text("\(user.friends.count) total friends").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Close button
                    Button(action: { withAnimation(.spring()) { isPresented = false } }) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)

                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                if loadingFriends {
                    // Loading indicator
                    Spacer()

                    VStack(spacing: 12) {
                        ProgressView().tint(cyanBlueAccent).scaleEffect(1.5)

                        Text("Loading friends...").font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
                else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Mutual friends section
                            if !mutualFriends.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("MUTUAL FRIENDS").font(.system(size: 16, weight: .bold))
                                        .tracking(2).foregroundColor(cyanBlueAccent)
                                        .padding(.horizontal, 20)

                                    ForEach(mutualFriends) { friend in
                                        FriendRow(friend: friend, isMutual: true)
                                    }
                                }

                                Divider().background(Color.white.opacity(0.2))
                                    .padding(.vertical, 10)
                            }

                            // Other friends section
                            if !userFriends.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(mutualFriends.isEmpty ? "FRIENDS" : "OTHER FRIENDS")
                                        .font(.system(size: 16, weight: .bold)).tracking(2)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 20)

                                    ForEach(userFriends) { friend in
                                        FriendRow(friend: friend, isMutual: false)
                                    }
                                }
                            }

                            // Empty state
                            if mutualFriends.isEmpty && userFriends.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.slash").font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.6)).padding(.top, 30)

                                    Text("No friends yet").font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("This user hasn't added any friends yet")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(.top, 40)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(
                maxWidth: UIScreen.main.bounds.width * 0.9,
                maxHeight: UIScreen.main.bounds.height * 0.8
            )
            .background(
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Theme.mediumMidnightPurple, Theme.indigoDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Glass effect
                    RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05))

                    // Border
                    RoundedRectangle(cornerRadius: 20).stroke(Theme.silveryGradient3, lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}
