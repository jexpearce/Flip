import FirebaseAuth
import SwiftUI

struct CommentsView: View {
    let session: Session
    let viewModel: FeedViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display existing comments from sessionComments
            if let comments = viewModel.sessionComments[session.id.uuidString], !comments.isEmpty {
                ForEach(comments) { comment in
                    CommentBubble(comment: comment, viewModel: viewModel).padding(.vertical, 2)
                }
            }
            // For backward compatibility, handle legacy comment field
            else if let comment = session.comment, !comment.isEmpty {
                // Legacy comment handling with enhanced styling
                HStack(alignment: .top, spacing: 10) {
                    // Comment icon bubble with glow
                    ZStack {
                        Circle().fill(Theme.lightTealBlue.opacity(0.2)).frame(width: 28, height: 28)

                        Image(systemName: "text.bubble.fill").font(.system(size: 14))
                            .foregroundColor(Theme.lightTealBlue.opacity(0.8))
                            .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Check if we have commentor information
                        if let commentorId = session.commentorId,
                            let commentorName = session.commentorName
                        {
                            // Keep the NavigationLink inside this scope where commentorId is defined
                            NavigationLink(destination: UserProfileLoader(userId: commentorId)) {
                                Text(commentorName).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                                    .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(comment).font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9)).lineLimit(3)
                                .padding(.vertical, 2)

                            // Show comment time if available
                            if let commentTime = session.commentTime {
                                Text(formatTime(commentTime)).font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5)).padding(.top, 2)
                            }
                        }
                        else {
                            // Legacy comments without user info - show session owner
                            NavigationLink(destination: UserProfileLoader(userId: session.userId)) {
                                Text(session.username).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.lightTealBlue.opacity(0.9))
                                    .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text(comment).font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9)).lineLimit(3)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            // Load comments when view appears
            print("CommentsView appeared for session: \(session.id.uuidString)")
            viewModel.loadCommentsForSession(session.id.uuidString)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        }
        else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
