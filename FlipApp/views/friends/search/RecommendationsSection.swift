//
//  RecommendationsSection.swift
//  Flip
//
//  Created by James Pearce on 4/14/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct RecommendationsSection: View {
    @ObservedObject var viewModel: SearchManager
    let orangeGlow: Color
    @Binding var selectedUser: FirebaseManager.FlipUser?

    // Gold color for mutual friends
    private let goldAccent = Theme.yellow
    private let orangeAccent = Theme.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Mutual Friends Section
            if !viewModel.usersWithMutuals.isEmpty {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill").foregroundColor(goldAccent)
                            .font(.system(size: 16))
                            .shadow(color: goldAccent.opacity(0.7), radius: 4)

                        Text("MUTUAL FRIENDS").font(.system(size: 16, weight: .black)).tracking(2)
                            .foregroundColor(.white)
                            .shadow(color: goldAccent.opacity(0.5), radius: 6)
                    }

                    Spacer()

                    Text("\(viewModel.usersWithMutuals.count) users").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                let sortedMutuals = viewModel.usersWithMutuals.sorted { userA, userB in
                    let mutualCountA = viewModel.mutualFriendCount(for: userA.id)
                    let mutualCountB = viewModel.mutualFriendCount(for: userB.id)
                    return mutualCountA > mutualCountB
                }

                // Users with mutual friends
                ForEach(sortedMutuals) { user in
                    EnhancedUserSearchCard(
                        user: user,
                        requestStatus: viewModel.requestStatus(for: user.id),
                        mutualCount: viewModel.mutualFriendCount(for: user.id),
                        onSendRequest: { viewModel.sendFriendRequest(to: user.id) },
                        onCancelRequest: { viewModel.promptCancelRequest(for: user) },
                        onViewProfile: { selectedUser = user }
                    )
                }
            }

            // Other Users Section
            if !viewModel.otherUsers.isEmpty {
                // Section header
                HStack {
                    Text("OTHER USERS").font(.system(size: 16, weight: .black)).tracking(2)
                        .foregroundColor(.white).shadow(color: orangeGlow, radius: 6)

                    Spacer()

                    Text("\(viewModel.otherUsers.count) users").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal).padding(.top, 10)

                // Users without mutual friends (limited unless "Show More" is tapped)
                ForEach(viewModel.otherUsersToShow) { user in
                    EnhancedUserSearchCard(
                        user: user,
                        requestStatus: viewModel.requestStatus(for: user.id),
                        mutualCount: 0,
                        onSendRequest: { viewModel.sendFriendRequest(to: user.id) },
                        onCancelRequest: { viewModel.promptCancelRequest(for: user) },
                        onViewProfile: { selectedUser = user }
                    )
                }

                // Show More button
                if viewModel.hasMoreOtherUsers {
                    Button(action: { withAnimation { viewModel.toggleShowMoreRecommendations() } })
                    {
                        HStack {
                            Text(viewModel.showMoreRecommendations ? "SHOW LESS" : "SHOW MORE")
                                .font(.system(size: 14, weight: .bold)).tracking(1)
                                .foregroundColor(.white)

                            Image(
                                systemName: viewModel.showMoreRecommendations
                                    ? "chevron.up" : "chevron.down"
                            )
                            .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2), Color.white.opacity(0.05),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.silveryGradient4, lineWidth: 1)
                            }
                        )
                        .shadow(color: orangeAccent.opacity(0.2), radius: 4)
                    }
                    .padding(.horizontal).padding(.top, 5)
                }
            }

            // If no recommendations at all
            if viewModel.usersWithMutuals.isEmpty && viewModel.otherUsers.isEmpty {
                NoUsersFoundView(message: "No users found to recommend", icon: "person.2.slash")
            }
        }
    }
}
