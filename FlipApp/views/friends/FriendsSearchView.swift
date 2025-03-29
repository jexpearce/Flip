import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

// MARK: - FriendsSearchView
struct FriendsSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchManager()
    @State private var searchText = ""
    @State private var showUserProfile = false
    @State private var selectedUser: FirebaseManager.FlipUser?

    // Orange-purple theme colors for friend-related views
    private let orangePurpleGradient = LinearGradient(
        colors: [
            Theme.mutedPurple,  // Deep purple
            Color(red: 47 / 255, green: 17 / 255, blue: 67 / 255),  // Medium purple
            Color(red: 65 / 255, green: 20 / 255, blue: 60 / 255),  // Purple with hint of red
            Color(red: 35 / 255, green: 15 / 255, blue: 50 / 255),  // Back to deeper purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let orangeAccent = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)  // Warm Orange
    private let orangeGlow = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255).opacity(0.5)
    private let purpleAccent = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)  // Vibrant Purple

    var body: some View {
        ZStack {
            // Main background with decorative elements
            orangePurpleGradient.edgesIgnoringSafeArea(.all)

            // Decorative elements
            BackgroundDecorationView(orangeAccent: orangeAccent, purpleAccent: purpleAccent)

            // Main content view
            FriendsSearchContentView(
                viewModel: viewModel,
                searchText: $searchText,
                orangeAccent: orangeAccent,
                orangeGlow: orangeGlow,
                orangePurpleGradient: orangePurpleGradient,
                selectedUser: $selectedUser,
                showUserProfile: $showUserProfile,
                dismiss: dismiss
            )
        }
        .fullScreenCover(isPresented: $showUserProfile) {
            if let user = selectedUser {
                NavigationView {
                    UserProfileLoader(userId: user.id)
                        .navigationBarItems(leading: Button("Back") { showUserProfile = false })
                }
            }
        }
    }
}

// MARK: - Background Decoration View
struct BackgroundDecorationView: View {
    let orangeAccent: Color
    let purpleAccent: Color

    var body: some View {
        ZStack {
            // Top decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            orangeAccent.opacity(0.2), orangeAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300).offset(x: 150, y: -150).blur(radius: 50)
                .edgesIgnoringSafeArea(.all)

            // Bottom decorative element
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            purpleAccent.opacity(0.2), purpleAccent.opacity(0.05),
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 250, height: 250).offset(x: -120, y: 350).blur(radius: 40)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Main Content View
struct FriendsSearchContentView: View {
    @ObservedObject var viewModel: SearchManager
    @Binding var searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    let orangePurpleGradient: LinearGradient
    @Binding var selectedUser: FirebaseManager.FlipUser?
    @Binding var showUserProfile: Bool
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
                    onViewProfile: { user in
                        selectedUser = user
                        showUserProfile = true
                    }
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
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    var onSearchTextChanged: (String) -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(orangeAccent)
                .font(.system(size: 20)).shadow(color: orangeGlow, radius: 4).padding(.leading, 6)

            TextField("Search by username", text: $searchText).font(.system(size: 16))
                .foregroundColor(.white).accentColor(orangeAccent).padding(.vertical, 12)
                .onChange(of: searchText) { onSearchTextChanged(searchText) }
                .autocapitalization(.none).disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal).padding(.top, 16).padding(.bottom, 12)
    }
}

// MARK: - Scrollable Content View
struct ScrollableContentView: View {
    @ObservedObject var viewModel: SearchManager
    let searchText: String
    let orangeAccent: Color
    let orangeGlow: Color
    var onViewProfile: (FirebaseManager.FlipUser) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if searchText.isEmpty {
                    // Recommendations section with mutual friends first
                    RecommendationsSection(
                        viewModel: viewModel,
                        orangeGlow: orangeGlow,
                        onViewProfile: onViewProfile
                    )
                }
                else {
                    // Search results
                    SearchResultsSection(
                        viewModel: viewModel,
                        searchText: searchText,
                        orangeAccent: orangeAccent,
                        onViewProfile: onViewProfile
                    )
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Search Results Section
struct SearchResultsSection: View {
    @ObservedObject var viewModel: SearchManager
    let searchText: String
    let orangeAccent: Color
    var onViewProfile: (FirebaseManager.FlipUser) -> Void

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
                    onViewProfile: { onViewProfile(user) }
                )
            }
        }
    }
}

// MARK: - Recommendations Section
struct RecommendationsSection: View {
    @ObservedObject var viewModel: SearchManager
    let orangeGlow: Color
    var onViewProfile: (FirebaseManager.FlipUser) -> Void

    // Gold color for mutual friends
    private let goldAccent = Theme.yellow
    private let orangeAccent = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)

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
                        onViewProfile: { onViewProfile(user) }
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
                        onViewProfile: { onViewProfile(user) }
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
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4), Color.white.opacity(0.1),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
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

