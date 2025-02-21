
import SwiftUI

struct Theme {
    // Base Colors
    static let pink = Color(red: 236/255, green: 72/255, blue: 153/255)      // #EC4899
    static let purple = Color(red: 147/255, green: 51/255, blue: 234/255)    // #9333EA
    static let glowWhite = Color.white
    static let mediumGray = Color(white: 0.15)
    static let lightGray = Color(white: 0.3)
    static let offWhite = Color(white: 0.7)
    static let orange = Color(red: 249/255, green: 115/255, blue: 22/255)    // Warm Orange
    static let darkOrange = Color(red: 194/255, green: 65/255, blue: 12/255) // Deep Orange
    static let blue = Color(red: 37/255, green: 99/255, blue: 235/255)       // Rich Blue
    static let darkBlue = Color(red: 30/255, green: 58/255, blue: 138/255)   // Deep Blue
    static let darkGray = Color(red: 24/255, green: 24/255, blue: 27/255)    // Almost Black
        
    // Glass Effect Colors
        static let glassEffect = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.1)
        
        // Button Colors - A more sophisticated palette
    static let buttonGradient = LinearGradient(
        colors: [
                Color(red: 56/255, green: 189/255, blue: 248/255),  // Lighter teal blue
                Color(red: 14/255, green: 165/255, blue: 233/255)   // Darker teal blue
            ],
        startPoint: .top,
        endPoint: .bottom
    )
        
    // Gradients
    static let mainGradient = LinearGradient(
        colors: [
            Color(red: 26/255, green: 14/255, blue: 47/255),  // Deep Midnight Purple
                        Color(red: 59/255, green: 130/255, blue: 246/255), // Electric Blue
                        Color(red: 26/255, green: 14/255, blue: 47/255)  // Electric Blue
                ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let headerGradient = LinearGradient(
        colors: [orange, blue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let tabBarGradient = LinearGradient(
        colors: [Color(red: 15/255, green: 15/255, blue: 30/255).opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let actionGradient = LinearGradient(
            colors: [orange, blue],
            startPoint: .leading,
            endPoint: .trailing
        )
}

// Text Style Extensions
extension Text {
    func title() -> Text {
        self
            .font(.system(size: 28, weight: .black))  // Removed rounded design
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
            .font(.system(size: 60, weight: .black))  // Original sharp font
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
            .font(.system(size: 24, weight: .black))  // Sharp, not rounded
            .tracking(4)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Theme.headerGradient)
            .cornerRadius(30)
    }

    func controlBackground() -> some View {
        self
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
    }

    func retroGlow() -> some View {
        self.shadow(color: Theme.orange.opacity(0.3), radius: 8)
    }
}
