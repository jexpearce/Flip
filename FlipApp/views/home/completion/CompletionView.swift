import SwiftUI

struct CompletionView: View {
  @EnvironmentObject var manager: Manager

  var body: some View {
    VStack(spacing: 30) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 60))
        .foregroundColor(Theme.neonYellow)

      Text("Congratulations!")
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundColor(Theme.neonYellow)

      VStack(spacing: 15) {
        Text("You completed")
          .font(.system(size: 20))
          .foregroundColor(.white)

        Text("\(manager.selectedMinutes) minutes")
          .font(.system(size: 40, weight: .bold))
          .foregroundColor(.white)

        Text("of focused time!")
          .font(.system(size: 20))
          .foregroundColor(.white)
      }

      Button(action: {
        manager.currentState = .initial
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
    .padding(.horizontal, 30)
  }
}
