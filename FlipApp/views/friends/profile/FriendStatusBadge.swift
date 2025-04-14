import SwiftUI

struct FriendStatusBadge: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)

            Text(text).font(.system(size: 14, weight: .medium)).foregroundColor(color)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(
            Capsule().fill(color.opacity(0.15))
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        )
        .padding(.top, -5)
    }
}
