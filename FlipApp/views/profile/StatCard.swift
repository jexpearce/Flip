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

      Text(title)
        .font(.system(size: 10, weight: .heavy))
        .tracking(1)
        .foregroundColor(Theme.neonYellow.opacity(0.7))

      Text(unit)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(Theme.lightGray)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 15)
    .background(Theme.darkGray)
    .cornerRadius(15)
  }
}