// MARK: - No Users Found View
struct NoUsersFoundView: View {
    let message: String
    let icon: String

    private let orangeAccent = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 50))
                .foregroundColor(orangeAccent.opacity(0.6)).padding(.top, 30)

            Text(message).font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

// MARK: - Cancel Friend Request Alert
struct CancelFriendRequestAlert: View {
    @Binding var isPresented: Bool
    let username: String
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Cancel Request").font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Cancel friend request to \(username)?").font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9)).multilineTextAlignment(.center)

                HStack(spacing: 15) {
                    Button("No") { isPresented = false }.foregroundColor(.white)
                        .padding(.vertical, 10).padding(.horizontal, 25)
                        .background(Color.gray.opacity(0.3)).cornerRadius(10)

                    Button("Yes") {
                        onConfirm()
                        isPresented = false
                    }
                    .foregroundColor(.white).padding(.vertical, 10).padding(.horizontal, 25)
                    .background(Color.red.opacity(0.7)).cornerRadius(10)
                }
            }
            .padding(25).background(Color(red: 30 / 255, green: 30 / 255, blue: 46 / 255))
            .cornerRadius(15).shadow(radius: 10).padding(30)
        }
    }
}

// Keep these original enum and structs unchanged
enum RequestStatus {
    case none
    case sent
    case friends
}

// Enhanced user search card component with profile navigation
struct EnhancedUserSearchCard: View {
    let user: FirebaseManager.FlipUser
    let requestStatus: RequestStatus
    let mutualCount: Int  // New parameter for mutual friends count
    let onSendRequest: () -> Void
    let onCancelRequest: () -> Void
    let onViewProfile: () -> Void

    @State private var isAddPressed = false
    @State private var isCancelPressed = false
    @State private var isCardPressed = false

    private let orangeAccent = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)
    private let orangeGlow = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255).opacity(0.5)
    private let purpleAccent = Color(red: 147 / 255, green: 51 / 255, blue: 234 / 255)
    private let goldAccent = Theme.yellow  // Gold color for mutual friends

    var body: some View {
        Button(action: {
            // Only navigate to profile on card tap, not button taps
            withAnimation(.spring()) { isCardPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isCardPressed = false
                onViewProfile()
            }
        }) {
            HStack {
                // User profile picture with enhanced styling
                ProfileAvatarView(imageURL: user.profileImageURL, size: 56, username: user.username)
                    .shadow(color: orangeGlow, radius: 6)

                // User info with enhanced styling
                VStack(alignment: .leading, spacing: 5) {
                    // Username with mutual badge
                    HStack(spacing: 8) {
                        Text(user.username).font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white).lineLimit(1)
                            .frame(maxWidth: 150, alignment: .leading)
                            .shadow(color: orangeGlow, radius: 6)

                        // Show mutual friends badge if any - Simple version
                        if mutualCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "person.2.fill").font(.system(size: 10))
                                    .foregroundColor(goldAccent)

                                Text("\(mutualCount)").font(.system(size: 11, weight: .bold))
                                    .foregroundColor(goldAccent)
                            }
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8).fill(goldAccent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(goldAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    HStack(spacing: 12) {
                        Label("\(user.totalSessions) sessions", systemImage: "timer")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

                        Label("\(user.totalFocusTime) min", systemImage: "clock")
                            .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))

                    }
                }
                .padding(.leading, 4)

                Spacer()

                // Action buttons with enhanced styling
                Group {
                    switch requestStatus {
                    case .none:
                        Button(action: {
                            withAnimation(.spring()) { isAddPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onSendRequest()
                                isAddPressed = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus").font(.system(size: 14))
                                Text("Add Friend").font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white).padding(.horizontal, 15).padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    orangeAccent.opacity(0.8),
                                                    purpleAccent.opacity(0.6),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: orangeGlow, radius: 4)
                            .scaleEffect(isAddPressed ? 0.95 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())

                    case .sent:
                        Button(action: {
                            withAnimation(.spring()) { isCancelPressed = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onCancelRequest()
                                isCancelPressed = false
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill").font(.system(size: 12))

                                Text("Request Sent").font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8)).padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.3))

                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .scaleEffect(isCancelPressed ? 0.95 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())

                    case .friends:
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.green)
                                .font(.system(size: 16))

                            Text("Friends").font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 15).padding(.vertical, 10)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Theme.mutedGreen.opacity(0.3),
                                                Theme.darkerGreen.opacity(0.2),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 4)
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    // Give mutual friends cards a subtle gold highlight
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    mutualCount > 0
                                        ? goldAccent.opacity(0.05) : Color.white.opacity(0.1),
                                    Color.white.opacity(0.05),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    mutualCount > 0
                                        ? goldAccent.opacity(0.3) : Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: mutualCount > 0 ? goldAccent.opacity(0.1) : Color.black.opacity(0.2),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isCardPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCardPressed)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
