import Foundation
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
    @State private var showLocationUpgradeAlert = false

    // Check if we're navigating back from a joined session view
    @State private var joinLiveSessionMode = false
    @State private var sessionToJoin: (id: String, name: String)? = nil

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
                        Button(action: {
                            // Toggle the popup instead of just showing it
                            showLocationSelector.toggle()
                        }) {
                            ZStack {
                                Circle().fill(Theme.buttonGradient).frame(width: 35, height: 35)
                                    .overlay(Circle().stroke(Theme.silveryGradient, lineWidth: 1))
                                    .shadow(color: Theme.purpleShadow.opacity(0.3), radius: 4)

                                Image(systemName: "building.2")
                                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .padding(.top, 5)

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
                        if joinLiveSessionMode, let sessionInfo = sessionToJoin {
                            Text("JOIN \(sessionInfo.name.uppercased())'S SESSION")
                                .font(.system(size: 20, weight: .black)).tracking(6)
                                .foregroundColor(.white).retroGlow().multilineTextAlignment(.center)

                            Text("友達と一緒に").font(.system(size: 12, weight: .medium)).tracking(3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        else {
                            Text("SET TIME").font(.system(size: 24, weight: .black)).tracking(8)
                                .foregroundColor(Theme.yellow).retroGlow()

                        }
                    }
                    .padding(.top, -5)

                    // Circular Time Picker
                    CircularTime(selectedMinutes: $appManager.selectedMinutes).padding(.top, -15)  // Increase negative padding from -15 to -20
                        .disabled(joinLiveSessionMode).opacity(joinLiveSessionMode ? 0.7 : 1)
                        .frame(height: 280)  // Reduce from 290 to 280

                    // Controls Section - Redesigned with horizontal layout
                    VStack(spacing: 12) {  // Reduced spacing
                        // Row 1: Allow Pause and # of Pauses in horizontal layout
                        HStack(spacing: 12) {
                            // 1. Allow Pause Toggle - Reduced width
                            ControlButton(title: "ALLOW PAUSE") {
                                Toggle("", isOn: $appManager.allowPauses)
                                    .toggleStyle(ModernToggleStyle())
                                    .disabled(joinLiveSessionMode)  // Disable in join mode
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
                                isDisabled: !appManager.allowPauses || joinLiveSessionMode
                            ) {
                                NumberPickerWithInfinity(
                                    range: 1...5,
                                    selection: $appManager.maxPauses,
                                    isInfinite: $isInfinitePauses,
                                    isDisabled: !appManager.allowPauses || joinLiveSessionMode
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
                            isDisabled: !appManager.allowPauses || joinLiveSessionMode,
                            reducedHeight: true
                        ) {
                            ModernPickerStyle(
                                options: pauseDurationLabels,
                                selection: $selectedPauseDurationIndex,
                                isDisabled: !appManager.allowPauses || joinLiveSessionMode
                            )
                            .onChange(of: selectedPauseDurationIndex) {
                                appManager.pauseDuration =
                                    pauseDurations[selectedPauseDurationIndex]
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 0)  // Reduced padding

                    // Begin Button
                    // Replace the inline BeginButton action with this handler:
                    BeginButton(
                        action: {
                            // Check if we have proper permissions
                            if permissionManager.motionPermissionGranted {
                                // Check if we're in joining mode
                                if !joinLiveSessionMode {
                                    // Set the appropriate flag in AppManager based on permission status
                                    appManager.usingLimitedLocationPermission =
                                        permissionManager.hasLimitedLocationPermission
                                        && !permissionManager.hasFullLocationPermission

                                    // Start the countdown regardless of location permission type
                                    appManager.startCountdown()
                                }
                            }
                            else {
                                // Show permission alert if motion permission is missing
                                permissionManager.showPermissionRequiredAlert = true
                            }
                        },
                        joinMode: joinLiveSessionMode
                    )
                    .overlay(
                        Group {
                            if joinLiveSessionMode {
                                Text("JOINING...").font(.system(size: 36, weight: .black))
                                    .tracking(8).foregroundColor(.white)
                                    .shadow(color: Color.green.opacity(0.6), radius: 8)
                                    .opacity(showJoiningIndicator ? 1 : 0)
                            }
                        }
                    )
                    .padding(.top, 5)
                }
                .padding(.top, 15)  // Reduced from 20 to 10
            }

            // Join Session Mode Control - shown only during join mode
            if joinLiveSessionMode {
                VStack {
                    Spacer()
                    Button(action: {
                        // FIXED: This button now correctly cancels join mode instead of trying to join
                        joinLiveSessionMode = false
                        sessionToJoin = nil
                    }) {
                        Text("CANCEL").font(.system(size: 16, weight: .bold)).tracking(2)
                            .foregroundColor(.white).frame(width: 120, height: 40)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20).fill(Color.red.opacity(0.7))

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                    }
                    .disabled(showJoiningIndicator)  // Disable during join process
                    .padding(.bottom, 50)
                }
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
                                                .fill(Theme.yellowAccentGradient)

                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color.white.opacity(0.1))

                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Theme.silveryGradient, lineWidth: 1)
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
                                    .stroke(Theme.silveryGradient2, lineWidth: 1)
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
            if showLocationUpgradeAlert {
                LocationUpgradeAlert(isPresented: $showLocationUpgradeAlert)
                    .onDisappear {
                        // Mark as shown when dismissed
                        permissionManager.hasShownLocationUpgradeAlert = true
                    }
            }
            if showLocationUpgradeAlert {
                LocationUpgradeAlert(isPresented: $showLocationUpgradeAlert)
                    .onDisappear {
                        // Mark as shown when dismissed
                        permissionManager.hasShownLocationUpgradeAlert = true
                    }
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
            // Refresh permission status first to catch any changes made in Settings
            permissionManager.refreshPermissionStatus()
            if permissionManager.locationAuthStatus == .denied
                && !permissionManager.hasShownLocationUpgradeAlert
            {
                showLocationUpgradeAlert = true
            }

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
                    if !hasCompleted && joinLiveSessionMode {
                        withAnimation {
                            joinLiveSessionMode = false
                            sessionToJoin = nil
                            SessionJoinCoordinator.shared.showFirstSessionRequiredAlert = true
                        }
                    }
                }
            }

            // Check if we're being called to join a session
            if let sessionData = SessionJoinCoordinator.shared.getJoinSession() {
                joinLiveSessionMode = true
                sessionToJoin = sessionData

                // Show joining indicator
                withAnimation { showJoiningIndicator = true }

                // First ensure any existing session state is properly reset
                appManager.resetJoinState()

                // Get session details
                LiveSessionManager.shared.getSessionDetails(sessionId: sessionData.id) { session in
                    if let session = session {
                        DispatchQueue.main.async {
                            // Set values first
                            self.appManager.selectedMinutes = session.targetDuration

                            // Now try to join
                            LiveSessionManager.shared.joinSession(sessionId: sessionData.id) {
                                success,
                                remainingSeconds,
                                totalDuration in
                                if success {
                                    self.appManager.joinLiveSession(
                                        sessionId: sessionData.id,
                                        remainingSeconds: remainingSeconds,
                                        totalDuration: totalDuration
                                    )

                                    // Clear coordinator state
                                    SessionJoinCoordinator.shared.clearPendingSession()

                                    // Hide join indicator after short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation { self.showJoiningIndicator = false }
                                    }
                                }
                                else {
                                    // Handle failure
                                    SessionJoinCoordinator.shared.clearPendingSession()
                                    withAnimation {
                                        self.showJoiningIndicator = false
                                        self.joinLiveSessionMode = false
                                    }
                                }
                            }
                        }
                    }
                    else {
                        // Session doesn't exist
                        DispatchQueue.main.async {
                            SessionJoinCoordinator.shared.clearPendingSession()
                            withAnimation {
                                self.showJoiningIndicator = false
                                self.joinLiveSessionMode = false
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(viewRouter)
    }
}

// Full LocationSelectorPopup implementation

struct LocationSelectorPopup: View {
    let buildingName: String  // Keep for compatibility
    @Binding var isPresented: Bool
    let onChangeLocation: () -> Void  // Keep for compatibility

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

                RoundedRectangle(cornerRadius: 16).stroke(Theme.silveryGradient4, lineWidth: 1)
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
