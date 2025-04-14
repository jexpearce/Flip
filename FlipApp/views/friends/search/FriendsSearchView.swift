import SwiftUI

// MARK: - FriendsSearchView
struct FriendsSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchManager()
    @State private var searchText = ""
    @State private var selectedUser: FirebaseManager.FlipUser?

    private let orangeAccent = Theme.orange  // Warm Orange
    private let orangeGlow = Theme.orange.opacity(0.5)
    private let purpleAccent = Theme.purple  // Vibrant Purple

    var body: some View {
        ZStack {
            // Main background with decorative elements
            Theme.orangePurpleGradient.edgesIgnoringSafeArea(.all)

            // Decorative elements
            BackgroundDecorationView(orangeAccent: orangeAccent, purpleAccent: purpleAccent)

            // Main content view
            FriendsSearchContentView(
                viewModel: viewModel,
                searchText: $searchText,
                orangeAccent: orangeAccent,
                orangeGlow: orangeGlow,
                orangePurpleGradient: Theme.orangePurpleGradient,
                selectedUser: $selectedUser,
                dismiss: dismiss
            )
        }
    }
}
