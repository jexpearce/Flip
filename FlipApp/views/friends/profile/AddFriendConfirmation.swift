import SwiftUI

struct AddFriendConfirmation: View {
    @Binding var isPresented: Bool
    let username: String
    let onConfirm: () -> Void
    @State private var isConfirmPressed = false
    @State private var isCancelPressed = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }

            // Alert card
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle().fill(Theme.tealyGradient).frame(width: 70, height: 70).opacity(0.2)

                    Image(systemName: "person.fill.badge.plus").font(.system(size: 36))
                        .foregroundStyle(Theme.tealyGradient)
                        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                }
                .padding(.top, 20)

                // Title
                VStack(spacing: 4) {
                    Text("ADD FRIEND?").font(.system(size: 22, weight: .black)).tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)

                    Text("友達を追加").font(.system(size: 12)).tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Message
                Text("Send a friend request to \(username)?")
                    .font(.system(size: 16, weight: .medium)).multilineTextAlignment(.center)
                    .foregroundColor(.white).padding(.horizontal, 20).padding(.top, 10)

                // Buttons
                HStack(spacing: 15) {
                    // Cancel button
                    Button(action: {
                        withAnimation(.spring()) { isCancelPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCancelPressed = false
                            isPresented = false
                        }
                    }) {
                        Text("CANCEL").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                    }

                    // Add friend button
                    Button(action: {
                        withAnimation(.spring()) { isConfirmPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isConfirmPressed = false
                            isPresented = false
                            onConfirm()
                        }
                    }) {
                        Text("SEND REQUEST").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22).fill(Theme.tealyGradient)
                                        .opacity(0.8)

                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2),
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .scaleEffect(isConfirmPressed ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10).padding(.horizontal, 20).padding(.bottom, 25)
            }
            .frame(width: 320)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.darkGray)

                    RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))

                    RoundedRectangle(cornerRadius: 20).stroke(Theme.silveryGradient2, lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}
