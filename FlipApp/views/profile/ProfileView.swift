import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var scoreManager = ScoreManager.shared
    @StateObject private var profileImageManager = ProfileImageManager()
    
    @State private var isSigningOut = false
    @State private var showAllSessions = false
    @State private var showStatsDetail = false
    @State private var showDetailedStats = false
    @State private var showSettings = false
    @State private var username = FirebaseManager.shared.currentUser?.username ?? "User"
    @State private var showUploadProgress = false
    @State private var showSettingsSheet = false
    
    // Cyan-midnight theme colors
    private let cyanBluePurpleGradient = LinearGradient(
        colors: [
            Color(red: 20/255, green: 10/255, blue: 40/255), // Deep midnight purple
            Color(red: 30/255, green: 18/255, blue: 60/255), // Medium midnight purple
            Color(red: 14/255, green: 101/255, blue: 151/255).opacity(0.7), // Dark cyan blue
            Color(red: 12/255, green: 74/255, blue: 110/255).opacity(0.6)  // Deeper cyan blue
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let cyanBlueAccent = Color(red: 56/255, green: 189/255, blue: 248/255)
    private let cyanBlueGlow = Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5)
    
    private func loadProfileDataFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Load current user data from Firestore
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { document, error in
                if let error = error {
                    print("Error loading profile data: \(error.localizedDescription)")
                    return
                }
                
                guard let userData = try? document?.data(as: FirebaseManager.FlipUser.self) else {
                    print("Failed to decode user data")
                    return
                }
                
                // Update the UI with Firestore data
                DispatchQueue.main.async {
                    self.username = userData.username
                    
                    // IMPORTANT: Update the FirebaseManager.shared.currentUser with the Firestore data
                    // This ensures the profile image URL is properly synchronized
                    FirebaseManager.shared.currentUser = userData
                    
                    // After updating the shared current user, load the profile image
                    self.profileImageManager.loadProfileImage()
                }
            }
    }
    
    private var displayedSessions: [Session] {
        if showAllSessions {
            return sessionManager.sessions
        } else {
            return Array(sessionManager.sessions.prefix(5))
        }
    }
    
    private var weeksLongestSession: Int? {
        let calendar = Calendar.current
        let currentDate = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        return sessionManager.sessions
            .filter { session in
                // Only include successful sessions from this week
                session.wasSuccessful && calendar.isDate(session.startTime, equalTo: weekStart, toGranularity: .weekOfYear)
            }
            .max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration
    }
    
    var body: some View {
        ZStack {
            // Main background
            cyanBluePurpleGradient
                .edgesIgnoringSafeArea(.all)
            
            // Top decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.2),
                            cyanBlueAccent.opacity(0.05)
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 300
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: -150)
                .blur(radius: 50)
            
            // Bottom decorative glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            cyanBlueAccent.opacity(0.15),
                            cyanBlueAccent.opacity(0.03)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 200
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: -120, y: 350)
                .blur(radius: 40)
                
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Title and Settings button
                    HStack {
                        // Add rank circle
                        RankCircle(score: scoreManager.currentScore)
                            .frame(width: 50, height: 50)
                        
                        VStack(spacing: 4) {
                            Text("PROFILE")
                                .font(.system(size: 28, weight: .black))
                                .tracking(8)
                                .foregroundColor(.white)
                                .shadow(color: cyanBlueGlow, radius: 8)
                            
                        }
                        
                        Spacer()
                        
                        // Enhanced Settings Button
                        Button(action: {
                            withAnimation(.spring()) {
                                showSettingsSheet = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                cyanBlueAccent.opacity(0.7),
                                                cyanBlueAccent.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: cyanBlueGlow, radius: 5)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // New Profile Picture Section
                    VStack(spacing: 15) {
                        // Profile Picture with Edit Button
                        ZStack(alignment: .bottomTrailing) {
                            ZoomableProfileAvatar(
                                        imageURL: FirebaseManager.shared.currentUser?.profileImageURL,
                                        size: 120,
                                        username: username
                                    )
                            
                            // Edit button overlay
                            Button(action: {
                                profileImageManager.selectImage()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    cyanBlueAccent.opacity(0.8),
                                                    cyanBlueAccent.opacity(0.6)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)
                                        .opacity(0.95)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4)
                            }
                        }
                        .padding(.bottom, 4)
                        
                        // Username display
                        Text(username)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: cyanBlueGlow, radius: 6)
                        
                        // Upload progress indicator (only shown while uploading)
                        if profileImageManager.isUploading {
                            VStack(spacing: 8) {
                                ProgressView(value: profileImageManager.uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: cyanBlueAccent))
                                    .frame(width: 200)
                                
                                Text("Uploading profile picture...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Streamlined Discipline rank card with Cyan theme
                    VStack(spacing: 15) {
                        HStack {
                            // Rank Display
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DISCIPLINE RANK")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(3)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                let rank = scoreManager.getCurrentRank()
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(rank.name)
                                        .font(.system(size: 26, weight: .black))
                                        .foregroundColor(rank.color)
                                        .shadow(color: rank.color.opacity(0.5), radius: 6)
                                    
                                    Text("\(String(format: "%.1f", scoreManager.currentScore))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // Progress to next rank
                            if let pointsToNext = scoreManager.pointsToNextRank() {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("NEXT RANK")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(2)
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text("\(String(format: "%.1f", pointsToNext))")
                                        .font(.system(size: 22, weight: .black))
                                        .foregroundColor(.white)
                                        .shadow(color: cyanBlueGlow, radius: 6)
                                    
                                    Text("points needed")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        
                        // Centered Score Details & History Button
                        Button(action: {
                            showStatsDetail = true
                        }) {
                            Text("SCORE DETAILS & HISTORY")
                                .font(.system(size: 15, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    }
                                )
                        }
                    }
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            cyanBlueAccent.opacity(0.5),
                                            cyanBlueAccent.opacity(0.2)
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
                    .padding(.horizontal)
                    .sheet(isPresented: $showStatsDetail) {
                        ScoreHistoryView()
                    }

                    VStack(spacing: 8) {
                        // Week's longest flip
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                // Title with improved crown layout
                                HStack(alignment: .center, spacing: 8) {
                                    Text("\(username)'s LONGEST FLIP OF THE WEEK")
                                        .font(.system(size: 12, weight: .black))
                                        .tracking(3)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    cyanBlueAccent,
                                                    Color(red: 125/255, green: 211/255, blue: 252/255)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: cyanBlueGlow, radius: 4)
                                }

                                Text(weeksLongestSession != nil ? "\(weeksLongestSession!) min" : "No sessions yet this week")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundColor(.white)
                                    .shadow(color: cyanBlueGlow, radius: 8)
                            }
                            Spacer()
                        }
                        
                        // View more stats button
                        Button(action: {
                            // Show detailed stats popup
                            showDetailedStats = true
                        }) {
                            Text("VIEW DETAILED STATS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        cyanBlueAccent.opacity(0.6),
                                                        cyanBlueAccent.opacity(0.3)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    }
                                )
                        }
                    }
                    .padding(16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            cyanBlueAccent.opacity(0.3),
                                            cyanBlueAccent.opacity(0.1)
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
                    .padding(.horizontal)
                    .sheet(isPresented: $showDetailedStats) {
                        DetailedStatsView(sessionManager: sessionManager)
                    }

                    // History Section with Show More functionality
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(spacing: 4) {
                            Text("HISTORY")
                                .font(.system(size: 16, weight: .black))
                                .tracking(5)
                                .foregroundColor(.white)
                                .shadow(color: cyanBlueGlow, radius: 8)

                        }
                        .padding(.horizontal)

                        ForEach(displayedSessions) { session in
                            SessionHistoryCard(session: session)
                        }
                        
                        if sessionManager.sessions.isEmpty {
                            Text("No sessions recorded yet")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        }
                        
                        if sessionManager.sessions.count > 5 {
                            Button(action: {
                                withAnimation(.spring()) {
                                    showAllSessions.toggle()
                                }
                            }) {
                                HStack {
                                    Text(showAllSessions ? "Show Less" : "Show More")
                                        .font(.system(size: 16, weight: .bold))
                                    Image(systemName: showAllSessions ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        cyanBlueAccent.opacity(0.5),
                                                        cyanBlueAccent.opacity(0.3)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                        
                                        RoundedRectangle(cornerRadius: 12)
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
                                .shadow(color: cyanBlueGlow, radius: 6)
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        }
                    }
                }
                .onAppear {
                    if let currentUser = FirebaseManager.shared.currentUser {
                        self.username = currentUser.username
                    }
                    loadProfileDataFromFirestore()
                    profileImageManager.loadProfileImage()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $profileImageManager.isImagePickerPresented) {
            PHPickerRepresentable(
                selectedImage: $profileImageManager.selectedImage,
                isPresented: $profileImageManager.isImagePickerPresented
            ) {
                profileImageManager.isCropperPresented = true
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $profileImageManager.isCropperPresented) {
            ImprovedProfileCropperView(
                image: $profileImageManager.selectedImage
            ) { croppedImage in
                profileImageManager.profileImage = croppedImage
                profileImageManager.uploadImage()
            }
        }
        .alert(isPresented: $profileImageManager.showUploadError) {
            Alert(
                title: Text("Upload Error"),
                message: Text(profileImageManager.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

