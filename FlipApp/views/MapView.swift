//
//  MapView.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/25/25.
//

import Foundation
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

enum MapStyleType {
    case standard
    case hybrid
}


struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var showPrivacySettings = false
    @State private var selectedFriend: FriendLocation? = nil
    @State private var mapStyle: MapStyleType = .standard
    
    var body: some View {
        ZStack {
            // Custom styled map
            Map(coordinateRegion: $viewModel.region, interactionModes: .all, showsUserLocation: true, annotationItems: viewModel.friendLocations) { friend in
                MapAnnotation(coordinate: friend.coordinate) {
                    FriendMapMarker(friend: friend)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedFriend = friend
                            }
                        }
                }
            }
            // Replace .mapStyle(mapStyle) with:
            .mapStyle(mapStyle == .standard ? .standard : .hybrid)
            .preferredColorScheme(.dark) // Force dark mode for map
            .edgesIgnoringSafeArea(.all)
            
            // Header with title and settings button
            VStack {
                HStack {
                    Text("FRIEND MAP")
                        .font(.system(size: 24, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        showPrivacySettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.8))
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 50)
                .padding(.bottom, 10)
                .background(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.9),
                                    Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)
                )
                
                Spacer()
                
                // Map controls
                HStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // Refresh button
                        Button(action: viewModel.refreshLocations) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(Theme.buttonGradient)
                                            .opacity(0.9)
                                        
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                        
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4)
                        }
                        
                        // Locate me button
                        Button(action: viewModel.centerOnUser) {
                            Image(systemName: "location")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(Theme.buttonGradient)
                                            .opacity(0.9)
                                        
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                        
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4)
                        }
                        
                        // Map style toggle
                        Button(action: {
                            mapStyle = mapStyle == .standard ? .hybrid : .standard
                        }) {
                            Image(systemName: mapStyle == .standard ? "globe" : "map")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(Theme.buttonGradient)
                                            .opacity(0.9)

                                        Circle()
                                            .fill(Color.white.opacity(0.1))

                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4)
                        }
                    }
                    .padding(.trailing)
                    .padding(.bottom, 30)
                }
            }
            
            // Friend preview popup when a friend is selected
            if let friend = selectedFriend {
                VStack {
                    Spacer()
                    
                    FriendPreviewCard(friend: friend, onDismiss: {
                        selectedFriend = nil
                    }, onViewProfile: {
                        // Navigate to profile (handled by your navigation)
                        selectedFriend = nil
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100) // Above tab bar
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showPrivacySettings) {
            MapPrivacySettingsView()
        }
        .onAppear {
            viewModel.startLocationTracking()
        }
        .onDisappear {
            viewModel.stopLocationTracking()
        }
    }
}

struct FriendMapMarker: View {
    let friend: FriendLocation
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base circle with status color
            Circle()
                .fill(statusColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Profile image placeholder
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            // Pulsing animation for active sessions
            if friend.isCurrentlyFlipped {
                Circle()
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: animate ? 60 : 40, height: animate ? 60 : 40)
                    .opacity(animate ? 0 : 0.7)
            }
            
            // Session indicator icon
            if friend.isCurrentlyFlipped {
                Image(systemName: "iphone")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(statusColor)
                            .frame(width: 20, height: 20)
                    )
                    .offset(x: 14, y: -14)
            }
        }
        .shadow(color: statusColor.opacity(0.5), radius: 4)
        .onAppear {
            if friend.isCurrentlyFlipped {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
        }
    }
    
    private var statusColor: Color {
        if friend.isCurrentlyFlipped {
            return Color(red: 56/255, green: 189/255, blue: 248/255) // Blue for active
        } else if friend.lastFlipWasSuccessful {
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Green for success
        } else {
            return Color(red: 239/255, green: 68/255, blue: 68/255) // Red for failure
        }
    }
}

