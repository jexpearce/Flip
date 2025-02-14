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

        Text("\(user.totalSessions) sessions completed")
          .font(.system(size: 12))
          .foregroundColor(.gray)
      }

      Spacer()

      HStack(spacing: 12) {
        Button(action: { onResponse(false) }) {
          Image(systemName: "xmark")
            .foregroundColor(.red)
            .padding(8)
            .background(Color.red.opacity(0.2))
            .clipShape(Circle())
        }

        Button(action: { onResponse(true) }) {
          Image(systemName: "checkmark")
            .foregroundColor(Theme.neonYellow)
            .padding(8)
            .background(Theme.neonYellow.opacity(0.2))
            .clipShape(Circle())
        }
      }
    }
    .padding()
    .background(Theme.darkGray)
    .cornerRadius(15)
  }
}
