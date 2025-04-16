import FirebaseFirestore
import MapKit
import SwiftUI

enum MapStyleType {
    case standard
    case hybrid
}

// Add this ViewModel to load user data for the card
class ScoreViewModel: ObservableObject {
    @Published var userScore: Double = 3.0
    @Published var userObject: FirebaseManager.FlipUser = FirebaseManager.FlipUser(
        id: "",
        username: "User",
        totalFocusTime: 0,
        totalSessions: 0,
        longestSession: 0,
        friends: [],
        friendRequests: [],
        sentRequests: [],
        profileImageURL: nil,
        blockedUsers: []
    )

    private let db = Firestore.firestore()

    func loadUserData(userId: String) {
        // Extract clean userId from potential composite IDs (like userId_hist_1)
        let cleanUserId = userId.split(separator: "_").first.map(String.init) ?? userId

        db.collection("users").document(cleanUserId)
            .getDocument { [weak self] document, error in
                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    DispatchQueue.main.async { self?.userObject = userData }
                }

                // Load score
                if let data = document?.data(), let score = data["score"] as? Double {
                    DispatchQueue.main.async { self?.userScore = score }
                }
            }
    }
}
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showPrivacySettings = false
    @State private var selectedFriend: FriendLocation? = nil
    @State private var mapStyle: MapStyleType = .standard
    @EnvironmentObject var viewRouter: ViewRouter
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared
    @StateObject private var mapConsentManager = MapConsentManager.shared
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // Custom styled map
            Map(
                coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.friendLocations
            ) { friend in
                MapAnnotation(coordinate: friend.coordinate) {
                    FriendMapMarker(friend: friend)
                        .onTapGesture { withAnimation(.spring()) { selectedFriend = friend } }
                }
            }
            .mapStyle(mapStyle == .standard ? .standard : .hybrid).preferredColorScheme(.dark)  // Force dark mode for map
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Check location permissions when view appears
                locationPermissionManager.checkRegionalAvailability { hasPermission in
                    if !hasPermission {
                        // If location is disabled, dismiss the view
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }

            // Add alert for when location is disabled
            .alert("Location Access Required", isPresented: $locationPermissionManager.showLocationDisabledAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Location access is required for this feature. Please enable location access in your device settings.")
            }

            // Back button overlay
            VStack {
                HStack {
                    // Back button
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            // Button background
                            Circle().fill(Theme.mutedPurple.opacity(0.85))
                                .frame(width: 46, height: 46)
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                                .shadow(color: Color.black.opacity(0.4), radius: 6)

                            // X icon
                            Image(systemName: "xmark").font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Text("FRIENDS MAP").font(.system(size: 18, weight: .bold)).tracking(2)
                        .foregroundColor(.white)

                    Spacer()

                    // Settings button
                    Button(action: { showPrivacySettings = true }) {
                        Image(systemName: "gear").font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white).frame(width: 44, height: 44)
                            .background(
                                ZStack {
                                    Circle().fill(Theme.mutedPurple.opacity(0.8))
                                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.mutedPurple, Theme.mutedPurple.opacity(0),
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 100).edgesIgnoringSafeArea(.top)
                )

                Spacer()

                // Map controls and toggle at the bottom
                VStack(spacing: 15) {
                    // Map posting toggle
                    if mapConsentManager.hasAcceptedMapPrivacy {
                        HStack(alignment: .top, spacing: 10) {
                            // Map icon
                            ZStack {
                                Circle()
                                    .fill(
                                        mapConsentManager.postToMap
                                            ? Theme.yellow.opacity(0.2) : Color.white.opacity(0.08)
                                    )
                                    .frame(width: 28, height: 28)
                                Image(systemName: "mappin.and.ellipse").font(.system(size: 14))
                                    .foregroundColor(
                                        mapConsentManager.postToMap
                                            ? Theme.yellow : .white.opacity(0.7)
                                    )
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        mapConsentManager.hasExpired ? Theme.yellow : Color.clear,
                                        lineWidth: 2
                                    )
                                    .scaleEffect(mapConsentManager.hasExpired ? 1.2 : 1.0)
                                    .opacity(mapConsentManager.hasExpired ? 0.6 : 0)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                        value: mapConsentManager.hasExpired
                                    )
                            )
                            // Text and toggle
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("POST TO MAP").font(.system(size: 12, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(
                                            mapConsentManager.postToMap
                                                ? Theme.yellow : .white.opacity(0.8)
                                        )
                                    Spacer()
                                    // Toggle switch
                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: { mapConsentManager.postToMap },
                                            set: { mapConsentManager.togglePostToMap($0) }
                                        )
                                    )
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: Theme.yellow))
                                    .scaleEffect(0.8)
                                }
                                // Status text - shows expiry or prompt to enable
                                Text(
                                    mapConsentManager.postToMap
                                        ? "Auto-expires in \(mapConsentManager.formattedExpiryTime())"
                                        : "Enable to share sessions on map"
                                )
                                .font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }

                    // Map controls
                    HStack {
                        Spacer()

                        VStack(spacing: 15) {
                            // Refresh button
                            Button(action: viewModel.refreshLocations) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Theme.darkRed, Theme.darkerRed],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .opacity(0.9)

                                            Circle().fill(Color.white.opacity(0.1))

                                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                            }

                            // Locate me button
                            Button(action: viewModel.centerOnUser) {
                                Image(systemName: "location").font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white).frame(width: 44, height: 44)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Theme.darkRed, Theme.darkerRed],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .opacity(0.9)

                                            Circle().fill(Color.white.opacity(0.1))

                                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                            }

                            // Map style toggle
                            Button(action: {
                                mapStyle = mapStyle == .standard ? .hybrid : .standard
                            }) {
                                Image(systemName: mapStyle == .standard ? "globe" : "map")
                                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Theme.darkRed, Theme.darkerRed],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .opacity(0.9)

                                            Circle().fill(Color.white.opacity(0.1))

                                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4)
                            }
                        }
                        .padding(.trailing).padding(.bottom, 30)
                    }
                }
                .padding(.bottom, 20)
            }

            // Friend preview popup when a friend is selected
            if let friend = selectedFriend {
                VStack {
                    Spacer()

                    FriendPreviewCard(
                        friend: friend,
                        onDismiss: { withAnimation { selectedFriend = nil } },
                        onViewProfile: {}
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)  // Above tab bar
                    .padding(.horizontal)
                }
            }

            // Location permission alert overlay
