import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ToggleSettingRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let action: () -> Void

    private let cyanBlueAccent = Theme.lightTealBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }

                Spacer()

                Toggle("", isOn: $isOn).toggleStyle(SwitchToggleStyle(tint: cyanBlueAccent))
                    .onChange(of: isOn) { action() }
            }

            Text(subtitle).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
