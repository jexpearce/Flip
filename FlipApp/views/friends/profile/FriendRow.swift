import SwiftUI

struct FriendRow: View {
    let friend: FirebaseManager.FlipUser
    let isMutual: Bool

    // Colors
    private let cyanBlueAccent = Theme.lightTealBlue
    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: UserProfileView(user: friend)) {
            HStack(spacing: 12) {
                // Profile picture
                ProfileAvatarView(
                    imageURL: friend.profileImageURL,
                    size: 50,
                    username: friend.username
                )

                // Friend info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(friend.username).font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(
                                color: isMutual
                                    ? cyanBlueAccent.opacity(0.6) : Color.white.opacity(0.3),
                                radius: 4
                            )

                        if isMutual {
                            // Mutual friend badge
                            Text("Mutual").font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white).padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(cyanBlueAccent.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(cyanBlueAccent.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                    }

                    // Stats
                    HStack(spacing: 12) {
                        Label("\(friend.totalSessions) sessions", systemImage: "timer")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))

                        Label("\(friend.totalFocusTime)m focus", systemImage: "clock")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right").font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5)).padding(.trailing, 4)
            }
            .padding(.vertical, 12).padding(.horizontal, 20)
            .background(
                ZStack {
                    // Different background for mutual friends
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isMutual ? cyanBlueAccent.opacity(0.15) : Color.white.opacity(0.05))

                    // Border
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isMutual
                                ? LinearGradient(
                                    colors: [
                                        cyanBlueAccent.opacity(0.5), cyanBlueAccent.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: 1
                        )
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
