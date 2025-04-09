import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var friendFailureNotifications = true
    @Published var visibilityLevel: LocationVisibilityLevel = .friendsOnly
    @Published var showSessionHistory = true
    @Published var commentNotifications = true
    @Published var regionalDisplayMode: RegionalDisplayMode = .normal
    @Published var regionalOptOut = false

    private let db = Firestore.firestore()

    init() { loadSettings() }

    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Load notification and privacy settings
        db.collection("user_settings").document(userId)
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists, let data = document.data() {
                    // Load friend failure notification setting (default to ON if not set)
                    self.friendFailureNotifications =
                        data["friendFailureNotifications"] as? Bool ?? true

                    // Load comment notifications setting (default to ON if not set)
                    self.commentNotifications = data["commentNotifications"] as? Bool ?? true

                    // Load visibility level (default to friendsOnly if not set)
                    if let visibilityString = data["visibilityLevel"] as? String,
                        let visibility = LocationVisibilityLevel(rawValue: visibilityString)
                    {
                        self.visibilityLevel = visibility
                    }

                    // Load session history setting (default to ON if not set)
                    self.showSessionHistory = data["showSessionHistory"] as? Bool ?? true

                    // Load regional display mode (default to normal if not set)
                    if let modeString = data["regionalDisplayMode"] as? String,
                        let mode = RegionalDisplayMode(rawValue: modeString)
                    {
                        self.regionalDisplayMode = mode
                    }

                    // Load regional opt out setting (default to OFF if not set)
                    self.regionalOptOut = data["regionalOptOut"] as? Bool ?? false
                }
                else {
                    // Set defaults and save them
                    self.friendFailureNotifications = true
                    self.commentNotifications = true
                    self.visibilityLevel = .friendsOnly
                    self.showSessionHistory = true
                    self.regionalDisplayMode = .normal
                    self.regionalOptOut = false
                    self.saveSettings()
                }
            }
    }

    func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let settings: [String: Any] = [
            "friendFailureNotifications": friendFailureNotifications,
            "commentNotifications": commentNotifications,
            "visibilityLevel": visibilityLevel.rawValue, "showSessionHistory": showSessionHistory,
            "regionalDisplayMode": regionalDisplayMode.rawValue, "regionalOptOut": regionalOptOut,
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        db.collection("user_settings").document(userId)
            .setData(settings, merge: true) { error in
                if let error = error {
                    print("Error saving settings: \(error.localizedDescription)")
                }
            }
    }

    func toggleCommentNotifications() {
        commentNotifications.toggle()
        saveSettings()
    }

    func updateVisibilityLevel(_ level: LocationVisibilityLevel) {
        visibilityLevel = level
        saveSettings()
    }

    func toggleFriendFailureNotifications() {
        friendFailureNotifications.toggle()
        saveSettings()
    }

    // New methods for regional privacy settings
    func updateRegionalDisplayMode(_ mode: RegionalDisplayMode) {
        regionalDisplayMode = mode
        saveSettings()

        // Update in UserSettingsManager too for immediate effect
        UserSettingsManager.shared.setRegionalDisplayMode(mode)
    }

    func toggleRegionalOptOut() {
        regionalOptOut.toggle()
        saveSettings()

        // Update in UserSettingsManager too for immediate effect
        UserSettingsManager.shared.setRegionalOptOut(regionalOptOut)
    }
}
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

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.system(size: 16, weight: .black)).tracking(5).foregroundColor(.white)
                .shadow(color: Theme.lightTealBlue.opacity(0.4), radius: 4)

            content
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mediumMidnightPurple, Theme.purplishNavy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16).stroke(Theme.silveryGradient2, lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8)
    }
}

struct HelpSupportView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background gradient
            Theme.darkPurpleGradient.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // Header
                HStack {
                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal).padding(.top, 20)

                // Content
                VStack(spacing: 25) {
                    Image(systemName: "bubble.left.and.bubble.right.fill").font(.system(size: 60))
                        .foregroundColor(Theme.lightTealBlue).padding()
                        .background(
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 120, height: 120)
                        )

                    Text("Need Help?").font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(
                        "Any questions? Found a bug? Just want to say hi? Send an email to jex@jajajeev.com or hit me up on instagram at @jexpearce"
                    )
                    .font(.system(size: 18)).foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center).padding(.horizontal, 25)

                    // Contact buttons
                    VStack(spacing: 15) {
                        ContactButton(icon: "envelope.fill", text: "jex@jajajeev.com") {
                            if let url = URL(string: "mailto:jex@jajajeev.com") {
                                UIApplication.shared.open(url)
                            }
                        }

                        ContactButton(icon: "camera.fill", text: "@jexpearce") {
                            if let url = URL(string: "instagram://user?username=jexpearce") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                                else if let webURL = URL(string: "https://instagram.com/jexpearce")
                                {
                                    UIApplication.shared.open(webURL)
                                }
                            }
                        }
                    }
                    .padding(.top, 15)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct ContactButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(Theme.lightTealBlue)

                Text(text).font(.system(size: 16, weight: .medium)).foregroundColor(.white)

                Spacer()

                Image(systemName: "arrow.up.right.square").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
