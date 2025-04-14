import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RegionalPrivacySection: View {
    @ObservedObject var viewModel: SettingsViewModel
    private let cyanBlueAccent = Theme.lightTealBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("REGIONAL LEADERBOARD PRIVACY").font(.system(size: 14, weight: .bold)).tracking(2)
                .foregroundColor(.white.opacity(0.7))

            // Opt Out Toggle
            Toggle(isOn: $viewModel.regionalOptOut) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Opt Out of Leaderboard").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("When enabled, your sessions won't appear on any regional leaderboards")
                        .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: cyanBlueAccent))
            .onChange(of: viewModel.regionalOptOut) { viewModel.toggleRegionalOptOut() }.padding()
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            // Display Mode Selection (only visible if not opted out)
            if !viewModel.regionalOptOut {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Display Name Option").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 20) {
                        // Normal display mode
                        VStack {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: 24, height: 24)

                                if viewModel.regionalDisplayMode == .normal {
                                    Circle().fill(cyanBlueAccent).frame(width: 16, height: 16)
                                }
                            }
                            .onTapGesture { viewModel.updateRegionalDisplayMode(.normal) }

                            Text("Normal").font(.system(size: 14)).foregroundColor(.white)
                        }

                        // Anonymous display mode
                        VStack {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    .frame(width: 24, height: 24)

                                if viewModel.regionalDisplayMode == .anonymous {
                                    Circle().fill(cyanBlueAccent).frame(width: 16, height: 16)
                                }
                            }
                            .onTapGesture { viewModel.updateRegionalDisplayMode(.anonymous) }

                            Text("Anonymous").font(.system(size: 14)).foregroundColor(.white)
                        }
                    }

                    Text(
                        viewModel.regionalDisplayMode == .normal
                            ? "Your username and profile picture will be visible on regional leaderboards"
                            : "You'll appear as 'Anonymous' with a default profile image on regional leaderboards"
                    )
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
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
    }
}
