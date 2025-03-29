import SwiftUI

struct PausedView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showingCancelAlert = false
    @State private var isResumePressed = false
    @State private var isCancelPressed = false
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            // Main Paused View Content
            VStack(spacing: 35) {
                // Top section
                VStack(spacing: 10) {
                    // Pause Icon with enhanced glow
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                            .opacity(0.2),
                                        Color(red: 88 / 255, green: 28 / 255, blue: 135 / 255)
                                            .opacity(0.1),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: "pause.circle.fill").font(.system(size: 65))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.yellow,  // Yellow
                                        Theme.yellowyOrange,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: Theme.yellow.opacity(isGlowing ? 0.5 : 0.3),
                                radius: isGlowing ? 10 : 5
                            )
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            isGlowing = true
                        }
                    }

                    // Title with Japanese
                    VStack(spacing: 4) {
                        Text("SESSION PAUSED").font(.system(size: 28, weight: .black)).tracking(6)
                            .foregroundColor(.white)
                            .shadow(color: Theme.yellow.opacity(0.4), radius: 6)

                    }
                }

                // Time info section
                VStack(spacing: 30) {
                    // Pause timer section
                    VStack(spacing: 8) {
                        Text("PAUSE ENDS IN").font(.system(size: 16, weight: .bold)).tracking(2)
                            .foregroundColor(Theme.yellow)

                        HStack(spacing: 6) {
                            timeComponent(
                                value: appManager.remainingPauseSeconds / 60,
                                label: "MIN"
                            )

                            Text(":").font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundColor(.white).offset(y: -4)

                            timeComponent(
                                value: appManager.remainingPauseSeconds % 60,
                                label: "SEC"
                            )
                        }

                        Text("Auto-resumes when timer ends").font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 15).padding(.horizontal, 25)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255)
                                                .opacity(0.6),
                                            Color(red: 30 / 255, green: 15 / 255, blue: 60 / 255)
                                                .opacity(0.4),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))  // Glass effect

                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4), Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8)

                    // Simplified status display - just shows pauses remaining
                    VStack(spacing: 8) {
                        Text("PAUSES REMAINING").font(.system(size: 16, weight: .bold)).tracking(2)
                            .foregroundColor(.white.opacity(0.8))

                        Text("\(appManager.remainingPauses)").font(.system(size: 56, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(
                                color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                    .opacity(0.6),
                                radius: 6
                            )

                        if appManager.remainingPauses == 1 {
                            Text("Last pause available").font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        else if appManager.remainingPauses > 1 {
                            Text("\(appManager.remainingPauses) pauses available")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        else {
                            Text("No more pauses available")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 15).padding(.horizontal, 25)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 40 / 255, green: 20 / 255, blue: 80 / 255)
                                                .opacity(0.4),
                                            Color(red: 30 / 255, green: 15 / 255, blue: 60 / 255)
                                                .opacity(0.2),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))  // Glass effect

                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3), Color.white.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 6)
                }

                // Action Buttons
                VStack(spacing: 15) {
                    // Resume Button with glass effect
                    Button(action: {
                        withAnimation(.spring()) { isResumePressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            appManager.resumeSession()
                            isResumePressed = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                            Text("RESUME NOW")
                        }
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        .frame(height: 54).frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(
                                                    red: 168 / 255,
                                                    green: 85 / 255,
                                                    blue: 247 / 255
                                                ),
                                                Color(
                                                    red: 88 / 255,
                                                    green: 28 / 255,
                                                    blue: 135 / 255
                                                ),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6), Color.white.opacity(0.2),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(
                            color: Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
                                .opacity(0.5),
                            radius: 8
                        )
                        .scaleEffect(isResumePressed ? 0.97 : 1.0)
                    }
                    .padding(.horizontal, 25)

                    // Cancel Button
                    Button(action: {
                        withAnimation(.spring()) { isCancelPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingCancelAlert = true
                            isCancelPressed = false
                        }
                    }) {
                        Text("CANCEL SESSION").font(.system(size: 16, weight: .bold)).tracking(1)
                            .foregroundColor(.white.opacity(0.8)).padding(.vertical, 12)
                    }
                    .scaleEffect(isCancelPressed ? 0.97 : 1.0)
                }
            }
            .padding(.horizontal, 20).padding(.top, 40).padding(.bottom, 30)

            // Custom alert overlay
            if showingCancelAlert {
                CustomCancelAlert(
                    isPresented: $showingCancelAlert,
                    onConfirm: { appManager.failSession() }
                )
            }
        }
    }

    private func timeComponent(value: Int, label: String) -> some View {
        VStack(spacing: 0) {
            Text("\(String(format: "%02d", value))")
                .font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundColor(.white)

            Text(label).font(.system(size: 10, weight: .bold)).tracking(1)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct CustomCancelAlert: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @State private var isConfirmPressed = false
    @State private var isCancelPressed = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation(.spring()) { isPresented = false } }

            // Alert card
            VStack(spacing: 20) {
                // Warning Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.mutedRed,
                                    Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70).opacity(0.2)

                    Circle().fill(Color.white.opacity(0.05)).frame(width: 75, height: 75)

                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.mutedRed,
                                    Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.red.opacity(0.5), radius: 8)
                }
                .padding(.top, 20)

                // Title
                VStack(spacing: 4) {
                    Text("CANCEL SESSION?").font(.system(size: 22, weight: .black)).tracking(2)
                        .foregroundColor(.white).shadow(color: Color.red.opacity(0.5), radius: 6)

                    Text("セッションをキャンセル").font(.system(size: 12)).tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Message
                Text("This session will be marked as failed and you will lose points.")
                    .font(.system(size: 16, weight: .medium)).multilineTextAlignment(.center)
                    .foregroundColor(.white).padding(.horizontal, 20).padding(.top, 10)

                // Buttons
                HStack(spacing: 15) {
                    // Keep Session button
                    Button(action: {
                        withAnimation(.spring()) { isCancelPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isCancelPressed = false
                            isPresented = false
                        }
                    }) {
                        Text("KEEP SESSION").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.97 : 1.0)
                    }

                    // Cancel Session button
                    Button(action: {
                        withAnimation(.spring()) { isConfirmPressed = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isConfirmPressed = false
                            isPresented = false
                            onConfirm()
                        }
                    }) {
                        Text("CANCEL SESSION").font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white).frame(height: 44).frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Theme.mutedRed,
                                                    Color(
                                                        red: 185 / 255,
                                                        green: 28 / 255,
                                                        blue: 28 / 255
                                                    ),
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(0.8)

                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 22)
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
                            .scaleEffect(isConfirmPressed ? 0.97 : 1.0)
                    }
                }
                .padding(.top, 10).padding(.horizontal, 20).padding(.bottom, 25)
            }
            .frame(width: 320)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Theme.mutedPurple, Theme.deepMidnightPurple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.3))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .transition(.opacity)
    }
}
