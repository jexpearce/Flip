import SwiftUI

struct PulsingTabIndicator: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(Theme.darkRed.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.5)
            
            // Inner circle
            Circle()
                .fill(Theme.darkRed)
                .frame(width: 10, height: 10)
        }
        .offset(y: -15) // Position above tab icon
        .onAppear {
            // Start pulsing animation
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}