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
                    
                    Text(viewModel.isBuildingSpecific ? "LONGEST FLIP OF THE WEEK" : "REGIONAL LEADERBOARD")
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
                    
                    Text("DURATION")
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
                                Text("\(entry.duration) min")
                                    .onAppear {
                                        print("⏱️ Displaying duration for \(entry.username): \(entry.duration)")
                                    }
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(viewModel.isBuildingSpecific ?
                                                     Color(red: 234/255, green: 179/255, blue: 8/255) :
                                                        Color(red: 239/255, green: 68/255, blue: 68/255))
                                    .shadow(color: viewModel.isBuildingSpecific ?
                                            Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3) :
                                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3), radius: 4)
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
// This component fetches and displays user profiles
struct UserProfileSheet: View {
    let userId: String
    @State private var user: FirebaseManager.FlipUser?
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Group {
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
        }
        .onAppear {
            loadUser()
        }
    }
    
    private func loadUser() {
        FirebaseManager.shared.db.collection("users").document(userId).getDocument { snapshot, error in
            isLoading = false
            if let error = error {
                print("Error loading user: \(error.localizedDescription)")
                return
            }
            
            if let userData = try? snapshot?.data(as: FirebaseManager.FlipUser.self) {
                self.user = userData
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

    private func fetchCompleteUserData() {
        print("🔍 Fetching complete user data for: \(userId)")
        
        // First try with dispatch group and multiple retry strategy
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

// STRUCTURE 2: RegionalLeaderboardViewModel class - moved outside struct
class RegionalLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [RegionalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var radius: Int = 5 // Default radius in miles
    @Published var locationName: String?
    @Published var isBuildingSpecific: Bool = false // Add this property here
    
    var userCache: [String: UserCacheItem] = [:]
    
    private var currentLocation: CLLocation?
    private let firebaseManager = FirebaseManager.shared
    private let geocoder = CLGeocoder()
    
    func loadRegionalLeaderboard(near location: CLLocation) {
        isBuildingSpecific = false
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        currentLocation = location
        isLoading = true
        
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
                
                // Reverse geocode location
                self.getLocationName(for: location)
                
                // Calculate the coordinates
                let center = location.coordinate
                let radiusInMeters = Double(self.radius) * 1609.34 // Convert miles to meters
                
                // Query for sessions within radius
                self.fetchRegionalTopSessions(center: center, radiusInMeters: radiusInMeters, friendIds: friendIds)
            }
    }
    
    func increaseRadius() {
        radius = min(radius + 1, 20)
        if let location = currentLocation {
            loadRegionalLeaderboard(near: location)
        }
    }
    
    func decreaseRadius() {
        radius = max(radius - 1, 1)
        if let location = currentLocation {
            loadRegionalLeaderboard(near: location)
        }
    }
    
    private func getLocationName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    if let locality = placemark.locality {
                        self?.locationName = locality
                    } else if let area = placemark.administrativeArea {
                        self?.locationName = area
                    } else {
                        self?.locationName = nil
                    }
                } else {
                    self?.locationName = nil
                }
            }
        }
    }
    
    private func fetchRegionalTopSessions(center: CLLocationCoordinate2D, radiusInMeters: Double, friendIds: [String]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate the current week's start date (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        components.weekday = 2  // Monday (2 = Monday in iOS Calendar)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let weekStart = calendar.date(from: components) else {
            print("❌ Error calculating week start")
            self.isLoading = false
            return
        }
        
        print("🗓️ Current week starts at: \(weekStart)")
        
        // Get the user's location as a CLLocation
        let userLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        // Process query
        var matchingSessions: [SessionWithLocation] = []
        
        // Query all session locations from this week
        db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .whereField("sessionStartTime", isGreaterThan: Timestamp(date: weekStart)) // Weekly filter
            .order(by: "sessionStartTime")
            .order(by: "actualDuration", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot else {
                    self?.isLoading = false
                    return
                }
                
                print("📊 Found \(snapshot.documents.count) sessions this week")
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    // Extract session info
                    guard let userId = data["userId"] as? String,
                          let username = data["username"] as? String,
                          let geoPoint = data["location"] as? GeoPoint,
                          let actualDuration = data["actualDuration"] as? Int,
                          let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool,
                          let _ = (data["sessionStartTime"] as? Timestamp)?
                        .dateValue() else {
                        continue
                    }
                    
                    // Only include successful sessions
                    if !wasSuccessful {
                        continue
                    }
                    
                    // Calculate distance
                    let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    let distance = sessionLocation.distance(from: userLocation)
                    
                    // Only include if within radius
                    if distance <= radiusInMeters {
                        // Only show distance for friends and current user
                        let showDistance = userId == currentUserId || friendIds.contains(userId)
                        
                        let session = SessionWithLocation(
                            id: document.documentID,
                            userId: userId,
                            username: username,
                            duration: actualDuration,
                            location: sessionLocation,
                            distance: showDistance ? distance : 0, // Only set distance for friends
                            isFriend: friendIds.contains(userId),
                            isCurrentUser: userId == currentUserId
                        )
                        
                        matchingSessions.append(session)
                    }
                }
                
                // Group by user, find max duration for each
                var userBestSessions: [String: SessionWithLocation] = [:]
                
                for session in matchingSessions {
                    if let existingBest = userBestSessions[session.userId],
                       existingBest.duration >= session.duration {
                        continue
                    }
                    
                    userBestSessions[session.userId] = session
                }
                
                
                // Convert to leaderboard entries and sort
                let entries = userBestSessions.values.map { session in
                    RegionalLeaderboardEntry(
                        id: session.id,
                        userId: session.userId,
                        username: session.username,
                        duration: session.duration,
                        distance: session.isCurrentUser ? 0 : session.distance,
                        isFriend: session.isFriend,
                        isCurrentUser: session.isCurrentUser
                    )
                }.sorted { $0.duration > $1.duration }
                
                DispatchQueue.main.async {
                    self.leaderboardEntries = entries
                    self.isLoading = false
                }
            }
    }
}
    
