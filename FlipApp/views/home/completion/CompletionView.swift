import SwiftUI

struct CompletionView: View {
  @EnvironmentObject var appManager: AppManager

  var body: some View {
    VStack(spacing: 30) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      Text("Congratulations!").title()

      VStack(spacing: 15) {
        Text("You completed")
          .font(.system(size: 20))
          .foregroundColor(.white)

        Text("\(appManager.selectedMinutes) minutes")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(.white)

        Text("of focused time!")
          .font(.system(size: 20))
          .foregroundColor(.white)
      }

      Button(action: {
        appManager.currentState = .initial
      }) {
        Text("Back to Home")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.black)
          .frame(width: 200, height: 50)
          .background(Color.white)
          .cornerRadius(25)
      }
      .padding(.top, 30)
    }
    .background(Theme.mainGradient)
    .padding(.horizontal, 30)
  }

}
