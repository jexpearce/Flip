import SwiftUI

struct FirstSessionRequiredAlert: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.yellow, Theme.yellowyOrange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.yellow.opacity(0.5), radius: 5)

                // Title
                Text("FIRST SESSION REQUIRED").font(.system(size: 22, weight: .black)).tracking(2)
                    .foregroundColor(.white).multilineTextAlignment(.center)

                // Message
                Text(
                    "You need to complete your own first session before joining others. This helps you learn how FLIP works!"
                )
                .font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center).padding(.horizontal, 20)

                // Button
                Button(action: { withAnimation { isPresented = false } }) {
                    Text("GOT IT").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(width: 140, height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 168 / 255,
                                                    green: 85 / 255,
                                                    blue: 247 / 255
                                                ),
                                                Color(
                                                    red: 88 / 255,
                                                    green: 28 / 255,
                                                    blue: 135 / 255
                                                ),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6), Color.white.opacity(0.2),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(
                            color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                .opacity(0.4),
                            radius: 5
                        )
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 60 / 255, green: 30 / 255, blue: 110 / 255)
                                        .opacity(0.6),
                                    Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255)
                                        .opacity(0.4),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.2))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
            .frame(maxWidth: 320).shadow(color: Color.black.opacity(0.5), radius: 20)
        }
        .transition(.opacity)
    }
}
