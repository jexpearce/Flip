import SwiftUI

struct EnhancedProfileBackgroundView: View {
    let cyanBluePurpleGradient: LinearGradient
    let cyanBlueAccent: Color
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            // Main background
            cyanBluePurpleGradient.edgesIgnoringSafeArea(.all)

            // Animated top decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.3), cyanBlueAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 350, height: 350).offset(x: 150, y: -150).blur(radius: 40)
                .opacity(animateGlow ? 0.8 : 0.6)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateGlow
                )

            // Bottom decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.2), cyanBlueAccent.opacity(0.03),
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300).offset(x: -120, y: 350).blur(radius: 35)
                .opacity(animateGlow ? 0.6 : 0.4)
                .animation(
                    Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1),
                    value: animateGlow
                )

            // Additional smaller accent glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.15), cyanBlueAccent.opacity(0.01),
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 200).offset(x: 100, y: 200).blur(radius: 30)
                .opacity(animateGlow ? 0.5 : 0.3)
                .animation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(2),
                    value: animateGlow
                )
        }
        .onAppear { animateGlow = true }
    }
}
