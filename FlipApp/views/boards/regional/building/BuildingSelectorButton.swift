import SwiftUI

struct BuildingSelectorButton: View {
    let buildingName: String?
    let action: () -> Void
    let refreshAction: () -> Void
    @Binding var isRefreshing: Bool
    @State private var isPulsing = false
    @State private var hasAppeared = false
    @State private var hasTapped = false
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var showLocationAlert = false
    // Check if location permission is granted
    private var hasLocationPermission: Bool {
        permissionManager.locationAuthStatus == .authorizedWhenInUse
            || permissionManager.locationAuthStatus == .authorizedAlways
    }
    // Check if this is the first time showing the button with location permission
    private var shouldPulse: Bool {
        hasLocationPermission && !hasTapped && !hasAppeared && (buildingName == nil || !hasAppeared)
    }

    var body: some View {
        HStack {
            Button(action: {
                hasTapped = true
                isPulsing = false
                if hasLocationPermission {
                    action()
                }
                else {
                    // Show the permission alert if location is denied
                    showLocationAlert = true
                }
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BUILDING").font(.system(size: 12, weight: .bold)).tracking(2)
                        .foregroundColor(
                            hasLocationPermission ? .white.opacity(0.7) : .white.opacity(0.4)
                        )

                    Text(buildingName ?? "Tap to select building")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(hasLocationPermission ? .white : .white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .disabled(!hasLocationPermission)

            // Refresh button
            Button(action: {
                if hasLocationPermission {
                    refreshAction()
                }
                else {
                    // Show the permission alert if location is denied
                    showLocationAlert = true
                }
            }) {
                ZStack {
                    if isRefreshing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    else {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16))
                                .foregroundColor(
                                    hasLocationPermission
                                        ? .white.opacity(0.7) : .white.opacity(0.4)
                                )

                            Text("REFRESH").font(.system(size: 10, weight: .bold))
                                .foregroundColor(
                                    hasLocationPermission
                                        ? .white.opacity(0.7) : .white.opacity(0.4)
                                )
                        }
                    }
                }
                .frame(width: 60).padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(hasLocationPermission ? 0.1 : 0.05))
                )
            }
            .disabled(isRefreshing || !hasLocationPermission)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(hasLocationPermission ? 0.08 : 0.04))

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(isPulsing ? 0.6 : (hasLocationPermission ? 0.2 : 0.1)),
                        lineWidth: isPulsing ? 2 : 1
                    )
                    .animation(
                        isPulsing
                            ? Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
            }
        )
        .padding(.horizontal)
        .onAppear {
            // Only pulse if we should (first time or no building selected)
            if shouldPulse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { isPulsing = true }
                }

                // Turn off pulsing after the user has seen it for a while
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        if !hasTapped { isPulsing = false }
                        hasAppeared = true
                    }
                }
            }
        }
        // Listen for changes in location permission
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("locationPermissionChanged")
            )
        ) { _ in
            // If permission has been granted and we should pulse, start pulsing
            if hasLocationPermission && !hasAppeared && !hasTapped {
                withAnimation { isPulsing = true }
            }
        }
        // Add alert for location permission
        .alert("Location Access Required", isPresented: $showLocationAlert) {
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
}
