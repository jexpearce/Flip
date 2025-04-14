import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct ScrollableContentView: View {
    @ObservedObject var viewModel: SearchManager
    let searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    @Binding var selectedUser: FirebaseManager.FlipUser?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if searchText.isEmpty {
                    // Recommendations section with mutual friends first
                    RecommendationsSection(
                        viewModel: viewModel,
                        orangeGlow: orangeGlow,
                        selectedUser: $selectedUser
                    )
                }
                else {
                    // Search results
                    SearchResultsSection(
                        viewModel: viewModel,
                        searchText: searchText,
                        orangeAccent: orangeAccent,
                        selectedUser: $selectedUser
                    )
                }
            }
            .padding(.vertical)
        }
    }
}
