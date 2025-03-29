import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct SuccessLockView: View {
    private let gradientBackground = LinearGradient(
        colors: [
            Theme.deepMidnightPurple,
            Theme.darkPurpleBlue,
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 15) {
            // Success Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.mutedGreen,
                                Theme.darkerGreen,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                    .opacity(0.2)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 65, height: 65)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.mutedGreen,
                                Theme.darkerGreen,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.green.opacity(0.5), radius: 8)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            Text("SESSION COMPLETE!")
                .font(.system(size: 24, weight: .black))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Theme.yellow,  // Yellow
                            Theme.yellowyOrange,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Theme.yellow.opacity(0.5), radius: 8
                )
                .scaleEffect(scale)
                .opacity(opacity)

            Text("Great job staying focused!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .padding()
        .background(
            ZStack {
                gradientBackground
                Color.white.opacity(0.05)  // Glass effect

                // Subtle pattern
                GeometryReader { geometry in
                    Path { path in
                        for i in stride(
                            from: 0, to: geometry.size.width, by: 20)
                        {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(
                                to: CGPoint(x: i, y: geometry.size.height))
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
