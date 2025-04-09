import SwiftUI

struct ControlButton<Content: View>: View {
    let title: String
    let content: Content
    var isDisabled: Bool = false
    var reducedHeight: Bool = false  // New parameter

    init(
        title: String,
        isDisabled: Bool = false,
        reducedHeight: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.reducedHeight = reducedHeight
        self.content = content()
    }

    var body: some View {
        VStack(spacing: reducedHeight ? 4 : 6) {  // Conditional spacing
            Text(title).font(.system(size: 14, weight: .bold)).tracking(2)
                .foregroundColor(isDisabled ? .white.opacity(0.4) : .white.opacity(0.9))

            HStack {
                content.frame(height: reducedHeight ? 32 : 36)  // Reduce height conditionally
                    .opacity(isDisabled ? 0.4 : 1.0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, reducedHeight ? 8 : 10)  // Reduce padding conditionally
        .padding(.horizontal, 14)  // Reduced from 16 to 14
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mutedPink.opacity(0.3), Theme.deepBlue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Glass effect overlay
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDisabled ? 0.2 : 0.5),
                                Color.white.opacity(isDisabled ? 0.05 : 0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                // Track
                Capsule()
                    .fill(
                        configuration.isOn
                            ? Theme.accentGradient
                            : LinearGradient(
                                colors: [Theme.darkBlue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: 50, height: 28)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: configuration.isOn ? Theme.yellowShadow : Color.black.opacity(0.1),
                        radius: 3
                    )

                // Thumb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 11 : -11)
                    .animation(
                        .spring(response: 0.2, dampingFraction: 0.7),
                        value: configuration.isOn
                    )
            }
        }
        .onTapGesture { withAnimation { configuration.isOn.toggle() } }
    }
}

struct ModernPickerStyle: View {
    let options: [String]
    @Binding var selection: Int
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: { if !isDisabled { withAnimation(.spring()) { selection = index } } }
                ) {
                    Text(options[index])
                        .font(.system(size: 15, weight: selection == index ? .bold : .medium))
                        .foregroundColor(selection == index ? Theme.yellow : .white.opacity(0.7))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            ZStack {
                                if selection == index {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Theme.mutedPink.opacity(0.7),
                                                    Theme.deepBlue.opacity(0.5),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.silveryGradient2, lineWidth: 1)
                                        )
                                        .shadow(color: Theme.purpleShadow.opacity(0.3), radius: 4)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle()).disabled(isDisabled)
            }
        }
        .padding(4).background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.2)))
        .opacity(isDisabled ? 0.5 : 1)
    }
}
