import CoreLocation
import CoreMotion
import SwiftUI
import UserNotifications

struct InitialView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var activePermission: PermissionType?
    @State private var showLocationPermission = false
    @State private var showMotionPermission = false
    @State private var showNotificationPermission = false
    @State private var showPrivacyPolicy = false
    @State private var animateCheckmarks = false
    @State private var readyToProceed = false

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
                return
                    "Enables regional leaderboards, FlipMaps, and background sessions"
            case .motion:
                return "Required to detect phone flipping during focus sessions"
            case .notification: return "For session alerts and social features"
            }
        }

        var isRequired: Bool {
            return self == .motion
        }
    }

    var body: some View {
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

            // Main content
            VStack(spacing: 30) {
                // App logo or header
                VStack {
                    Image(systemName: "hourglass")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 150, height: 150)
                        )

                    Text("FLIP")
                        .font(.system(size: 36, weight: .black))
                        .tracking(10)
                        .foregroundColor(.white)
                        .shadow(
                            color: Color(
                                red: 139 / 255, green: 92 / 255, blue: 246 / 255
                            ).opacity(0.6), radius: 8)

                    Text("ONE MORE STEP")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(5)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 5)
                }
                .padding(.top, 40)

                // Permission checklist
                VStack(spacing: 22) {
                    Text("SETUP YOUR PERMISSIONS")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 5)

                    // Permission items
                    ForEach(PermissionType.allCases, id: \.self) { permission in
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
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal)

                // Privacy policy link
                Button(action: {
                    showPrivacyPolicy = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 16))

                        Text("Privacy Policy")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(
                        Color(red: 139 / 255, green: 92 / 255, blue: 246 / 255)
                    )
                    .padding(.vertical, 8)
                }
                .padding(.top, 5)

                // Continue button
                Button(action: {
                    // Mark permissions as completed
                    UserDefaults.standard.set(
                        true, forKey: "hasCompletedPermissionFlow")

                    // Handle permissions that weren't granted
                    if !permissionManager.motionPermissionGranted {
                        // Warn that motion is required (you can even block progress here)
                        // For now, just proceed anyway
                    }

                    // Proceed to main app
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ProceedToMainApp"),
                        object: nil)
                }) {
                    Text("CONTINUE")
                        .font(.system(size: 20, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 139 / 255,
                                                    green: 92 / 255,
                                                    blue: 246 / 255),
                                                Color(
                                                    red: 79 / 255,
                                                    green: 70 / 255,
                                                    blue: 229 / 255),
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(
                            color: Color(
                                red: 139 / 255, green: 92 / 255, blue: 246 / 255
                            ).opacity(0.4), radius: 8)
                }
                .opacity(readyToProceed ? 1 : 0.6)
                .disabled(!readyToProceed)
                .padding(.horizontal)
                .padding(.top, 40)

                Spacer()
            }

            // Permission overlays
            if showLocationPermission {
                EnhancedLocationPermissionAlert(
                    isPresented: $showLocationPermission,
                    onContinue: {
                        permissionManager.requestLocationPermission()
                    }
                )
            }

            if showMotionPermission {
                MotionPermissionAlert(
                    isPresented: $showMotionPermission,
                    onContinue: {
                        permissionManager.requestMotionPermission()
                    }
                )
            }

            if showNotificationPermission {
                NotificationPermissionAlert(
                    isPresented: $showNotificationPermission,
                    onContinue: {
                        permissionManager.requestNotificationPermission()
                    }
                )
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSNotification.Name("ShowEnhancedLocationAlert"))
        ) { _ in
            showLocationPermission = true
        }
        .onAppear {
            // Automatically start with first non-granted permission
            startFirstMissingPermission()

            // Add observers for permission changes
            setupPermissionObservers()

            // Animate in checkmarks for already granted permissions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    animateCheckmarks = true
                }
            }

            // Check if we can proceed immediately
            updateReadyToProceed()
        }
    }

    // Permission item view
    private func permissionItem(
        permission: PermissionType, isActive: Bool, isGranted: Bool
    ) -> some View {
        HStack(spacing: 15) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(
                        isGranted
                            ? Theme.mutedGreen.opacity(0.2)
                            : (isActive
                                ? Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.2) : Color.white.opacity(0.1))
                    )
                    .frame(width: 36, height: 36)

                if isGranted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(
                            Theme.mutedGreen
                        )
                        .opacity(animateCheckmarks ? 1 : 0)
                        .scaleEffect(animateCheckmarks ? 1 : 0.5)
                } else {
                    Image(systemName: permission.icon)
                        .font(.system(size: 16))
                        .foregroundColor(
                            isActive
                                ? Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255) : .white.opacity(0.7))
                }
            }

            // Permission details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(permission.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    if permission.isRequired {
                        Text("Required")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }

                Text(permission.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer()

            // Action indicator
            Image(
                systemName: isGranted
                    ? "checkmark.circle.fill" : "chevron.right"
            )
            .font(.system(size: 20))
            .foregroundColor(
                isGranted
                    ? Theme.mutedGreen
                    : .white.opacity(0.4)
            )
            .opacity(isGranted && animateCheckmarks ? 1 : (isGranted ? 0 : 1))
            .animation(
                .easeIn(duration: 0.5), value: isGranted && animateCheckmarks)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isActive ? Color.white.opacity(0.1) : Color.clear
                )
                .animation(.easeInOut(duration: 0.3), value: isActive)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive
                        ? LinearGradient(
                            colors: [
                                Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.7),
                                Color(
                                    red: 139 / 255, green: 92 / 255,
                                    blue: 246 / 255
                                ).opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: isActive ? 1.5 : 1
                )
        )

    }

    // Helper to check if permission is granted
    private func isPermissionGranted(_ permission: PermissionType) -> Bool {
        if UserDefaults.standard.bool(forKey: "isResettingPermissions") {
            return false
        }
        switch permission {
        case .location:
            return permissionManager.locationAuthStatus == .authorizedWhenInUse
                || permissionManager.locationAuthStatus == .authorizedAlways
        case .motion:
            return permissionManager.motionPermissionGranted
        case .notification:
            return permissionManager.notificationPermissionGranted
        }
    }

    // Helper to request a specific permission
    private func requestPermission(_ permission: PermissionType) {
        activePermission = permission

        switch permission {
        case .location:
            showLocationPermission = true
        case .motion:
            showMotionPermission = true
        case .notification:
            showNotificationPermission = true
        }
    }

    // Start with first permission that isn't granted
    private func startFirstMissingPermission() {
        for permission in PermissionType.allCases {
            if !isPermissionGranted(permission) {
                // Short delay before showing first permission
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    requestPermission(permission)
                }
                return
            }
        }

        // If all granted, mark as ready
        readyToProceed = true
    }

    // Set up observers for permission status changes
    private func setupPermissionObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("locationPermissionChanged"),
            object: nil,
            queue: .main
        ) { _ in
            self.handlePermissionChanged()
        }

        // Refresh every time view appears to catch permission changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            permissionManager.refreshPermissionStatus()
            self.handlePermissionChanged()
        }
    }

    // Handle permission status changes
    private func handlePermissionChanged() {
        // If the current active permission was granted, move to the next one
        if let active = activePermission, isPermissionGranted(active) {
            // Close any open permission alerts
            switch active {
            case .location:
                showLocationPermission = false
            case .motion:
                showMotionPermission = false
            case .notification:
                showNotificationPermission = false
            }

            // Find next permission to request
            activePermission = nil
            var foundCurrent = false

            for permission in PermissionType.allCases {
                if foundCurrent && !isPermissionGranted(permission) {
                    // Short delay before showing next permission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        requestPermission(permission)
                    }
                    return
                }

                if permission == active {
                    foundCurrent = true
                }
            }

            // If we got here, we've processed all permissions
            updateReadyToProceed()
        }
    }

    // Check if we can proceed to the main app
    private func updateReadyToProceed() {
        // At minimum, we require motion permission
        let requiredGranted = permissionManager.motionPermissionGranted

        // Check if all permissions are granted
        _ = PermissionType.allCases.allSatisfy {
            isPermissionGranted($0)
        }

        // Can proceed if either all granted or just required ones with others skipped
        readyToProceed = requiredGranted
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
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }

            // Alert content
            VStack(spacing: 20) {
                // Header with icon
                ZStack {
                    Circle()
                        .fill(
                            Theme.lightTealBlue.opacity(0.2)
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(animateContent ? 1.3 : 0.8)
                        .opacity(animateContent ? 0.0 : 0.5)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.lightTealBlue,
                                    Color(
                                        red: 14 / 255, green: 165 / 255,
                                        blue: 233 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "location.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.5), radius: 4)
                }

                Text("LOCATION ACCESS")
                    .font(.system(size: 22, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .shadow(
                        color: Theme.lightTealBlue.opacity(0.6), radius: 8)

                // Privacy explanation
                Text(
                    "Flip protects your privacy. Location data is only used during active sessions and only your last 3 session locations are stored."
                )
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                // Feature explanation
                VStack(spacing: 15) {
                    featureRow(
                        icon: "map.fill",
                        title: "FlipMaps",
                        description:
                            "See where friends are focusing in real-time"
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
                Button(action: {
                    showPrivacyPolicy = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                        Text("View Full Privacy Policy")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(
                        Theme.lightTealBlue
                    )
                    .padding(.vertical, 8)
                }

                // Buttons
                HStack(spacing: 15) {
                    // Skip button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 100, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                Color.white.opacity(0.2),
                                                lineWidth: 1)
                                    )
                            )
                    }

                    // Continue button
                    Button(action: {
                        withAnimation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                        ) {
                            animateButton = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.8
                            ) {
                                onContinue()
                            }
                        }
                    }) {
                        Text("Allow")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 48)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Theme.lightTealBlue,
                                                    Color(
                                                        red: 14 / 255,
                                                        green: 165 / 255,
                                                        blue: 233 / 255),
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color.white.opacity(0.3),
                                            lineWidth: 1)
                                }
                            )
                            .shadow(
                                color: Theme.lightTealBlue.opacity(0.5),
                                radius: 8
                            )
                            .scaleEffect(animateButton ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)

                Text("You can change this later in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(
                                        red: 26 / 255, green: 14 / 255,
                                        blue: 47 / 255),
                                    Color(
                                        red: 16 / 255, green: 24 / 255,
                                        blue: 57 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .frame(maxWidth: 350)
            .shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8), value: isPresented
            )
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2).repeatForever(
                    autoreverses: true)
            ) {
                animateContent = true
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String)
        -> some View
    {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
