import SwiftUI

struct CountdownView: View {
  @EnvironmentObject var appManager: AppManager
  var body: some View {
    VStack(spacing: 25) {
      Text("GET READY").title()

      Text("\(appManager.countdownSeconds)")
        .font(.system(size: 120, weight: .black))
        .foregroundColor(.white)
        .animation(.spring(), value: appManager.countdownSeconds)  // This replaces contentTransition
        .scaleEffect(1.2)  // Makes the number slightly larger

      Text("1. LOCK YOUR PHONE")
        .font(.system(size: 20, weight: .heavy))
        .tracking(2)
        .foregroundColor(Theme.neonYellow.opacity(0.7))
      Text("2. FLIP IT OVER!")
        .font(.system(size: 20, weight: .heavy))
        .tracking(2)
        .foregroundColor(Theme.neonYellow.opacity(0.7))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.mainGradient)
  }
}
