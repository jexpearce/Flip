import SwiftUI

struct TrackingView: View {
  @EnvironmentObject var appManager: AppManager

  var body: some View {
    VStack(spacing: 30) {
      // Status Icon
      Image(
        systemName: appManager.isFaceDown
          ? "checkmark.circle.fill" : "xmark.circle.fill"
      )
      .font(.system(size: 60))
      .foregroundColor(appManager.isFaceDown ? Theme.neonYellow : .red)

      // Status Text
      Text(appManager.isFaceDown ? "STAY FOCUSED!" : "FLIP YOUR PHONE!")
        .title()
        .foregroundColor(appManager.isFaceDown ? Theme.neonYellow : .red)
        .multilineTextAlignment(.center)

      VStack(spacing: 15) {
        if appManager.isFaceDown {
          Text("REMAINING")
            .font(.system(size: 16, weight: .heavy))
            .tracking(4)
            .foregroundColor(Theme.neonYellow.opacity(0.7))
        }
        Text(appManager.remainingTimeString)
          .font(.system(size: 50, weight: .heavy))
          .foregroundColor(.white)
          .padding(.horizontal, 40)
          .padding(.vertical, 20)
          .background(
            RoundedRectangle(cornerRadius: 25)
              .fill(Theme.darkGray)
              .overlay(
                RoundedRectangle(cornerRadius: 25)
                  .strokeBorder(Theme.neonYellow.opacity(0.3), lineWidth: 1)
              )
          )
      }
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)

  }
}