//            if locationPermissionManager.showCustomAlert {
//                LocationPermissionAlert(
//                    isPresented: $locationPermissionManager.showCustomAlert,
//                    onContinue: { locationPermissionManager.requestSystemPermission() }
//                )
//                .zIndex(10)  // Ensure it's above other content
//            }
        }  // Move .sheet modifier outside of ZStack
        .sheet(isPresented: $showPrivacySettings) { MapPrivacySettingsView() }
        .onAppear {
            // Start tracking and refresh locations since consent is already handled
            viewModel.startLocationTracking()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { viewModel.refreshLocations() }
        }
        .onDisappear {
            viewModel.stopLocationTracking()
            Task { @MainActor in LocationHandler.shared.completelyStopLocationUpdates() }
        }
    }
}
struct FriendMapMarker: View {
    let friend: FriendLocation
    @State private var animate = false
    @State private var profileImage: Image?
    @State private var isLoading = true
    @State private var loadingId: String = ""

    // In FriendMapMarker - statusColor computed property:
    private var statusColor: Color {
        if friend.isHistorical {
            // Historical sessions - with correct transparency based on index
            let baseColor =
                friend.lastFlipWasSuccessful
                ? Theme.mutedGreen
                :  // Success green
                Theme.mutedRed  // Failure red

            // Apply opacity based on session index
            switch friend.sessionIndex {
            case 1: return baseColor.opacity(0.8)  // Most recent historical
            case 2: return baseColor.opacity(0.6)  // Second most recent
            case 3: return baseColor.opacity(0.4)  // Third most recent
            default: return baseColor.opacity(0.3)  // Fallback
            }
        }
        else if friend.isCurrentlyFlipped {
            // Live session - use blue instead of green
            return Theme.standardBlue  // Blue
        }
        else {
            // Completed or failed session - FIXED
            if friend.lastFlipWasSuccessful {
                // Success - green
                return Theme.mutedGreen
            }
            else {
                // Failed - red - ENSURE this branch is properly reached
                return Theme.mutedRed
            }
        }
    }

