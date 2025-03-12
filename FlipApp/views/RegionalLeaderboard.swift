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
                
                // Leaderboard entries
                VStack(spacing: 8) {
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
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        // Query all session locations from this week
        let query = db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .order(by: "actualDuration", descending: true)
            .limit(to: 50) // Get a reasonable number to filter
        
        // Process query
        var matchingSessions: [SessionWithLocation] = []
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self,
                  let snapshot = snapshot else {
                self?.isLoading = false
                return
            }
            
            for document in snapshot.documents {
                let data = document.data()
                
                // Extract session info
                guard let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let geoPoint = data["location"] as? GeoPoint,
                      let actualDuration = data["actualDuration"] as? Int,
                      let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool,
                      let sessionStartTime = (data["sessionStartTime"] as? Timestamp)?.dateValue() else {
                    continue
                }
                
                // Check if session is from this week and successful
                if calendar.compare(sessionStartTime, to: weekStart, toGranularity: .weekOfYear) == .orderedSame && wasSuccessful {
                    // Calculate distance
                    let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    let distance = sessionLocation.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                    
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
                
                // Fetch all sessions in this building
                self.fetchBuildingTopSessions(building: building, friendIds: friendIds)
            }
    }
    
    // Improved fetchBuildingTopSessions method with better error handling and debugging
    func fetchBuildingTopSessions(building: BuildingInfo, friendIds: [String]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Use the standardized building ID that's already stored in the BuildingInfo struct
        let buildingId = building.id
        
        print("🔍 Querying sessions for building ID: \(buildingId)")
        print("🏢 Building coordinates: \(building.coordinate.latitude), \(building.coordinate.longitude)")
        
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
                .order(by: "actualDuration", descending: true)
                .limit(to: 50)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("❌ Error in building ID search: \(error.localizedDescription)")
                        self.tryProximitySearch(
                            buildingLocation: buildingLocation,
                            radius: radius,
                            usernames: usernames,
                            friendIds: friendIds,
                            currentUserId: currentUserId
                        )
                        return
                    }
                    
                    if let documents = snapshot?.documents, !documents.isEmpty {
                        print("📊 Found \(documents.count) sessions with exact building ID match")
                        self.processSessionDocuments(
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
                            currentUserId: currentUserId
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
        currentUserId: String
    ) {
        print("🔍 Trying proximity search")
        
        firebaseManager.db.collection("session_locations")
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .order(by: "actualDuration", descending: true)
            .limit(to: 100)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error in proximity search: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No documents found in proximity search")
                    self.isLoading = false
                    return
                }
                
                print("🔍 Filtering \(documents.count) sessions by proximity")
                
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
                
                print("📊 Found \(nearbyDocuments.count) sessions within \(Int(radius))m of building")
                self.processSessionDocuments(
                    nearbyDocuments,
                    buildingLocation,
                    friendIds,
                    currentUserId,
                    usernames: usernames
                )
            }
    }
    
    // Improved processSessionDocuments method with username cache
    private func processSessionDocuments(
        _ documents: [QueryDocumentSnapshot],
        _ buildingLocation: CLLocation,
        _ friendIds: [String],
        _ currentUserId: String,
        usernames: [String: String]
    ) {
        var matchingSessions: [SessionWithLocation] = []
        
        for document in documents {
                let data = document.data()
                
                // Extract session info
                guard let userId = data["userId"] as? String,
                      let actualDuration = data["actualDuration"] as? Int,
                      let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool,
                      let geoPoint = data["location"] as? GeoPoint else {
                    print("⚠️ Skipping session - missing required fields")
                    continue
                }
                
                // Prioritize different username sources with multiple fallbacks
                var username: String
                
                // 1. First try to get from document (most reliable source)
                if let docUsername = data["username"] as? String, !docUsername.isEmpty {
                    username = docUsername
                }
                // 2. Next try to get from our cached user data
                else if let cachedUserData = userCache[userId] {
                    username = cachedUserData.username
                }
                // 3. Then try to get from the username parameter (passed from earlier query)
                else if let passedUsername = usernames[userId], !passedUsername.isEmpty {
                    username = passedUsername
                }
                // 4. Final fallback - uses user prefix
                else {
                    username = "User \(userId.prefix(4))"
                    
                    // Start a background load to try to get the real username for next time
                    DispatchQueue.global(qos: .background).async {
                        FirebaseManager.shared.db.collection("users").document(userId).getDocument { document, error in
                            if let userData = document?.data(), let realUsername = userData["username"] as? String, !realUsername.isEmpty {
                                print("✅ Background loaded username for \(userId): \(realUsername)")
                                
                                // Add to cache
                                let cacheItem = UserCacheItem(
                                    userId: userId,
                                    username: realUsername,
                                    profileImageURL: userData["profileImageURL"] as? String
                                )
                                
                                DispatchQueue.main.async {
                                    self.userCache[userId] = cacheItem
                                }
                            }
                        }
                    }
                }
            // Create session data structure
            let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
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
        
        // Log final number of entries
        print("📊 Final regional leaderboard entries: \(entries.count)")
        
        DispatchQueue.main.async {
            self.leaderboardEntries = entries
            self.isLoading = false
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
