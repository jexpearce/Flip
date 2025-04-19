import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showPauseDisabledWarning = false
    @State private var isInfinitePauses = false
    @State private var selectedPauseDurationIndex = 1  // Default to 5 minutes (index 1)
    @AppStorage("hasShownPauseWarning") private var hasShownPauseWarning = false
    @ObservedObject private var regionalViewModel = RegionalViewModel.shared
    @State private var showJoiningIndicator = false
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var viewRouter = ViewRouter()
    @State private var showLocationSelector = false
    @State private var showRules = false
    @State private var showLocationSettingsAlert = false

    // Pause durations in minutes
    private let pauseDurations = [3, 5, 10, 15, 20]
    private let pauseDurationLabels = ["3m", "5m", "10m", "15m", "20m"]

    var body: some View {
        ZStack {
            // Main View Content
            ScrollView {
                VStack(spacing: 8) {
                    HStack {
                        // Location Button
                        let locationButtonAction = {
                            // Check location permission before showing the popup
                            if permissionManager.locationAuthStatus == .authorizedWhenInUse
                                || permissionManager.locationAuthStatus == .authorizedAlways
                            {
                                // If this is the first tap and we don't have a building selected yet,
                                // automatically find and select the nearest building
                                if regionalViewModel.shouldPulseBuildingButton
                                    && regionalViewModel.selectedBuilding == nil
                                {
                                    regionalViewModel.selectNearestBuilding()
                                }
                                else {
                                    // Otherwise toggle the popup
                                    showLocationSelector.toggle()
                                }
                            }
                            else {
                                // Show location permission settings alert if denied
                                showLocationSettingsAlert = true
                            }
                        }

                        let hasLocationPermission =
                            permissionManager.locationAuthStatus == .authorizedWhenInUse
                            || permissionManager.locationAuthStatus == .authorizedAlways
                        let shouldPulseBuilding = regionalViewModel.shouldPulseBuildingButton

                        Button(action: locationButtonAction) {
                            ZStack {
                                // Conditionally render appropriate styling based on permission
                                if hasLocationPermission {
                                    Circle().fill(Theme.vibrantPurple).frame(width: 35, height: 35)
                                        .overlay(
                                            Circle().stroke(Color.white.opacity(0.6), lineWidth: 1)
                                        )
                                        .shadow(color: Theme.purpleShadow.opacity(0.3), radius: 4)
                                        .overlay(
                                            Circle().stroke(Theme.purpleShadow, lineWidth: 2)
                                                .scaleEffect(shouldPulseBuilding ? 1.3 : 1.0)
                                                .opacity(shouldPulseBuilding ? 0.6 : 0)
                                                .animation(
                                                    shouldPulseBuilding
                                                        ? Animation.easeInOut(duration: 1.2)
                                                            .repeatForever(autoreverses: true)
                                                        : .default,
                                                    value: shouldPulseBuilding
                                                )
                                        )
                                }
                                else {
                                    Circle().fill(Color.gray.opacity(0.3))
                                        .frame(width: 35, height: 35)
                                        .overlay(
                                            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }

                                Image(systemName: "building.2")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(
                                        hasLocationPermission ? .white : .white.opacity(0.5)
                                    )
                            }
                        }
                        .padding(.top, 5)  // Listen for changes in location permission
                        .onReceive(
                            NotificationCenter.default.publisher(
                                for: Notification.Name("locationPermissionChanged")
                            )
                        ) { _ in handleLocationPermissionChange() }

                        Spacer()

                        // Add Rules Button here
                        RulesButtonView(showRules: $showRules).padding(.top, 5)  // Match the padding on the location button
                    }
                    .padding(.horizontal, 20).padding(.top, 2)
                    // FLIP Logo adjusted slightly higher
                    FlipLogo().padding(.horizontal).padding(.top, -40)  // Negative padding to move up slightly

                    // Location Popup
                    if showLocationSelector {
                        LocationSelectorPopup(
                            buildingName: regionalViewModel.selectedBuilding?.name
                                ?? "Detecting location...",
                            isPresented: $showLocationSelector,
                            onChangeLocation: {
                                // Switch to Regional tab
                                viewRouter.selectedTab = 1
                                NotificationCenter.default.post(
                                    name: Notification.Name("SwitchToRegionalTab"),
                                    object: nil
                                )
                            }
                        )
                        .transition(.scale.combined(with: .opacity)).zIndex(1)
                        .padding(.horizontal, 24)
                    }

                    // Set Time Title
                    VStack(spacing: 2) {  // Reduced spacing from 4 to 2
                        Text("SET TIME").font(.system(size: 24, weight: .black)).tracking(8)
                            .foregroundColor(Theme.yellow).retroGlow()
                    }
                    .padding(.top, -5)

                    // Circular Time Picker
                    CircularTimeView(
                        selectedMinutes: $appManager.selectedMinutes,
                        isDisabled: false,
                        opacity: 1.0
                    )

                    // Controls Section - Redesigned with horizontal layout
                    ControlsSection(
                        appManager: appManager,
                        isInfinitePauses: $isInfinitePauses,
                        selectedPauseDurationIndex: $selectedPauseDurationIndex,
                        pauseDurations: pauseDurations,
                        pauseDurationLabels: pauseDurationLabels,
                        showPauseDisabledWarning: $showPauseDisabledWarning,
                        hasShownPauseWarning: $hasShownPauseWarning
                    )
                    .padding(.horizontal, 20).padding(.top, 0)  // Reduced padding

                    // Begin Button with Joining Overlay
                    BeginButtonWithOverlay(
                        appManager: appManager,
                        permissionManager: permissionManager,
                        showJoiningIndicator: showJoiningIndicator
                    )
                    .padding(.top, 5)
                }
                .padding(.top, 15)  // Reduced from 20 to 10
            }

            // Loading Overlay
            if showJoiningIndicator {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView().scaleEffect(2).tint(.white)

                            Text("Joining Session...").font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white).padding(.top, 20)
                        }
                    )
                    .transition(.opacity)
            }
            if showRules { RulesView(showRules: $showRules) }

            // Custom Alert Overlay
            if showPauseDisabledWarning {
                Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            // Warning Icon
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.yellow, Theme.orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Theme.yellowShadow, radius: 10).padding(.top, 30)

                            // Warning Title
                            VStack(spacing: 4) {
                                Text("WARNING").font(.system(size: 28, weight: .black)).tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: Theme.yellowShadow, radius: 8)

                                Text("警告").font(.system(size: 14)).tracking(4)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Alert Message
                            Text(
                                "With pauses disabled, flipping your phone at any time will instantly fail your session."
                            )
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.center).foregroundColor(.white)
                            .padding(.horizontal, 30).padding(.vertical, 10)

                            // Confirm Button
                            Button(action: {
                                withAnimation(.spring()) { showPauseDisabledWarning = false }
                            }) {
                                Text("GOT IT").font(.system(size: 20, weight: .black)).tracking(2)
                                    .foregroundColor(.white).frame(width: 200, height: 50)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Theme.yellow.opacity(0.9))

                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color.white.opacity(0.1))

                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Theme.yellowShadow, radius: 8)
                            }
                            .padding(.bottom, 30)
                        }
                        .frame(width: 320)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20).fill(Theme.darkGray)

                                RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 20)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    )
                    .transition(.opacity)
            }

            // Permission Required Alert
            if permissionManager.showPermissionRequiredAlert {
                PermissionRequiredAlert(isPresented: $permissionManager.showPermissionRequiredAlert)
            }

            // Location Permission Alert
            if permissionManager.showLocationAlert {
                LocationPermissionAlert(
                    isPresented: $permissionManager.showLocationAlert,
                    onContinue: { permissionManager.requestLocationPermission() }
                )
            }

            // Motion Permission Alert
            if permissionManager.showMotionAlert {
                MotionPermissionAlert(
                    isPresented: $permissionManager.showMotionAlert,
                    onContinue: { permissionManager.requestMotionPermission() }
                )
            }

            // Notification Permission Alert
            if permissionManager.showNotificationAlert {
                NotificationPermissionAlert(
                    isPresented: $permissionManager.showNotificationAlert,
                    onContinue: { permissionManager.requestNotificationPermission() }
                )
            }

            // Motion Settings Alert - appears after motion permission is denied
            if permissionManager.showMotionSettingsAlert {
                MotionSettingsAlert(isPresented: $permissionManager.showMotionSettingsAlert)
            }
            if SessionJoinCoordinator.shared.showFirstSessionRequiredAlert {
                FirstSessionRequiredAlert(
                    isPresented: Binding<Bool>(
                        get: { SessionJoinCoordinator.shared.showFirstSessionRequiredAlert },
                        set: { newValue in
                            SessionJoinCoordinator.shared.showFirstSessionRequiredAlert = newValue
                        }
                    )
                )
            }
        }
        .onAppear {
            if PermissionManager.shared.isPermissionLocked() {
                print("⏸️ SetupView: Deferring permission checks until InitialView completes")
                return
            }
            // Refresh permission status first to catch any changes made in Settings
            permissionManager.refreshPermissionStatus()

            // Initialize selected pause duration from AppManager
            if appManager.pauseDuration > 0 {
                if let index = pauseDurations.firstIndex(of: appManager.pauseDuration) {
                    selectedPauseDurationIndex = index
                }
            }
            else {
                // Default to 5 minutes (index 1)
                selectedPauseDurationIndex = 1
                appManager.pauseDuration = pauseDurations[selectedPauseDurationIndex]
            }

            // Check if infinite pauses are set
            isInfinitePauses = appManager.maxPauses > 10
            FirebaseManager.shared.hasCompletedFirstSession { hasCompleted in
                DispatchQueue.main.async {
                    // If user hasn't completed first session, don't allow joining
                    if !hasCompleted && showJoiningIndicator {
                        withAnimation {
                            showJoiningIndicator = false
                        }
                    }
                }
            }
        }
        .environmentObject(viewRouter)
        .alert("Location Access Required", isPresented: $showLocationSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Location access is required to identify and select nearby buildings.")
        }
    }

    // Extract complex logic into helper functions
    private func handleLocationPermissionChange() {
        // Start pulsing if we got location permission
        if permissionManager.locationAuthStatus == .authorizedWhenInUse
            || permissionManager.locationAuthStatus == .authorizedAlways
        {
            // Don't pulse if the user already selected a building
            if regionalViewModel.selectedBuilding == nil {
                regionalViewModel.shouldPulseBuildingButton = true
            }
        }
    }
}

