import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct FriendsSearchContentView: View {
    @ObservedObject var viewModel: SearchManager
    @Binding var searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    let orangePurpleGradient: LinearGradient
    @Binding var selectedUser: FirebaseManager.FlipUser?
    var dismiss: DismissAction

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced search bar
                SearchBarView(
                    searchText: $searchText,
                    orangeAccent: orangeAccent,
                    orangeGlow: orangeGlow,
                    onSearchTextChanged: { newText in viewModel.searchUsers(query: newText) }
                )

                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)

                // Main scrollable content
                ScrollableContentView(
                    viewModel: viewModel,
                    searchText: searchText,
                    orangeAccent: orangeAccent,
                    orangeGlow: orangeGlow,
                    selectedUser: $selectedUser
                )
            }
            .background(orangePurpleGradient.edgesIgnoringSafeArea(.all))
            .navigationTitle("FIND FRIENDS").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                        .shadow(color: orangeGlow, radius: 4)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .overlay(
                Group {
                    if viewModel.showCancelRequestAlert, let user = viewModel.userToCancelRequest {
                        CancelFriendRequestAlert(
                            isPresented: $viewModel.showCancelRequestAlert,
                            username: user.username
                        ) { viewModel.cancelFriendRequest(to: user.id) }
                    }
                }
            )
            .background(
                NavigationLink(
                    destination: selectedUser.map { UserProfileLoader(userId: $0.id) },
                    isActive: Binding(
                        get: { selectedUser != nil },
                        set: { if !$0 { selectedUser = nil } }
                    )
                ) { EmptyView() }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
