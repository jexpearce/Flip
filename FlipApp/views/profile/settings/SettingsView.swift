import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showHelpSheet = false
    @State private var showPrivacyPolicy = false
    @State private var showPermissionResetAlert = false
    @State private var animateSettings = false

    // Colors from the app's theme
    private let cyanBlueAccent = Theme.lightTealBlue

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Theme.darkPurpleGradient.edgesIgnoringSafeArea(.all)

                // Decorative background elements
                Circle().fill(cyanBlueAccent.opacity(0.1)).frame(width: 300).offset(x: 150, y: -200)
                    .blur(radius: 60)

                Circle().fill(cyanBlueAccent.opacity(0.08)).frame(width: 250)
                    .offset(x: -150, y: 300).blur(radius: 50)

                ScrollView {
                    VStack(spacing: 25) {
                        // Section Header
                        Text("SETTINGS").font(.system(size: 28, weight: .black)).tracking(8)
                            .foregroundColor(.white).frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20).padding(.bottom, 10).opacity(animateSettings ? 1 : 0)
                            .offset(y: animateSettings ? 0 : -20)

                        // Notifications Section
                        SettingsSection(title: "NOTIFICATIONS") {
                            VStack(spacing: 15) {
                                // Friend Failure Toggle
                                ToggleSettingRow(
                                    title: "Friend Failure Alerts",
                                    subtitle:
                                        "Get notified when your friends fail a session? WARNING: Turning this on also allows your failed sessions to notify your friends too.",
                                    isOn: $viewModel.friendFailureNotifications,
                                    action: viewModel.toggleFriendFailureNotifications
                                )
                                ToggleSettingRow(
                                    title: "Comment Notifications",
                                    subtitle:
                                        "Get notified when someone comments on your focus sessions",
                                    isOn: $viewModel.commentNotifications,
                                    action: viewModel.toggleCommentNotifications
                                )
                                .padding(.top, 10)
                            }
                        }
                        .offset(x: animateSettings ? 0 : -300)

                        // Privacy Section
                        SettingsSection(title: "PRIVACY") {
                            VStack(spacing: 20) {
                                // Location Visibility Section
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("LOCATION VISIBILITY")
                                        .font(.system(size: 14, weight: .bold)).tracking(2)
                                        .foregroundColor(.white.opacity(0.7))

                                    // Radio button options
                                    privacyOption(
                                        title: "Everyone",
                                        description: "All users can see where your past flips were",
                                        isSelected: viewModel.visibilityLevel == .everyone
                                    ) { viewModel.updateVisibilityLevel(.everyone) }

                                    privacyOption(
                                        title: "Friends Only",
                                        description: "Only friends can see your past & live flips",
                                        isSelected: viewModel.visibilityLevel == .friendsOnly
                                    ) { viewModel.updateVisibilityLevel(.friendsOnly) }

                                    privacyOption(
                                        title: "Nobody",
                                        description: "Your flips are hidden from everyone",
                                        isSelected: viewModel.visibilityLevel == .nobody
                                    ) { viewModel.updateVisibilityLevel(.nobody) }
                                }

                                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 5)

                                // Session History Toggle
                                Toggle(isOn: $viewModel.showSessionHistory) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Show Past Sessions on Map")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Text(
                                            "When enabled, the map will show your past session locations"
                                        )
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: cyanBlueAccent))
                                .onChange(of: viewModel.showSessionHistory) {
                                    viewModel.saveSettings()
                                }
                                Divider().background(Color.white.opacity(0.2)).padding(.vertical, 5)

                                RegionalPrivacySection(viewModel: viewModel)

                                // Privacy Information
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 18)).foregroundColor(cyanBlueAccent)

                                        Text("Your Data Privacy")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }

                                    Text(
                                        "Your current location data is NEVER stored, solely your last 3 session locations on the friends map if permitted. FLIP will only ever store your last 3 sessions in its private database that's secure and protected."
                                    )
                                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(cyanBlueAccent.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(cyanBlueAccent.opacity(0.3), lineWidth: 1)
                                        )
                                )

                                // Privacy Policy Button
                                Button(action: { showPrivacyPolicy = true }) {
                                    HStack {
                                        Image(systemName: "doc.text").font(.system(size: 18))
                                            .foregroundColor(cyanBlueAccent)

                                        Text("Privacy Policy")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right").font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Data Deletion Request Button
                                Button(action: {
                                    if let emailURL = URL(
                                        string:
                                            "mailto:jex@jajajeev.com?subject=Data%20Deletion%20Request"
                                    ) {
                                        UIApplication.shared.open(emailURL)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill").font(.system(size: 18))
                                            .foregroundColor(Color.red.opacity(0.8))

                                        Text("Request Data Deletion")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "envelope").font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Reset Permissions Button
                                Button(action: { showPermissionResetAlert = true }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 18)).foregroundColor(Color.orange)

                                        Text("Reset Permissions")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right").font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .offset(x: animateSettings ? 0 : 300)

                        // Support Section
                        SettingsSection(title: "SUPPORT") {
                            Button(action: { showHelpSheet = true }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18)).foregroundColor(cyanBlueAccent)

                                    Text("Help & Support")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right").font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .opacity(animateSettings ? 1 : 0).offset(y: animateSettings ? 0 : 50)

                        // Sign Out Button - Destructive Action
                        VStack(spacing: 10) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    AuthManager.shared.signOut()
                                }
                            }) {
                                Text("Sign Out").font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.7))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // App version
                            Text("Flip v1.0.0").font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5)).padding(.top, 5)
                        }
                        .padding(.top, 15).opacity(animateSettings ? 1 : 0)
                        .offset(y: animateSettings ? 0 : 30)
                    }
                    .padding(.horizontal).padding(.bottom, 30)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            )
            .sheet(isPresented: $showHelpSheet) { HelpSupportView() }
            .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
            .alert(isPresented: $showPermissionResetAlert) {
                Alert(
                    title: Text("Reset Permissions"),
                    message: Text("This will restart the permission setup process. Continue?"),
                    primaryButton: .default(Text("Reset")) {
                        // Reset permission flow flag
                        UserDefaults.standard.set(true, forKey: "isResettingPermissions")
                        UserDefaults.standard.set(false, forKey: "hasCompletedPermissionFlow")
                        // Restart app with InitialView
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowPermissionsFlow"),
                            object: nil
                        )
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateSettings = true
                }
            }
        }
    }

    private func privacyOption(
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Radio button
                ZStack {
                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected { Circle().fill(cyanBlueAccent).frame(width: 16, height: 16) }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)

                    Text(description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.vertical, 10).padding(.horizontal)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(cyanBlueAccent.opacity(0.5), lineWidth: 1)
                    }
                }
            )
        }
    }
}