struct LocationSelectorPopup: View {
    let buildingName: String  // Keep for compatibility
    @Binding var isPresented: Bool
    let onChangeLocation: () -> Void  // Keep for compatibility
    @ObservedObject private var mapConsentManager = MapConsentManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Building information section
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT LOCATION").font(.system(size: 12, weight: .bold)).tracking(1)
                        .foregroundColor(Theme.yellow.opacity(0.9))

                    // Use the passed building name (which comes from RegionalViewModel)
                    Text(buildingName).font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white).lineLimit(1)
                }

                Spacer()

                HStack {
                    Button(action: onChangeLocation) {
                        HStack(spacing: 4) {
                            Text("CHANGE").font(.system(size: 10, weight: .bold)).tracking(1)

                            Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(Theme.yellow.opacity(0.9)).padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }

                    Button(action: { withAnimation(.spring()) { isPresented = false } }) {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.7)).padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            // Only show map toggle if user has accepted map privacy
            if mapConsentManager.hasAcceptedMapPrivacy {
                // Subtle divider
                Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)
                // Map posting toggle
                HStack(alignment: .top, spacing: 10) {
                    // Map icon
                    ZStack {
                        Circle()
                            .fill(
                                mapConsentManager.postToMap
                                    ? Theme.yellow.opacity(0.2) : Color.white.opacity(0.08)
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 14))
                            .foregroundColor(
                                mapConsentManager.postToMap ? Theme.yellow : .white.opacity(0.7)
                            )
                    }
                    .overlay(
                        Circle()
                            .stroke(
                                mapConsentManager.hasExpired ? Theme.yellow : Color.clear,
                                lineWidth: 2
                            )
                            .scaleEffect(mapConsentManager.hasExpired ? 1.2 : 1.0)
                            .opacity(mapConsentManager.hasExpired ? 0.6 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: mapConsentManager.hasExpired
                            )
                    )
                    // Text and toggle
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("POST TO MAP").font(.system(size: 12, weight: .bold)).tracking(1)
                                .foregroundColor(
                                    mapConsentManager.postToMap ? Theme.yellow : .white.opacity(0.8)
                                )
                            Spacer()
                            // Toggle switch
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { mapConsentManager.postToMap },
                                    set: { mapConsentManager.togglePostToMap($0) }
                                )
                            )
                            .labelsHidden().toggleStyle(SwitchToggleStyle(tint: Theme.yellow))
                            .scaleEffect(0.8)
                        }
                        // Status text - shows expiry or prompt to enable
                        Text(
                            mapConsentManager.postToMap
                                ? "Auto-expires in \(mapConsentManager.formattedExpiryTime())"
                                : "Enable to share sessions on map"
                        )
                        .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    mapConsentManager.postToMap
                                        ? Theme.yellow.opacity(0.3) : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: mapConsentManager.postToMap)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.mutedPink.opacity(0.3), Theme.deepBlue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 1)  // Use solid color instead of Theme.silveryGradient4
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4)
    }
}

