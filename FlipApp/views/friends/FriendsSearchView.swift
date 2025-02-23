import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct FriendsSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchManager()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .retroGlow()

                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(FlipTextFieldStyle())
                        .autocapitalization(.none)
                        .onChange(of: searchText) {
                            viewModel.searchUsers(query: searchText)
                        }
                }
                .padding()

                Divider()
                    .background(Color.white.opacity(0.1))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if searchText.isEmpty {
                            // Recommendations section
                            if !viewModel.recommendations.isEmpty {
                                Text("RECOMMENDED")
                                    .font(.system(size: 14, weight: .heavy))
                                    .tracking(5)
                                    .foregroundColor(.white)
                                    .retroGlow()
                                    .padding(.horizontal)
                                    .padding(.top)

                                ForEach(viewModel.recommendations) { user in
                                    UserSearchCard(
                                        user: user,
                                        requestStatus: viewModel.requestStatus(
                                            for: user.id)
                                    ) {
                                        viewModel.sendFriendRequest(to: user.id)
                                    }
                                }
                            }
                        } else {
                            if viewModel.isSearching {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 30)
                            } else {
                                ForEach(viewModel.searchResults) { user in
                                    UserSearchCard(
                                        user: user,
                                        requestStatus: viewModel.requestStatus(
                                            for: user.id)
                                    ) {
                                        viewModel.sendFriendRequest(to: user.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("FIND FRIENDS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .retroGlow()
                }
            }
        }
    }
}

struct UserSearchCard: View {
    let user: FirebaseManager.FlipUser
    let requestStatus: RequestStatus
    let onSendRequest: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(user.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .retroGlow()

                Text(
                    "\(user.totalSessions) sessions • \(user.totalFocusTime) min"
                )
                .font(.system(size: 14))
                .foregroundColor(.gray)
            }

            Spacer()

            switch requestStatus {
            case .none:
                Button(action: onSendRequest) {
                    Text("Add Friend")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .retroGlow()
                }
            case .sent:
                Text("Request Sent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            case .friends:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .retroGlow()
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .background(Theme.darkGray)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
enum RequestStatus {
    case none
    case sent
    case friends
}
