import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct ProfileHeaderView: View {
    let user: FirebaseManager.FlipUser
    let userScore: Double
    let cyanBlueGlow: Color
    let cyanBlueAccent: Color
    let isCurrentUser: Bool
    let isFriend: Bool
    let hasSentFriendRequest: Bool
    @State private var streakStatus: StreakStatus = .none
    @Binding var showRemoveFriendAlert: Bool
    @Binding var showCancelRequestAlert: Bool
    @Binding var showAddFriendConfirmation: Bool

    // Helper function to get rank
    private func getRank(for score: Double) -> (name: String, color: Color) {
        switch score {
        case 0.0..<30.0: return ("Novice", Theme.periwinkle)  // Periwinkle
        case 30.0..<60.0: return ("Apprentice", Theme.lightBlue)  // Light blue
        case 60.0..<90.0: return ("Beginner", Theme.standardBlue)  // Blue
        case 90.0..<120.0: return ("Steady", Theme.emeraldGreen)  // Green
        case 120.0..<150.0: return ("Focused", Theme.brightAmber)  // Bright amber
        case 150.0..<180.0: return ("Disciplined", Theme.orange)  // Orange
        case 180.0..<210.0: return ("Resolute", Theme.mutedRed)  // Red
        case 210.0..<240.0: return ("Master", Theme.pink)  // Pink
        case 240.0..<270.0: return ("Guru", Theme.purple)  // Vivid purple
        case 270.0...300.0: return ("Enlightened", Theme.brightFuchsia)  // Bright fuchsia
        default: return ("Unranked", Color.gray)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 15) {
                // Profile Picture with Streak Indicator
                EnhancedProfileAvatarWithStreak(
                    imageURL: user.profileImageURL,
                    size: 80,
                    username: user.username,
                    streakStatus: streakStatus
                )

                VStack(alignment: .leading, spacing: 8) {
                    // Username with truncation handling
                    Text(user.username).font(.system(size: 28, weight: .black))
                        .foregroundColor(.white).shadow(color: cyanBlueGlow, radius: 8).lineLimit(1)
                        .truncationMode(.tail).frame(maxWidth: 180, alignment: .leading)

                    // Display rank name
                    let rank = getRank(for: userScore)
                    Text(rank.name).font(.system(size: 18, weight: .bold))
                        .foregroundColor(rank.color)
                        .shadow(color: rank.color.opacity(0.5), radius: 4)
                }

                Spacer()

                // Rank Circle
                RankCircle(score: userScore).frame(width: 60, height: 60)
            }

            // Display streak status if active - moved to its own row
            if streakStatus != .none {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill").font(.system(size: 16, weight: .bold))
                        .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                        .shadow(
                            color: streakStatus == .redFlame
                                ? Color.red.opacity(0.6) : Color.orange.opacity(0.6),
                            radius: 4
                        )

                    Text(streakStatus == .redFlame ? "BLAZING STREAK" : "ON FIRE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(streakStatus == .redFlame ? .red : .orange)
                        .shadow(
                            color: streakStatus == .redFlame
                                ? Color.red.opacity(0.4) : Color.orange.opacity(0.4),
                            radius: 2
                        )
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            streakStatus == .redFlame
                                ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    streakStatus == .redFlame
                                        ? Color.red.opacity(0.2) : Color.orange.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
            }

            // Only show friend action buttons if this is not the current user's profile
            if !isCurrentUser {
                HStack {
                    Spacer()
                    if isFriend {
                        // Remove friend button
                        Button(action: { showRemoveFriendAlert = true }) {
                            ZStack {
                                Circle().fill(Color.red.opacity(0.2)).frame(width: 44, height: 44)

                                Image(systemName: "person.fill.badge.minus").font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                        }
                    }
                    else if hasSentFriendRequest {
                        // Pending request indicator
                        Button(action: { showCancelRequestAlert = true }) {
                            ZStack {
                                Circle().fill(Color.orange.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "clock.fill").font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .shadow(color: Color.orange.opacity(0.3), radius: 4)
                        }
                    }
                    else {
                        // Add friend button
                        Button(action: { showAddFriendConfirmation = true }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cyanBlueAccent.opacity(0.7),
                                                cyanBlueAccent.opacity(0.4),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                Image(systemName: "person.fill.badge.plus").font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .overlay(Circle().stroke(Theme.silveryGradient, lineWidth: 1))
                            .shadow(color: cyanBlueGlow, radius: 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal).padding(.top, 20)
        .onAppear {
            // Load streak status on appear
            loadStreakStatus()
        }
    }

    // Function to load the user's streak status
    private func loadStreakStatus() {
        FirebaseManager.shared.db.collection("users").document(user.id).collection("streak")
            .document("current")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let statusString = data["streakStatus"] as? String,
                    let status = StreakStatus(rawValue: statusString)
                {

                    DispatchQueue.main.async { self.streakStatus = status }
                }
            }
    }
}
