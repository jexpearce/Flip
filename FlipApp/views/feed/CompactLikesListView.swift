import SwiftUI

struct CompactLikesListView: View {
    let sessionId: String
    let likesCount: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [FirebaseManager.FlipUser] = []
    @State private var isLoading = true
    let viewModel: FeedViewModel

    init(sessionId: String, likesCount: Int, viewModel: FeedViewModel = FeedViewModel()) {
        self.sessionId = sessionId
        self.likesCount = likesCount
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with enhanced styling
            HStack {
                Text("\(likesCount) \(likesCount == 1 ? "Like" : "Likes")")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .shadow(color: Theme.orange.opacity(0.4), radius: 4)

                Spacer()

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.2))

            if isLoading {
                // Enhanced loading indicator
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ZStack {
                            // Glowing circle behind spinner
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Theme.orange.opacity(0.3), Theme.orange.opacity(0.0),
                                        ]),
                                        center: .center,
                                        startRadius: 1,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60).blur(radius: 8)

                            // Spinner
                            ProgressView().tint(Theme.orange).scaleEffect(1.2)
                        }

                        Text("Loading likes...").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
            }
            else if users.isEmpty {
                // Enhanced empty state
                VStack(spacing: 10) {
                    ZStack {
                        // Faded heart background
                        Circle().fill(Theme.orange.opacity(0.15)).frame(width: 60, height: 60)
                            .blur(radius: 10)

                        Image(systemName: "heart.slash").font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 4)

                    Text("No likes yet").font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 30)
            }
            else {
                // Enhanced users list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(users) { user in
                            NavigationLink(destination: UserProfileLoader(userId: user.id)) {
                                HStack(spacing: 12) {
                                    // Enhanced profile image
                                    ProfileAvatarView(
                                        imageURL: user.profileImageURL,
                                        size: 40,
                                        username: user.username
                                    )
                                    .overlay(Circle().stroke(Theme.silveryGradient3, lineWidth: 1))

                                    // Username with subtle shadow
                                    Text(user.username).font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 1)

                                    Spacer()

                                    // Enhanced chevron indicator
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        // Glass background
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.05))

                                        // Highlight on top
                                        RoundedRectangle(cornerRadius: 10).trim(from: 0, to: 0.5)
                                            .fill(Color.white.opacity(0.08))
                                            .rotationEffect(.degrees(180)).padding(1)
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            if users.last?.id != user.id {
                                Divider().background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)  // Limit the height for compact display
            }
        }
        .background(
            ZStack {
                // Base gradient
                Theme.baseGradient

                // Glass effect
                Color.white.opacity(0.05)

                // Border
                RoundedRectangle(cornerRadius: 16).stroke(Theme.silveryGradient3, lineWidth: 1)
            }
        )
        .cornerRadius(16).shadow(color: Color.black.opacity(0.3), radius: 20).frame(width: 300)
        .onAppear { loadUsers() }
    }

    private func loadUsers() {
        isLoading = true

        viewModel.getLikeUsers(sessionId: sessionId) { likeUsers in
            self.users = likeUsers
            self.isLoading = false
        }
    }
}
