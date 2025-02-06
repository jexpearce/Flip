import SwiftUI

struct Theme {
    static let neonYellow = Color(red: 232/255, green: 255/255, blue: 57/255)
    static let darkGray = Color(white: 0.12)
    static let mediumGray = Color(white: 0.18)
    static let lightGray = Color(white: 0.25)
    
    static let mainGradient = LinearGradient(
        colors: [.black, darkGray],
        startPoint: .top,
        endPoint: .bottom
    )
}

