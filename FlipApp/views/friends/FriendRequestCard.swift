import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct EnhancedFriendRequestCard: View {
    let user: FirebaseManager.FlipUser
    let onResponse: (Bool) -> Void
    @State private var isAcceptPressed = false
    @State private var isDeclinePressed = false
    @State private var isGlowing = false
    @State private var showUserProfile = false

    var body: some View {
        ZStack {
            // Profile navigation when tapped
            NavigationLink(destination: UserProfileView(user: user), isActive: $showUserProfile) {
                EmptyView()
            }
            .opacity(0)

            HStack {
                // Profile picture with glow - make this tappable
                Button(action: { showUserProfile = true }) {
                    ProfileAvatarView(
                        imageURL: user.profileImageURL,
                        size: 56,
                        username: user.username
                    )
                    .shadow(
                        color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255).opacity(0.5),
                        radius: 8
                    )
                }

                // User info - make this tappable too
                Button(action: { showUserProfile = true }) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(user.username).font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(
                                color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                    .opacity(0.5),
                                radius: 6
                            )

                        Text("Wants to add you as a friend").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.leading, 10)
                }

                Spacer()

                // Accept/Decline buttons (unchanged)
                HStack(spacing: 10) {
                    // Decline button
                    Button(action: {
                        withAnimation(.spring()) { isDeclinePressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onResponse(false)
                            isDeclinePressed = false
                        }
                    }) {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white).frame(width: 36, height: 36)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Theme.mutedRed.opacity(0.8),
                                                    Theme.darkerRed.opacity(0.8),
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )

                                    Circle().fill(Color.white.opacity(0.1))

                                    Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.red.opacity(0.4), radius: 4)
                            .scaleEffect(isDeclinePressed ? 0.9 : 1.0)
                    }

                    // Accept button
                    Button(action: {
                        withAnimation(.spring()) { isAcceptPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onResponse(true)
                            isAcceptPressed = false
                        }
                    }) {
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white).frame(width: 36, height: 36)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.mutedGreen, Theme.darkerGreen],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )

                                    Circle().fill(Color.white.opacity(0.15))

                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(isGlowing ? 0.8 : 0.5),
                                                    Color.white.opacity(0.2),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            )
                            .shadow(color: Color.green.opacity(0.5), radius: isGlowing ? 6 : 4)
                            .scaleEffect(isAcceptPressed ? 0.9 : 1.0)
                            .onAppear {
                                withAnimation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                ) { isGlowing = true }
                            }
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    // Background styling (unchanged)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                        .opacity(0.3),
                                    Color(red: 88 / 255, green: 28 / 255, blue: 135 / 255)
                                        .opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                        .opacity(0.6), Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255).opacity(0.3),
                radius: 8
            )
        }
    }
}
