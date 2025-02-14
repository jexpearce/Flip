import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct SearchFriendsView: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var viewModel = SearchViewModel()
  @State private var searchText = ""

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Search bar
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(Theme.neonYellow)
            .font(.system(size: 20))

          TextField("Search by username", text: $searchText)
            .textFieldStyle(FlipTextFieldStyle())
            .autocapitalization(.none)
            .onChange(of: searchText) { query in
              viewModel.searchUsers(query: query)
            }
        }
        .padding()

        Divider()
          .background(Color.gray.opacity(0.3))

        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            if searchText.isEmpty {
              // Recommendations section
              if !viewModel.recommendations.isEmpty {
                Text("RECOMMENDED")
                  .font(.system(size: 14, weight: .heavy))
                  .tracking(2)
                  .foregroundColor(Theme.neonYellow)
                  .padding(.horizontal)
                  .padding(.top)

                ForEach(viewModel.recommendations) { user in
                  UserSearchCard(
                    user: user,
                    requestStatus: viewModel.requestStatus(for: user.id)
                  ) {
                    viewModel.sendFriendRequest(to: user.id)
                  }
                }
              }
            } else {
              if viewModel.isSearching {
                ProgressView()
                  .tint(Theme.neonYellow)
                  .frame(maxWidth: .infinity)
                  .padding(.top, 30)
              } else {
                ForEach(viewModel.searchResults) { user in
                  UserSearchCard(
                    user: user,
                    requestStatus: viewModel.requestStatus(for: user.id)
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
      .background(Color.black)
      .navigationTitle("Find Friends")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
            .foregroundColor(Theme.neonYellow)
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

        Text("\(user.totalSessions) sessions • \(user.totalFocusTime) min")
          .font(.system(size: 14))
          .foregroundColor(.gray)
      }

      Spacer()

      switch requestStatus {
      case .none:
        Button(action: onSendRequest) {
          Text("Add Friend")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Theme.neonYellow)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.neonYellow, lineWidth: 1)
            )
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
          .foregroundColor(Theme.neonYellow)
          .font(.system(size: 20))
      }
    }
    .padding()
    .background(Theme.darkGray)
    .cornerRadius(15)
    .padding(.horizontal)
  }
}

enum RequestStatus {
  case none
  case sent
  case friends
}