struct NumberPickerWithInfinity: View {
    let range: ClosedRange<Int>
    @Binding var selection: Int
    @Binding var isInfinite: Bool
    var isDisabled: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Minus button
            Button(action: {
                if !isDisabled && !isInfinite && selection > range.lowerBound {
                    withAnimation(.spring()) { selection -= 1 }
                }
            }) {
                Image(systemName: "minus").font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8)).frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled || isInfinite || selection <= range.lowerBound)
            .opacity((isDisabled || isInfinite || selection <= range.lowerBound) ? 0.5 : 1)

            // Value display or infinity
            ZStack {
                // Number display (shown when not infinite)
                Text("\(selection)").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    .frame(minWidth: 40).opacity(isInfinite ? 0 : 1)

                // Infinity symbol (shown when infinite)
                Image(systemName: "infinity").font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.yellow).frame(minWidth: 40).opacity(isInfinite ? 1 : 0)
            }

            // Plus/Infinity toggle button
            Button(action: {
                if !isDisabled {
                    if selection < range.upperBound && !isInfinite {
                        withAnimation(.spring()) { selection += 1 }
                    }
                    else if selection >= range.upperBound && !isInfinite {
                        // When we reach max value, next press toggles to infinity
                        withAnimation(.spring()) { isInfinite = true }
                    }
                    else if isInfinite {
                        // When infinite, press returns to lowest value
                        withAnimation(.spring()) {
                            isInfinite = false
                            selection = range.lowerBound
                        }
                    }
                }
            }) {
                Image(systemName: isInfinite ? "arrow.counterclockwise" : "plus")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white.opacity(0.8))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle()).disabled(isDisabled).opacity(isDisabled ? 0.5 : 1)
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.2)))
        .opacity(isDisabled ? 0.5 : 1)
    }
}

