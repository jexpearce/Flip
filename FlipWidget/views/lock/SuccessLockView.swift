import Foundation
import ActivityKit
import SwiftUI
import WidgetKit

struct SuccessLockView: View {
    private let gradientBackground = LinearGradient(
        colors: [
            Color(red: 26/255, green: 14/255, blue: 47/255),
            Color(red: 30/255, green: 58/255, blue: 138/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        VStack(spacing: 15) {
            // Success Icon with gradient
            ZStack {
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
                    .frame(width: 60, height: 60)
                    .opacity(0.2)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 34/255, green: 197/255, blue: 94/255),
                                Color(red: 22/255, green: 163/255, blue: 74/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.green.opacity(0.5), radius: 8)
            }

            Text("Session Complete!")
                .font(.system(size: 24, weight: .black))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

            Text("Great job staying focused!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            ZStack {
                gradientBackground
                Color.white.opacity(0.05)  // Glass effect
                
                // Optional: subtle pattern or texture
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
    }
}