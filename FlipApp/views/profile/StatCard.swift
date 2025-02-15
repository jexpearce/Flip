import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
                .retroGlow()

            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))

            Text(unit)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.lightGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
