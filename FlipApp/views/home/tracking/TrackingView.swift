import SwiftUI

struct TrackingView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var permissionManager: PermissionManager
    @State private var isPausePressed = false
    @State private var isCancelPressed = false
    @State private var showingCancelAlert = false
    @State private var isGlowing = false
    @ObservedObject private var liveSessionManager = LiveSessionManager.shared

    var body: some View {
        ZStack {
            // Background gradient
            VStack {
                // Live Session Indicator - NEW
                if appManager.isJoinedSession {
                    JoinedSessionIndicator()
                        .padding(.bottom, 10)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Status Card
                        statusCard()

                        // Timer Card
                        timerCard()

                        // Action buttons
                        actionButtons()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }

            // Limited location warning if needed
            if appManager.usingLimitedLocationPermission
                && appManager.isFaceDown
            {
                limitedLocationWarning()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Cancel Session?", isPresented: $showingCancelAlert) {
            Button("Cancel Session", role: .destructive) {
                appManager.failSession()
            }
            Button("Keep Session", role: .cancel) {}
        } message: {
            Text("This session will be marked as failed. Are you sure?")
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2).repeatForever(autoreverses: true)
            ) {
                isGlowing = true
            }
        }
    }
    var flipBackTimeRemaining: Int {
        return appManager.flipBackTimeRemaining
    }
    private func statusCard() -> some View {
        VStack(spacing: 20) {
            // First check phone position and display appropriate icon
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Status icon
                Image(
                    systemName: appManager.isFaceDown
                        ? "iphone.gen3.circle.fill" : "iphone.gen3"
                )
                .font(.system(size: 60))
                .foregroundColor(appManager.isFaceDown ? .green : .red)
                .rotationEffect(.degrees(appManager.isFaceDown ? 180 : 0))
                .shadow(
                    color: appManager.isFaceDown
                        ? Color.green.opacity(0.6) : Color.red.opacity(0.6),
                    radius: isGlowing ? 10 : 5)
            }

            // Status text
            Text(
                appManager.isFaceDown
                    ? "Phone is face down" : "Phone is not face down"
            )
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(appManager.isFaceDown ? .green : .red)

            // Add flip back timer indicator when phone is face up
            if !appManager.isFaceDown && appManager.flipBackTimeRemaining > 0 {
                VStack(spacing: 8) {
                    Text("FLIP BACK OR PAUSE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.red)
                        .tracking(2)

                    // Timer progress bar
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)

                        // Progress indicator
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: UIScreen.main.bounds.width * 0.7
                                    * CGFloat(appManager.flipBackTimeRemaining)
                                    / 10, height: 10
                            )
                            .animation(
                                .linear(duration: 1),
                                value: appManager.flipBackTimeRemaining)
                    }
                    .padding(.horizontal, 10)

                    Text(
                        "\(appManager.flipBackTimeRemaining) seconds remaining"
                    )
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
                .animation(
                    .easeInOut,
                    value: !appManager.isFaceDown
                        && appManager.flipBackTimeRemaining > 0)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 30)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 40 / 255, green: 20 / 255,
                                    blue: 80 / 255
                                ).opacity(0.5),
                                Color(
                                    red: 30 / 255, green: 15 / 255,
                                    blue: 60 / 255
                                ).opacity(0.3),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12)
    }

    // Timer card with remaining time
    private func timerCard() -> some View {
        VStack(spacing: 15) {
            Text("REMAINING")
                .font(.system(size: 16, weight: .bold))
                .tracking(4)
                .foregroundColor(Theme.offWhite.opacity(0.8))

            HStack(spacing: 10) {
                // Timer container
                ZStack {
                    // Timer background
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.2))

                    // Timer text
                    Text(appManager.remainingTimeString)
                        .font(
                            .system(
                                size: 60, weight: .bold, design: .monospaced)
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.4), radius: 10)
                }
                .frame(height: 80)
                .padding(.horizontal, 30)
            }

            if appManager.allowPauses {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 10)

                    HStack(spacing: 10) {
                        Image(systemName: "pause.circle")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.offWhite.opacity(0.7))

                        Text(
                            "\(appManager.remainingPauses) \(appManager.remainingPauses == 1 ? "PAUSE" : "PAUSES") REMAINING"
                        )
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Theme.offWhite.opacity(0.7))
                    }
                    .padding(.bottom, 5)
                }
            }
        }
        .padding(.vertical, 25)
        .padding(.horizontal, 30)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(
                                    red: 40 / 255, green: 20 / 255,
                                    blue: 80 / 255
                                ).opacity(0.4),
                                Color(
                                    red: 30 / 255, green: 15 / 255,
                                    blue: 60 / 255
                                ).opacity(0.2),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))

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
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12)
    }

    // Action buttons
    private func actionButtons() -> some View {
        VStack(spacing: 20) {
            // Show pause and cancel buttons if:
            // 1. Phone is not face down OR
            // 2. User has limited location permission (even if face down)
            if (!appManager.isFaceDown
                || appManager.usingLimitedLocationPermission)
                && appManager.allowPauses && appManager.remainingPauses > 0
            {

                // Pause Button
                Button(action: {
                    withAnimation(.spring()) {
                        isPausePressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appManager.pauseSession()
                        isPausePressed = false
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "pause.circle.fill")
                        Text("PAUSE SESSION")
                    }
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
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
                        color: Theme.lightTealBlue.opacity(0.5), radius: 8
                    )
                    .scaleEffect(isPausePressed ? 0.95 : 1.0)
                }

                // Cancel Button
                Button(action: {
                    withAnimation(.spring()) {
                        isCancelPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingCancelAlert = true
                        isCancelPressed = false
                    }
                }) {
                    Text("CANCEL SESSION")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 239 / 255,
                                                    green: 68 / 255,
                                                    blue: 68 / 255),
                                                Color(
                                                    red: 185 / 255,
                                                    green: 28 / 255,
                                                    blue: 28 / 255),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .opacity(0.8)

                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 6)
                        .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                }
            }
        }
    }

    // Warning that appears for limited location users when their phone is face down
    private func limitedLocationWarning() -> some View {
        VStack {
            Spacer()

            ZStack {
                // Background with blur
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .blur(radius: 0.5)

                // Warning message
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.yellow)

                        Text("LIMITED LOCATION MODE")
                            .font(.system(size: 16, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Theme.yellow)
                    }

                    Text(
                        "Keep your phone on during the entire session. You can use the pause button anytime."
                    )
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)

                    // Dismiss button
                    Button(action: {
                        withAnimation {
                            // This is just to dismiss the warning
                            // It will reappear if needed
                        }
                    }) {
                        Text("GOT IT")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Theme.yellow.opacity(0.3))
                                    .stroke(
                                        Theme.yellow.opacity(0.7), lineWidth: 1)
                            )
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 25)
            }
            .frame(maxWidth: .infinity, maxHeight: 180)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(
            .spring(),
            value: appManager.usingLimitedLocationPermission
                && appManager.isFaceDown)
    }
}
