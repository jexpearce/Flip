import SwiftUI

struct RegionalPrivacyButton: View {
    @Binding var showSettings: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RegionalPrivacySheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var userSettings = UserSettingsManager.shared
    @State private var regionalDisplayMode: RegionalDisplayMode
    @State private var regionalOptOut: Bool

    private let cyanBlueAccent = Theme.lightTealBlue
    private let redAccent = Theme.mutedRed

    init() {
        // Initialize state directly from the shared instance
        let settings = UserSettingsManager.shared
        _regionalDisplayMode = State(initialValue: settings.regionalDisplayMode)
        _regionalOptOut = State(initialValue: settings.regionalOptOut)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Theme.deepMidnightPurple,
                        Color(red: 30 / 255, green: 18 / 255, blue: 60 / 255),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(redAccent)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 100, height: 100)
                            )

                        Text("Regional Privacy")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Control how you appear on regional leaderboards")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Opt Out Toggle
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Visibility Control")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Toggle("", isOn: $regionalOptOut)
                                .toggleStyle(SwitchToggleStyle(tint: redAccent))
                                .onChange(of: regionalOptOut) {
                                    userSettings.setRegionalOptOut(regionalOptOut)
                                }
                        }

                        Text(
                            regionalOptOut
                                ? "Your sessions are not shown on regional leaderboards"
                                : "Your sessions are visible on regional leaderboards"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)

                    // Display Options (only if not opted out)
                    if !regionalOptOut {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How You Appear")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            // Normal Option
                            displayOption(
                                title: "Normal",
                                description:
                                    "Show your actual username and profile picture",
                                isSelected: regionalDisplayMode == .normal,
                                action: {
                                    regionalDisplayMode = .normal
                                    userSettings.setRegionalDisplayMode(.normal)
                                }
                            )

                            // Anonymous Option
                            displayOption(
                                title: "Anonymous",
                                description:
                                    "Appear as 'Anonymous' with a default profile image",
                                isSelected: regionalDisplayMode == .anonymous,
                                action: {
                                    regionalDisplayMode = .anonymous
                                    userSettings.setRegionalDisplayMode(
                                        .anonymous)
                                }
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            Color.white.opacity(0.2),
                                            lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }

                    // Note about how changes are applied
                    Text(
                        "Changes may take a few seconds to reflect on the leaderboard"
                    )
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitle("Privacy Settings", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }

    private func displayOption(
        title: String, description: String, isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(redAccent)
                            .frame(width: 16, height: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                    ? redAccent.opacity(0.5) : Color.clear,
                                lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