struct FriendPreviewCard: View {
    let friend: FriendLocation
    let onDismiss: () -> Void
    let onViewProfile: () -> Void
    @State private var cardScale = 0.95
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with name and rank
            HStack {
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.username)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Time info - either current session or last session time
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if friend.isCurrentlyFlipped {
                            Text("Flipped for \(friend.sessionDurationString)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("\(timeAgoString(from: friend.lastFlipTime))")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                // Rank circle - placeholder using random rank
                RankCircle(score: Double.random(in: 1...280))
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 8)
            
            // Status card
            statusCard
                .padding(.horizontal, 15)
                .padding(.bottom, 8)
            
            // Action buttons
            HStack(spacing: 12) {
                // View profile button
                Button(action: onViewProfile) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                        
                        Text("View Profile")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.buttonGradient)
                                .opacity(0.8)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        }
                    )
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                }
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 26/255, green: 14/255, blue: 47/255).opacity(0.95),
                                Color(red: 16/255, green: 24/255, blue: 57/255).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
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
        .shadow(color: Color.black.opacity(0.25), radius: 16)
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 1.0
            }
        }
    }
    
    private var statusCard: some View {
        ZStack {
            // Background with status color
            RoundedRectangle(cornerRadius: 12)
                .fill(statusColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.5), lineWidth: 1)
                )
            
            HStack {
                // Status icon
                Image(systemName: statusIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(statusColor)
                
                // Status text
                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Extra info
                if friend.isCurrentlyFlipped {
                    Text("\(friend.sessionMinutesElapsed) min")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                } else if !friend.lastFlipWasSuccessful {
                    Text("\(friend.sessionMinutesElapsed) of \(friend.sessionDuration) min")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                } else {
                    Text("\(friend.sessionDuration) min")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    private var statusColor: Color {
        if friend.isCurrentlyFlipped {
            return Color(red: 56/255, green: 189/255, blue: 248/255) // Blue for active
        } else if friend.lastFlipWasSuccessful {
            return Color(red: 34/255, green: 197/255, blue: 94/255) // Green for success
        } else {
            return Color(red: 239/255, green: 68/255, blue: 68/255) // Red for failure
        }
    }
    
    private var statusIcon: String {
        if friend.isCurrentlyFlipped {
            return "iphone.gen3"
        } else if friend.lastFlipWasSuccessful {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        if friend.isCurrentlyFlipped {
            return "Currently Flipped"
        } else if friend.lastFlipWasSuccessful {
            return "Completed Session"
        } else {
            return "Failed Session"
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MapPrivacySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MapPrivacyViewModel()
    @State private var animateSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.mainGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Privacy Settings
                    VStack(spacing: 15) {
                        Text("LOCATION VISIBILITY")
                            .font(.system(size: 16, weight: .black))
                            .tracking(4)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Radio buttons for privacy settings
                        VStack(spacing: 10) {
                            privacyOption(title: "Everyone", description: "All users can see your location", isSelected: viewModel.visibilityLevel == .everyone) {
                                viewModel.updateVisibilityLevel(.everyone)
                            }
                            
                            privacyOption(title: "Friends Only", description: "Only friends can see your location", isSelected: viewModel.visibilityLevel == .friendsOnly) {
                                viewModel.updateVisibilityLevel(.friendsOnly)
                            }
                            
                            privacyOption(title: "Nobody", description: "Your location is hidden from everyone", isSelected: viewModel.visibilityLevel == .nobody) {
                                viewModel.updateVisibilityLevel(.nobody)
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Theme.buttonGradient)
                                .opacity(0.1)
                            
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
                    .offset(x: animateSettings ? 0 : -300)
                    
                    // Display Options
                    VStack(spacing: 15) {
                        Text("SESSION HISTORY")
                            .font(.system(size: 16, weight: .black))
                            .tracking(4)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Toggle for showing session history
                        Toggle("Show Past Sessions on Map", isOn: $viewModel.showSessionHistory)
                            .foregroundColor(.white)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 56/255, green: 189/255, blue: 248/255)))
                            .padding()
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                        
                        // Info text
                        Text("When enabled, the map will show the locations of your past focus sessions. If disabled, only your live sessions will appear to others.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Theme.buttonGradient)
                                .opacity(0.1)
                            
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
                    .offset(x: animateSettings ? 0 : 300)
                    
                    Spacer()
                    
                    // Privacy Info
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 32))
                        
                        Text("Your privacy is important")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Location is only tracked during active focus sessions and your data is never shared with third parties.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
                    .padding(.bottom)
                    .opacity(animateSettings ? 1 : 0)
                }
                .padding(.horizontal)
                .padding(.top, 30)
            }
            .navigationBarTitle("Map Privacy", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
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
    
    private func privacyOption(title: String, description: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(red: 56/255, green: 189/255, blue: 248/255))
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), lineWidth: 1)
                    }
                }
            )
        }
    }
}