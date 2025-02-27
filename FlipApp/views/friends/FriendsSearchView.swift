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
                                    } onCancelRequest: {
                                        viewModel.promptCancelRequest(for: user)
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
                                    } onCancelRequest: {
                                        viewModel.promptCancelRequest(for: user)
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
            .overlay(
                Group {
                    if viewModel.showCancelRequestAlert, let user = viewModel.userToCancelRequest {
                        CancelFriendRequestAlert(
                            isPresented: $viewModel.showCancelRequestAlert,
                            username: user.username
                        ) {
                            viewModel.cancelFriendRequest(to: user.id)
                        }
                    }
                }
            )
        }
        .background(Theme.mainGradient.edgesIgnoringSafeArea(.all))
    }
}


struct UserSearchCard: View {
    let user: FirebaseManager.FlipUser
    let requestStatus: RequestStatus
    let onSendRequest: () -> Void
    let onCancelRequest: () -> Void
    @State private var isAddPressed = false
    @State private var isCancelPressed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(user.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                
                Text(
                    "\(user.totalSessions) sessions • \(user.totalFocusTime) min"
                )
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            switch requestStatus {
            case .none:
                Button(action: {
                    withAnimation(.spring()) {
                        isAddPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onSendRequest()
                        isAddPressed = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14))
                        Text("Add Friend")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Theme.buttonGradient)
                                .opacity(0.8)
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 8)
                    .scaleEffect(isAddPressed ? 0.95 : 1.0)
                }
            case .sent:
                Button(action: {
                    withAnimation(.spring()) {
                        isCancelPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onCancelRequest()
                        isCancelPressed = false
                    }
                }) {
                    Text("Request Sent")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.3))
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                }
            case .friends:
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    
                    Text("Friends")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 34/255, green: 197/255, blue: 94/255),
                                        Color(red: 22/255, green: 163/255, blue: 74/255)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(0.5)
                        
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                )
                .shadow(color: Color.green.opacity(0.3), radius: 6)
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Theme.buttonGradient)
                    .opacity(0.1)
                
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
enum RequestStatus {
    case none
    case sent
    case friends
}
