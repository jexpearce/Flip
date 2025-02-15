import SwiftUI

struct Theme {
    // Colors
    static let glowWhite = Color.white
    static let darkGray = Color(white: 0.08)
    static let mediumGray = Color(white: 0.15)
    static let lightGray = Color(white: 0.3)
    static let offWhite = Color(white: 0.7)

    // Gradients
    static let mainGradient = LinearGradient(
        colors: [Color.black.opacity(0.8), .black],
        startPoint: .top,
        endPoint: .bottom
    )
}

// Text Style Extensions
extension Text {
    func title() -> Text {
        self
            .font(.system(size: 24, weight: .bold))
            .tracking(8)
            .foregroundColor(.white)
    }

    func subtitle() -> Text {
        self
            .font(.system(size: 12, weight: .medium))
            .tracking(5)
            .foregroundColor(Color.gray.opacity(0.8))
    }

    func retro() -> Text {
        self
            .font(.system(size: 60, weight: .black, design: .default))
            .tracking(8)
            .foregroundColor(.white)
    }

    func japanese() -> Text {
        self
            .font(.system(size: 14, weight: .regular))
            .tracking(3)
            .foregroundColor(Color.gray.opacity(0.8))
    }
}

// View Extensions for Common Styles
extension View {
    func glowingButton() -> some View {
        self
            .font(.system(size: 24, weight: .black))
            .tracking(4)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                Color.white
                    .shadow(color: .white.opacity(0.5), radius: 10)
            )
            .cornerRadius(30)
    }

    func controlBackground() -> some View {
        self
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .background(Theme.darkGray)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
    }

    func retroGlow() -> some View {
        self.shadow(color: .white.opacity(0.5), radius: 10)
    }
}
