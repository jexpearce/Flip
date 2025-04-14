import SwiftUI

struct BackgroundDecorationView: View {
    let orangeAccent: Color
    let purpleAccent: Color

    var body: some View {
        ZStack {
            // Top decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            orangeAccent.opacity(0.2), orangeAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300).offset(x: 150, y: -150).blur(radius: 50)
                .edgesIgnoringSafeArea(.all)

            // Bottom decorative element
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            purpleAccent.opacity(0.2), purpleAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 250, height: 250).offset(x: -120, y: 350).blur(radius: 40)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
