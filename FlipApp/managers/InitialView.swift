import CoreMotion
import SwiftUI

struct InitialView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var activePermission: PermissionType?
    @State private var showLocationPermission = false
    @State private var showMotionPermission = false
    @State private var showNotificationPermission = false
    @State private var showPrivacyPolicy = false
    @State private var animateCheckmarks = false
    @State private var readyToProceed = false
    @State private var animateContent = false
    // Gradient animation
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 1, y: 1)

    // Background circles animation
    @State private var circle1Scale: CGFloat = 1.0
    @State private var circle2Scale: CGFloat = 1.0
    @State private var circle1Opacity: Double = 0.2
    @State private var circle2Opacity: Double = 0.15

    enum PermissionType: String, CaseIterable {
        case location = "Location"
        case motion = "Motion"
        case notification = "Notifications"

        var icon: String {
            switch self {
            case .location: return "location.fill"
            case .motion: return "figure.walk"
            case .notification: return "bell.fill"
            }
        }

        var description: String {
            switch self {
            case .location:
                return "Enables regional leaderboards, FlipMaps, and background sessions"
            case .motion: return "Required to detect phone flipping during focus sessions"
            case .notification: return "For session alerts and social features"
            }
        }

        var isRequired: Bool { return self == .motion }
        var color: Color {
            switch self {
            case .location: return Theme.lightTealBlue
            case .motion: return Theme.softViolet
            case .notification: return Theme.mutedGreen
            }
        }
    }

    var body: some View {
        ZStack {
            // Animated background
            ZStack {
                // Main gradient background
                LinearGradient(
                    colors: [
                        Theme.deepMidnightPurple, Theme.mediumMidnightPurple, Theme.darkPurpleBlue,
                    ],
                    startPoint: gradientStart,
                    endPoint: gradientEnd
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)
                    ) {
                        gradientStart = UnitPoint(x: 1, y: 0)
                        gradientEnd = UnitPoint(x: 0, y: 1)
                    }
                }

                // Animated circle 1
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.softViolet.opacity(0.3), Theme.softViolet.opacity(0),
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 300
                        )
                    )
                    .frame(width: 400, height: 400).offset(x: 100, y: -200).blur(radius: 60)
                    .scaleEffect(circle1Scale).opacity(circle1Opacity)

                // Animated circle 2
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Theme.lightTealBlue.opacity(0.25), Theme.lightTealBlue.opacity(0),
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 250
                        )
                    )
                    .frame(width: 350, height: 350).offset(x: -120, y: 300).blur(radius: 50)
                    .scaleEffect(circle2Scale).opacity(circle2Opacity)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    circle1Scale = 1.2
                    circle1Opacity = 0.3
                }
                withAnimation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(1)
                ) {
                    circle2Scale = 1.15
                    circle2Opacity = 0.25
                }
            }

            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // App logo and title
                    VStack(spacing: 5) {
                        // Logo
                        ZStack {
                            Circle().fill(Theme.silveryGradient).frame(width: 80, height: 80)
                                .shadow(color: Theme.softViolet.opacity(0.5), radius: 20)
                                .opacity(animateContent ? 1 : 0)
                                .scaleEffect(animateContent ? 1 : 0.8)
                            Image(systemName: "hourglass").font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Theme.softViolet.opacity(0.8), radius: 10)
                                .opacity(animateContent ? 1 : 0)
                                .scaleEffect(animateContent ? 1 : 0.8)
                        }
                        .padding(.top, 20)
                        // Title with animated reveal
                        Text("FLIP").font(.system(size: 48, weight: .black)).tracking(16)
                            .foregroundColor(.white)
                            .shadow(color: Theme.softViolet.opacity(0.8), radius: 10)
                            .opacity(animateContent ? 1 : 0).offset(y: animateContent ? 0 : 30)
                    }

                    // Permission checklist card
                    VStack(spacing: 20) {
                        // Header with animated reveal
                        Text("SET UP PERMISSIONS").font(.system(size: 16, weight: .black))
                            .tracking(3).foregroundColor(.white.opacity(0.9)).padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(Theme.silveryGradient5)
                                    .opacity(0.3)
                            )
                            .opacity(animateContent ? 1 : 0).offset(y: animateContent ? 0 : 15)

                        // Permission items with staggered animation
                        ForEach(Array(PermissionType.allCases.enumerated()), id: \.element) {
                            index,
                            permission in
                            permissionItem(
                                permission: permission,
                                isActive: activePermission == permission,
                                isGranted: isPermissionGranted(permission)
                            )
                            .onTapGesture {
                                if !isPermissionGranted(permission) {
                                    requestPermission(permission)
                                }
                            }
                            .opacity(animateContent ? 1 : 0).offset(y: animateContent ? 0 : 20)
                            .animation(
                                Animation.spring(response: 0.6, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.15 + 0.3),
                                value: animateContent
                            )
                        }
                        // Privacy policy link with animated reveal
                        Button(action: { showPrivacyPolicy = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield").font(.system(size: 14))
                                    .foregroundColor(Theme.lightTealBlue)
                                Text("Privacy Policy").font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.lightTealBlue)
                            }
                            .padding(.vertical, 12).padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.lightTealBlue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.lightTealBlue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .opacity(animateContent ? 1 : 0).offset(y: animateContent ? 0 : 20)
                        .animation(
                            Animation.spring(response: 0.6, dampingFraction: 0.7).delay(0.8),
                            value: animateContent
                        )
                    }
                    .padding(24)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.mediumMidnightPurple, Theme.deepMidnightPurple,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Theme.silveryGradient2, lineWidth: 1.5)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20).padding(.horizontal, 20)
                    .opacity(animateContent ? 1 : 0).offset(y: animateContent ? 0 : 40)
                    .animation(
                        Animation.spring(response: 0.7, dampingFraction: 0.7).delay(0.1),
                        value: animateContent
                    )

                    // Continue button with animated reveal
                    Button(action: {
                        print("Continue button tapped")
                        // Mark permissions as completed
                        UserDefaults.standard.set(true, forKey: "hasCompletedPermissionFlow")
                        // Proceed to main app
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ProceedToMainApp"),
                            object: nil
                        )
                    }) {
                        Text("CONTINUE").font(.system(size: 20, weight: .black)).tracking(4)
                            .foregroundColor(.white).frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: readyToProceed
                                                    ? [Theme.softViolet, Theme.electricViolet]
                                                    : [
                                                        Theme.softViolet.opacity(0.5),
                                                        Theme.electricViolet.opacity(0.5),
                                                    ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Theme.silveryGradient, lineWidth: 1)
                                }
                            )
                            .shadow(
                                color: Theme.softViolet.opacity(readyToProceed ? 0.5 : 0.2),
                                radius: 10
                            )
                    }
                    .opacity(animateContent ? 1 : 0).scaleEffect(readyToProceed ? 1 : 0.97)
                    .disabled(!readyToProceed).padding(.horizontal, 20).padding(.bottom, 50)
                    .animation(
                        Animation.spring(response: 0.6, dampingFraction: 0.7).delay(1.0),
                        value: animateContent
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Permission overlays
            if showLocationPermission {
                EnhancedLocationPermissionAlert(
                    isPresented: $showLocationPermission,
                    onContinue: { permissionManager.requestLocationPermission() }
                )
            }

            if showMotionPermission {
                MotionPermissionAlert(
                    isPresented: $showMotionPermission,
                    onContinue: { permissionManager.requestMotionPermission() }
                )
            }
            if permissionManager.showMotionSettingsAlert {
                SettingsAlertView(
                    isPresented: $permissionManager.showMotionSettingsAlert,
                    title: "Motion Permission Required",
                    message:
                        "Motion permission is required to use Flip. Please enable it in Settings to continue.",
                    settingsAction: { permissionManager.openMotionSettings() }
                )
            }

            if showNotificationPermission {
                NotificationPermissionAlert(
                    isPresented: $showNotificationPermission,
                    onContinue: { permissionManager.requestNotificationPermission() }
                )
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("ShowEnhancedLocationAlert")
            )
        ) { _ in showLocationPermission = true }
        .onAppear {
            // Lock all other permission requests during this flow
            permissionManager.lockPermissions()
            // Set flag that we're in the initial permission flow
            permissionManager.isInitialPermissionFlow = true
            // Start animations
            withAnimation(.easeOut(duration: 0.7)) { animateContent = true }
            // Ensure no permissions are requested until we're ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Start with first permission that isn't granted
                startFirstMissingPermission()
                // Add observers for permission changes
                setupPermissionObservers()
                // Animate in checkmarks for already granted permissions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.5)) { animateCheckmarks = true }
                }
                // Check if we can proceed immediately
                updateReadyToProceed()
            }
        }
        .onDisappear {
            // Relinquish control over permission flow when done
            permissionManager.isInitialPermissionFlow = false
            // Unlock permissions for the rest of the app
            permissionManager.unlockPermissions()
            print("🏁 InitialView disappeared, permission flow completed")
        }
    }
    // MARK: - Helper Views

    // Permission item view with enhanced visuals
    private func permissionItem(permission: PermissionType, isActive: Bool, isGranted: Bool)
        -> some View
    {
        HStack(spacing: 15) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(
                        isGranted
                            ? Theme.mutedGreen.opacity(0.2)
                            : (isActive ? permission.color.opacity(0.2) : Color.white.opacity(0.1))
                    )
                    .frame(width: 44, height: 44)

                if isGranted {
                    Circle().fill(Theme.mutedGreen.opacity(0.8)).frame(width: 32, height: 32)
                        .scaleEffect(animateCheckmarks ? 1 : 0)
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white).opacity(animateCheckmarks ? 1 : 0)
                        .scaleEffect(animateCheckmarks ? 1 : 0.5)
                }
                else {
                    Image(systemName: permission.icon).font(.system(size: 18))
                        .foregroundColor(isActive ? permission.color : .white.opacity(0.7))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isGranted)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animateCheckmarks)

            // Permission details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.rawValue).font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    if permission.isRequired {
                        Text("Required").font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6)).padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1))
                            )
                    }
                }

                Text(permission.description).font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7)).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Action indicator
            if isGranted {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 24))
                    .foregroundColor(Theme.mutedGreen).opacity(animateCheckmarks ? 1 : 0)
                    .scaleEffect(animateCheckmarks ? 1 : 0.7)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7),
                        value: animateCheckmarks
                    )
            }
            else {
                Image(systemName: "chevron.right").font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.5)).frame(width: 30)
            }
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .background(
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? permission.color.opacity(0.15) : Color.white.opacity(0.05))
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isActive
                            ? LinearGradient(
                                colors: [
                                    permission.color.opacity(0.7), permission.color.opacity(0.3),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isActive ? 1.5 : 1
                    )
            }
        )
        .shadow(
            color: isActive ? permission.color.opacity(0.3) : Color.clear,
            radius: isActive ? 8 : 0
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
    }

    // Helper to check if permission is granted
    private func isPermissionGranted(_ permission: PermissionType) -> Bool {
        if UserDefaults.standard.bool(forKey: "isResettingPermissions") { return false }
        switch permission {
        case .location:
            return permissionManager.locationAuthStatus == .authorizedWhenInUse
                || permissionManager.locationAuthStatus == .authorizedAlways
        case .motion: return permissionManager.motionPermissionGranted
        case .notification: return permissionManager.notificationPermissionGranted
        }
    }

    // Helper to request a specific permission
    private func requestPermission(_ permission: PermissionType) {
        activePermission = permission

        switch permission {
        case .location: showLocationPermission = true
        case .motion:
            // Check if motion permission was previously denied
            let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
            if motionAuthStatus == .denied {
                // Show settings alert instead of the custom alert
                permissionManager.showMotionSettingsAlert = true
            }
            else {
                showMotionPermission = true
            }
        case .notification: showNotificationPermission = true
        }
    }

    // Start with first permission that isn't granted
    private func startFirstMissingPermission() {
        // Don't automatically show permission alerts
        // Just check if we can proceed
        updateReadyToProceed()
    }

    // Set up observers for permission status changes
    private func setupPermissionObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("locationPermissionChanged"),
            object: nil,
            queue: .main
        ) { _ in self.handlePermissionChanged() }

        // Refresh every time view appears to catch permission changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            permissionManager.refreshPermissionStatus()
            self.handlePermissionChanged()
        }
    }

    // Handle permission status changes
    private func handlePermissionChanged() {
        // Update ready to proceed state
        updateReadyToProceed()
    }

    // Check if we can proceed to the main app
    private func updateReadyToProceed() {
        // At minimum, we require motion permission since it's essential
        let requiredGranted = permissionManager.motionPermissionGranted
        print("Motion permission granted: \(requiredGranted)")
        // Check if all permissions are granted
        let allGranted = PermissionType.allCases.allSatisfy { isPermissionGranted($0) }
        print("All permissions granted: \(allGranted)")

        // Can proceed if motion permission is granted
        readyToProceed = requiredGranted
        print("Ready to proceed: \(readyToProceed)")
        // If all permissions are granted, make the continue button more prominent
        if allGranted {
            // Make animation more noticeable for "all done" state
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                // This will trigger the animation on the continue button
                readyToProceed = true
            }
        }
    }
}
// Enhance the location permission alert - this is a redesigned version aligned with the privacy policy
struct EnhancedLocationPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }

            // Alert content
            VStack(spacing: 20) {
                // Header with icon
                ZStack {
                    Circle().fill(Theme.lightTealBlue.opacity(0.2)).frame(width: 90, height: 90)
                        .scaleEffect(animateContent ? 1.3 : 0.8).opacity(animateContent ? 0.0 : 0.5)

                    Circle().fill(Theme.tealyGradient).frame(width: 70, height: 70)

                    Image(systemName: "location.fill").font(.system(size: 32))
                        .foregroundColor(.white).shadow(color: Color.white.opacity(0.5), radius: 4)
                }

                Text("LOCATION ACCESS").font(.system(size: 22, weight: .black)).tracking(4)
                    .foregroundColor(.white)
                    .shadow(color: Theme.lightTealBlue.opacity(0.6), radius: 8)

                // Privacy explanation
                Text(
                    "Flip protects your privacy. Location data is only used during active sessions and only your last 3 session locations are stored."
                )
                .font(.system(size: 16)).foregroundColor(.white).multilineTextAlignment(.center)
                .padding(.horizontal)

                // Feature explanation
                VStack(spacing: 15) {
                    featureRow(
                        icon: "map.fill",
                        title: "FlipMaps",
                        description: "See where friends are focusing in real-time"
                    )

                    featureRow(
                        icon: "building.2.fill",
                        title: "Building Leaderboards",
                        description: "Compete with others in the same location"
                    )

                    featureRow(
                        icon: "moon.stars.fill",
                        title: "Background Sessions",
                        description: "Keep sessions running with screen off"
                    )
                }
                .padding(.vertical, 5)

                // Privacy policy link
                Button(action: { showPrivacyPolicy = true }) {
                    HStack {
                        Image(systemName: "doc.text").font(.system(size: 14))
                        Text("View Full Privacy Policy").font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.lightTealBlue).padding(.vertical, 8)
                }

                // Buttons
                HStack(spacing: 15) {
                    // Continue button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            animateButton = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onContinue() }
                        }
                    }) {
                        Text("Continue").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            .frame(width: 160, height: 48)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.lightTealBlue, Theme.darkTealBlue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                            .scaleEffect(animateButton ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)

                Text("You can change this later in Settings").font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5)).padding(.bottom, 10)
            }
            .padding(25)
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
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicyView() }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
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

struct SettingsAlertView: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let settingsAction: () -> Void
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }
            // Alert content
            VStack(spacing: 20) {
                // Header with icon
                ZStack {
                    Circle().fill(Theme.softViolet.opacity(0.2)).frame(width: 90, height: 90)
                    Image(systemName: "gear").font(.system(size: 32)).foregroundColor(.white)
                }
                Text(title).font(.system(size: 22, weight: .black)).tracking(4)
                    .foregroundColor(.white)
                Text(message).font(.system(size: 16)).foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center).padding(.horizontal)
                // Buttons
                HStack(spacing: 15) {
                    // Cancel button
                    Button(action: { isPresented = false }) {
                        Text("Cancel").font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7)).frame(width: 100, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    // Settings button
                    Button(action: {
                        isPresented = false
                        settingsAction()
                    }) {
                        Text("Settings").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(width: 160, height: 48)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.softViolet, Theme.electricViolet],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Theme.softViolet.opacity(0.5), radius: 8)
                    }
                }
                .padding(.top, 10)
            }
            .padding(25)
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
    }
}
