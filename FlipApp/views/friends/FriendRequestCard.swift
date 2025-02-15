import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendRequestCard: View {
    let user: FirebaseManager.FlipUser
    let onResponse: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .retroGlow()

                Text("\(user.totalSessions) sessions completed")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { onResponse(false) }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Circle())
                        .retroGlow()
                }

                Button(action: { onResponse(true) }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .retroGlow()
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
