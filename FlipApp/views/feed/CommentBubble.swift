import FirebaseAuth
import SwiftUI

struct CommentBubble: View {
    let comment: SessionComment
    let viewModel: FeedViewModel
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Comment icon with enhanced styling
            ZStack {
                // Glow effect
                Circle().fill(Theme.lightTealBlue.opacity(0.15)).frame(width: 32, height: 32)
                    .blur(radius: 4)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.lightTealBlue.opacity(0.3), Theme.darkTealBlue.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                // Icon
                Image(systemName: "text.bubble.fill").font(.system(size: 14))
                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Username with enhanced styling
                NavigationLink(destination: UserProfileLoader(userId: comment.userId)) {
                    Text(comment.username).font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                        .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                }
                .buttonStyle(PlainButtonStyle())

                // Comment text with enhanced styling
                Text(comment.comment).font(.system(size: 14)).foregroundColor(.white.opacity(0.9))
                    .lineLimit(4).padding(.vertical, 2)

                // Comment time with subtle styling
                Text(comment.formattedTime).font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Delete button (only shows on long press for own comments)
            if showDeleteConfirm && comment.userId == Auth.auth().currentUser?.uid {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash").font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.8)).padding(6)
                        .background(
                            ZStack {
                                // Glass background
                                Circle().fill(Color.black.opacity(0.3))

                                // Subtle border
                                Circle().stroke(Color.red.opacity(0.3), lineWidth: 1)
                            }
                        )
                }
                .transition(.scale.combined(with: .opacity)).buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))
                .opacity(showDeleteConfirm ? 0.3 : 0)
        )
        .contentShape(Rectangle())  // Make the entire area tappable
        .onLongPressGesture(minimumDuration: 0.5) {
            // Only show delete option if comment belongs to current user
            if comment.userId == Auth.auth().currentUser?.uid {
                withAnimation(.spring()) { showDeleteConfirm = true }

                // Auto-hide after 3 seconds if not tapped
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring()) { showDeleteConfirm = false }
                }

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Comment"),
                message: Text("Are you sure you want to delete this comment?"),
                primaryButton: .destructive(Text("Delete")) {
                    // Delete the comment
                    withAnimation {
                        viewModel.deleteComment(sessionId: comment.sessionId, commentId: comment.id)
                    }
                    showDeleteConfirm = false
                },
                secondaryButton: .cancel { showDeleteConfirm = false }
            )
        }
    }
}
