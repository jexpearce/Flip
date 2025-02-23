import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var isButtonPressed = false

    var body: some View {

        VStack(spacing: 25) {
            // Title Section with logo to the right
            HStack(spacing: 15) {
                Text("FLIP")
                    .font(.system(size: 80, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()

                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .retroGlow()
                    .rotationEffect(.degrees(isButtonPressed ? 360 : 0))
                    .animation(
                        .spring(response: 2.0, dampingFraction: 0.6)
                            .repeatForever(autoreverses: false),
                        value: isButtonPressed
                    )
            }
            .padding(.top, 50)
            .onAppear { isButtonPressed = true }

            // Set Time Title
            VStack(spacing: 4) {
                Text("SET TIME")
                    .font(.system(size: 24, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()
                Text("タイマーの設定")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(3)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Circular Time Picker
            CircularTime(selectedMinutes: $appManager.selectedMinutes)
                .padding(.top, -10)

            // Controls
            HStack(spacing: 20) {
                ControlButton(title: "ALLOW PAUSE") {
                    Spacer()
                    Toggle("", isOn: $appManager.allowPauses)
                        .toggleStyle(ModernToggleStyle())
                    Spacer()
                        .onChange(of: appManager.allowPauses) {
                            if appManager.allowPauses {
                                appManager.maxPauses = 3
                            } else {
                                appManager.maxPauses = 0
                            }
                        }
                }

                ControlButton(title: "# OF PAUSES") {
                    HStack {
                        Text("\(appManager.maxPauses)")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(
                                appManager.allowPauses
                                    ? .white : .white.opacity(0.3))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(
                                appManager.allowPauses
                                    ? .white : .white.opacity(0.3)
                            )
                            .offset(y: 2)
                    }
                }
                .overlay(
                    Menu {
                        Picker("", selection: $appManager.maxPauses) {
                            ForEach(0...10, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                    } label: {
                        Color.clear
                    }
                    .disabled(!appManager.allowPauses)
                )
            }
            .padding(.horizontal)

            // Begin Button
            // Begin Button
            BeginButton {
                withAnimation(.spring()) {
                    appManager.startCountdown()
                }
            }

            Spacer()
        }
    }
}
