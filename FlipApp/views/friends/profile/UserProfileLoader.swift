import SwiftUI

struct UserProfileLoader: View {
    let userId: String
    @State private var isLoading = true
    @State private var loadedUser: FirebaseManager.FlipUser?

    // Match the app's theme
    private let cyanBlueAccent = Theme.lightTealBlue
    private let cyanBlueGlow = Theme.lightTealBlue.opacity(0.5)

    var body: some View {
        ZStack {
            // Background gradient to prevent black screen
            Theme.profileGradient.edgesIgnoringSafeArea(.all)

            if isLoading || loadedUser == nil {
                // Loading indicator - styled to match the app
                VStack(spacing: 20) {
                    ZStack {
                        Circle().stroke(cyanBlueAccent.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)

                        Circle().trim(from: 0, to: 0.7).stroke(cyanBlueAccent, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1).repeatForever(autoreverses: false),
                                value: isLoading
                            )
                    }

                    Text("Loading profile...").font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white).shadow(color: cyanBlueGlow, radius: 6)
                }
            }
            else if let user = loadedUser {
                // Show the actual profile with fully loaded data
                UserProfileView(user: user).transition(.opacity)
            }
        }
        .onAppear { loadUserData() }
    }

    private func loadUserData() {
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.loadedUser = userData
                            self.isLoading = false
                        }
                    }
                }
                else {
                    print("Error loading user profile for ID: \(userId)")
                    DispatchQueue.main.async {
                        // Keep loading state visible to prevent black screen
                        self.isLoading = false
                    }
                }
            }
    }
}
