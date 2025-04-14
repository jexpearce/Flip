import SwiftUI

struct LeaderboardConsentAlert: View {
    @Binding var isPresented: Bool
    @ObservedObject private var consentManager = LeaderboardConsentManager.shared
    @ObservedObject private var userSettings = UserSettingsManager.shared
    // Local state for the alert settings
    @State private var regionalOptOut: Bool = false
    @State private var regionalDisplayMode: RegionalDisplayMode = .normal
    @State private var showAdvancedSettings: Bool = false
    // Animation state
    @State private var animateContent = false
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }
            // Alert content
            ScrollView {
                VStack(spacing: 20) {
                    // Header with icon
                    VStack(spacing: 15) {
                        ZStack {
                            // Trophy icon with background
                            Circle().fill(Theme.darkRed.opacity(0.3)).frame(width: 90, height: 90)
                                .scaleEffect(animateContent ? 1.2 : 0.9)
                                .opacity(animateContent ? 0.8 : 0.5)
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.darkRed, Theme.mutedRed],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 70, height: 70)
                            Image(systemName: "trophy.fill").font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: Color.white.opacity(0.7), radius: 5)
                        }
                        Text("LEADERBOARD CONSENT").font(.system(size: 22, weight: .black))
                            .tracking(2).foregroundColor(.white)
                            .shadow(color: Theme.darkRed.opacity(0.6), radius: 8)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)
                    // Description text
                    Text(
                        "FLIP lets you compete with others on regional, building, and global leaderboards! Your session counts and focus time will appear on leaderboards with your username."
                    )
                    .font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
                    // Features list
                    VStack(spacing: 15) {
                        featureRow(
                            icon: "building.2.fill",
                            title: "Building Leaderboards",
                            description:
                                "Compete with others in the same building (coffee shops, libraries, etc.)"
                        )
                        featureRow(
                            icon: "map.fill",
                            title: "Regional Leaderboards",
                            description: "See who's the most focused in your area"
                        )
                        featureRow(
                            icon: "globe",
                            title: "Global Rankings",
                            description: "Compete with users worldwide based on focus time"
                        )
                        featureRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Controls",
                            description: "Opt out or appear anonymously at any time"
                        )
                    }
                    .padding(.horizontal, 5)
                    // Advanced Settings (expandable)
                    VStack(spacing: 10) {
                        Button(action: { withAnimation { showAdvancedSettings.toggle() } }) {
                            HStack {
                                Text("Privacy Settings").font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(
                                    systemName: showAdvancedSettings ? "chevron.up" : "chevron.down"
                                )
                                .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1))
                            )
                        }
                        if showAdvancedSettings {
                            VStack(spacing: 15) {
                                // Opt Out Toggle
                                Toggle(isOn: $regionalOptOut) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Opt out of leaderboards")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Hide completely from all leaderboards")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Theme.darkRed))
                                // Display Mode Options (if not opted out)
                                if !regionalOptOut {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Display Name Option:")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        HStack(spacing: 15) {
                                            // Normal Option
                                            Button(action: { regionalDisplayMode = .normal }) {
                                                HStack {
                                                    ZStack {
                                                        Circle()
                                                            .stroke(
                                                                Color.white.opacity(0.5),
                                                                lineWidth: 2
                                                            )
                                                            .frame(width: 22, height: 22)
                                                        if regionalDisplayMode == .normal {
                                                            Circle().fill(Theme.darkRed)
                                                                .frame(width: 14, height: 14)
                                                        }
                                                    }
                                                    Text("Normal").font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            // Anonymous Option
                                            Button(action: { regionalDisplayMode = .anonymous }) {
                                                HStack {
                                                    ZStack {
                                                        Circle()
                                                            .stroke(
                                                                Color.white.opacity(0.5),
                                                                lineWidth: 2
                                                            )
                                                            .frame(width: 22, height: 22)
                                                        if regionalDisplayMode == .anonymous {
                                                            Circle().fill(Theme.darkRed)
                                                                .frame(width: 14, height: 14)
                                                        }
                                                    }
                                                    Text("Anonymous").font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                        Text(
                                            regionalDisplayMode == .normal
                                                ? "Your username will appear on leaderboards"
                                                : "You'll appear as 'Anonymous' on leaderboards"
                                        )
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .padding().background(Color.black.opacity(0.3)).cornerRadius(10)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 5)
                    // Privacy Note
                    Text(
                        "You can change these settings anytime in the Regional tab or Profile settings."
                    )
                    .font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center).padding(.horizontal, 20)
                    // Buttons
                    VStack(spacing: 12) {
                        // Accept Button
                        Button(action: {
                            // Apply settings
                            userSettings.setRegionalOptOut(regionalOptOut)
                            userSettings.setRegionalDisplayMode(regionalDisplayMode)
                            // Grant consent
                            consentManager.setConsent(granted: true)
                            // Dismiss
                            isPresented = false
                        }) {
                            Text("JOIN LEADERBOARDS").font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white).frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Theme.darkRed, Theme.mutedRed],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Theme.darkRed.opacity(0.5), radius: 8)
                        }
                        .padding(.horizontal, 20)
                        // Decline Button
                        Button(action: {
                            // Apply opt-out setting
                            userSettings.setRegionalOptOut(true)
                            // Don't grant consent
                            consentManager.setConsent(granted: false)
                            // Dismiss
                            isPresented = false
                        }) {
                            Text("MAYBE LATER").font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7)).padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 5).padding(.bottom, 15)
                }
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.mutedPurple, Theme.blueishPurple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        RoundedRectangle(cornerRadius: 25).fill(Color.white.opacity(0.05))
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Theme.silveryGradient3, lineWidth: 1.5)
                    }
                )
                .frame(maxWidth: 350).shadow(color: Color.black.opacity(0.3), radius: 20)
                .scaleEffect(isPresented ? 1 : 0.8).opacity(isPresented ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
            }
            .maxHeight(600)
        }
        .onAppear {
            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
            // Initialize with current settings
            regionalOptOut = userSettings.regionalOptOut
            regionalDisplayMode = userSettings.regionalDisplayMode
        }
    }
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon in circle
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text(description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Helper extension for ScrollView max height
extension View { func maxHeight(_ height: CGFloat) -> some View { self.frame(maxHeight: height) } }
