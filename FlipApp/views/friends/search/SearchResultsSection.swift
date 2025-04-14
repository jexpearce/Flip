import SwiftUI

struct SearchResultsSection: View {
    @ObservedObject var viewModel: SearchManager
    let searchText: String
    let orangeAccent: Color
    @Binding var selectedUser: FirebaseManager.FlipUser?

    var body: some View {
        if viewModel.isSearching {
            // Enhanced loading state
            VStack(spacing: 16) {
                ProgressView().tint(orangeAccent).scaleEffect(1.5).frame(maxWidth: .infinity)
                    .padding(.top, 30)

                Text("Searching for users...").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 40)
        }
        else if viewModel.filteredSearchResults.isEmpty && !searchText.isEmpty {
            // No search results state
            NoUsersFoundView(
                message: "No users found matching '\(searchText)'",
                icon: "magnifyingglass"
            )
        }
        else {
            // Sort search results by mutual friends count
            let sortedResults = viewModel.filteredSearchResults.sorted { userA, userB in
                let mutualCountA = viewModel.mutualFriendCount(for: userA.id)
                let mutualCountB = viewModel.mutualFriendCount(for: userB.id)
                return mutualCountA > mutualCountB
            }

            // Search results with enhanced styling
            ForEach(sortedResults) { user in
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
    }
}
