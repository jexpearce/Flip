//
//  RegionalLeaderboard.swift
//  FlipApp
//
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct RegionalLeaderboard: View {
    @ObservedObject var viewModel: RegionalLeaderboardViewModel
    
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
            // Title
            HStack {
                Text("REGIONAL LEADERBOARD")
                    .font(.system(size: 14, weight: .black))
                    .tracking(3)
                    .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255)) // Reddish tint
                    .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 6)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 239/255, green: 68/255, blue: 68/255),
                                Color(red: 248/255, green: 113/255, blue: 113/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.5), radius: 4)
                
                Spacer()
                
                if viewModel.radius == 5 {
                    Text("5 MILE RADIUS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("\(viewModel.radius) MILE RADIUS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Location display
            if let locationName = viewModel.locationName {
                HStack {
                    Text(locationName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.top, -5)
                .padding(.bottom, 5)
            }
            
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
                Text("No active users in your area this week")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            } else {
                // Leaderboard entries
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.leaderboardEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            // Rank with medal indicator
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.white)
                                    .frame(width: 24)
                                
                                // Medal for top 3
                                if index < 3 {
                                    ZStack {
                                        Circle()
                                            .fill(index == 0 ? goldColor : (index == 1 ? silverColor : bronzeColor))
                                            .frame(width: 22, height: 22)
                                        
                                        Image(systemName: "medal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.2), radius: 1)
                                    }
                                }
                            }
                            
                            // Username
                            Text(entry.username)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Only show distance for friends
                            if entry.distance > 0 && entry.isFriend {
                                Text("\(entry.formattedDistance)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Friend icon if a friend
                            if entry.isFriend {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                            }
                            
                            // Duration
                            Text("\(entry.duration) min")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255)) // Reddish tint
                                .shadow(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.3), radius: 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
                
                // Radius control
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
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 153/255, green: 27/255, blue: 27/255).opacity(0.4),
                                Color(red: 127/255, green: 29/255, blue: 29/255).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
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
    }
}

// ViewModel for Regional Leaderboard
class RegionalLeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [RegionalLeaderboardEntry] = []
    @Published var isLoading = false
    @Published var radius: Int = 5 // Default radius in miles
    @Published var locationName: String?
    
    private var currentLocation: CLLocation?
    private let firebaseManager = FirebaseManager.shared
    private let geocoder = CLGeocoder()
    
    func loadRegionalLeaderboard(near location: CLLocation) {
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
                if calendar.isDate(sessionStartTime, inSameWeekAs: weekStart) && wasSuccessful {
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

// Data model for regional leaderboard entries
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

// Helper model for session with location data
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