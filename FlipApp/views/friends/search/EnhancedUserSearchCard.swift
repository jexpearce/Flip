import SwiftUI

struct EnhancedUserSearchCard: View {
    let user: FirebaseManager.FlipUser
    let requestStatus: RequestStatus
    let mutualCount: Int  // New parameter for mutual friends count
    let onSendRequest: () -> Void
    let onCancelRequest: () -> Void
    let onViewProfile: () -> Void

    @State private var isAddPressed = false
    @State private var isCancelPressed = false
    @State private var isCardPressed = false

    private let orangeAccent = Theme.orange
    private let orangeGlow = Theme.orange.opacity(0.5)
    private let purpleAccent = Theme.purple
    private let goldAccent = Theme.yellow  // Gold color for mutual friends

    var body: some View {
        Button(action: {
            // Only navigate to profile on card tap, not button taps
            withAnimation(.spring()) { isCardPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isCardPressed = false
                onViewProfile()
            }
        }) {
            HStack {
                // User profile picture with enhanced styling
                ProfileAvatarView(imageURL: user.profileImageURL, size: 56, username: user.username)
                    .shadow(color: orangeGlow, radius: 6)

                // User info with enhanced styling
                VStack(alignment: .leading, spacing: 5) {
                    // Username with mutual badge
                    HStack(spacing: 8) {
                        Text(user.username).font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white).lineLimit(1)
                            .frame(maxWidth: 150, alignment: .leading)
                            .shadow(color: orangeGlow, radius: 6)

                        // Show mutual friends badge if any - Simple version
                        if mutualCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "person.2.fill").font(.system(size: 10))
                                    .foregroundColor(goldAccent)

                                Text("\(mutualCount)").font(.system(size: 11, weight: .bold))
                                    .foregroundColor(goldAccent)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(goldAccent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(goldAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    HStack(spacing: 12) {
                        Label("\(user.totalSessions) sessions", systemImage: "timer")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

                        Label("\(user.totalFocusTime) min", systemImage: "clock")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

                    }
                }
                .padding(.leading, 4)

                Spacer()

                // Action buttons with enhanced styling
                Group {
                    switch requestStatus {
                    case .none:
                        Button(action: {
                            withAnimation(.spring()) { isAddPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onSendRequest()
                                isAddPressed = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus").font(.system(size: 14))
                                Text("Add Friend").font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white).padding(.horizontal, 15).padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    orangeAccent.opacity(0.8),
                                                    purpleAccent.opacity(0.6),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Theme.silveryGradient5, lineWidth: 1)
                                }
                            )
                            .shadow(color: orangeGlow, radius: 4)
                            .scaleEffect(isAddPressed ? 0.95 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())

                    case .sent:
                        Button(action: {
                            withAnimation(.spring()) { isCancelPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onCancelRequest()
                                isCancelPressed = false
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill").font(.system(size: 12))

                                Text("Request Sent").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8)).padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.3))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())

                    case .friends:
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.green)
                                .font(.system(size: 16))

                            Text("Friends").font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 15).padding(.vertical, 10)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Theme.mutedGreen.opacity(0.3),
                                                Theme.darkerGreen.opacity(0.2),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 4)
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    // Give mutual friends cards a subtle gold highlight
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mutualCount > 0
                                        ? goldAccent.opacity(0.05) : Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    mutualCount > 0
                                        ? goldAccent.opacity(0.3) : Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: mutualCount > 0 ? goldAccent.opacity(0.1) : Color.black.opacity(0.2),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isCardPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCardPressed)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