// STRUCTURE 3: Extension for RegionalLeaderboardViewModel - moved outside class

// Extension for RegionalLeaderboardViewModel to handle buildings
extension RegionalLeaderboardViewModel {
    
    // Update in RegionalLeaderboardViewModel
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
        
        // Use the standardized building ID that's already stored in the BuildingInfo struct
        let buildingId = building.id
        
        // Get the building's location as a CLLocation
        let buildingLocation = CLLocation(latitude: building.coordinate.latitude, longitude: building.coordinate.longitude)
        let radius = 100.0 // Search within 100 meters of the building
        
        // First, fetch all users to ensure we have usernames
        var usernames: [String: String] = [:]
        let userGroup = DispatchGroup()
        
        // Always include current user
        userGroup.enter()
        db.collection("users").document(currentUserId).getDocument { document, error in
            defer { userGroup.leave() }
            
            if let document = document, let username = document.data()?["username"] as? String {
                usernames[currentUserId] = username
            }
        }
        
        // Fetch friend usernames
        for friendId in friendIds {
            userGroup.enter()
            db.collection("users").document(friendId).getDocument { document, error in
                defer { userGroup.leave() }
                
                if let document = document, let username = document.data()?["username"] as? String {
                    usernames[friendId] = username
                }
            }
        }
        
        userGroup.notify(queue: .main) {
            // Use exact building ID match first
            db.collection("session_locations")
                .whereField("buildingId", isEqualTo: buildingId)
                .whereField("lastFlipWasSuccessful", isEqualTo: true)
                .whereField("sessionStartTime", isGreaterThan: Timestamp(date: weekStart))
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.tryProximitySearch(
                            buildingLocation: buildingLocation,
                            radius: radius,
                            usernames: usernames,
                            friendIds: friendIds,
                            currentUserId: currentUserId,
                            weekStart: weekStart
                        )
                        return
                    }
                    
