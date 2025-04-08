import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Background gradient
            Theme.darkPurpleGradient.edgesIgnoringSafeArea(.all)

            VStack {
                // Header with dismiss button
                HStack {
                    Text("Privacy Policy").font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal).padding(.top, 20)

                // Policy content in a scroll view
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        policySection(
                            emoji: "1️⃣",
                            title: "How Flip Uses Your Data",
                            content:
                                "Flip uses motion tracking and location data to enhance your productivity experience. We do not store motion tracking data, and we never sell your data to third parties. Flip uses Firebase for authentication. Firebase does not sell your data, only processes it to improve app performance. Users can request their data be deleted by emailing jex@jajajeev.com. Requests will be processed within 10 days."
                        )

                        policySection(
                            emoji: "2️⃣",
                            title: "Motion Tracking (Required)",
                            content:
                                "• Tracks motion periodically to ensure your phone remains flipped over during productivity sessions.\n• Optimized for battery efficiency (runs only when needed).\n• Only active during productivity sessions and once upon installation (to request motion permissions)."
                        )

                        policySection(
                            emoji: "3️⃣",
                            title: "Location Tracking (Optional)",
                            content:
                                "Location tracking is not required to use Flip, but enabling it enhances core features, allowing sessions to run while your screen is off, and primarily allowing additional features:\n✅ Regional & Building-Specific Leaderboards – Compete with others in the same location (e.g., libraries, cafés).\n✅ FlipMaps – See friends' live Flip sessions and their last 3 historical sessions.\nWithout location tracking, Flip works normally, but you won't have access to leaderboards or FlipMaps. Location is sparingly triggered, putting battery health as the first priority."
                        )

                        policySection(
                            emoji: "4️⃣",
                            title: "FlipMaps & Data Storage",
                            content:
                                "FlipMaps only displays your last 3 sessions and your current live session.\nData is automatically removed after 7 days (resets every Monday at 3 AM).\nYour current location is NOT shared unless you are in an active Flip session.\n\nVisibility Settings:\n🔹 No One – Completely disables historical session visibility.\n🔹 Friends Only (default) – Only your friends can see your last 3 session locations.\n🔹 Everyone – Your last 3 session locations are visible to all users."
                        )

                        policySection(
                            emoji: "5️⃣",
                            title: "Leaderboards & Privacy Controls",
                            content:
                                "Building-Specific Leaderboards – Tracks weekly session counts for individual buildings.\nRegional & Global Leaderboards – Compete based on total weekly session time. The Regional specific leaderboard contains your entire total weekly time, not the sessions you have only done in that area. It moves you to the new regional leaderboard only when you have done your first session there. Global Leaderboards do not use location. \nAnonymity & Opt-Out – Users can remain anonymous or disable leaderboard visibility entirely.\n\n🏆 Leaderboard Resets:\nWeekly Leaderboards reset every Monday at 3 AM.\nAll-Time"
                        )

                        VStack(alignment: .leading, spacing: 15) {
                            Text("🔒 Your Privacy, Your Choice")
                                .font(.system(size: 18, weight: .bold)).foregroundColor(.white)

                            Text(
                                "Flip is designed with privacy-first principles. You are in complete control of your data, and you can disable location tracking, anonymize your profile, or opt out of leaderboards at any time."
                            )
                            .font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)

                            Text("For any questions, contact jex@jajajeev.com")
                                .font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                                .padding(.top, 5)

                            Text("Last Updated: March 22, 2025")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7)).padding(.top, 10)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal).padding(.bottom, 30)
                }
            }
            .padding(.top, 10)
        }
    }

    private func policySection(emoji: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(emoji).font(.system(size: 24))

                Text(title).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
            }

            Text(content).font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
