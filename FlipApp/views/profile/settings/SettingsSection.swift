import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.system(size: 16, weight: .black)).tracking(5).foregroundColor(.white)
                .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)

            content
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mediumMidnightPurple, Theme.purplishNavy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16).stroke(Theme.silveryGradient2, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8)
    }
}
