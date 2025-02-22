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
                    Color(red: 26/255, green: 14/255, blue: 47/255),
                    Color(red: 30/255, green: 58/255, blue: 138/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content with glass effect container
            VStack(spacing: 12) {
                if context.state.isFailed {
                    FailedLockView()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    ActiveLockView(context: context)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))  // Glass effect
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