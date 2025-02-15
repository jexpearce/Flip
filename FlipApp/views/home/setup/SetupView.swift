import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appManager: AppManager

    var body: some View {
        VStack(spacing: 25) {
            // Title with icon
            VStack(spacing: 4) {
                HStack(spacing: 15) {
                    Text("FLIP")
                        .retro()
                        .retroGlow()

                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .retroGlow()
                }

                Text("TRUE PRODUCTIVITY").subtitle()
            }
            .padding(.top, 20)

            // Set Time Title
            VStack(spacing: 4) {
                Text("SET TIME").title()
                    .retroGlow()  // Added here
                Text("タイマーの設定").japanese()
            }

            // Circular Time Picker
            CircularTime(selectedMinutes: $appManager.selectedMinutes)
                .padding(.top, -10)

            // Settings Controls
            HStack(spacing: 20) {
                // Pause Toggle
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
                            .tint(Color.white)
                    }
                )

                // Number of Pauses
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
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(
                                        appManager.allowPauses ? .white : .gray)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(
                                        appManager.allowPauses ? .white : .gray)
                            }
                        }
                        .disabled(!appManager.allowPauses)
                    }
                )
            }
            .padding(.horizontal)

            // Begin Button
            Button(action: {
                appManager.startCountdown()
            }) {
                Text("BEGIN").glowingButton()
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)

            Spacer()
        }
        .background(Theme.mainGradient)
    }
}
