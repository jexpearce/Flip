import SwiftUI

struct Theme {
    // Base Colors
    static let pink = Color(red: 236 / 255, green: 72 / 255, blue: 153 / 255)  // #EC4899
    static let purple = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)  // #9333EA
    static let deepPurple = Color(red: 88 / 255, green: 28 / 255, blue: 135 / 255)  // Darker purple
    static let vibrantPurple = Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)  // Brighter purple

    static let glowWhite = Color.white
    static let offWhite = Color(white: 0.9)
    // CONSOLIDATED: yellow family
    static let yellow = Color(red: 250 / 255, green: 204 / 255, blue: 21 / 255)  // Vibrant yellow
    static let darkYellow = Color(red: 202 / 255, green: 138 / 255, blue: 4 / 255)  // Darker yellow
    // yellowyOrange and orangeyYellow can be consolidated with yellow and darkYellow
    static let yellowyOrange = Color(red: 234 / 255, green: 179 / 255, blue: 8 / 255)
    static let orangeyYellow = Color(red: 220 / 255, green: 170 / 255, blue: 0 / 255)
    static let brightYellow = Color(red: 253 / 255, green: 224 / 255, blue: 71 / 255)  // Lighter yellow

    // CONSOLIDATED: orange family
    static let orange = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)  // Warm Orange
    static let saturatedOrange = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)  // Similar to orange but more saturated

    // Blues
    static let blue = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)  // Rich Blue
    // CONSOLIDATED: deepBlue and darkBlue are similar
    static let darkBlue = Color(red: 30 / 255, green: 58 / 255, blue: 138 / 255)  // Deep Blue
    static let deepBlue = Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255)  // More purple-tinted blue

    static let darkGray = Color(red: 24 / 255, green: 24 / 255, blue: 27 / 255)  // Almost Black
    static let nearBlack = Color(red: 17 / 255, green: 12 / 255, blue: 34 / 255)  // Very dark purple-tinted black
    static let silverBlue = Color(red: 28 / 255, green: 28 / 255, blue: 45 / 255)
    static let oldBrick = Color(red: 153 / 255, green: 27 / 255, blue: 27 / 255)
    static let cyanBlue = Color(red: 125 / 255, green: 211 / 255, blue: 252 / 255)
    static let blue800 = Color(red: 30 / 255, green: 64 / 255, blue: 175 / 255)
    static let purple800 = Color(red: 91 / 255, green: 33 / 255, blue: 182 / 255)
    // Colors extracted from views
    static let periwinkle = Color(red: 156 / 255, green: 163 / 255, blue: 231 / 255)
    // CONSOLIDATED: light blue family
    static let lightBlue = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
    static let standardBlue = Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
    static let lightTealBlue = Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255)
    static let darkTealBlue = Color(red: 14 / 255, green: 165 / 255, blue: 233 / 255)
    static let emeraldGreen = Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255)
    static let brightAmber = Color(red: 249 / 255, green: 180 / 255, blue: 45 / 255)
    static let forestGreen = Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255)
    static let brightFuchsia = Color(red: 236 / 255, green: 64 / 255, blue: 255 / 255)
    static let darkRuby = Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255)
    // CONSOLIDATED: purple variants
    // mediumPurple and mutedPurple are similar dark purples
    static let mediumPurple = Color(red: 65 / 255, green: 16 / 255, blue: 94 / 255)
    static let mutedPurple = Color(red: 26 / 255, green: 14 / 255, blue: 47 / 255)
    static let lighterPurple = Color(red: 38 / 255, green: 18 / 255, blue: 58 / 255)
    static let electricViolet = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255)  // Similar to purple
    static let softViolet = Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
    static let goldenBrown = Color(red: 133 / 255, green: 77 / 255, blue: 14 / 255)
    static let russetBrown = Color(red: 113 / 255, green: 63 / 255, blue: 18 / 255)
    static let silverLight = Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255)
    static let silverDark = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let bronzeLight = Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255)
    static let bronzeDark = Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255)
    static let oliveGreen = Color(red: 20 / 255, green: 83 / 255, blue: 45 / 255)
    static let purplishNavy = Color(red: 40 / 255, green: 25 / 255, blue: 65 / 255)
    static let darkCyanBlue = Color(red: 14 / 255, green: 101 / 255, blue: 151 / 255)
    static let deeperCyanBlue = Color(red: 12 / 255, green: 74 / 255, blue: 110 / 255)
    static let indigoDark = Color(red: 14 / 255, green: 30 / 255, blue: 60 / 255)
    static let purpleIndigo = Color(red: 128 / 255, green: 65 / 255, blue: 217 / 255)
    static let midnightNavy = Color(red: 30 / 255, green: 30 / 255, blue: 46 / 255)
    // CONSOLIDATED: green variants
    static let mutedGreen = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255)
    static let darkerGreen = Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)
    // CONSOLIDATED: This is actually purple, not pink
    static let mutedPink = Color(red: 60 / 255, green: 30 / 255, blue: 110 / 255)
    // CONSOLIDATED: midnight purple variants
    static let deepMidnightPurple = Color(red: 20 / 255, green: 10 / 255, blue: 40 / 255)  // Darker
    static let mediumMidnightPurple = Color(red: 30 / 255, green: 18 / 255, blue: 60 / 255)
    static let darkPurpleBlue = Color(red: 35 / 255, green: 20 / 255, blue: 90 / 255)
    static let blueishPurple = Color(red: 16 / 255, green: 24 / 255, blue: 57 / 255)
    // CONSOLIDATED: red variants
    static let mutedRed = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
    static let darkerRed = Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255)
    static let darkRed = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)  // Between mutedRed and darkerRed

    // Medal colors
    static let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let silverColor = LinearGradient(
        colors: [
            silverLight,  // Using existing silverLight color
            silverDark,  // Using existing silverDark color
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Gradients

    static let mainGradient = LinearGradient(
        colors: [deepMidnightPurple, darkPurpleBlue, nearBlack],
        startPoint: .top,
        endPoint: .bottom
    )

    // Enhanced gradient with more vibrant teal-green tones
    static let feedGradient = LinearGradient(
        colors: [
            Color(red: 17 / 255, green: 29 / 255, blue: 48 / 255),  // Brighter deep blue
            Color(red: 23 / 255, green: 42 / 255, blue: 58 / 255),  // Enhanced midnight teal
            Color(red: 15 / 255, green: 38 / 255, blue: 52 / 255),  // Vibrant deep teal
            Color(red: 18 / 255, green: 32 / 255, blue: 55 / 255),  // Rich blue-purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let amberBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 120 / 255, green: 53 / 255, blue: 15 / 255).opacity(0.4),  // Amber 900
            Color(red: 146 / 255, green: 64 / 255, blue: 14 / 255).opacity(0.3),  // Amber 800
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buildingGradient = LinearGradient(
        colors: [
            Color(red: 146 / 255, green: 123 / 255, blue: 21 / 255).opacity(0.3),
            Color(red: 133 / 255, green: 109 / 255, blue: 7 / 255).opacity(0.2),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let nonBuildingGradient = LinearGradient(
        colors: [Theme.oldBrick.opacity(0.3), Theme.darkRuby.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [
            Color(red: 25 / 255, green: 52 / 255, blue: 65 / 255).opacity(0.85),
            Color(red: 17 / 255, green: 48 / 255, blue: 66 / 255).opacity(0.9),
            Color(red: 15 / 255, green: 35 / 255, blue: 55 / 255).opacity(0.95),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let nonSuccessGradient = LinearGradient(
        colors: [
            Color(red: 55 / 255, green: 30 / 255, blue: 50 / 255).opacity(0.95),
            Color(red: 45 / 255, green: 28 / 255, blue: 58 / 255).opacity(0.9),
            Color(red: 35 / 255, green: 24 / 255, blue: 55 / 255).opacity(0.85),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let profileGradient = LinearGradient(
        colors: [
            deepMidnightPurple, mediumMidnightPurple, darkCyanBlue.opacity(0.7),  // Using existing darkCyanBlue
            deeperCyanBlue.opacity(0.6),  // Using existing deeperCyanBlue
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Regional gradient
    static let regionalGradient = LinearGradient(
        colors: [
            deepMidnightPurple,  // Deep midnight purple
            Color(red: 28 / 255, green: 14 / 255, blue: 45 / 255),  // Midnight purple
            Color(red: 35 / 255, green: 14 / 255, blue: 40 / 255),  // Purple with slight red
            Color(red: 30 / 255, green: 12 / 255, blue: 36 / 255),  // Back to purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Orange-purple theme colors for friend-related views
    static let orangePurpleGradient = LinearGradient(
        colors: [
            Theme.mutedPurple,  // Deep purple
            Color(red: 47 / 255, green: 17 / 255, blue: 67 / 255),  // Medium purple
            Color(red: 65 / 255, green: 20 / 255, blue: 60 / 255),  // Purple with hint of red
            Color(red: 35 / 255, green: 15 / 255, blue: 50 / 255),  // Back to deeper purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let baseGradient = LinearGradient(
        colors: [
            Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255),  // Dark blue-green
            Color(red: 24 / 255, green: 45 / 255, blue: 60 / 255),  // Midnight teal
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    // Custom gradient for the creation view
    static let creationGradient = LinearGradient(
        colors: [
            Color(red: 35 / 255, green: 16 / 255, blue: 55 / 255),  // Deep midnight purple
            Color(red: 42 / 255, green: 22 / 255, blue: 60 / 255),  // Medium purple with slight red
            Color(red: 48 / 255, green: 24 / 255, blue: 65 / 255),  // Light purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    // Custom gradient for the selection view
    static let selectionGradient = LinearGradient(
        colors: [
            mediumMidnightPurple,  // Deep midnight purple
            lighterPurple,  // Lighter purple with slight red
            Color(red: 45 / 255, green: 20 / 255, blue: 60 / 255),  // Medium purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Button Colors
    static let buttonGradient = LinearGradient(
        colors: [vibrantPurple, deepPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let yellowAccentGradient = LinearGradient(
        colors: [yellow.opacity(0.9), darkYellow.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [yellow, orange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let indigoPurpleGradient = LinearGradient(
        colors: [
            deepMidnightPurple,  // Deep midnight purple
            mediumMidnightPurple,  // Medium midnight purple
            indigoAccent.opacity(0.4),  // Using indigoAccent
            Color(red: 67 / 255, green: 56 / 255, blue: 202 / 255).opacity(0.3),  // Deeper indigo
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let indigoAccent = Color(red: 79 / 255, green: 70 / 255, blue: 229 / 255)
    static let indigoGlow = indigoAccent.opacity(0.5)  // Using indigoAccent with opacity

    // Shadows
    static let purpleShadow = purple.opacity(0.5)  // Using existing purple color
    static let yellowShadow = yellow.opacity(0.5)  // Using existing yellow color

    static let yellowyGradient = LinearGradient(
        colors: [Theme.yellow, Theme.yellowyOrange],
        startPoint: .top,
        endPoint: .bottom
    )
    static let purplyGradient = LinearGradient(
        colors: [Theme.vibrantPurple, Theme.deepPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let silveryGradient = LinearGradient(
        colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let silveryGradient2 = LinearGradient(
        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let silveryGradient3 = LinearGradient(
        colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let silveryGradient4 = LinearGradient(
        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let silveryGradient5 = LinearGradient(
        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let redGradient = LinearGradient(
        colors: [Theme.mutedRed, Theme.darkerRed],
        startPoint: .top,
        endPoint: .bottom
    )
    static let redGradient2 = LinearGradient(
        colors: [Theme.mutedRed, Theme.darkRed],
        startPoint: .top,
        endPoint: .bottom
    )
    static let pinkBlueGradient = LinearGradient(
        colors: [Theme.mutedPink.opacity(0.6), Theme.deepBlue.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let darkPurpleGradient = LinearGradient(
        colors: [Theme.deepMidnightPurple, Theme.mediumMidnightPurple],
        startPoint: .top,
        endPoint: .bottom
    )
    static let tealyGradient = LinearGradient(
        colors: [Theme.lightTealBlue, Theme.darkTealBlue],
        startPoint: .top,
        endPoint: .bottom
    )
}

// View Extensions for Common Styles
extension View {

    func retroGlow() -> some View { self.shadow(color: Theme.yellow.opacity(0.5), radius: 8) }

}
