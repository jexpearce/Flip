import SwiftUI

struct FriendsCountButton: View {
    let user: FirebaseManager.FlipUser
    let isCurrentUser: Bool
    let cyanBlueAccent: Color
    @Binding var showFriendsList: Bool
    let loadUserFriends: () -> Void

    var body: some View {
        Button(action: {
            loadUserFriends()
            showFriendsList = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    // The title shows appropriate text based on whose profile it is
                    Text(isCurrentUser ? "YOUR FRIENDS" : "\(user.username.uppercased())'S FRIENDS")
                        .font(.system(size: 14, weight: .bold)).tracking(1)
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill").font(.system(size: 18))
                            .foregroundColor(cyanBlueAccent)

                        Text("\(user.friends.count) friends").font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 14).padding(.horizontal, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [cyanBlueAccent.opacity(0.4), cyanBlueAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 15).stroke(Theme.silveryGradient2, lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2).padding(.horizontal)
        }
    }
}
