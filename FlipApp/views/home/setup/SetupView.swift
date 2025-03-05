import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showPauseDisabledWarning = false
    @State private var isInfinitePauses = false
    @State private var selectedPauseDurationIndex = 1 // Default to 5 minutes (index 1)
    @AppStorage("hasShownPauseWarning") private var hasShownPauseWarning = false
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared
    @ObservedObject private var regionalViewModel = RegionalViewModel.shared
    @State private var isJoining = false
    @State private var showJoiningIndicator = false
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var viewRouter = ViewRouter()
    
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
                VStack(spacing: 25) {
                    // FLIP Logo at the top
                    FlipLogo()
                    .padding(.horizontal)
                    
                    // Current Building Indicator
                    CurrentBuildingIndicator(
                        buildingName: regionalViewModel.selectedBuilding?.name ?? "Detecting location..."
                    ) {
                        // Switch to Regional tab
                        viewRouter.selectedTab = 1
                        NotificationCenter.default.post(name: Notification.Name("SwitchToRegionalTab"), object: nil)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
                    
                    // Set Time Title
                    VStack(spacing: 4) {
                        if joinLiveSessionMode, let sessionInfo = sessionToJoin {
                            Text("JOIN \(sessionInfo.name.uppercased())'S SESSION")
                                .font(.system(size: 20, weight: .black))
                                .tracking(6)
                                .foregroundColor(.white)
                                .retroGlow()
                                .multilineTextAlignment(.center)
                            
                            Text("友達と一緒に")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(3)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("SET TIME")
                                .font(.system(size: 24, weight: .black))
                                .tracking(8)
                                .foregroundColor(Theme.yellow)
                                .retroGlow()
                                .padding(.top, 5)
                            
                            Text("タイマーの設定")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Circular Time Picker
                    CircularTime(selectedMinutes: $appManager.selectedMinutes)
                        .padding(.top, -10)
                        .disabled(joinLiveSessionMode) // Disable time selection for joined sessions
                        .opacity(joinLiveSessionMode ? 0.7 : 1)
                        .frame(height: 300)

                    // Controls Section - redesigned with 3 controls
                    VStack(spacing: 16) {
                        // 1. Allow Pause Toggle
                        ControlButton(title: "ALLOW PAUSE") {
                            Spacer()
                            Toggle("", isOn: $appManager.allowPauses)
                                .toggleStyle(ModernToggleStyle())
                                .disabled(joinLiveSessionMode) // Disable in join mode
                                .onChange(of: appManager.allowPauses) { newValue in
                                    if !newValue {
                                        // Only show the warning if it hasn't been shown before
                                        if !hasShownPauseWarning {
                                            showPauseDisabledWarning = true
                                            hasShownPauseWarning = true
                                        }
                                        appManager.maxPauses = 0
                                        isInfinitePauses = false
                                    } else {
                                        appManager.maxPauses = 3 // Default number of pauses
                                    }
                                }
                            Spacer()
                        }

                        // 2. Number of Pauses with Infinite option
                        ControlButton(title: "# OF PAUSES", isDisabled: !appManager.allowPauses || joinLiveSessionMode) {
                            HStack {
                                NumberPicker(
                                    range: 1...5,
                                    selection: $appManager.maxPauses,
                                    isDisabled: !appManager.allowPauses || joinLiveSessionMode || isInfinitePauses
                                )
                                
                                Spacer()
                                
                                InfinityToggle(
                                    isInfinite: $isInfinitePauses,
                                    isDisabled: !appManager.allowPauses || joinLiveSessionMode
                                )
                                .onChange(of: isInfinitePauses) { newValue in
                                    if newValue {
                                        // Set to a high number when infinite is selected
                                        appManager.maxPauses = 999
                                    } else {
                                        // Revert to default when turning off infinite
                                        appManager.maxPauses = 3
                                    }
                                }
                            }
                        }
                        
                        // 3. Pause Duration Selector
                        ControlButton(title: "PAUSE DURATION", isDisabled: !appManager.allowPauses || joinLiveSessionMode) {
                            ModernPickerStyle(
                                options: pauseDurationLabels,
                                selection: $selectedPauseDurationIndex,
                                isDisabled: !appManager.allowPauses || joinLiveSessionMode
                            )
                            .onChange(of: selectedPauseDurationIndex) { newValue in
                                appManager.pauseDuration = pauseDurations[newValue]
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 5)

                    // Begin Button
                    BeginButton {
                        // Only start a regular session here, joining is handled in onAppear
                        if !joinLiveSessionMode {
                            appManager.startCountdown()
                        }
                    }
                    .overlay(
                        Group {
                            if joinLiveSessionMode {
                                Text("JOINING...")
                                    .font(.system(size: 36, weight: .black))
                                    .tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.green.opacity(0.6), radius: 8)
                                    .opacity(showJoiningIndicator ? 1 : 0)
                            }
                        }
                    )
                    .disabled(joinLiveSessionMode) // Disable when joining
                    .padding(.bottom, 50)
                }
                .padding(.top, 20)
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
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 40)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.red.opacity(0.7))
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                    }
                    .disabled(showJoiningIndicator) // Disable during join process
                    .padding(.bottom, 50)
                }
            }
            
            // Loading Overlay
            if showJoiningIndicator {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.white)
                            
                            Text("Joining Session...")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    )
                    .transition(.opacity)
            }
            
            // Custom Alert Overlay
            if showPauseDisabledWarning {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack(spacing: 20) {
                            // Warning Icon
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Theme.yellow,
                                            Theme.orange
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Theme.yellowShadow, radius: 10)
                                .padding(.top, 30)
                            
                            // Warning Title
                            VStack(spacing: 4) {
                                Text("WARNING")
                                    .font(.system(size: 28, weight: .black))
                                    .tracking(8)
                                    .foregroundColor(.white)
                                    .shadow(color: Theme.yellowShadow, radius: 8)
                                
                                Text("警告")
                                    .font(.system(size: 14))
                                    .tracking(4)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Alert Message
                            Text("With pauses disabled, flipping your phone at any time will instantly fail your session.")
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                            
                            // Confirm Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    showPauseDisabledWarning = false
                                }
                            }) {
                                Text("GOT IT")
                                    .font(.system(size: 20, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 50)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Theme.yellowAccentGradient)
                                            
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(Color.white.opacity(0.1))
                                            
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.6),
                                                            Color.white.opacity(0.2)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        }
                                    )
                                    .shadow(color: Theme.yellowShadow, radius: 8)
                            }
                            .padding(.bottom, 30)
                        }
                        .frame(width: 320)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Theme.darkGray)
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.3))
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
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
                    onContinue: {
                        permissionManager.requestLocationPermission()
                    }
                )
            }
            
            // Motion Permission Alert
            if permissionManager.showMotionAlert {
                MotionPermissionAlert(
                    isPresented: $permissionManager.showMotionAlert,
                    onContinue: {
                        permissionManager.requestMotionPermission()
                    }
                )
            }
            
            // Notification Permission Alert
            if permissionManager.showNotificationAlert {
                NotificationPermissionAlert(
                    isPresented: $permissionManager.showNotificationAlert,
                    onContinue: {
                        permissionManager.requestNotificationPermission()
                    }
                )
            }
        }
        .onAppear {
            // Initialize selected pause duration from AppManager
            if appManager.pauseDuration > 0 {
                if let index = pauseDurations.firstIndex(of: appManager.pauseDuration) {
                    selectedPauseDurationIndex = index
                }
            } else {
                // Default to 5 minutes (index 1)
                selectedPauseDurationIndex = 1
                appManager.pauseDuration = pauseDurations[selectedPauseDurationIndex]
            }
            
            // Check if infinite pauses are set
            isInfinitePauses = appManager.maxPauses > 10
            
            // Check if we're being called to join a session
            if let sessionData = SessionJoinCoordinator.shared.getJoinSession() {
                joinLiveSessionMode = true
                sessionToJoin = sessionData
                
                // Show joining indicator
                withAnimation {
                    showJoiningIndicator = true
                }
                
                // Get session details and AUTO-JOIN after verification
                LiveSessionManager.shared.getSessionDetails(sessionId: sessionData.id) { session in
                    if let session = session {
                        DispatchQueue.main.async {
                            // Set timer and values first
                            appManager.selectedMinutes = session.targetDuration
                            
                            // Then auto-join the session
                            LiveSessionManager.shared.joinSession(sessionId: sessionData.id) { success, remainingSeconds, totalDuration in
                                if success {
                                    appManager.joinLiveSession(
                                        sessionId: sessionData.id,
                                        remainingSeconds: remainingSeconds,
                                        totalDuration: totalDuration
                                    )
                                    
                                    // Hide join indicator after short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            showJoiningIndicator = false
                                        }
                                    }
                                } else {
                                    // Handle failure
                                    print("Failed to join session")
                                    withAnimation {
                                        showJoiningIndicator = false
                                        joinLiveSessionMode = false
                                    }
                                }
                            }
                        }
                    } else {
                        // Session doesn't exist, reset join mode
                        DispatchQueue.main.async {
                            withAnimation {
                                showJoiningIndicator = false
                                joinLiveSessionMode = false
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(viewRouter)
    }
}

struct PermissionRequiredAlert: View {
    @Binding var isPresented: Bool
    @ObservedObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.yellow, Theme.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.yellowShadow, radius: 6)
                
                // Title
                Text("PERMISSIONS REQUIRED")
                    .font(.system(size: 22, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .shadow(color: Theme.yellowShadow, radius: 4)
                
                // Description
                Text("FLIP needs location and motion access to track when your phone is flipped. Without these permissions, the app cannot function.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 15)
                
                // Location status
                permissionStatus(
                    title: "Location",
                    isGranted: permissionManager.locationAuthStatus == .authorizedWhenInUse ||
                              permissionManager.locationAuthStatus == .authorizedAlways
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
                        Text("ENABLE")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 45)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Theme.buttonGradient)
                                        
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                        
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: Theme.purpleShadow, radius: 4)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 120, height: 45)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.3))
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.darkGray)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
            )
            .frame(maxWidth: 320)
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
            .animation(.spring(), value: isPresented)
        }
    }
    
    private func permissionStatus(title: String, isGranted: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
                .font(.system(size: 20))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 10)
    }
}