    private var markerSize: CGFloat {
        // Slightly smaller for historical sessions based on recency
        if friend.isHistorical {
            switch friend.sessionIndex {
            case 1: return 32  // Most recent historical
            case 2: return 28  // Second most recent
            case 3: return 24  // Third most recent
            default: return 22
            }
        }
        else {
            return 36  // Current/Live session
        }
    }

    var body: some View {
        ZStack {
            // Group session indicator
            if let participants = friend.participants, participants.count > 1 {
                // Show larger circle with overlapping profile icons
                Circle().fill(statusColor).frame(width: markerSize + 10, height: markerSize + 10)
                // Show participant count badge
                Text("\(participants.count)").font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white).frame(width: 20, height: 20)
                    .background(Circle().fill(Color.black.opacity(0.6))).offset(x: 16, y: -16)
            }

            // Base circle with status color
            Circle().fill(statusColor).frame(width: markerSize, height: markerSize)
                .overlay(Circle().stroke(Color.white, lineWidth: friend.isHistorical ? 1 : 2))

            // Use the cached profile image if available, otherwise show default
            if let profileImage = profileImage {
                profileImage.resizable().scaledToFill()
                    .frame(width: markerSize - 4, height: markerSize - 4).clipShape(Circle())
            }
            else if isLoading {
                // Show loading indicator
                ProgressView().scaleEffect(0.7).frame(width: markerSize - 4, height: markerSize - 4)
            }
            else {
                // Default placeholder
                Text(String(friend.username.prefix(1).uppercased()))
                    .font(.system(size: friend.isHistorical ? 12 : 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Pulsing animation for active sessions - blue color for LIVE sessions
            if friend.isCurrentlyFlipped && !friend.isHistorical {
                Circle().stroke(Theme.standardBlue, lineWidth: 2)
                    .frame(width: animate ? 60 : 40, height: animate ? 60 : 40)
                    .opacity(animate ? 0 : 0.7)
                    .animation(
                        Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: animate
                    )
                    .onAppear { animate = true }
            }

            // Session indicator icon
            if friend.isCurrentlyFlipped && !friend.isHistorical {
                ZStack {
                    Circle().fill(Theme.standardBlue).frame(width: 20, height: 20)

                    Text("LIVE").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                }
                .offset(x: 14, y: -14)
            }

            // Historical session index badge
            if friend.isHistorical {
                Text("\(friend.sessionIndex)").font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white).frame(width: 16, height: 16)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1)).offset(x: 12, y: -12)
            }

            // Debug indicator for failed sessions
            if !friend.lastFlipWasSuccessful {
                Text("F").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    .frame(width: 16, height: 16).background(Circle().fill(Color.red.opacity(0.8)))
                    .offset(x: -12, y: 12)
            }
        }
        .shadow(
            color: statusColor.opacity(friend.isHistorical ? 0.3 : 0.5),
            radius: friend.isHistorical ? 2 : 4
        )
        .opacity(friend.isHistorical ? (1.0 - (Double(friend.sessionIndex) * 0.15)) : 1.0)  // Additional subtle opacity adjustment
        .onAppear {
            // Reset state when view appears
            if loadingId != friend.id {
                profileImage = nil
                isLoading = true
                loadingId = friend.id
            }

            if friend.isCurrentlyFlipped && !friend.isHistorical {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false))
                { animate = true }
            }

            // Try to load the user's profile image
            loadProfileImage()
        }
        .id(friend.id)  // Force view refresh when friend.id changes
        .onChange(of: friend.id) {
            // Reset and reload when ID changes
            profileImage = nil
            isLoading = true
            loadingId = friend.id
            loadProfileImage()
        }
    }

    private func loadProfileImage() {
        // First get a clean user ID (without historical suffix)
        let cleanUserId = String(friend.id.split(separator: "_").first ?? "")

        // Check if we already have this image cached
        if let cachedImage = ProfileImageCache.shared.getCachedImage(for: cleanUserId) {
            DispatchQueue.main.async {
                self.profileImage = Image(uiImage: cachedImage)
                self.isLoading = false
            }
            return
        }

        // If no cached image, check if we have profile URL in RegionalViewModel's cache
        if let cachedUser = RegionalViewModel.shared.leaderboardViewModel.userCache[cleanUserId],
            let profileURL = cachedUser.profileImageURL, !profileURL.isEmpty,
            let url = URL(string: profileURL)
        {

            URLSession.shared
                .dataTask(with: url) { data, response, error in
                    // Check if the friend ID is still the same
                    guard loadingId == friend.id else { return }

                    if let data = data, let uiImage = UIImage(data: data) {
                        // Create a thumbnail for better performance
                        let thumbnail = uiImage.thumbnailForCache(size: 100)

                        // Store in cache with user ID
                        ProfileImageCache.shared.storeImage(thumbnail, for: cleanUserId)

                        DispatchQueue.main.async {
                            self.profileImage = Image(uiImage: thumbnail)
                            self.isLoading = false
                        }
                    }
                    else {
                        DispatchQueue.main.async { self.isLoading = false }
                    }
                }
                .resume()
            return
        }

        // If we get here, query Firestore for the user's profile image URL
        FirebaseManager.shared.db.collection("users").document(cleanUserId)
            .getDocument { document, error in
                // Check if the friend ID is still the same
                guard loadingId == friend.id else { return }

                if let userData = try? document?.data(as: FirebaseManager.FlipUser.self),
                    let imageURLString = userData.profileImageURL,
                    let imageURL = URL(string: imageURLString)
                {

                    // Update RegionalViewModel's cache
                    let userCache = UserCacheItem(
                        userId: cleanUserId,
                        username: userData.username,
                        profileImageURL: imageURLString
                    )
                    RegionalViewModel.shared.leaderboardViewModel.userCache[cleanUserId] = userCache

                    URLSession.shared
                        .dataTask(with: imageURL) { data, response, error in
                            // Check if the friend ID is still the same
                            guard loadingId == friend.id else { return }

                            if let data = data, let uiImage = UIImage(data: data) {
                                // Create a thumbnail for better performance
                                let thumbnail = uiImage.thumbnailForCache(size: 100)

                                // Store in cache with user ID
                                ProfileImageCache.shared.storeImage(thumbnail, for: cleanUserId)

                                DispatchQueue.main.async {
                                    self.profileImage = Image(uiImage: thumbnail)
                                    self.isLoading = false
                                }
                            }
                            else {
                                DispatchQueue.main.async { self.isLoading = false }
                            }
                        }
                        .resume()
                }
                else {
                    DispatchQueue.main.async { self.isLoading = false }
                }
            }
    }
}

