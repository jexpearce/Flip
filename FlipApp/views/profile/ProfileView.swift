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
    @State private var username = FirebaseManager.shared.currentUser?.username ?? "User"
    @State private var showUploadProgress = false
    
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
                session.wasSuccessful && calendar.isDate(session.startTime, inSameWeekAs: weekStart)
            }
            .max(by: { $0.actualDuration < $1.actualDuration })?.actualDuration
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with Title and Sign Out
                HStack {
                    // Add rank circle
                    RankCircle(score: scoreManager.currentScore)
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 4) {
                        Text("PROFILE")
                            .font(.system(size: 28, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                        Text("プロフィール")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Enhanced Sign Out Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isSigningOut = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            authManager.signOut()
                        }
                    }) {
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 239/255, green: 68/255, blue: 68/255),
                                                    Color(red: 185/255, green: 28/255, blue: 28/255)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .opacity(0.8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 4)
                            .scaleEffect(isSigningOut ? 0.95 : 1.0)
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
                                    .fill(Theme.buttonGradient)
                                    .frame(width: 36, height: 36)
                                    .opacity(0.9)
                                
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
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                    
                    // Upload progress indicator (only shown while uploading)
                    if profileImageManager.isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: profileImageManager.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 56/255, green: 189/255, blue: 248/255)))
                                .frame(width: 200)
                            
                            Text("Uploading profile picture...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 10)
                
                // Streamlined Discipline rank card
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
                                    .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                                
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
                                        Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.6),
                                        Color(red: 79/255, green: 70/255, blue: 229/255).opacity(0.3)
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

                // Enhanced Longest Session Card - Weekly Stats with View More button
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
                                                Color(red: 234/255, green: 179/255, blue: 8/255),
                                                Color(red: 253/255, green: 224/255, blue: 71/255)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5), radius: 4)
                            }

                            Text(weeksLongestSession != nil ? "\(weeksLongestSession!) min" : "No sessions yet this week")
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
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
                                        Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.4),
                                        Color(red: 236/255, green: 72/255, blue: 153/255).opacity(0.3)
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
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)

                        Text("セッション履歴")
                            .font(.system(size: 12))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
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
                                                    Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.5),
                                                    Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.3)
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
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), radius: 6)
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
        }
        .sheet(isPresented: $profileImageManager.isImagePickerPresented) {
            PHPickerRepresentable(
                selectedImage: $profileImageManager.selectedImage,
                isPresented: $profileImageManager.isImagePickerPresented
            ) {
                profileImageManager.isCropperPresented = true
            }
        }
        .sheet(isPresented: $profileImageManager.isCropperPresented) {
            MovableCircleCropperView(
                image: $profileImageManager.selectedImage,
                isPresented: $profileImageManager.isCropperPresented
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

// Add this to DetailedStatsView to use Firestore data consistently
struct DetailedStatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var sessionManager: SessionManager
    @State private var animateStats = false
    @State private var userData: FirebaseManager.FlipUser?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 26/255, green: 14/255, blue: 47/255),
                    Color(red: 16/255, green: 24/255, blue: 57/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("YOUR STATS")
                            .font(.system(size: 24, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        
                        Text("スタッツ")
                            .font(.system(size: 12))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 40)
                
                // Main stats display - using Firestore data when available
                VStack(spacing: 30) {
                    // Total Focus Time
                    DetailedStatCard(
                        title: "TOTAL FOCUS TIME",
                        value: "\(userData?.totalFocusTime ?? sessionManager.totalFocusTime)",
                        unit: "minutes",
                        icon: "clock.fill",
                        color: Color(red: 59/255, green: 130/255, blue: 246/255),
                        delay: 0
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Total Sessions
                    DetailedStatCard(
                        title: "TOTAL SESSIONS",
                        value: "\(userData?.totalSessions ?? sessionManager.totalSuccessfulSessions)",
                        unit: "completed",
                        icon: "checkmark.circle.fill",
                        color: Color(red: 16/255, green: 185/255, blue: 129/255),
                        delay: 0.1
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Average Session Length - calculate if we have data
                    let avgSession = userData != nil && userData!.totalSessions > 0
                        ? userData!.totalFocusTime / userData!.totalSessions
                        : sessionManager.averageSessionLength
                    
                    DetailedStatCard(
                        title: "AVERAGE SESSION LENGTH",
                        value: "\(avgSession)",
                        unit: "minutes",
                        icon: "chart.bar.fill",
                        color: Color(red: 245/255, green: 158/255, blue: 11/255),
                        delay: 0.2
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                    
                    // Longest Session
                    DetailedStatCard(
                        title: "LONGEST SESSION",
                        value: "\(userData?.longestSession ?? sessionManager.longestSession)",
                        unit: "minutes",
                        icon: "crown.fill",
                        color: Color(red: 236/255, green: 72/255, blue: 153/255),
                        delay: 0.3
                    )
                    .scaleEffect(animateStats ? 1 : 0.8)
                    .opacity(animateStats ? 1 : 0)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Back to profile button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK TO PROFILE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Theme.buttonGradient)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 15)
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
                            }
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .opacity(animateStats ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: animateStats)
            }
        }
        .onAppear {
            // Load Firestore data
            loadUserData()
            
            // Animation timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateStats = true
                }
            }
        }
    }
    
    // Function to load data from Firestore
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseManager.shared.db.collection("users").document(userId)
            .getDocument { document, error in
                if let user = try? document?.data(as: FirebaseManager.FlipUser.self) {
                    DispatchQueue.main.async {
                        self.userData = user
                    }
                }
            }
    }
}

struct DetailedStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 5)
            }
            .scaleEffect(animate ? 1 : 0.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.5), radius: 6)
                    
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(animate ? 1 : 0)
                .offset(x: animate ? 0 : -20)
            }
            
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animate = true
                }
            }
        }
    }
}
