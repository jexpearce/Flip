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
                .tracking(2)
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Spacer()
                content
                    .frame(height: 32)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                // Base glass effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.buttonGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.glassEffect)
                    )
                
                // Frosted edge
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // Inner glow
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.orange.opacity(0.2), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(y: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                // Track
                Capsule()
                    .fill(configuration.isOn ? Theme.orange : Theme.darkBlue.opacity(0.3))
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .offset(x: configuration.isOn ? 11 : -11)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isOn)
            }
        }
        .onTapGesture {
            withAnimation {
                configuration.isOn.toggle()
            }
        }
    }
}