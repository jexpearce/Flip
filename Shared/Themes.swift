import SwiftUI

struct Theme {
    // Base Colors
    static let pink = Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255)  // #EC4899
    static let purple = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)  // #9333EA
    static let deepPurple = Color(
        red: 88 / 255, green: 28 / 255, blue: 135 / 255)  // Darker purple
    static let vibrantPurple = Color(
        red: 168 / 255, green: 85 / 255, blue: 247 / 255)  // Brighter purple
    static let glowWhite = Color.white
    static let mediumGray = Color(white: 0.15)
    static let lightGray = Color(white: 0.3)
    static let offWhite = Color(white: 0.9)
    static let yellow = Color(red: 250 / 255, green: 204 / 255, blue: 21 / 255)  // Vibrant yellow
    static let darkYellow = Color(
        red: 202 / 255, green: 138 / 255, blue: 4 / 255)  // Darker yellow
    static let orange = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)  // Warm Orange
    static let darkOrange = Color(
        red: 194 / 255, green: 65 / 255, blue: 12 / 255)  // Deep Orange
    static let blue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)  // Rich Blue
    static let darkBlue = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)  // Deep Blue
    static let darkGray = Color(red: 24 / 255, green: 24 / 255, blue: 27 / 255)  // Almost Black
    static let nearBlack = Color(red: 17 / 255, green: 12 / 255, blue: 34 / 255)  // Very dark purple-tinted black

    static let mutedGreen = Color(
        red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    static let darkerGreen = Color(
        red: 22 / 255, green: 163 / 255, blue: 74 / 255)

    // Glass Effect Colors
    static let glassEffect = Color(
        red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0.1)
    static let glassHighlight = Color(
        red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0.15)
    static let glassShadow = Color(
        red: 0 / 255, green: 0 / 255, blue: 0 / 255, opacity: 0.2)

    static let lightTealBlue = Color(
        red: 56 / 255, green: 189 / 255, blue: 248 / 255)
    static let darkTealBlue = Color(
        red: 14 / 255, green: 165 / 255, blue: 233 / 255)

    static let deepMidnightPurple = Color(
        red: 20 / 255, green: 10 / 255, blue: 40 / 255)  // Darker
    static let darkPurpleBlue = Color(
        red: 35 / 255, green: 20 / 255, blue: 90 / 255)
    static let mutedPurple = Color(red: 26 / 255, green: 14 / 255, blue: 47 / 255)
    static let blueishPurple = Color(red: 16 / 255, green: 24 / 255, blue: 57 / 255)

    // Gradients
    static let mainGradient = LinearGradient(
        colors: [
            deepMidnightPurple,
            darkPurpleBlue,
            nearBlack,
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Button Colors
    static let buttonGradient = LinearGradient(
        colors: [
            vibrantPurple,
            deepPurple,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let yellowAccentGradient = LinearGradient(
        colors: [
            yellow.opacity(0.9),
            darkYellow.opacity(0.8),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let headerGradient = LinearGradient(
        colors: [
            vibrantPurple,
            deepPurple,
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Glassy surfaces
    static let glassyPurpleGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.3),
            Color.white.opacity(0.1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassyDarkGradient = LinearGradient(
        colors: [
            Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255).opacity(0.3),
            Theme.deepMidnightPurple.opacity(0.1),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tabBarGradient = LinearGradient(
        colors: [
            nearBlack.opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [
            yellow,
            orange,
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let indigoPurpleGradient = LinearGradient(
        colors: [
            Theme.deepMidnightPurple,  // Deep midnight purple
            Color(red: 30 / 255, green: 18 / 255, blue: 60 / 255),  // Medium midnight purple
            Color(red: 79 / 255, green: 70 / 255, blue: 229 / 255).opacity(0.4),  // Indigo
            Color(red: 67 / 255, green: 56 / 255, blue: 202 / 255).opacity(0.3),  // Deeper indigo
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let indigoAccent = Color(
        red: 79 / 255, green: 70 / 255, blue: 229 / 255)
    static let indigoGlow = Color(
        red: 79 / 255, green: 70 / 255, blue: 229 / 255
    ).opacity(0.5)

    // Shadows
    static let purpleShadow = Color(
        red: 147 / 255, green: 51 / 255, blue: 234 / 255
    ).opacity(0.5)
    static let yellowShadow = Theme.yellow.opacity(0.5)
}

// Text Style Extensions
extension Text {
    func title() -> Text {
        self
            .font(.system(size: 28, weight: .black))
            .tracking(8)
            .foregroundColor(.white)
    }

    func subtitle() -> Text {
        self
            .font(.system(size: 12, weight: .medium))
            .tracking(4)
            .foregroundColor(.white.opacity(0.7))
    }

    func retro() -> Text {
        self
            .font(.system(size: 60, weight: .black))
            .tracking(8)
            .foregroundColor(.white)
    }

    func japanese() -> Text {
        self
            .font(.system(size: 14, weight: .medium))
            .tracking(3)
            .foregroundColor(.white.opacity(0.7))
    }
}

// View Extensions for Common Styles
extension View {
    func glowingButton() -> some View {
        self
            .font(.system(size: 24, weight: .black))
            .tracking(4)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Theme.headerGradient)

                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Theme.purpleShadow, radius: 10)
    }

    func controlBackground() -> some View {
        self
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4)
    }

    func retroGlow() -> some View {
        self.shadow(color: Theme.yellow.opacity(0.5), radius: 8)
    }

    func glassCard() -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: 6)
    }
}
