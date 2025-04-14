import SwiftUI

struct EnhancedStatBox: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    @State private var animateValue = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.3), accentColor.opacity(0.1),
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 54, height: 54)

                Image(systemName: icon).font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white).shadow(color: accentColor.opacity(0.6), radius: 4)
            }
            .scaleEffect(animateValue ? 1.0 : 0.9)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateValue)

            Text(value).font(.system(size: 26, weight: .black)).foregroundColor(.white)
                .shadow(color: accentColor.opacity(0.7), radius: 4).opacity(animateValue ? 1 : 0)
                .offset(y: animateValue ? 0 : 10)
                .animation(.spring(response: 0.6).delay(0.3), value: animateValue)

            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.8))
                .opacity(animateValue ? 1 : 0).animation(.easeIn.delay(0.5), value: animateValue)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animateValue = true } }
    }
}
