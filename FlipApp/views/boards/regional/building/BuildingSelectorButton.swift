import SwiftUI

struct BuildingSelectorButton: View {
    let buildingName: String?
    let action: () -> Void
    let refreshAction: () -> Void
    @Binding var isRefreshing: Bool
    @State private var isPulsing = false
    @State private var hasAppeared = false

    // Check if this is the first time showing the button
    private var shouldPulse: Bool { !hasAppeared && (buildingName == nil || !hasAppeared) }

    var body: some View {
        HStack {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BUILDING").font(.system(size: 12, weight: .bold)).tracking(2)
                        .foregroundColor(.white.opacity(0.7))

                    Text(buildingName ?? "Tap to select building")
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                .padding(.horizontal, 16)
            }

            // Refresh button
            Button(action: refreshAction) {
                ZStack {
                    if isRefreshing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    else {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))

                            Text("REFRESH").font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .frame(width: 60).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
            }
            .disabled(isRefreshing)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(isPulsing ? 0.6 : 0.2),
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

                // Turn off pulsing after the user has seen it
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation {
                        isPulsing = false
                        hasAppeared = true
                    }
                }
            }
        }
    }
}
