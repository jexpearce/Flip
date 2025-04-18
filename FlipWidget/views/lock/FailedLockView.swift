import SwiftUI

struct FailedLockView: View {
    private let gradientBackground = LinearGradient(
        colors: [Theme.deepMidnightPurple, Theme.darkPurpleBlue],
        startPoint: .top,
        endPoint: .bottom
    )

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 15) {
            // Failed Icon with gradient
            ZStack {
                Circle().fill(Theme.redGradient).frame(width: 60, height: 60).opacity(0.2)

                Circle().fill(Color.white.opacity(0.1)).frame(width: 65, height: 65)

                Image(systemName: "xmark.circle.fill").font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.redGradient)
                    .shadow(color: Color.red.opacity(0.5), radius: 8)
            }
            .scaleEffect(scale).opacity(opacity)

            Text("SESSION FAILED").font(.system(size: 24, weight: .black)).tracking(4)
                .foregroundStyle(Theme.redGradient).shadow(color: Color.red.opacity(0.5), radius: 8)
                .scaleEffect(scale).opacity(opacity)

            Text("Phone was flipped during session").font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center)
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .scaleEffect(scale).opacity(opacity)
        }
        .padding()
        .background(
            ZStack {
                gradientBackground
                Color.white.opacity(0.05)  // Glass effect

                // Subtle pattern
                GeometryReader { geometry in
                    Path { path in
                        for i in stride(from: 0, to: geometry.size.width, by: 20) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: geometry.size.height))
                        }
                    }
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
        )
        .onAppear {
            // Simple animation to draw attention
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