// Add this helper extension if not already present
extension UIImage {
    func thumbnailForCache(size: CGFloat = 100) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
    }
}
struct FriendPreviewCard: View {
    let friend: FriendLocation
    let onDismiss: () -> Void
    let onViewProfile: () -> Void
    @State private var cardScale = 0.95
    @StateObject private var scoreViewModel = ScoreViewModel()
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formattedSessionTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: friend.lastFlipTime)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact Header with username and time
            VStack(spacing: 8) {
                // Username and rank
                HStack(alignment: .center, spacing: 10) {
                    Text(friend.username).font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white).lineLimit(1)

                    if friend.isCurrentlyFlipped && !friend.isHistorical {
                        // LIVE indicator
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 8, height: 8)

                            Text("LIVE").font(.system(size: 12, weight: .black))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }

                    Spacer()

                    // Rank
                    RankCircle(score: scoreViewModel.userScore).frame(width: 30, height: 30)
                }

                // Status card - more compact
                HStack(spacing: 10) {
                    // Status icon
                    Image(systemName: statusIcon).font(.system(size: 16, weight: .bold))
                        .foregroundColor(statusColor)

                    // Status text with live timer for active sessions
                    if friend.isCurrentlyFlipped && !friend.isHistorical {
                        let elapsedSeconds = Int(
                            currentTime.timeIntervalSince(friend.sessionStartTime)
                        )
                        let minutes = elapsedSeconds / 60
                        let seconds = elapsedSeconds % 60

                        Text("LIVE · \(String(format: "%d:%02d", minutes, seconds))")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    }
                    else if friend.isHistorical {
                        // For historical sessions, show when it happened
                        Text("Session \(friend.sessionTimeAgo)")
                            .font(.system(size: 14, weight: .medium)).foregroundColor(.white)
                    }
                    else {
                        Text(statusText).font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Duration/Time info
                    if friend.isHistorical {
                        // Show time ago for historical sessions
                        Text("\(friend.sessionMinutesElapsed) min")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(statusColor)
                    }
                    else if friend.isCurrentlyFlipped {
                        Text("\(friend.sessionMinutesElapsed) min")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(statusColor)
                    }
                    else if !friend.lastFlipWasSuccessful {
                        Text("\(friend.sessionMinutesElapsed)/\(friend.sessionDuration)m")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(statusColor)
                    }
                    else {
                        Text("\(friend.sessionDuration) min").font(.system(size: 14, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(statusColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )

                // New Session detail info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session \(friend.lastFlipWasSuccessful ? "completed" : "failed") at:")
                        .font(.system(size: 14, weight: .medium))
                    Text(formattedSessionTime).font(.system(size: 14, weight: .bold))
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 15).padding(.top, 12).padding(.bottom, 10)
        }
        .frame(width: 280, height: 140)  // Reduced height since removing profile button
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Theme.silverBlue.opacity(0.95))

                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))

                RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14)
        .overlay(
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white).padding(6)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            .padding(8),
            alignment: .topTrailing
        )
        .scaleEffect(cardScale)
        .onReceive(timer) { time in
            // Update current time for live timer
            currentTime = time
        }
        .onAppear {
            // Get real user ID from the friend ID (may include "_hist_1" suffix)
            let userId = String(friend.id.split(separator: "_").first ?? "")

            // Load user's score and data when card appears
            scoreViewModel.loadUserData(userId: userId)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { cardScale = 1.0 }
        }
    }

    private var statusColor: Color {
        if friend.isHistorical {
            // Historical sessions - use gray shades
            return friend.lastFlipWasSuccessful
                ? Color.gray.opacity(0.8) : Theme.mutedRed.opacity(0.6)  // Red for failed
        }
        else if friend.isCurrentlyFlipped {
            // Active session - blue
            return Theme.standardBlue
        }
        else {
            // Completed or failed session
            if !friend.lastFlipWasSuccessful {
                // Failed - red (explicit check)
                return Theme.mutedRed
            }
            else {
                // Success - green
                return Theme.mutedGreen
            }
        }
    }

    private var statusIcon: String {
        if friend.isHistorical {
            return friend.lastFlipWasSuccessful ? "clock.arrow.circlepath" : "xmark.circle.fill"
        }
        else if friend.isCurrentlyFlipped {
            return "iphone.gen3"
        }
        else if friend.lastFlipWasSuccessful {
            return "checkmark.circle.fill"
        }
        else {
            return "xmark.circle.fill"
        }
    }

    private var statusText: String {
        if friend.isHistorical {
            return friend.lastFlipWasSuccessful ? "Past Successful Session" : "Past Failed Session"
        }
        else if friend.isCurrentlyFlipped {
            return "Currently Flipped"
        }
        else if friend.lastFlipWasSuccessful {
            return "Completed Session"
        }
        else {
            return "Failed Session"
        }
    }
}

