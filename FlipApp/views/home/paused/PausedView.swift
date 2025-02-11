import SwiftUI

struct PausedView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var showingCancelAlert = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.neonYellow)

            VStack(spacing: 15) {
                Text("Session Paused")
                    .font(.title)
                    .foregroundColor(.white)

                Text(formatTime(seconds: appManager.pausedRemainingSeconds))
                    .font(.system(size: 40, design: .monospaced))
                    .foregroundColor(Theme.neonYellow)

                Text("\(appManager.pausedRemainingFlips) retries left")
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Button(action: {
                appManager.resumeSession()
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Resume")
                }
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.black)
                .frame(width: 200, height: 50)
                .background(Theme.neonYellow)
                .cornerRadius(25)
            }
            
            Button(action: {
                showingCancelAlert = true
            }) {
                Text("Cancel Session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 200, height: 44)
                    .background(Color(white: 0.2))
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
        }
        .padding()
        .background(Theme.mainGradient)
        .alert("Cancel Session?", isPresented: $showingCancelAlert) {
            Button("Cancel Session", role: .destructive) {
                appManager.failSession()
            }
            Button("Keep Session", role: .cancel) { }
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