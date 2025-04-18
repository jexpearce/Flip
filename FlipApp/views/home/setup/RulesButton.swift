import SwiftUI

struct RulesButtonView: View {
    @Binding var showRules: Bool

    var body: some View {
        Button(action: { withAnimation(.spring()) { showRules = true } }) {
            ZStack {
                Circle().fill(Theme.buttonGradient).frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Theme.silveryGradient, lineWidth: 1))
                    .shadow(color: Theme.lightTealBlue.opacity(0.3), radius: 4)

                Text("?").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }
        }
    }
}
