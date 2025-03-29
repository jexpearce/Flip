import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

struct RegionalLeaderboard: View {
    @ObservedObject var viewModel: RegionalLeaderboardViewModel
    @State private var selectedUserId: String?
    @State private var showUserProfile = false

    // Silver-red theme colors
    private let silverRedGradient = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),  // Light silver
            Color(red: 185 / 255, green: 28 / 255, blue: 28 / 255),  // Deep red
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverRedBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 153 / 255, green: 27 / 255, blue: 27 / 255).opacity(0.4),
            Color(red: 127 / 255, green: 29 / 255, blue: 29 / 255).opacity(0.3),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Medal colors
    private let goldColor = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 215 / 255, blue: 0 / 255),
            Color(red: 212 / 255, green: 175 / 255, blue: 55 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let silverColor = LinearGradient(
        colors: [
            Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255),
            Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bronzeColor = LinearGradient(
        colors: [
            Color(red: 205 / 255, green: 127 / 255, blue: 50 / 255),
            Color(red: 165 / 255, green: 113 / 255, blue: 78 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 12) {
            // Title section with enhanced visual style
            VStack(spacing: 4) {
                // Main title with icon
                HStack {
                    Image(
                        systemName: viewModel.isBuildingSpecific
                            ? "building.2.fill" : "map.fill"
                    )
                    .font(.system(size: 20))
                    .foregroundStyle(
                        viewModel.isBuildingSpecific
                            ? LinearGradient(
                                colors: [
                                    Theme.yellowyOrange,
                                    Color(
                                        red: 202 / 255, green: 138 / 255,
                                        blue: 4 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Theme.mutedRed,
                                    Color(
                                        red: 185 / 255, green: 28 / 255,
                                        blue: 28 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .shadow(
                        color: viewModel.isBuildingSpecific
                            ? Theme.yellowyOrange.opacity(0.5)
                            : Theme.mutedRed.opacity(0.5), radius: 4)

                    Text(
                        viewModel.isBuildingSpecific
                            ? "MOST SESSIONS OF THE WEEK"
                            : "REGIONAL LEADERBOARD"
                    )
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundStyle(
                        viewModel.isBuildingSpecific
                            ? LinearGradient(
                                colors: [
                                    Theme.yellowyOrange,
                                    Color(
                                        red: 202 / 255, green: 138 / 255,
                                        blue: 4 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Theme.mutedRed,
                                    Color(
                                        red: 185 / 255, green: 28 / 255,
                                        blue: 28 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .shadow(
                        color: viewModel.isBuildingSpecific
                            ? Theme.yellowyOrange.opacity(0.5)
                            : Theme.mutedRed.opacity(0.5), radius: 4
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // Subtitle with location name
                if let locationName = viewModel.locationName {
                    Text("in \(locationName)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        viewModel.isBuildingSpecific
                            ? LinearGradient(
                                colors: [
                                    Theme.yellowyOrange.opacity(0.3),
                                    Color(
                                        red: 202 / 255, green: 138 / 255,
                                        blue: 4 / 255
                                    ).opacity(0.2),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [
                                    Theme.mutedRed.opacity(0.3),
                                    Color(
                                        red: 185 / 255, green: 28 / 255,
                                        blue: 28 / 255
                                    ).opacity(0.2),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
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
                    )
            )

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                        .padding(.vertical, 25)
                    Spacer()
                }
            } else if viewModel.leaderboardEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(
                        systemName: viewModel.isBuildingSpecific
                            ? "building.2.crop.circle" : "mappin.circle"
                    )
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 5)

                    Text(
                        viewModel.isBuildingSpecific
                            ? "No sessions in this building yet"
                            : "No active users in your area this week"
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                    Text("Complete a session to be the first!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Column headers for clarity
                HStack {
                    Text("RANK")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            viewModel.isBuildingSpecific
                                ? Theme.yellowyOrange.opacity(0.9)
                                : Theme.mutedRed.opacity(0.9)
                        )
                        .frame(width: 50, alignment: .center)

                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            viewModel.isBuildingSpecific
                                ? Theme.yellowyOrange.opacity(0.9)
                                : Theme.mutedRed.opacity(0.9)
                        )
                        .frame(alignment: .leading)

                    Spacer()

                    Text("SESSIONS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(
                            viewModel.isBuildingSpecific
                                ? Theme.yellowyOrange.opacity(0.9)
                                : Theme.mutedRed.opacity(0.9)
                        )
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries without any "Show more" button
                    ForEach(
                        Array(
                            viewModel.leaderboardEntries.prefix(10).enumerated()
                        ), id: \.element.id
                    ) { index, entry in
                        Button(action: {
                            // Only show profile for non-anonymous users
                            if !entry.isAnonymous {
                                self.selectedUserId = entry.userId
                                self.showUserProfile = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                // Rank with medal for top 3
                                if index < 3 {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                index == 0
                                                    ? goldColor
                                                    : (index == 1
                                                        ? silverColor
                                                        : bronzeColor)
                                            )
                                            .frame(width: 26, height: 26)

                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(
                                                color: Color.black.opacity(0.2),
                                                radius: 1)
                                    }
                                    .frame(width: 32, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 32, alignment: .center)
                                }

                                // NEW: Rank circle if score is available
                                if entry.isAnonymous {
                                    // Show question mark for anonymous users
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 26, height: 26)

                                        Text("?")
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)
                                    }
                                } else if let score = entry.score {
                                    // Show normal rank for non-anonymous users
                                    RankCircle(
                                        score: score, size: 26,
                                        showStreakIndicator: false)
                                }

                                // Profile picture with streak indicator
                                ZStack {
                                    // Use anonymous profile picture for anonymous users
                                    if entry.isAnonymous {
                                        DefaultProfileImage(
                                            username: "A", size: 32)
                                    } else {
                                        ProfileImage(
                                            userId: entry.userId, size: 32)

                                        // Optional streak indicator - only for non-anonymous users
                                        if entry.streakStatus != .none {
                                            Circle()
                                                .stroke(
                                                    entry.streakStatus
                                                        == .redFlame
                                                        ? Color.red.opacity(0.8)
                                                        : Color.orange.opacity(
                                                            0.8),
                                                    lineWidth: 2
                                                )
                                                .frame(width: 32, height: 32)

                                            // Flame icon
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        entry.streakStatus
                                                            == .redFlame
                                                            ? Color.red
                                                            : Color.orange
                                                    )
                                                    .frame(
                                                        width: 12, height: 12)

                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            }
                                            .position(x: 24, y: 8)
                                        }
                                    }
                                }

                                // Username with underline to indicate it's clickable (only for non-anonymous)
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(
                                        maxWidth: .infinity, alignment: .leading
                                    )
                                    .underline(
                                        color: entry.isAnonymous
                                            ? .clear : .white.opacity(0.3))

                                // Duration
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.sessionCount)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(
                                            viewModel.isBuildingSpecific
                                                ? Theme.yellowyOrange
                                                : Theme.mutedRed
                                        )
                                        .shadow(
                                            color: viewModel.isBuildingSpecific
                                                ? Theme.yellowyOrange.opacity(0.3)
                                                : Theme.mutedRed.opacity(0.3), radius: 4)

                                    Text("sessions")
                                        .font(
                                            .system(size: 10, weight: .medium)
                                        )
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        viewModel.isBuildingSpecific
                                            ? LinearGradient(
                                                colors: index < 3
                                                    ? [
                                                        Theme.yellowyOrange.opacity(0.2),
                                                        Theme.yellowyOrange.opacity(0.1),
                                                    ]
                                                    : [
                                                        Color.white.opacity(
                                                            0.08),
                                                        Color.white.opacity(
                                                            0.05),
                                                    ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            : LinearGradient(
                                                colors: index < 3
                                                    ? [
                                                        Theme.mutedRed.opacity(0.2),
                                                        Theme.mutedRed.opacity(0.1),
                                                    ]
                                                    : [
                                                        Color.white.opacity(
                                                            0.08),
                                                        Color.white.opacity(
                                                            0.05),
                                                    ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                // Highlight current user
                                                Auth.auth().currentUser?.uid
                                                    == entry.userId
                                                    ? (viewModel
                                                        .isBuildingSpecific
                                                        ? Theme.yellowyOrange.opacity(0.5)
                                                        : Theme.mutedRed.opacity(0.5))
                                                    : Color.white.opacity(0.2),
                                                lineWidth: Auth.auth()
                                                    .currentUser?.uid
                                                    == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
                        // Disable the button for anonymous users
                        .disabled(entry.isAnonymous)
                    }

                    // Radius control
                    if !viewModel.isBuildingSpecific {
                        HStack {
                            Spacer()

                            Button(action: {
                                viewModel.decreaseRadius()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .disabled(viewModel.radius <= 1)
                            .opacity(viewModel.radius <= 1 ? 0.5 : 1.0)

                            Text("\(viewModel.radius) mi")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40)

                            Button(action: {
                                viewModel.increaseRadius()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .disabled(viewModel.radius >= 20)
                            .opacity(viewModel.radius >= 20 ? 0.5 : 1.0)

                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        viewModel.isBuildingSpecific
                            ? LinearGradient(
                                colors: [
                                    Color(
                                        red: 146 / 255, green: 123 / 255,
                                        blue: 21 / 255
                                    ).opacity(0.3),
                                    Color(
                                        red: 133 / 255, green: 109 / 255,
                                        blue: 7 / 255
                                    ).opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(
                                        red: 153 / 255, green: 27 / 255,
                                        blue: 27 / 255
                                    ).opacity(0.3),
                                    Color(
                                        red: 127 / 255, green: 29 / 255,
                                        blue: 29 / 255
                                    ).opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        viewModel.isBuildingSpecific
                            ? LinearGradient(
                                colors: [
                                    Theme.yellowyOrange.opacity(0.5),
                                    Theme.yellowyOrange.opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Theme.mutedRed.opacity(0.5),
                                    Color(
                                        red: 185 / 255, green: 28 / 255,
                                        blue: 28 / 255
                                    ).opacity(0.2),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
        .sheet(
            isPresented: $showUserProfile,
            content: {
                if let userId = selectedUserId {
                    UserProfileLoader(userId: userId)
                }
            })
    }
}

struct UserProfileSheet: View {
    let userId: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            UserProfileLoader(userId: userId)
                .navigationBarItems(
                    trailing: Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Profile image component that loads user profile pictures
struct ProfileImage: View {
    let userId: String
    let size: CGFloat
    @State private var imageURL: String?
    @State private var username: String = ""
    @State private var isLoading = true

    var body: some View {
        Group {
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        if isLoading {
                            ProgressView()
                                .frame(width: size, height: size)
                        } else {
                            DefaultProfileImage(username: username, size: size)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        DefaultProfileImage(username: username, size: size)
                    @unknown default:
                        DefaultProfileImage(username: username, size: size)
                    }
                }
            } else {
                DefaultProfileImage(username: username, size: size)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            loadUserData()
        }
    }
    private func loadUserData() {
        isLoading = true

        print("🖼️ ProfileImage loading data for user: \(userId)")

        // First check if user is the current user
        if let currentUserId = Auth.auth().currentUser?.uid,
            let currentUser = FirebaseManager.shared.currentUser,
            userId == currentUserId,
            !currentUser.username.isEmpty
        {

            print("✅ This is the current user: \(currentUser.username)")
            self.username = currentUser.username
            self.imageURL = currentUser.profileImageURL
            isLoading = false

            // Make sure this user is in the cache
            let userCache = UserCacheItem(
                userId: userId,
                username: currentUser.username,
                profileImageURL: currentUser.profileImageURL
            )
            RegionalViewModel.shared.leaderboardViewModel.userCache[userId] =
                userCache
            return
        }

        // Next check our local cache in RegionalLeaderboardViewModel
        if let cachedUser = RegionalViewModel.shared.leaderboardViewModel
            .userCache[userId],
            !cachedUser.username.isEmpty && cachedUser.username != "User"
        {
            print("✅ Using cached username: \(cachedUser.username)")
            self.username = cachedUser.username
            self.imageURL = cachedUser.profileImageURL
            isLoading = false
            return
        }

        // Check in leaderboard entries
        for entry in RegionalViewModel.shared.leaderboardViewModel
            .leaderboardEntries
        {
            if entry.userId == userId && !entry.username.isEmpty
                && entry.username != "User"
            {
                print(
                    "✅ Found username in leaderboard entries: \(entry.username)"
                )
                self.username = entry.username

                // Save to cache
                let cacheItem = UserCacheItem(
                    userId: userId,
                    username: entry.username,
                    profileImageURL: nil  // Will fetch this below
                )
                RegionalViewModel.shared.leaderboardViewModel.userCache[
                    userId] = cacheItem

                // We found the username but still need to get profile image
                fetchProfileImage()
                return
            }
        }

        // Next check FirebaseManager.shared.friends
        for friend in FirebaseManager.shared.friends {
            if friend.id == userId && !friend.username.isEmpty {
                print("✅ Found in friends list: \(friend.username)")
                self.username = friend.username
                self.imageURL = friend.profileImageURL
                isLoading = false

                // Update cache
                let userCache = UserCacheItem(
                    userId: userId,
                    username: friend.username,
                    profileImageURL: friend.profileImageURL
                )
                RegionalViewModel.shared.leaderboardViewModel.userCache[
                    userId] = userCache
                return
            }
        }

        // If we're here, we need to fetch from Firestore
        fetchCompleteUserData()
    }

    // Helper method to just fetch the profile image for a user we already know the username for
    private func fetchProfileImage() {
        // Check if we already have a cached image
        if let _cachedImage = ProfileImageCache.shared.getCachedImage(
            for: userId)
        {
            self.imageURL = "cached"  // Just a placeholder, we won't use this value
            self.isLoading = false
            return
        }

        // Otherwise, fetch it from Firestore
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument(source: .default) { snapshot, error in

                if let data = snapshot?.data(),
                    let profileURL = data["profileImageURL"] as? String,
                    !profileURL.isEmpty
                {
                    DispatchQueue.main.async {
                        self.imageURL = profileURL
                        self.isLoading = false

                        // Update cache with profile URL
                        if var cachedUser = RegionalViewModel.shared
                            .leaderboardViewModel.userCache[userId]
                        {
                            cachedUser.profileImageURL = profileURL
                            RegionalViewModel.shared.leaderboardViewModel
                                .userCache[userId] = cachedUser
                        }

                        // Also download and cache the actual image
                        if let url = URL(string: profileURL) {
                            URLSession.shared.dataTask(with: url) {
                                data, response, error in
                                if let data = data,
                                    let image = UIImage(data: data)
                                {
                                    // Store in ProfileImageCache for map markers
                                    ProfileImageCache.shared.storeImage(
                                        image, for: self.userId)
                                }
                            }.resume()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
    }

    // Enhanced function to fetch complete user data
    private func fetchCompleteUserData() {
        print("🔍 Fetching complete user data for: \(userId)")

        var retryCount = 0
        let maxRetries = 2

        func attemptFetch() {
            FirebaseManager.shared.db.collection("users").document(userId)
                .getDocument(source: .default) { snapshot, error in

                    if let error = error {
                        print(
                            "❌ Error loading user data (attempt \(retryCount+1)): \(error.localizedDescription)"
                        )

                        if retryCount < maxRetries {
                            retryCount += 1
                            print("🔄 Retrying fetch...")
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.5
                            ) {
                                attemptFetch()
                            }
                        } else {
                            print("⚠️ All retries failed, using fallback name")
                            DispatchQueue.main.async {
                                self.username = "User \(userId.prefix(4))"
                                self.isLoading = false
                            }
                        }
                        return
                    }

                    if let data = snapshot?.data() {
                        // Try to get username directly
                        if let fetchedUsername = data["username"] as? String,
                            !fetchedUsername.isEmpty
                        {
                            print(
                                "✅ Successfully loaded username: \(fetchedUsername)"
                            )

                            // Get profile image URL if available
                            let profileImageURL =
                                data["profileImageURL"] as? String

                            // Cache this user
                            let userCache = UserCacheItem(
                                userId: userId,
                                username: fetchedUsername,
                                profileImageURL: profileImageURL
                            )
                            RegionalViewModel.shared.leaderboardViewModel
                                .userCache[userId] = userCache

                            DispatchQueue.main.async {
                                self.username = fetchedUsername
                                self.imageURL = profileImageURL
                                self.isLoading = false
                            }

                            // Also update Firebase sessions with correct username
                            RegionalViewModel.shared.leaderboardViewModel
                                .updateSessionUsernames(
                                    userId: self.userId,
                                    username: fetchedUsername)

                            // If we have an image URL, cache the actual image
                            if let imageURL = profileImageURL,
                                let url = URL(string: imageURL)
                            {
                                URLSession.shared.dataTask(with: url) {
                                    data, response, error in
                                    if let data = data,
                                        let image = UIImage(data: data)
                                    {
                                        // Store in ProfileImageCache for map markers
                                        ProfileImageCache.shared.storeImage(
                                            image, for: self.userId)
                                    }
                                }.resume()
                            }
                        } else {
                            // Try alternative methods to get a name
                            print("⚠️ Username field is empty or missing")

                            // Check if user's document has any other identifying fields
                            if let email = data["email"] as? String,
                                !email.isEmpty
                            {
                                let username =
                                    email.components(separatedBy: "@").first
                                    ?? "User"
                                print(
                                    "🔤 Using email-derived username: \(username)"
                                )

                                DispatchQueue.main.async {
                                    self.username = username
                                    self.imageURL =
                                        data["profileImageURL"] as? String
                                    self.isLoading = false
                                }

                                // Cache this result
                                let userCache = UserCacheItem(
                                    userId: userId,
                                    username: username,
                                    profileImageURL: data["profileImageURL"]
                                        as? String
                                )
                                RegionalViewModel.shared.leaderboardViewModel
                                    .userCache[userId] = userCache
                            } else {
                                print(
                                    "❌ No usable identifying info for user: \(userId)"
                                )
                                DispatchQueue.main.async {
                                    self.username =
                                        "User \(self.userId.prefix(4))"
                                    self.isLoading = false
                                }
                            }
                        }
                    } else {
                        print("❌ No user data found for ID: \(userId)")
                        DispatchQueue.main.async {
                            self.username = "User \(self.userId.prefix(4))"
                            self.isLoading = false
                        }
                    }
                }
        }

        // Start the first attempt
        attemptFetch()
    }
}

// Default profile image to use when user has no profile picture
struct DefaultProfileImage: View {
    let username: String
    let size: CGFloat

    private var initials: String {
        guard !username.isEmpty else { return "?" }
        let firstChar = String(username.prefix(1)).uppercased()
        return firstChar
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.7), Color.blue.opacity(0.4),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
struct UserCacheItem {
    let userId: String
    let username: String
    var profileImageURL: String?
}

// Replace your current RegionalLeaderboardViewModel class implementation with this:

class RegionalLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [RegionalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var radius: Int = 5  // Keeping this for backward compatibility
    @Published var locationName: String?
    @Published var isBuildingSpecific: Bool = true  // Default to building-specific mode
    var userCache: [String: UserCacheItem] = [:]

    private var currentLocation: CLLocation?
    private let firebaseManager = FirebaseManager.shared
    private let geocoder = CLGeocoder()

    // Only keep the building-specific leaderboard functionality
    func loadBuildingLeaderboard(building: BuildingInfo) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isBuildingSpecific = true
        isLoading = true

        // Set the building name for display
        self.locationName = building.name

        // First get the user's friends list to mark friends in leaderboard
        firebaseManager.db.collection("users").document(currentUserId)
            .getDocument { [weak self] document, error in
                guard let self = self,
                    let userData = try? document?.data(
                        as: FirebaseManager.FlipUser.self)
                else {
                    self?.isLoading = false
                    return
                }

                let friendIds = userData.friends

                // Now call fetchBuildingTopSessions with the friends list
                self.fetchBuildingTopSessions(
                    building: building, friendIds: friendIds)
            }
    }
    func fetchBuildingTopSessions(building: BuildingInfo, friendIds: [String]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        // Calculate the current week's start date (Monday)
        let calendar = Calendar.current
        let currentDate = Date()
        var components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: currentDate)
        components.weekday = 2  // Monday (2 = Monday in iOS Calendar)
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let weekStart = calendar.date(from: components) else {
            self.isLoading = false
            return
        }

        print("🗓️ Weekly leaderboard from: \(weekStart)")

        // Use the standardized building ID
        let buildingId = building.id

        // Get the building's location as a CLLocation
        let buildingLocation = CLLocation(
            latitude: building.coordinate.latitude,
            longitude: building.coordinate.longitude
        )
        let radius = 100.0  // Search within 100 meters of the building

        // First, fetch all sessions from this week in and near this building
        db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .whereField(
                "sessionStartTime", isGreaterThan: Timestamp(date: weekStart)
            )
            .getDocuments(source: .default) { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print(
                        "Error fetching sessions: \(error.localizedDescription)"
                    )
                    self.isLoading = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }

                print("📊 Found \(documents.count) total sessions this week")

                // Dictionary to track each user's total time and session count
                var userWeeklyData:
                    [String: (
                        userId: String, username: String, sessionCount: Int,
                        distance: Double, isFriend: Bool, isCurrentUser: Bool
                    )] = [:]

                // Collection of user IDs we need to fetch usernames for
                var userIdsToFetch = Set<String>()

                // First, fetch all user privacy settings to filter out opted-out users
                self.fetchUserPrivacySettings(
                    userIds: documents.compactMap {
                        $0.data()["userId"] as? String
                    }
                ) { privacySettings in
                    // Process each session document
                    for document in documents {
                        let data = document.data()

                        // Extract basic session info
                        guard let userId = data["userId"] as? String,
                            let geoPoint = data["location"] as? GeoPoint
                        else {
                            continue
                        }

                        // Check if user has opted out of the leaderboard
                        if let userPrivacy = privacySettings[userId],
                            userPrivacy.optOut
                        {
                            // Skip this user entirely if they've opted out
                            continue
                        }

                        // Add this user ID to the list we need to fetch
                        userIdsToFetch.insert(userId)

                        // Check if this session is in or near our target building
                        // Either by exact buildingId match OR by proximity
                        let isExactBuildingMatch =
                            (data["buildingId"] as? String) == buildingId

                        if !isExactBuildingMatch {
                            // Not an exact match, check proximity
                            let sessionLocation = CLLocation(
                                latitude: geoPoint.latitude,
                                longitude: geoPoint.longitude
                            )
                            let distance = sessionLocation.distance(
                                from: buildingLocation)

                            // Skip if not within radius
                            if distance > radius {
                                continue
                            }
                        }

                        // Get session data like duration
                        let sessionDuration =
                            data["actualDuration"] as? Int ?? 0

                        // Check if user is anonymous in privacy settings
                        var tempUsername = data["username"] as? String ?? "User"
                        if let userPrivacy = privacySettings[userId],
                            userPrivacy.isAnonymous
                        {
                            tempUsername = "Anonymous"
                        }

                        // Calculate distance for display
                        let sessionLocation = CLLocation(
                            latitude: geoPoint.latitude,
                            longitude: geoPoint.longitude
                        )
                        let distance = sessionLocation.distance(
                            from: buildingLocation)

                        // Only show distance for friends and current user
                        let showDistance =
                            userId == currentUserId
                            || friendIds.contains(userId)
                        let displayDistance = showDistance ? distance : 0

                        // Update the user's total time
                        if let existingData = userWeeklyData[userId] {
                            // Add to existing record - keep existing username
                            userWeeklyData[userId] = (
                                userId: userId,
                                username: existingData.username,
                                sessionCount: existingData.sessionCount + 1,
                                distance: displayDistance,
                                isFriend: friendIds.contains(userId),
                                isCurrentUser: userId == currentUserId
                            )
                        } else {
                            // Create new record with temporary username - we'll update this later
                            userWeeklyData[userId] = (
                                userId: userId,
                                username: tempUsername,
                                sessionCount: 1,
                                distance: displayDistance,
                                isFriend: friendIds.contains(userId),
                                isCurrentUser: userId == currentUserId
                            )
                        }
                    }

                    // No data found - update UI now
                    if userWeeklyData.isEmpty {
                        DispatchQueue.main.async {
                            self.leaderboardEntries = []
                            self.isLoading = false
                        }
                        return
                    }

                    // Now fetch all usernames in a single batch for better performance
                    self.fetchUsernamesRespectingPrivacy(
                        Array(userIdsToFetch), privacySettings: privacySettings
                    ) { usernameMap in
                        // Update the usernames in our data
                        for userId in userWeeklyData.keys {
                            if let fetchedUsername = usernameMap[userId],
                                !fetchedUsername.isEmpty
                            {
                                var userData = userWeeklyData[userId]!
                                userData.username = fetchedUsername
                                userWeeklyData[userId] = userData
                            }
                        }

                        // Convert aggregated data to leaderboard entries
                        self.fetchUserScoresAndStreaks(Array(userIdsToFetch)) {
                            scoresMap, streaksMap in
                            // Convert aggregated data to leaderboard entries with scores
                            var entries: [RegionalLeaderboardEntry] = []

                            for userData in userWeeklyData.values {
                                // Create the entry with all required fields
                                let entry = RegionalLeaderboardEntry(
                                    id: userData.userId,
                                    userId: userData.userId,
                                    username: userData.username,
                                    totalWeeklyTime: 0,  // We don't use this field anymore
                                    score: scoresMap[userData.userId],
                                    streakStatus: streaksMap[userData.userId]
                                        ?? .none,
                                    sessionCount: userData.sessionCount,
                                    distance: userData.distance,
                                    isFriend: userData.isFriend,
                                    isCurrentUser: userData.isCurrentUser,
                                    // Add this property to track if user is anonymous
                                    isAnonymous: userData.username
                                        == "Anonymous"
                                )
                                entries.append(entry)
                            }

                            // Sort entries by session count (manually instead of using sorted with a closure)
                            entries.sort { entry1, entry2 in
                                return entry1.sessionCount > entry2.sessionCount
                            }

                            // Take top 10 for display
                            DispatchQueue.main.async {
                                self.leaderboardEntries = Array(
                                    entries.prefix(10))
                                self.isLoading = false
                            }
                        }
                    }
                }
            }
    }

    private func fetchUserScoresAndStreaks(
        _ userIds: [String],
        completion: @escaping ([String: Double], [String: StreakStatus]) -> Void
    ) {
        let db = Firestore.firestore()
        var scores: [String: Double] = [:]
        var streaks: [String: StreakStatus] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            // Get user score
            db.collection("users").document(userId).getDocument(
                source: .default
            ) { document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    if let score = data["score"] as? Double {
                        scores[userId] = score
                    }
                }
            }

            // Get user streak status in a separate call
            dispatchGroup.enter()
            db.collection("users").document(userId).collection("streak")
                .document("current").getDocument { document, error in
                    defer { dispatchGroup.leave() }

                    if let data = document?.data(),
                        let statusString = data["streakStatus"] as? String
                    {
                        streaks[userId] =
                            StreakStatus(rawValue: statusString) ?? .none
                    }
                }
        }

        dispatchGroup.notify(queue: .main) {
            completion(scores, streaks)
        }
    }

    // Add these helper functions to RegionalLeaderboardViewModel

    // New helper function to fetch usernames efficiently
    private func fetchUsernamesRespectingPrivacy(
        _ userIds: [String],
        privacySettings: [String: (optOut: Bool, isAnonymous: Bool)],
        completion: @escaping ([String: String]) -> Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        print("🔄 Fetching usernames for \(userIds.count) users")

        // First check our cache
        var result: [String: String] = [:]
        var idsToFetch: [String] = []

        for userId in userIds {
            // Check if user is anonymous based on privacy settings
            if let privacySetting = privacySettings[userId],
                privacySetting.isAnonymous
            {
                result[userId] = "Anonymous"
                continue
            }

            if let cachedUser = userCache[userId],
                !cachedUser.username.isEmpty && cachedUser.username != "User"
            {
                result[userId] = cachedUser.username
            } else if let currentUser = FirebaseManager.shared.currentUser,
                currentUser.id == userId, !currentUser.username.isEmpty
            {
                result[userId] = currentUser.username
                // Update cache
                userCache[userId] = UserCacheItem(
                    userId: userId,
                    username: currentUser.username,
                    profileImageURL: currentUser.profileImageURL
                )
            } else {
                idsToFetch.append(userId)
            }
        }

        // If we have all usernames already, return
        if idsToFetch.isEmpty {
            completion(result)
            return
        }

        // Fetch in batches of 10 to avoid Firestore limitations
        let batchSize = 10
        let dispatchGroup = DispatchGroup()

        for i in stride(from: 0, to: idsToFetch.count, by: batchSize) {
            let end = min(i + batchSize, idsToFetch.count)
            let batch = Array(idsToFetch[i..<end])

            dispatchGroup.enter()
            fetchUserBatch(batch) { batchResult in
                // Add this batch to our results
                for (id, username) in batchResult {
                    // Apply privacy settings - override with "Anonymous" if needed
                    if let privacySetting = privacySettings[id],
                        privacySetting.isAnonymous
                    {
                        result[id] = "Anonymous"
                    } else {
                        result[id] = username
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print(
                "✅ Completed fetching usernames - found \(result.count) valid names"
            )
            completion(result)
        }
    }

    private func fetchUserBatch(
        _ userIds: [String], completion: @escaping ([String: String]) -> Void
    ) {
        let db = Firestore.firestore()
        var batchResult: [String: String] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("users").document(userId).getDocument(
                source: .default
            ) { [weak self] document, error in
                defer { dispatchGroup.leave() }

                // Try to get username from document
                if let data = document?.data(),
                    let username = data["username"] as? String,
                    !username.isEmpty
                {
                    print("📝 Found username for \(userId): \(username)")
                    batchResult[userId] = username

                    // Update our cache
                    let profileImageURL = data["profileImageURL"] as? String
                    self?.userCache[userId] = UserCacheItem(
                        userId: userId,
                        username: username,
                        profileImageURL: profileImageURL
                    )

                    // Also update any sessions that have a generic username
                    self?.updateSessionUsernames(
                        userId: userId, username: username)
                } else {
                    print("⚠️ No username found for user \(userId)")
                    batchResult[userId] = "User"
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(batchResult)
        }
    }
    private func fetchUserPrivacySettings(
        userIds: [String],
        completion: @escaping ([String: (optOut: Bool, isAnonymous: Bool)]) ->
            Void
    ) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }

        let db = Firestore.firestore()
        var result: [String: (optOut: Bool, isAnonymous: Bool)] = [:]
        let dispatchGroup = DispatchGroup()

        for userId in userIds {
            dispatchGroup.enter()

            db.collection("user_settings").document(userId).getDocument {
                document, error in
                defer { dispatchGroup.leave() }

                if let data = document?.data() {
                    // Get opt-out setting (default to false)
                    let optOut = data["regionalOptOut"] as? Bool ?? false

                    // Get display mode (default to normal)
                    let displayModeString =
                        data["regionalDisplayMode"] as? String ?? "normal"
                    let isAnonymous = displayModeString == "anonymous"

                    result[userId] = (optOut: optOut, isAnonymous: isAnonymous)
                } else {
                    // Use defaults if no settings document
                    result[userId] = (optOut: false, isAnonymous: false)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(result)
        }
    }

    // Helper method to update usernames in session records
    func updateSessionUsernames(userId: String, username: String) {
        // Only update if we have a valid username
        guard !username.isEmpty && username != "User" else { return }

        // Get collections where usernames might be stored
        let collections = ["session_locations", "locations", "sessions"]
        let db = FirebaseManager.shared.db
        let oneMonthAgo =
            Calendar.current.date(byAdding: .month, value: -1, to: Date())
            ?? Date()

        for collection in collections {
            // Look for sessions by this user in the last month
            db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .whereField("username", isEqualTo: "User")  // Only update if username is empty/generic
                .whereField(
                    "sessionStartTime",
                    isGreaterThan: Timestamp(date: oneMonthAgo)
                )
                .limit(to: 20)  // Limit the updates to avoid excessive writes
                .getDocuments(source: .default) { snapshot, error in
                    if let error = error {
                        print(
                            "❌ Error finding sessions to update: \(error.localizedDescription)"
                        )
                        return
                    }

                    guard let documents = snapshot?.documents,
                        !documents.isEmpty
                    else {
                        print(
                            "✅ No sessions need username update in \(collection)"
                        )
                        return
                    }

                    print(
                        "🔄 Updating \(documents.count) sessions with correct username in \(collection)"
                    )

                    // Create a batch write
                    let batch = db.batch()

                    for document in documents {
                        let docRef = db.collection(collection).document(
                            document.documentID)
                        batch.updateData(
                            ["username": username], forDocument: docRef)
                    }

                    // Commit the batch
                    batch.commit { error in
                        if let error = error {
                            print(
                                "❌ Error updating session usernames: \(error.localizedDescription)"
                            )
                        } else {
                            print(
                                "✅ Successfully updated \(documents.count) session usernames"
                            )
                        }
                    }
                }
        }
    }
    // For backward compatibility - required by RegionalView.swift
    func increaseRadius() {
        // No implementation needed if you're only using building leaderboard
    }

    func decreaseRadius() {
        // No implementation needed if you're only using building leaderboard
    }

    // Stub method for backward compatibility - redirect to building leaderboard
    func loadRegionalLeaderboard(near location: CLLocation) {
        // If there's a selected building in RegionalViewModel, use that
        if let building = RegionalViewModel.shared.selectedBuilding {
            loadBuildingLeaderboard(building: building)
        } else {
            // Otherwise reset state and show empty
            isBuildingSpecific = false
            leaderboardEntries = []
            isLoading = false

            // Try to get location name for display
            geocoder.reverseGeocodeLocation(location) {
                [weak self] placemarks, error in
                if let placemark = placemarks?.first,
                    let locality = placemark.locality
                {
                    DispatchQueue.main.async {
                        self?.locationName = locality
                    }
                }
            }
        }
    }
}

// STRUCTURE 4: RegionalLeaderboardEntry struct - moved outside
struct RegionalLeaderboardEntry: Identifiable {
    let id: String
    let userId: String
    let username: String
    let totalWeeklyTime: Int  // Changed from duration to totalWeeklyTime (in minutes)
    var score: Double? = nil  // Add this property for displaying rank
    var streakStatus: StreakStatus = .none  // Add streak status
    let sessionCount: Int  // New: count of sessions for this user this week
    let distance: Double  // In meters
    let isFriend: Bool
    let isCurrentUser: Bool
    var isAnonymous: Bool = false  // Add this property

    var formattedDistance: String {
        if isCurrentUser {
            return ""
        } else if distance < 500 {
            return "nearby"
        } else if distance < 1609 {  // Less than a mile
            return "<1 mi"
        } else {
            let miles = Int(distance / 1609.34)
            return "\(miles) mi"
        }
    }
}

// STRUCTURE 5: SessionWithLocation struct - moved outside
struct SessionWithLocation {
    let id: String
    let userId: String
    let username: String
    let duration: Int
    let location: CLLocation
    let distance: Double
    let isFriend: Bool
    let isCurrentUser: Bool
}
