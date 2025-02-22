import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FriendRequestCard: View {
    let user: FirebaseManager.FlipUser
    let onResponse: (Bool) -> Void
    @State private var isAcceptPressed = false
    @State private var isDeclinePressed = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)

                Text("\(user.totalSessions) sessions completed")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 12) {
                // Decline Button
                Button(action: {
                    withAnimation(.spring()) {
                        isDeclinePressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onResponse(false)
                        isDeclinePressed = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 239/255, green: 68/255, blue: 68/255),
                                            Color(red: 185/255, green: 28/255, blue: 28/255)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(0.8)
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 4)
                        .scaleEffect(isDeclinePressed ? 0.9 : 1.0)
                }

                // Accept Button
                Button(action: {
                    withAnimation(.spring()) {
                        isAcceptPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onResponse(true)
                        isAcceptPressed = false
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 34/255, green: 197/255, blue: 94/255),
                                            Color(red: 22/255, green: 163/255, blue: 74/255)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(0.8)
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 4)
                        .scaleEffect(isAcceptPressed ? 0.9 : 1.0)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}