import SwiftUI

struct FirstSessionRequiredAlert: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50))
                    .foregroundStyle(Theme.yellowyGradient)
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
                                RoundedRectangle(cornerRadius: 22).fill(Theme.purplyGradient)

                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Theme.silveryGradient, lineWidth: 1)
                            }
                        )
                        .shadow(color: Theme.vibrantPurple.opacity(0.4), radius: 5)
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.pinkBlueGradient)

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
