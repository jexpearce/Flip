import SwiftUI

struct SetupView: View {
  @EnvironmentObject var appManager: AppManager

  var body: some View {
    VStack(spacing: 30) {
      // Title with icon
      HStack(spacing: 15) {
        Image(systemName: "arrow.2.squarepath")
          .font(.system(size: 40))
          .foregroundColor(Theme.neonYellow)

        Text("FLIP")
          .font(.system(size: 60, weight: .black, design: .monospaced))
          .tracking(5)
          .foregroundColor(.white)
      }
      .padding(.top, 30)

      // Set Time Title
      Text("SET TIME").title()

      // Circular Time Picker
      CircularTime(selectedMinutes: $appManager.selectedMinutes)

      // Settings Controls
      HStack(spacing: 20) {
        ControlButton(
          title: "PAUSE",
          content: {
            Toggle("", isOn: $appManager.allowPauses)
              .onChange(of: appManager.allowPauses) {
                if appManager.allowPauses {
                  appManager.maxPauses = 3
                } else {
                  appManager.maxPauses = 0
                }
              }
              .labelsHidden()
              .tint(Theme.neonYellow)
          }
        )

        // Pause Toggle
        ControlButton(
          title: "PAUSES",
          content: {
            Menu {
              Picker("", selection: $appManager.maxPauses) {
                ForEach(0...10, id: \.self) { number in
                  Text("\(number)").tag(number)
                }
              }
            } label: {
              HStack {
                Text("\(appManager.maxPauses)")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(
                    appManager.allowPauses ? Theme.neonYellow : .gray)
                Image(systemName: "chevron.down")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundColor(
                    appManager.allowPauses ? Theme.neonYellow : .gray)
              }
            }
            .disabled(!appManager.allowPauses)
          }
        )
      }
      .padding(.horizontal)
      .padding(.top, -10)

      // Begin Button
      Button(action: {
        appManager.startCountdown()
      }) {
        Text("BEGIN")
          .font(.system(size: 24, weight: .black, design: .rounded))
          .tracking(2)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity)
          .frame(height: 60)
          .background(
            Theme.neonYellow
              .shadow(color: Theme.neonYellow.opacity(0.5), radius: 10)
          )
          .cornerRadius(30)
      }
      .padding(.horizontal, 40)

      Spacer()
    }
  }
}
