import SwiftUI

struct FlipLogo: View {
    @State private var isButtonPressed = false
    
    var body: some View {
        HStack(spacing: 15) {
            HStack(spacing: 2) {
                Text("F")
                    .font(.system(size: 80, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                
                Text("l")
                    .font(.system(size: 80, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                
                // Upside-down "i"
                Text("i")
                    .font(.system(size: 80, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(180))
                
                Text("P")
                    .font(.system(size: 80, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
            }
            .shadow(color: Theme.yellow.opacity(0.5), radius: 10)
  
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 55, weight: .bold))
                .foregroundColor(Color.white.opacity(1.0))
                .shadow(color: .white, radius: 5)
                .overlay(
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 55))
                        .foregroundColor(.white.opacity(0.25))
                        .offset(x: 1, y: 1)
                )
                .rotationEffect(.degrees(isButtonPressed ? 360 : 0))
                .animation(
                    .spring(response: 2.0, dampingFraction: 0.6)
                        .repeatForever(autoreverses: false),
                    value: isButtonPressed
                )
        }
        .padding(.top, 20)
        .onAppear { isButtonPressed = true }
    }
}

struct CurrentBuildingIndicator: View {
    let buildingName: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT LOCATION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.yellow.opacity(0.9))
                
                Text(buildingName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 4) {
                    Text("CHANGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(Theme.yellow.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 60/255, green: 30/255, blue: 110/255).opacity(0.3),
                                Color(red: 40/255, green: 20/255, blue: 80/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4)
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
            withAnimation(.spring()) {
                isPulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
                isPulsing = false
            }
            
            if permissionManager.allPermissionsGranted {
                action()
            } else {
                permissionManager.showPermissionRequiredAlert = true
            }
        }) {
            Text("BEGIN")
                .font(.system(size: 26, weight: .black))
                .tracking(6)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    ZStack {
                        // Base gradient
                        RoundedRectangle(cornerRadius: 35)
                            .fill(
                                LinearGradient(
                                    colors: permissionManager.allPermissionsGranted ?
                                    [
                                        Theme.vibrantPurple,
                                        Theme.deepPurple
                                    ] :
                                    [
                                        Color.gray.opacity(0.5),
                                        Color.gray.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Glass effect
                        RoundedRectangle(cornerRadius: 35)
                            .fill(Color.white.opacity(0.1))
                        
                        // Glowing border
                        RoundedRectangle(cornerRadius: 35)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .shadow(
                    color: Theme.purpleShadow,
                    radius: isPulsing ? 15 : 8
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(permissionManager.allPermissionsGranted ? 1.0 : 0.6)
        }
        .padding(.horizontal, 30)
        .padding(.top, 10)
    }
}
