import ActivityKit
import SwiftUI
import WidgetKit

struct LockView: View {
    let context: ActivityViewContext<FlipActivityAttributes>

    var body: some View {
        ZStack {
            // Base gradient background that covers the entire widget
            LinearGradient(
                colors: [
                    Color(red: 20/255, green: 10/255, blue: 40/255),
                    Color(red: 35/255, green: 20/255, blue: 90/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content with glass effect container
            VStack(spacing: 12) {
                // Order matters - check wasSuccessful first
                if let wasSuccessful = context.state.wasSuccessful, wasSuccessful {
                    SuccessLockView()
                        .transition(.opacity.combined(with: .scale))
                        .id("success") // Force view refresh when state changes
                } else if context.state.isFailed {
                    FailedLockView()
                        .transition(.opacity.combined(with: .scale))
                        .id("failed") // Force view refresh when state changes
                } else {
                    ActiveLockView(context: context)
                        .transition(.opacity.combined(with: .scale))
                        .id("active") // Force view refresh when state changes
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))  // Glass effect
            )
            .overlay(  // Subtle border
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}