                    if let documents = snapshot?.documents, !documents.isEmpty {
                        self.processSessionDocumentsWithImprovedDuration(
                            documents,
                            buildingLocation,
                            friendIds,
                            currentUserId,
                            usernames: usernames
                        )
                    } else {
                        // If no exact matches, try proximity search
                        self.tryProximitySearch(
                            buildingLocation: buildingLocation,
                            radius: radius,
                            usernames: usernames,
                            friendIds: friendIds,
                            currentUserId: currentUserId,
                            weekStart: weekStart
                        )
                    }
                }
        }
    }
    
    // Helper method for proximity search
    private func tryProximitySearch(
        buildingLocation: CLLocation,
        radius: Double,
        usernames: [String: String],
        friendIds: [String],
        currentUserId: String,
        weekStart: Date
    ) {
        firebaseManager.db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .whereField("sessionStartTime", isGreaterThan: Timestamp(date: weekStart))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                // Filter by proximity to building
                var nearbyDocuments: [QueryDocumentSnapshot] = []
                
                for document in documents {
                    if let geoPoint = document.data()["location"] as? GeoPoint {
                        let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                        let distance = sessionLocation.distance(from: buildingLocation)
                        
                        if distance <= radius {
                            nearbyDocuments.append(document)
                        }
                    }
                }
                
                self.processSessionDocumentsWithImprovedDuration(
                    nearbyDocuments,
                    buildingLocation,
                    friendIds,
                    currentUserId,
                    usernames: usernames
                )
            }
    }
    
    private func processSessionDocumentsWithImprovedDuration(
        _ documents: [QueryDocumentSnapshot],
        _ buildingLocation: CLLocation,
        _ friendIds: [String],
        _ currentUserId: String,
        usernames: [String: String]
    ) {
        var matchingSessions: [SessionWithLocation] = []
        
        // First gather all unique user IDs to fetch usernames in batch
        var userIds = Set<String>()
        for document in documents {
            if let userId = document.data()["userId"] as? String {
                userIds.insert(userId)
            }
        }
        
        // Fetch all user data in a batch to ensure we have usernames
        let group = DispatchGroup()
        var fetchedUsernames: [String: String] = [:]
        
        for userId in userIds {
            // Skip if we already have this username
            if let existingUsername = usernames[userId], !existingUsername.isEmpty {
                fetchedUsernames[userId] = existingUsername
                continue
            }
            
            // Try to get from cache first
            if let cachedUser = userCache[userId], !cachedUser.username.isEmpty {
                fetchedUsernames[userId] = cachedUser.username
                continue
            }
            
            // Otherwise fetch from Firestore
            group.enter()
            FirebaseManager.shared.db.collection("users").document(userId).getDocument { document, error in
                defer { group.leave() }
                
                if let document = document, let username = document.data()?["username"] as? String, !username.isEmpty {
                    fetchedUsernames[userId] = username
                    
                    // Also cache for future use
                    let cacheItem = UserCacheItem(
                        userId: userId,
                        username: username,
                        profileImageURL: document.data()?["profileImageURL"] as? String
                    )
                    self.userCache[userId] = cacheItem
                } else {
                    fetchedUsernames[userId] = "User \(userId.prefix(4))"
                }
            }
        }
        
        // Wait for all fetches to complete
        group.notify(queue: .main) {
            // Now process each document with the fetched usernames
            for document in documents {
                let data = document.data()
                
                // Extract session info with better error handling
                guard let userId = data["userId"] as? String else {
                    continue
                }
                
                let sessionLocation = CLLocation(
                    latitude: (data["location"] as? GeoPoint)?.latitude ?? 0,
                    longitude: (data["location"] as? GeoPoint)?.longitude ?? 0
                )
                
                // Skip invalid locations
                if sessionLocation.coordinate.latitude == 0 && sessionLocation.coordinate.longitude == 0 {
                    continue
                }
                
                // ***CRITICAL FIX*** - Extract duration with careful type handling
                var actualDuration = 0

                // Check for actual duration with correct type handling
                if let duration = data["actualDuration"] as? Int {
                    actualDuration = duration
                } else if let duration = data["actualDuration"] as? Double {
                    actualDuration = Int(duration)
                } else if let duration = data["actualDuration"] as? NSNumber {
                    actualDuration = duration.intValue
                } else if let durationString = data["actualDuration"] as? String, let duration = Int(durationString) {
                    // Also handle string values just in case
                    actualDuration = duration
                }
                // Then try sessionDuration if actualDuration wasn't found
                else if let duration = data["sessionDuration"] as? Int {
                    actualDuration = duration
                } else if let duration = data["sessionDuration"] as? Double {
                    actualDuration = Int(duration)
                } else if let duration = data["sessionDuration"] as? NSNumber {
                    actualDuration = duration.intValue
                } else if let durationString = data["sessionDuration"] as? String, let duration = Int(durationString) {
                    actualDuration = duration
                }
                // If we still don't have a duration, calculate it from timestamps
                else if let startTime = (data["sessionStartTime"] as? Timestamp)?.dateValue(),
                         let endTime = (data["sessionEndTime"] as? Timestamp)?.dateValue() {
                    let seconds = endTime.timeIntervalSince(startTime)
                    actualDuration = Int(seconds / 60) // Convert to minutes
                }
                
                // Get username with better resolution
                let username: String
                if let fetchedUsername = fetchedUsernames[userId], !fetchedUsername.isEmpty {
                    username = fetchedUsername
                } else if let docUsername = data["username"] as? String, !docUsername.isEmpty {
                    username = docUsername
                } else {
                    username = "User \(userId.prefix(4))"
                }
                
                let distance = sessionLocation.distance(from: buildingLocation)
                
                // Only show distance for friends and current user
                let showDistance = userId == currentUserId || friendIds.contains(userId)
                
                let session = SessionWithLocation(
                    id: document.documentID,
                    userId: userId,
                    username: username,
                    duration: actualDuration,
                    location: sessionLocation,
                    distance: showDistance ? distance : 0,
                    isFriend: friendIds.contains(userId),
                    isCurrentUser: userId == currentUserId
                )
                
                matchingSessions.append(session)
            }
            
            // Group by user, find max duration for each
            var userBestSessions: [String: SessionWithLocation] = [:]
            
            for session in matchingSessions {
                if let existingBest = userBestSessions[session.userId],
                   existingBest.duration >= session.duration {
                    continue
                }
                
                userBestSessions[session.userId] = session
            }
            
            // Convert to leaderboard entries and sort
            let entries = userBestSessions.values.map { session in
                RegionalLeaderboardEntry(
                    id: session.id,
                    userId: session.userId,
                    username: session.username,
                    duration: session.duration,
                    distance: session.isCurrentUser ? 0 : session.distance,
                    isFriend: session.isFriend,
                    isCurrentUser: session.isCurrentUser
                )
            }.sorted { $0.duration > $1.duration }
            
            // Take top 10 only
            let limitedEntries = entries.prefix(10).map { $0 }
            
            DispatchQueue.main.async {
                self.leaderboardEntries = limitedEntries
                self.isLoading = false
            }
        }
    }
}

// STRUCTURE 4: RegionalLeaderboardEntry struct - moved outside
struct RegionalLeaderboardEntry: Identifiable {
    let id: String
    let userId: String
    let username: String
    let duration: Int
    let distance: Double // In meters
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