struct MapPrivacySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MapPrivacyViewModel()
    @State private var animateSettings = false
    @State private var showFriendSelector = false
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.mainGradient.edgesIgnoringSafeArea(.all)
                if showFriendSelector {
                    // Show friend selector overlay
                    FriendSelectorView(viewModel: viewModel, isPresented: $showFriendSelector)
                        .transition(.opacity.combined(with: .scale(scale: 0.95))).zIndex(2)
                }
                else {
                    // Main Settings Content
                    ScrollView {
                        VStack(spacing: 30) {
                            // Privacy Settings
                            VStack(spacing: 15) {
                                Text("LOCATION VISIBILITY").font(.system(size: 16, weight: .black))
                                    .tracking(4).foregroundColor(.white)
                                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Radio buttons for privacy settings
                                VStack(spacing: 10) {
                                    privacyOption(
                                        title: "Everyone",
                                        description: "All users can see where your past flips were",
                                        isSelected: viewModel.visibilityLevel == .everyone
                                    ) { viewModel.updateVisibilityLevel(.everyone) }

                                    privacyOption(
                                        title: "Friends Only",
                                        description: "Only friends can see your past & live flips",
                                        isSelected: viewModel.visibilityLevel == .friendsOnly
                                    ) { viewModel.updateVisibilityLevel(.friendsOnly) }
                                    // New option: Only These Friends
                                    privacyOption(
                                        title: "Only These Friends",
                                        description:
                                            "Select specific friends who can see your flips",
                                        isSelected: viewModel.visibilityLevel == .selectiveFriends,
                                        showChevron: true,
                                        friendCount: viewModel.selectedFriends.count
                                    ) {
                                        viewModel.updateVisibilityLevel(.selectiveFriends)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation { showFriendSelector = true }
                                        }
                                    }
                                    // New option: All Friends Except
                                    privacyOption(
                                        title: "All Friends Except",
                                        description:
                                            "Block specific friends from seeing your flips",
                                        isSelected: viewModel.visibilityLevel == .allExcept,
                                        showChevron: true,
                                        friendCount: viewModel.excludedFriends.count
                                    ) {
                                        viewModel.updateVisibilityLevel(.allExcept)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation { showFriendSelector = true }
                                        }
                                    }

                                    privacyOption(
                                        title: "Nobody",
                                        description: "Your flips are hidden from everyone",
                                        isSelected: viewModel.visibilityLevel == .nobody
                                    ) { viewModel.updateVisibilityLevel(.nobody) }
                                }
                                .padding(.horizontal, 5)
                            }
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient)
                                        .opacity(0.1)

                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.05))

                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Theme.silveryGradient2, lineWidth: 1)
                                }
                            )
                            .offset(x: animateSettings ? 0 : -300)

                            // Display Options
                            VStack(spacing: 15) {
                                Text("SESSION HISTORY").font(.system(size: 16, weight: .black))
                                    .tracking(4).foregroundColor(.white)
                                    .shadow(color: Theme.lightTealBlue.opacity(0.5), radius: 6)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                // Toggle for showing session history
                                Toggle(
                                    "Show Past Sessions on Map",
                                    isOn: $viewModel.showSessionHistory
                                )
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Theme.lightTealBlue)).padding()
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))

                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    }
                                )
                                .onChange(of: viewModel.showSessionHistory) { _ in
                                    viewModel.saveSettings()
                                }

                                // Info text
                                Text(
                                    "When enabled, the map will show the locations of your past focus sessions. If disabled, only your live sessions will appear to others."
                                )
                                .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                                .padding(.top, 5)
                            }
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15).fill(Theme.buttonGradient)
                                        .opacity(0.1)

                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.05))

                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Theme.silveryGradient2, lineWidth: 1)
                                }
                            )
                            .offset(x: animateSettings ? 0 : 300)

                            Spacer(minLength: 30)

                            // Privacy Info
                            VStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.white.opacity(0.6)).font(.system(size: 32))

                                Text("Your privacy is important")
                                    .font(.system(size: 18, weight: .bold)).foregroundColor(.white)

                                Text(
                                    "Location is only tracked during active focus sessions and your data is never shared with third parties."
                                )
                                .font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center).padding(.horizontal)
                            }
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.05))

                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .padding(.bottom).opacity(animateSettings ? 1 : 0)
                        }
                        .padding(.horizontal).padding(.top, 30)
                    }
                }
            }
            .navigationBarTitle("Map Privacy", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    animateSettings = true
                }
            }
        }
    }

    private func privacyOption(
        title: String,
        description: String,
        isSelected: Bool,
        showChevron: Bool = false,
        friendCount: Int = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Radio button
                ZStack {
                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle().fill(Theme.lightTealBlue).frame(width: 16, height: 16)
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        if showChevron && isSelected && friendCount > 0 {
                            Text("(\(friendCount))").font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Text(description).font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                if showChevron && isSelected {
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 10).padding(.horizontal)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)

                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.lightTealBlue.opacity(0.5), lineWidth: 1)
                    }
                }
            )
        }
    }
}

