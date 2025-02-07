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
        // Retries Setting
        ControlButton(
          title: "RETRIES",
          content: {
            Menu {
              Picker("", selection: $appManager.allowedFlips) {
                Text("NONE").tag(0)
                ForEach(1...5, id: \.self) { number in
                  Text("\(number)").tag(number)
                }
              }
            } label: {
              HStack {
                Text(
                  appManager.allowedFlips == 0
                    ? "NONE" : "\(appManager.allowedFlips)"
                )
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.neonYellow)
                Image(systemName: "chevron.down")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundColor(Theme.neonYellow)
              }
            }
          }
        )

        // Pause Toggle
        ControlButton(
          title: "PAUSE",
          content: {
            Toggle("", isOn: $appManager.allowPause)
              .onChange(of: appManager.allowPause) {
                if appManager.allowPause && appManager.allowedFlips == 0 {
                  appManager.allowedFlips = 1
                }
              }
              .labelsHidden()
              .tint(Theme.neonYellow)
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
