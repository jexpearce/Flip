import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct RegionalLeaderboard: View {
    @ObservedObject var viewModel: RegionalLeaderboardViewModel
    @State private var selectedUserId: String?
    @State private var showUserProfile = false
    
    // Medal colors
    private let goldColor = LinearGradient(
        colors: [Color(red: 255/255, green: 215/255, blue: 0/255), Color(red: 212/255, green: 175/255, blue: 55/255)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let silverColor = LinearGradient(
        colors: [Color(red: 192/255, green: 192/255, blue: 192/255), Color(red: 169/255, green: 169/255, blue: 169/255)],
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
            // Title section
            VStack(spacing: 4) {
                // Main title
                Text(viewModel.isBuildingSpecific ? "LONGEST FLIP OF THE WEEK" : "REGIONAL LEADERBOARD")
                    .font(.system(size: 16, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .shadow(color: viewModel.isBuildingSpecific ?
                            Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5) :
                            Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Subtitle with location
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
                                Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.6),
                                Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.6),
                                Color(red: 248/255, green: 113/255, blue: 113/255).opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
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
                // Leaderboard entries
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.leaderboardEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                        Button(action: {
                            self.selectedUserId = entry.userId
                            self.showUserProfile = true
                        }) {
                            HStack(spacing: 12) {
                                // Rank number
                                Text("\(index + 1)")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(.white)
                                    .frame(width: 24)
                                
                                // Medal for top 3
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
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
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
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: viewModel.isBuildingSpecific ?
                            [
                                Color(red: 146/255, green: 123/255, blue: 21/255).opacity(0.4),
                                Color(red: 133/255, green: 109/255, blue: 7/255).opacity(0.3)
                            ] :
                                [
                                    Color(red: 153/255, green: 27/255, blue: 27/255).opacity(0.4),
                                    Color(red: 127/255, green: 29/255, blue: 29/255).opacity(0.3)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.07))
                
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1)
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
    
    var body: some View {
        Group {
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
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
        FirebaseManager.shared.db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.imageURL = data["profileImageURL"] as? String
                self.username = data["username"] as? String ?? ""
            }
        }
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


// STRUCTURE 2: RegionalLeaderboardViewModel class - moved outside struct
class RegionalLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [RegionalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var radius: Int = 5 // Default radius in miles
    @Published var locationName: String?
    @Published var isBuildingSpecific: Bool = false // Add this property here
    
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
extension RegionalLeaderboardViewModel {
    
    func loadBuildingLeaderboard(building: BuildingInfo) {
        isBuildingSpecific = true
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
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
                
                // Set the building name for display
                self.locationName = building.name
                
                // Fetch all sessions in this building
                self.fetchBuildingTopSessions(building: building, friendIds: friendIds)
            }
    }
    private func processSessionDocuments(_ documents: [QueryDocumentSnapshot], _ buildingLocation: CLLocation, _ friendIds: [String], _ currentUserId: String) {
        var matchingSessions: [SessionWithLocation] = []
        
        for document in documents {
            let data = document.data()
            
            // Extract session info
            guard let userId = data["userId"] as? String,
                  let username = data["username"] as? String,
                  let geoPoint = data["location"] as? GeoPoint,
                  let actualDuration = data["actualDuration"] as? Int,
                  let wasSuccessful = data["lastFlipWasSuccessful"] as? Bool else {
                continue
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
        print("📊 Final leaderboard entries: \(entries.count)")
        
        DispatchQueue.main.async {
            self.leaderboardEntries = entries
            self.isLoading = false
        }
    }
    private func fetchBuildingTopSessions(building: BuildingInfo, friendIds: [String]) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Use the standardized building ID that's already stored in the BuildingInfo struct
        let buildingId = building.id
        
        print("🔍 Querying sessions for building ID: \(buildingId)")
        print("🏢 Building coordinates: \(building.coordinate.latitude), \(building.coordinate.longitude)")
        
        // Get the building's location as a CLLocation
        let buildingLocation = CLLocation(latitude: building.coordinate.latitude, longitude: building.coordinate.longitude)
        
        // Use exact building ID match only - no proximity-based fallback
        // This ensures sessions only appear in their own building's leaderboard
        db.collection("session_locations")
            .whereField("buildingId", isEqualTo: buildingId)
            .whereField("lastFlipWasSuccessful", isEqualTo: true)
            .order(by: "actualDuration", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching building sessions: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No documents in snapshot")
                    self.leaderboardEntries = []
                    self.isLoading = false
                    return
                }
                
                print("📊 Found \(documents.count) sessions with exact building ID match")
                self.processSessionDocuments(documents, buildingLocation, friendIds, currentUserId)
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