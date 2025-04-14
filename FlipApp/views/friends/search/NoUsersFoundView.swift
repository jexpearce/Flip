import SwiftUI

struct NoUsersFoundView: View {
    let message: String
    let icon: String

    private let orangeAccent = Theme.orange

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 50))
                .foregroundColor(orangeAccent.opacity(0.6)).padding(.top, 30)

            Text(message).font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}
