import SwiftUI

struct PausedView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showingCancelAlert = false

    var body: some View {
        VStack(spacing: 30) {
            // Pause Icon
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .retroGlow()

            // Title with Japanese
            VStack(spacing: 4) {
                Text("SESSION PAUSED")
                    .font(.system(size: 28, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)
                    .retroGlow()

                Text("一時停止中")
                    .font(.system(size: 14))
                    .tracking(4)
                    .foregroundColor(.gray)
            }

            // Time Display
            Text(formatTime(seconds: appManager.pausedRemainingSeconds))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .retroGlow()

            Text("\(appManager.pausedRemainingFlips) retries left")
                .font(.title3)
                .foregroundColor(.white)
                .retroGlow()

            // Resume Button
            Button(action: {
                appManager.resumeSession()
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("RESUME")
                }
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.black)
                .frame(width: 200, height: 50)
                .background(
                    Color.white
                        .shadow(color: .white.opacity(0.5), radius: 10)
                )
                .cornerRadius(25)
            }

            // Cancel Button
            Button(action: {
                showingCancelAlert = true
            }) {
                Text("CANCEL SESSION")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(2)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(
                                Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .retroGlow()
            }
        }
        .padding()
        .background(Theme.mainGradient)
        .alert("Cancel Session?", isPresented: $showingCancelAlert) {
            Button("Cancel Session", role: .destructive) {
                appManager.failSession()
            }
            Button("Keep Session", role: .cancel) {}
        } message: {
            Text("This session will be marked as failed. Are you sure?")
        }
    }

    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