struct FriendSelectorView: View {
    @ObservedObject var viewModel: MapPrivacyViewModel
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    private var isSelectiveMode: Bool { return viewModel.visibilityLevel == .selectiveFriends }
    private var modeTitle: String { return isSelectiveMode ? "SELECT FRIENDS" : "EXCLUDE FRIENDS" }
    private var modeDescription: String {
        return isSelectiveMode
            ? "Choose friends who can see your locations"
            : "Choose friends who cannot see your locations"
    }
    private var filteredFriends: [FirebaseManager.FlipUser] {
        if searchText.isEmpty {
            return viewModel.allFriends
        }
        else {
            return viewModel.allFriends.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                .onTapGesture { withAnimation { isPresented = false } }
            // Friend selector panel
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    // Title and close button
                    HStack {
                        Text(modeTitle).font(.system(size: 20, weight: .black)).tracking(3)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { withAnimation { isPresented = false } }) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    // Description
                    Text(modeDescription).font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.6))
                        TextField("Search friends", text: $searchText).foregroundColor(.white)
                            .accentColor(Theme.lightTealBlue)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                }
                .padding().background(Theme.deepPurple)
                // Friend list
                if viewModel.isLoadingFriends {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading friends...").font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7)).padding()
                    Spacer()
                }
                else if viewModel.allFriends.isEmpty {
                    Spacer()
                    Image(systemName: "person.2.slash").font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5)).padding()
                    Text("No friends found").font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Add friends to customize your privacy settings").font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredFriends, id: \.id) { friend in
                                FriendSelectorRow(
                                    friend: friend,
                                    isSelected: viewModel.isFriendSelected(friend.id),
                                    onToggle: { viewModel.toggleFriendSelection(friend.id) }
                                )
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 70)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                // Save button
                Button(action: {
                    viewModel.saveSettings()
                    withAnimation { isPresented = false }
                }) {
                    Text("SAVE").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Theme.lightTealBlue)
                                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.deepPurple.opacity(0), Theme.deepPurple,
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 80)
                )
            }
            .background(Theme.deepPurple).cornerRadius(20)
            .frame(
                width: UIScreen.main.bounds.width * 0.9,
                height: UIScreen.main.bounds.height * 0.7
            )
        }
    }
}

struct FriendSelectorRow: View {
    let friend: FirebaseManager.FlipUser
    let isSelected: Bool
    let onToggle: () -> Void
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 15) {
                // Profile image
                ProfilePictureWithStreak(
                    imageURL: friend.profileImageURL,
                    username: friend.username,
                    size: 50,
                    streakStatus: .none  // We're not showing streak here
                )
                // Username and focus stats
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.username).font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(friend.totalSessions) sessions · \(friend.totalFocusTime) min")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            isSelected ? Theme.lightTealBlue : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4).fill(Theme.lightTealBlue)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
        }
    }
}
