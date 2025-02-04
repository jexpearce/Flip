
import SwiftUI

struct AppIcon: View {
    var body: some View {
        ZStack {
            Color.black
            
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 180))
                .foregroundColor(Theme.neonYellow)
        }
        .frame(width: 1024, height: 1024) // App Store size
        .ignoresSafeArea()
    }
}

// Preview this view
struct AppIcon_Previews: PreviewProvider {
    static var previews: some View {
        AppIcon()
    }
}