struct PermissionRequiredAlert: View {
    @Binding var isPresented: Bool
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.yellow, Theme.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.yellowShadow, radius: 6)

                // Title
                Text("PERMISSIONS REQUIRED").font(.system(size: 22, weight: .black)).tracking(4)
                    .foregroundColor(.white).shadow(color: Theme.yellowShadow, radius: 4)

                // Description
                Text(
                    "FLIP needs location and motion access to track when your phone is flipped. Without these permissions, the app cannot function."
                )
                .font(.system(size: 16)).multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.9)).padding(.horizontal, 15)

                // Location status
                permissionStatus(
                    title: "Location",
                    isGranted: permissionManager.locationAuthStatus == .authorizedWhenInUse
                        || permissionManager.locationAuthStatus == .authorizedAlways
                )

                // Motion status
                permissionStatus(
                    title: "Motion Tracking",
                    isGranted: permissionManager.motionPermissionGranted
                )

                // Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        isPresented = false
                        PermissionManager.shared.showPermissionRequiredAlert = false
                        permissionManager.requestAllPermissions()
                    }) {
                        Text("ENABLE").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(width: 120, height: 45)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20).fill(Theme.buttonGradient)

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Theme.silveryGradient, lineWidth: 1)
                                }
                            )
                            .shadow(color: Theme.purpleShadow, radius: 4)
                    }

                    Button(action: { isPresented = false }) {
                        Text("CANCEL").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8)).frame(width: 120, height: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.3))
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Theme.darkGray)

                    RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .frame(maxWidth: 320).shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
            .animation(.spring(), value: isPresented)
        }
    }

    private func permissionStatus(title: String, isGranted: Bool) -> some View {
        HStack {
            Text(title).font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red).font(.system(size: 20))
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        .padding(.horizontal, 10)
    }
}

