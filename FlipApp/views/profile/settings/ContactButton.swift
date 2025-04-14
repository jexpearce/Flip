import SwiftUI

struct ContactButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(Theme.lightTealBlue)

                Text(text).font(.system(size: 16, weight: .medium)).foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right.square").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
