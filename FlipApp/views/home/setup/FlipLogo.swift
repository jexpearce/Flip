import SwiftUI

struct FlipLogo: View {
    @State private var isButtonPressed = false

    var body: some View {
        HStack(spacing: 15) {
            HStack(spacing: 2) {
                Text("F").font(.system(size: 80, weight: .black)).tracking(2)
                    .foregroundColor(.white)

                Text("l").font(.system(size: 80, weight: .black)).tracking(2)
                    .foregroundColor(.white)

                // Upside-down "i"
                Text("i").font(.system(size: 80, weight: .black)).tracking(2)
                    .foregroundColor(.white).rotationEffect(.degrees(180))

                Text("P").font(.system(size: 80, weight: .black)).tracking(2)
                    .foregroundColor(.white)
            }
            .shadow(color: Theme.yellow.opacity(0.5), radius: 10)

            Image(systemName: "arrow.2.squarepath").font(.system(size: 55, weight: .bold))
                .foregroundColor(Color.white.opacity(1.0)).shadow(color: .white, radius: 5)
                .overlay(
                    Image(systemName: "arrow.2.squarepath").font(.system(size: 55))
                        .foregroundColor(.white.opacity(0.25)).offset(x: 1, y: 1)
                )
                .rotationEffect(.degrees(isButtonPressed ? 360 : 0))
                .animation(
                    .spring(response: 2.0, dampingFraction: 0.6).repeatForever(autoreverses: false),
                    value: isButtonPressed
                )
        }
        .padding(.top, 0)  // Reduced from 20 to 5
        .onAppear { isButtonPressed = true }
    }
}

struct BeginButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var isPulsing = false
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        Button(action: {
            isPressed = true
            withAnimation(.spring()) { isPulsing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
                isPulsing = false
            }

            // Only block the action if motion permission isn't granted
            if permissionManager.motionPermissionGranted {
                action()
            }
            else {
                permissionManager.showPermissionRequiredAlert = true
            }
        }) {
            Text("BEGIN").font(.system(size: 26, weight: .black)).tracking(6)
                .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 70)
                .background(
                    ZStack {
                        // Change gradient based on permission level
                        RoundedRectangle(cornerRadius: 35)
                            .fill(
                                LinearGradient(
                                    colors: !permissionManager.motionPermissionGranted
                                        ?  // No motion permission - grayed out (highest priority)
                                        [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
                                        : permissionManager.locationAuthStatus == .denied
                                            ?  // Location denied - orange/yellow gradient
                                            [
                                                Theme.yellow,  // Vibrant yellow
                                                Theme.orange,  // Warm orange
                                            ]
                                            :  // Location allowed - blue gradient
                                            [Theme.lightTealBlue, Theme.darkTealBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Glass effect
                        RoundedRectangle(cornerRadius: 35).fill(Color.white.opacity(0.1))

                        // Border
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(Theme.silveryGradient, lineWidth: 1.5)
                    }
                )
                .shadow(
                    color: !permissionManager.motionPermissionGranted
                        ? Color.gray.opacity(0.5)
                        : permissionManager.locationAuthStatus == .denied
                            ? Theme.yellowShadow : Theme.lightTealBlue.opacity(0.5),
                    radius: isPulsing ? 15 : 8
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(permissionManager.motionPermissionGranted ? 1.0 : 0.6)
        }
        .padding(.horizontal, 30).disabled(!permissionManager.motionPermissionGranted)
    }
}
