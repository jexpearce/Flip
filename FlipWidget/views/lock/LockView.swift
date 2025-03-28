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
                    Theme.deepMidnightPurple,
                    Theme.darkPurpleBlue,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content with glass effect container
            VStack(spacing: 8) {  // Reduced from 12 to 8 for more compact layout
                // Order matters - check wasSuccessful first
                if let wasSuccessful = context.state.wasSuccessful,
                    wasSuccessful
                {
                    SuccessLockView()
                        .transition(.opacity.combined(with: .scale))
                        .id("success")  // Force view refresh when state changes
                } else if context.state.isFailed {
                    FailedLockView()
                        .transition(.opacity.combined(with: .scale))
                        .id("failed")  // Force view refresh when state changes
                } else {
                    ActiveLockView(context: context)
                        .transition(.opacity.combined(with: .scale))
                        .id("active")  // Force view refresh when state changes
                }
            }
            .padding(8)  // Reduced from standard padding to 8
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
                                Color.white.opacity(0.1),
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
