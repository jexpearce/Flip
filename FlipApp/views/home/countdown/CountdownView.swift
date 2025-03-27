import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var permissionManager: PermissionManager
    @State private var numberScale: CGFloat = 1.0
    @State private var numberOpacity: Double = 1.0
    @State private var isGlowing = false
    @State private var showPulse = false

    var body: some View {
        VStack(spacing: 25) {
            // Title with animated glow
            Text("GET READY")
                .font(.system(size: 28, weight: .black))
                .tracking(8)
                .foregroundColor(.white)
                .shadow(
                    color: Color(
                        red: 56 / 255, green: 189 / 255, blue: 248 / 255
                    ).opacity(isGlowing ? 0.7 : 0.3), radius: isGlowing ? 15 : 8
                )
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.5).repeatForever(
                            autoreverses: true)
                    ) {
                        isGlowing = true
                    }
                }

            // Animated Countdown Number
            Text("\(appManager.countdownSeconds)")
                .font(.system(size: 120, weight: .black))
                .foregroundColor(.white)
                .scaleEffect(numberScale)
                .opacity(numberOpacity)
                .shadow(
                    color: Color(
                        red: 56 / 255, green: 189 / 255, blue: 248 / 255
                    ).opacity(0.6), radius: 15
                )
                .onChange(of: appManager.countdownSeconds) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6))
                    {
                        numberScale = 1.4
                        numberOpacity = 0.7
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(
                            .spring(response: 0.3, dampingFraction: 0.6)
                        ) {
                            numberScale = 1.0
                            numberOpacity = 1.0
                        }
                    }
                }

            // Warning for users without full location permission
            if appManager.usingLimitedLocationPermission {
                locationWarningBanner()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
            }

            // Instructions
            VStack(spacing: 15) {
                // Step 1 - Text changes based on permission level
                instructionRow(
                    number: "1",
                    text: appManager.usingLimitedLocationPermission
                        ? "KEEP PHONE ON" : "TURN OFF PHONE"
                )

                // Step 2
                instructionRow(
                    number: "2",
                    text: "FLIP PHONE"
                )
            }
            .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                // Subtle animated circles in background
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            appManager.usingLimitedLocationPermission
                                ? Theme.yellowAccentGradient
                                : Theme.buttonGradient
                        )
                        .frame(width: 200, height: 200)
                        .opacity(0.05)
                        .offset(
                            x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -100...100)
                        )
                        .blur(radius: 50)
                }
            }
        )
        .onAppear {
            // Start the pulse animation
            withAnimation(
                Animation.easeInOut(duration: 2).repeatForever(
                    autoreverses: true)
            ) {
                showPulse = true
            }
        }
    }

    private func locationWarningBanner() -> some View {
        HStack(spacing: 8) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(Theme.yellow)

            // Concise warning text
            Text("Keep phone on during session")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 15) {
            // Number circle with glass effect
            ZStack {
                Circle()
                    .fill(
                        appManager.usingLimitedLocationPermission
                            ? Theme.yellowAccentGradient : Theme.buttonGradient
                    )
                    .opacity(0.1)

                Circle()
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

                Text(number)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)

            Text(text)
                .font(.system(size: 20, weight: .heavy))
                .tracking(2)
                .foregroundColor(.white)
                .shadow(
                    color: appManager.usingLimitedLocationPermission
                        ? Theme.yellowShadow.opacity(0.7)
                        : Color(
                            red: 56 / 255, green: 189 / 255, blue: 248 / 255
                        ).opacity(0.5),
                    radius: 8)
        }
    }
}
