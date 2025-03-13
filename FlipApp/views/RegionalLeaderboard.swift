import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation


struct RegionalLeaderboard: View {
    @ObservedObject var viewModel: RegionalLeaderboardViewModel
    @State private var selectedUserId: String?
    @State private var showUserProfile = false
    
    // Silver-red theme colors
    private let silverRedGradient = LinearGradient(
        colors: [
            Color(red: 226/255, green: 232/255, blue: 240/255), // Light silver
            Color(red: 185/255, green: 28/255, blue: 28/255)    // Deep red
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let silverRedBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 153/255, green: 27/255, blue: 27/255).opacity(0.4),
            Color(red: 127/255, green: 29/255, blue: 29/255).opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Medal colors
    private let goldColor = LinearGradient(
        colors: [Color(red: 255/255, green: 215/255, blue: 0/255), Color(red: 212/255, green: 175/255, blue: 55/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let silverColor = LinearGradient(
        colors: [Color(red: 226/255, green: 232/255, blue: 240/255), Color(red: 148/255, green: 163/255, blue: 184/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let bronzeColor = LinearGradient(
        colors: [Color(red: 205/255, green: 127/255, blue: 50/255), Color(red: 165/255, green: 113/255, blue: 78/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        VStack(spacing: 12) {
            // Title section with enhanced visual style
            VStack(spacing: 4) {
                // Main title with icon
                HStack {
                    Image(systemName: viewModel.isBuildingSpecific ? "building.2.fill" : "map.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            viewModel.isBuildingSpecific ?
                            LinearGradient(
                                colors: [
                                    Color(red: 234/255, green: 179/255, blue: 8/255),
                                    Color(red: 202/255, green: 138/255, blue: 4/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: viewModel.isBuildingSpecific ?
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5) :
                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 4)
                    
                    Text(viewModel.isBuildingSpecific ? "MOST SESSIONS OF THE WEEK" : "REGIONAL LEADERBOARD")
                        .font(.system(size: 13, weight: .black))
                        .tracking(2)
                        .foregroundStyle(
                            viewModel.isBuildingSpecific ?
                            LinearGradient(
                                colors: [
                                    Color(red: 234/255, green: 179/255, blue: 8/255),
                                    Color(red: 202/255, green: 138/255, blue: 4/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: viewModel.isBuildingSpecific ?
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5) :
                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 4)
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
                    .fill(viewModel.isBuildingSpecific ?
                        LinearGradient(
                            colors: [
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3),
                                Color(red: 202/255, green: 138/255, blue: 4/255).opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3),
                                Color(red: 185/255, green: 28/255, blue: 28/255).opacity(0.2)
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
                                        Color.white.opacity(0.2)
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
                    Image(systemName: viewModel.isBuildingSpecific ? "building.2.crop.circle" : "mappin.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 5)
                    
                    Text(viewModel.isBuildingSpecific ?
                         "No sessions in this building yet" :
                            "No active users in your area this week")
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
                        .foregroundColor(viewModel.isBuildingSpecific ?
                                         Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.9) :
                                         Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.9))
                        .frame(width: 50, alignment: .center)
                    
                    Text("USER")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(viewModel.isBuildingSpecific ?
                                         Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.9) :
                                         Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.9))
                        .frame(alignment: .leading)
                    
                    Spacer()
                    
                    Text("SESSIONS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1)
                        .foregroundColor(viewModel.isBuildingSpecific ?
                                         Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.9) :
                                         Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.9))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
                
                // Leaderboard entries - LIMIT TO 10 ENTRIES
                VStack(spacing: 8) {
                    // Only show first 10 entries without any "Show more" button
                    ForEach(Array(viewModel.leaderboardEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                        Button(action: {
                            self.selectedUserId = entry.userId
                            self.showUserProfile = true
                        }) {
                            HStack {
                                // Rank with medal for top 3
                                if index < 3 {
                                    ZStack {
                                        Circle()
                                            .fill(index == 0 ? goldColor : (index == 1 ? silverColor : bronzeColor))
                                            .frame(width: 26, height: 26)
                                        
                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.2), radius: 1)
                                    }
                                    .frame(width: 50, alignment: .center)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, alignment: .center)
                                }
                                
                                // Profile picture
                                ProfileImage(userId: entry.userId, size: 32)
                                
                                // Username with underline to indicate it's clickable
                                Text(entry.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .underline(color: .white.opacity(0.3))
                                
                                // Duration
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(entry.sessionCount)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(viewModel.isBuildingSpecific ?
                                                         Color(red: 234/255, green: 179/255, blue: 8/255) :
                                                            Color(red: 239/255, green: 68/255, blue: 68/255))
                                        .shadow(color: viewModel.isBuildingSpecific ?
                                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3) :
                                                    Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3), radius: 4)
                                    
                                    Text("sessions")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        viewModel.isBuildingSpecific ?
                                        LinearGradient(
                                            colors: index < 3 ? [
                                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.2),
                                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.1)
                                            ] : [
                                                Color.white.opacity(0.08),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ) :
                                        LinearGradient(
                                            colors: index < 3 ? [
                                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.2),
                                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.1)
                                            ] : [
                                                Color.white.opacity(0.08),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                // Highlight current user
                                                Auth.auth().currentUser?.uid == entry.userId ?
                                                (viewModel.isBuildingSpecific ?
                                                 Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5) :
                                                 Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5)) :
                                                Color.white.opacity(0.2),
                                                lineWidth: Auth.auth().currentUser?.uid == entry.userId ? 1.5 : 1
                                            )
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 2)
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
                        viewModel.isBuildingSpecific ?
                        LinearGradient(
                            colors: [
                                Color(red: 146/255, green: 123/255, blue: 21/255).opacity(0.3),
                                Color(red: 133/255, green: 109/255, blue: 7/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(red: 153/255, green: 27/255, blue: 27/255).opacity(0.3),
                                Color(red: 127/255, green: 29/255, blue: 29/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        viewModel.isBuildingSpecific ?
                        LinearGradient(
                            colors: [
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5),
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5),
                                Color(red: 185/255, green: 28/255, blue: 28/255).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
        .sheet(isPresented: $showUserProfile, content: {
            if let userId = selectedUserId {
                UserProfileSheet(userId: userId)
            }
        })
    }
}

// In UserProfileSheet (RegionalLeaderboard.swift)
struct UserProfileSheet: View {
    let userId: String
    @State private var user: FirebaseManager.FlipUser?
    @State private var isLoading = true
    @State private var hasAppeared = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Add a background color to prevent the black screen
                Color(red: 20/255, green: 10/255, blue: 40/255) // Deep midnight purple
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading profile...")
                        .tint(.white)
                } else if let user = user {
                    UserProfileView(user: user)
                } else {
                    Text("Could not load user profile")
                        .foregroundColor(.white)
                }
            }
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitleDisplayMode(.inline)
            // Force the view to refresh after appearing
            .onAppear {
                loadUser()
                
                // This helps with the black screen issue
                if !hasAppeared {
                    hasAppeared = true
                    // Force a redraw after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isLoading = true
                        loadUser()
                    }
                }
            }
        }
    }
    
    private func loadUser() {
        print("Loading user profile for ID: \(userId)")
        isLoading = true
        
        FirebaseManager.shared.db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            if let userData = try? snapshot?.data(as: FirebaseManager.FlipUser.self) {
                print("Successfully loaded user: \(userData.username)")
                DispatchQueue.main.async {
                    self.user = userData
                    self.isLoading = false
                }
            } else {
                print("Failed to decode user data for ID: \(userId)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
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
    
    // In ProfileImage.swift - inside the loadUserData function
    private func loadUserData() {
        isLoading = true
        
        print("🖼️ ProfileImage loading data for user: \(userId)")
        
        // First check if we already have a cached username from the ViewModel
        if let cachedUser = RegionalViewModel.shared.leaderboardViewModel.userCache[userId] {
            if !cachedUser.username.isEmpty {
                print("✅ Using cached username: \(cachedUser.username)")
                self.username = cachedUser.username
                self.imageURL = cachedUser.profileImageURL
                isLoading = false
                return
            } else {
                print("⚠️ Cached username is empty, fetching fresh data")
            }
        }
        
        // First try FirebaseManager's current user and friends
        if let currentUserId = Auth.auth().currentUser?.uid,
           let currentUser = FirebaseManager.shared.currentUser {
            
            // If this is the current user
            if userId == currentUserId {
                print("✅ This is the current user: \(currentUser.username)")
                self.username = currentUser.username
                self.imageURL = currentUser.profileImageURL
                isLoading = false
                
                // Update cache
                let userCache = UserCacheItem(
                    userId: userId,
                    username: currentUser.username,
                    profileImageURL: currentUser.profileImageURL
                )
                RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = userCache
                return
            }
            
            // Check if in friends list
            for friend in FirebaseManager.shared.friends {
                if friend.id == userId {
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
                    RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = userCache
                    return
                }
            }
        }
        
        // Next check if the user is already in the leaderboard entries
        for entry in RegionalViewModel.shared.leaderboardViewModel.leaderboardEntries {
            if entry.userId == userId && !entry.username.isEmpty {
                print("✅ Found username in leaderboard entries: \(entry.username)")
                self.username = entry.username
                
                // Also cache this for future use
                let cacheItem = UserCacheItem(
                    userId: userId,
                    username: entry.username,
                    profileImageURL: nil // We don't have the URL yet
                )
                RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = cacheItem
                
                // Still fetch the profile image
                fetchProfileImage()
                return
            }
        }
        
        // If not found in cache, fetch from Firestore
        fetchCompleteUserData()
    }
    private func fetchProfileImage() {
        // Only fetch the profile image URL
        FirebaseManager.shared.db.collection("users").document(userId).getDocument {  snapshot, error in
            if let error = error {
                print("❌ Error fetching profile image: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            if let data = snapshot?.data(), let profileURL = data["profileImageURL"] as? String {
                DispatchQueue.main.async {
                    self.imageURL = profileURL
                    self.isLoading = false
                    
                    // Update cache with profile URL
                    if var cachedUser = RegionalViewModel.shared.leaderboardViewModel.userCache[userId] {
                        cachedUser.profileImageURL = profileURL
                        RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = cachedUser
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    // In ProfileImage.swift - modify the fetchCompleteUserData() function:
    private func fetchCompleteUserData() {
        print("🔍 Fetching complete user data for: \(userId)")
        
        // First check if the user is already in FirebaseManager.shared.currentUser or friends list
        if let currentUserId = Auth.auth().currentUser?.uid {
            if userId == currentUserId && FirebaseManager.shared.currentUser != nil {
                DispatchQueue.main.async {
                    self.username = FirebaseManager.shared.currentUser?.username ?? "User"
                    self.imageURL = FirebaseManager.shared.currentUser?.profileImageURL
                    self.isLoading = false
                }
                return
            }
            
            // Check if user is in friends list
            if let friend = FirebaseManager.shared.friends.first(where: { $0.id == userId }) {
                DispatchQueue.main.async {
                    self.username = friend.username
                    self.imageURL = friend.profileImageURL
                    self.isLoading = false
                }
                // Still update cache
                let userCache = UserCacheItem(
                    userId: userId,
                    username: friend.username,
                    profileImageURL: friend.profileImageURL
                )
                RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = userCache
                return
            }
        }
        
        // Original Firestore query logic with better error handling
        var retryCount = 0
        let maxRetries = 2
        
        func attemptFetch() {
            FirebaseManager.shared.db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error loading user data (attempt \(retryCount+1)): \(error.localizedDescription)")
                    
                    if retryCount < maxRetries {
                        retryCount += 1
                        print("🔄 Retrying fetch...")
                        attemptFetch()
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
                    if let fetchedUsername = data["username"] as? String, !fetchedUsername.isEmpty {
                        print("✅ Successfully loaded username: \(fetchedUsername)")
                        
                        // Cache this result
                        let userCache = UserCacheItem(
                            userId: userId,
                            username: fetchedUsername,
                            profileImageURL: data["profileImageURL"] as? String
                        )
                        RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = userCache
                        
                        DispatchQueue.main.async {
                            self.username = fetchedUsername
                            self.imageURL = data["profileImageURL"] as? String
                            self.isLoading = false
                        }
                    } else {
                        // Try alternative methods to get a name
                        print("⚠️ Username field is empty or missing")
                        
                        // Check if user's document has any other identifying fields
                        if let email = data["email"] as? String, !email.isEmpty {
                            let username = email.components(separatedBy: "@").first ?? "User"
                            print("🔤 Using email-derived username: \(username)")
                            
                            DispatchQueue.main.async {
                                self.username = username
                                self.imageURL = data["profileImageURL"] as? String
                                self.isLoading = false
                            }
                            
                            // Cache this result
                            let userCache = UserCacheItem(
                                userId: userId,
                                username: username,
                                profileImageURL: data["profileImageURL"] as? String
                            )
                            RegionalViewModel.shared.leaderboardViewModel.userCache[userId] = userCache
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
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.4)],
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
    @Published var radius: Int = 5 // Keeping this for backward compatibility
    @Published var locationName: String?
    @Published var isBuildingSpecific: Bool = true // Default to building-specific mode
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
                      let userData = try? document?.data(as: FirebaseManager.FlipUser.self)
                else {
                    self?.isLoading = false
                    return
                }
                
                let friendIds = userData.friends
                
                // Now call fetchBuildingTopSessions with the friends list
                self.fetchBuildingTopSessions(building: building, friendIds: friendIds)
            }
    }
    
    func fetchBuildingTopSessions(building: BuildingInfo, friendIds: [String]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Calculate the current week's start date (Monday)
        let calendar = Calendar.current
        let currentDate = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
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
        let radius = 100.0 // Search within 100 meters of the building
        
        // First, fetch all sessions from this week in and near this building
        db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .whereField("sessionStartTime", isGreaterThan: Timestamp(date: weekStart))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching sessions: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                print("📊 Found \(documents.count) total sessions this week")
                
                // Dictionary to track each user's total time and session count
                var userWeeklyData: [String: (userId: String, username: String, sessionCount: Int, distance: Double, isFriend: Bool, isCurrentUser: Bool)] = [:]
                
                // Process each session document
                for document in documents {
                    let data = document.data()
                    
                    // Extract basic session info
                    guard let userId = data["userId"] as? String,
                          let geoPoint = data["location"] as? GeoPoint else {
                        continue
                    }
                    
                    // Check if this session is in or near our target building
                    // Either by exact buildingId match OR by proximity
                    let isExactBuildingMatch = (data["buildingId"] as? String) == buildingId
                    
                    if !isExactBuildingMatch {
                        // Not an exact match, check proximity
                        let sessionLocation = CLLocation(
                            latitude: geoPoint.latitude,
                            longitude: geoPoint.longitude
                        )
                        let distance = sessionLocation.distance(from: buildingLocation)
                        
                        // Skip if not within radius
                        if distance > radius {
                            continue
                        }
                    }
                    
                    // Get the session duration, defaulting to 0 if missing
                    var sessionDuration = 0
                    if let duration = data["actualDuration"] {
                        // First debug what we're actually getting
                        print("👾 Raw actualDuration: \(duration), type: \(type(of: duration))")
                        
                        // Handle all possible Firestore data types
                        if let intDuration = duration as? Int {
                            sessionDuration = intDuration
                        } else if let doubleDuration = duration as? Double {
                            sessionDuration = Int(doubleDuration)
                        } else if let numberDuration = duration as? NSNumber {
                            sessionDuration = numberDuration.intValue
                        } else if let stringDuration = duration as? String, let parsed = Int(stringDuration) {
                            sessionDuration = parsed
                        } else {
                            // Try to safely convert any value to Int
                            let description = "\(duration)"
                            if let parsed = Int(description) {
                                sessionDuration = parsed
                            } else if let parsed = Double(description), parsed.isFinite {
                                sessionDuration = Int(parsed)
                            }
                        }
                    }

                    // Safety check - make sure we don't have zero for valid sessions
                    if sessionDuration <= 0 && data["lastFlipWasSuccessful"] as? Bool == true {
                        print("⚠️ Found zero or negative duration for successful session, using actual duration")
                        // Try to calculate actual duration from timestamps
                        if let startTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
                           let endTime = (data["sessionEndTime"] as? Timestamp)?.dateValue() {
                            let elapsedSeconds = endTime.timeIntervalSince(startTime)
                            sessionDuration = max(1, Int(elapsedSeconds / 60))
                            print("📱 Recalculated duration: \(sessionDuration) min from \(Int(elapsedSeconds)) seconds")
                        }
                    }

                    print("📱 Final session duration: \(sessionDuration) minutes")
                    
                    // Get username safely
                    let username = data["username"] as? String ?? "User"
                    
                    // Calculate distance for display
                    let sessionLocation = CLLocation(
                        latitude: geoPoint.latitude,
                        longitude: geoPoint.longitude
                    )
                    let distance = sessionLocation.distance(from: buildingLocation)
                    
                    // Only show distance for friends and current user
                    let showDistance = userId == currentUserId || friendIds.contains(userId)
                    let displayDistance = showDistance ? distance : 0
                    
                    // Update the user's total time
                    if let existingData = userWeeklyData[userId] {
                        // Add to existing record
                        userWeeklyData[userId] = (
                            userId: userId,
                            username: existingData.username,
                            sessionCount: existingData.sessionCount + 1,
                            distance: displayDistance,
                            isFriend: friendIds.contains(userId),
                            isCurrentUser: userId == currentUserId
                        )
                    } else {
                        // Create new record
                        userWeeklyData[userId] = (
                            userId: userId,
                            username: username,
                            sessionCount: 1,
                            distance: displayDistance,
                            isFriend: friendIds.contains(userId),
                            isCurrentUser: userId == currentUserId
                        )
                    }
                }
                
                // Convert aggregated data to leaderboard entries
                let entries = userWeeklyData.values.map { userData in
                    RegionalLeaderboardEntry(
                        id: UUID().uuidString,
                        userId: userData.userId,
                        username: userData.username,
                        totalWeeklyTime: 0, // We'll keep this field but don't use it
                        sessionCount: userData.sessionCount,
                        distance: userData.distance,
                        isFriend: userData.isFriend,
                        isCurrentUser: userData.isCurrentUser
                    )
                // IMPORTANT: Sort by session count instead of time
                }.sorted { $0.sessionCount > $1.sessionCount }
                // Take top 10 for display
                DispatchQueue.main.async {
                    self.leaderboardEntries = entries.prefix(10).map { $0 }
                    self.isLoading = false
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
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let placemark = placemarks?.first, let locality = placemark.locality {
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
    let totalWeeklyTime: Int // Changed from duration to totalWeeklyTime (in minutes)
    let sessionCount: Int    // New: count of sessions for this user this week
    let distance: Double     // In meters
    let isFriend: Bool
    let isCurrentUser: Bool
    
    var formattedDistance: String {
        if isCurrentUser {
            return ""
        } else if distance < 500 {
            return "nearby"
        } else if distance < 1609 { // Less than a mile
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