// Define this new extracted view at bottom of the file
struct CircularTimeView: View {
    @Binding var selectedMinutes: Int
    var isDisabled: Bool = false
    var opacity: Double = 1.0
    var body: some View {
        CircularTime(selectedMinutes: $selectedMinutes).padding(.top, -15).disabled(isDisabled)
            .opacity(opacity).frame(height: 280)  // Reduce from 290 to 280
    }
}

// Define this new extracted view at bottom of the file
struct ControlsSection: View {
    @ObservedObject var appManager: AppManager
    @Binding var isInfinitePauses: Bool
    @Binding var selectedPauseDurationIndex: Int
    let pauseDurations: [Int]
    let pauseDurationLabels: [String]
    @Binding var showPauseDisabledWarning: Bool
    @Binding var hasShownPauseWarning: Bool
    var body: some View {
        VStack(spacing: 12) {  // Reduced spacing
            // Row 1: Allow Pause and # of Pauses in horizontal layout
            HStack(spacing: 12) {
                // 1. Allow Pause Toggle - Reduced width
                ControlButton(title: "ALLOW PAUSE") {
                    Toggle("", isOn: $appManager.allowPauses).toggleStyle(ModernToggleStyle())
                        .onChange(of: appManager.allowPauses) {
                            if !appManager.allowPauses {
                                // Only show the warning if it hasn't been shown before
                                if !hasShownPauseWarning {
                                    showPauseDisabledWarning = true
                                    hasShownPauseWarning = true
                                }
                                appManager.maxPauses = 0
                                isInfinitePauses = false
                            }
                            else {
                                appManager.maxPauses = 3  // Default number of pauses
                            }
                        }
                }
                .frame(width: UIScreen.main.bounds.width * 0.43)

                // 2. Number of Pauses with Infinite option incorporated into the picker
                ControlButton(
                    title: "# OF PAUSES",
                    isDisabled: !appManager.allowPauses
                ) {
                    NumberPickerWithInfinity(
                        range: 1...5,
                        selection: $appManager.maxPauses,
                        isInfinite: $isInfinitePauses,
                        isDisabled: !appManager.allowPauses
                    )
                    .onChange(of: isInfinitePauses) {
                        if isInfinitePauses {
                            // Set to a high number when infinite is selected
                            appManager.maxPauses = 999
                        }
                        else {
                            // Revert to default when turning off infinite
                            appManager.maxPauses = 3
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.43)
            }

            // 3. Pause Duration Selector
            ControlButton(
                title: "PAUSE DURATION",
                isDisabled: !appManager.allowPauses,
                reducedHeight: true
            ) {
                ModernPickerStyle(
                    options: pauseDurationLabels,
                    selection: $selectedPauseDurationIndex,
                    isDisabled: !appManager.allowPauses
                )
                .onChange(of: selectedPauseDurationIndex) {
                    appManager.pauseDuration = pauseDurations[selectedPauseDurationIndex]
                }
            }
        }
    }
}

struct BeginButtonWithOverlay: View {
    @ObservedObject var appManager: AppManager
    @ObservedObject var permissionManager: PermissionManager
    let showJoiningIndicator: Bool
    var body: some View {
        BeginButton(
            action: {
                // Check if we have proper permissions
                if permissionManager.motionPermissionGranted {
                    // Start the countdown regardless of location permission type
                    appManager.startCountdown()
                }
                else {
                    // Show permission alert if motion permission is missing
                    permissionManager.showPermissionRequiredAlert = true
                }
            }
        )
        .overlay(
            Group {
                if showJoiningIndicator {
                    Text("JOINING...").font(.system(size: 36, weight: .black)).tracking(8)
                        .foregroundColor(.white).shadow(color: Color.green.opacity(0.6), radius: 8)
                        .opacity(showJoiningIndicator ? 1 : 0)
                }
            }
        )
    }
}
