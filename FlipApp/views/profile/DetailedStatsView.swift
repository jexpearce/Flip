import FirebaseAuth
import Foundation
import SwiftUI

struct DetailedStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var sessionManager: SessionManager
    @State private var animateStats = false
    @State private var userData: FirebaseManager.FlipUser?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 26 / 255, green: 14 / 255, blue: 47 / 255),
                    Color(red: 16 / 255, green: 24 / 255, blue: 57 / 255),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()

                    VStack(spacing: 4) {
                        Text("YOUR STATS")
                            .font(.system(size: 24, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(
                                color: Theme.lightTealBlue.opacity(0.5), radius: 8)

                        Text("スタッツ")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 40)

                // Main stats display - using Firestore data when available
                VStack(spacing: 30) {
                    // Total Focus Time
                    DetailedStatCard(
                        title: "TOTAL FOCUS TIME",
                        value:
                            "\(userData?.totalFocusTime ?? sessionManager.totalFocusTime)",
                        unit: "minutes",
                        icon: "clock.fill",
                        color: Color(
                            red: 59 / 255, green: 130 / 255, blue: 246 / 255),
                        delay: 0
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)

                    // Total Sessions
                    DetailedStatCard(
                        title: "TOTAL SESSIONS",
                        value:
                            "\(userData?.totalSessions ?? sessionManager.totalSuccessfulSessions)",
                        unit: "completed",
                        icon: "checkmark.circle.fill",
                        color: Color(
                            red: 16 / 255, green: 185 / 255, blue: 129 / 255),
                        delay: 0.1
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)

                    // Average Session Length - calculate if we have data
                    let avgSession =
                        userData != nil && userData!.totalSessions > 0
                        ? userData!.totalFocusTime / userData!.totalSessions
                        : sessionManager.averageSessionLength

                    DetailedStatCard(
                        title: "AVERAGE SESSION LENGTH",
                        value: "\(avgSession)",
                        unit: "minutes",
                        icon: "chart.bar.fill",
                        color: Color(
                            red: 245 / 255, green: 158 / 255, blue: 11 / 255),
                        delay: 0.2
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)

                    // Longest Session
                    DetailedStatCard(
                        title: "LONGEST SESSION",
                        value:
                            "\(userData?.longestSession ?? sessionManager.longestSession)",
                        unit: "minutes",
                        icon: "crown.fill",
                        color: Color(
                            red: 236 / 255, green: 72 / 255, blue: 153 / 255),
                        delay: 0.3
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Back to profile button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK TO PROFILE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Theme.buttonGradient)

                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 15)
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
                            color: Theme.lightTealBlue.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .opacity(animateStats ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateStats)
            }
        }
        .onAppear {
            // Load Firestore data
            loadUserData()

            // Animation timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateStats = true
                }
            }
        }
    }

    // Function to load data from Firestore
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { document, error in
                if let user = try? document?.data(
                    as: FirebaseManager.FlipUser.self)
                {
                    DispatchQueue.main.async {
                        self.userData = user
                    }
                }
            }
    }
}
struct DetailedStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let delay: Double

    @State private var animate = false

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            .scaleEffect(animate ? 1 : 0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 6)

                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(animate ? 1 : 0)
                .offset(x: animate ? 0 : -20)
            }

            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animate = true
                }
            }
        }
    }
}
