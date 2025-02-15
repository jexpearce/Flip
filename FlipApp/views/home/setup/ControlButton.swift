import SwiftUI

struct ControlButton<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .heavy))
                .tracking(5)
                .foregroundColor(.white)
                .retroGlow()  // Added here

            content
        }
        .frame(maxWidth: .infinity)
        .controlBackground()
    }
}