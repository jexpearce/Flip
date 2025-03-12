import Foundation
import SwiftUI
import CoreLocation

class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var showCustomAlert = false
    @Published var showSettingsAlert = false  // New alert for directing to Settings
    @Published var showRegionalUnavailableAlert = false  // Alert for Regional feature being unavailable
    
    // Track if we've already shown the alert to avoid repeated prompts
    private var hasShownCustomAlert = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
        
        // Load hasShownCustomAlert from UserDefaults
        hasShownCustomAlert = UserDefaults.standard.bool(forKey: "hasShownLocationAlert")
    }
    
    func requestPermissionWithCustomAlert() {
        // Check if we've already shown the alert and user denied
        if hasShownCustomAlert && authorizationStatus == .denied {
            // Show settings alert instead
            showSettingsAlert = true
            return
        }
        
        // Show our custom alert first
        showCustomAlert = true
        
        // Mark that we've shown the alert
        hasShownCustomAlert = true
        UserDefaults.standard.set(true, forKey: "hasShownLocationAlert")
    }
    
    func checkRegionalAvailability(completion: @escaping (Bool) -> Void) {
        // If permissions are already granted, return true
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            completion(true)
            return
        }
        
        // If permissions are denied and we've shown the alert, show the settings alert
        if authorizationStatus == .denied && hasShownCustomAlert {
            showSettingsAlert = true
            completion(false)
            return
        }
        
        // If permissions are not determined, request them
        if authorizationStatus == .notDetermined {
            requestPermissionWithCustomAlert()
            // We'll rely on the delegate to track status changes
            completion(false)
            return
        }
        
        // Default fallback
        completion(false)
    }
    
    func requestSystemPermission() {
        // Add a delay to ensure the custom alert is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            print("Requesting system location permission after delay")
            // Then request the system permission
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // Open settings app
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // CLLocationManagerDelegate methods
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("Location permission status updated: \(self.authorizationStatus.rawValue)")
            
            // Notify observers that permissions changed
            NotificationCenter.default.post(name: Notification.Name("locationPermissionChanged"), object: nil)
        }
    }
}

// Enhanced location permission alert view
struct EnhancedLocationPermissionAlert: View {
    @Binding var isPresented: Bool
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }
            
            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Location pin with pulse animation
                    ZStack {
                        // Outer pulse
                        Circle()
                            .fill(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3))
                            .frame(width: 90, height: 90)
                            .scaleEffect(animateContent ? 1.3 : 0.8)
                            .opacity(animateContent ? 0.0 : 0.5)
                        
                        // Inner circle
                        Circle()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 70, height: 70)
                        
                        // Icon
                        Image(systemName: "location.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }
                    
                    Text("LOCATION REQUIRED")
                        .font(.system(size: 20, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 8)
                }
                .padding(.top, 10)
                
                // Explanation text
                Text("Regional features require location access to show nearby focus sessions and buildings.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 15) {
                    privacyPoint(icon: "checkmark.shield.fill", text: "Your privacy is protected")
                    privacyPoint(icon: "checkmark.shield.fill", text: "Location used only during active app use")
                    privacyPoint(icon: "checkmark.shield.fill", text: "Only your last 3 sessions are stored")
                }
                .padding(.horizontal, 20)
                
                // Settings button
                Button(action: {
                    isPresented = false
                    LocationPermissionManager.shared.openSettings()
                }) {
                    Text("OPEN SETTINGS")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(red: 56/255, green: 189/255, blue: 248/255))
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Cancel button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Not Now")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 10)
                }
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 26/255, green: 14/255, blue: 47/255),
                                    Color(red: 16/255, green: 24/255, blue: 57/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 25)
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
            .frame(maxWidth: 350)
            .shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }
    
    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                .font(.system(size: 16))
                .frame(width: 24, alignment: .center)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
    }
}


struct LocationPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }
            
            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Location pin with pulse animation
                    ZStack {
                        // Outer pulse
                        Circle()
                            .fill(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3))
                            .frame(width: 90, height: 90)
                            .scaleEffect(animateContent ? 1.3 : 0.8)
                            .opacity(animateContent ? 0.0 : 0.5)
                        
                        // Inner circle
                        Circle()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 56/255, green: 189/255, blue: 248/255),
                                    Color(red: 14/255, green: 165/255, blue: 233/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 70, height: 70)
                        
                        // Icon
                        Image(systemName: "location.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }
                    
                    Text("LOCATION ACCESS")
                        .font(.system(size: 20, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 8)
                    
                    Text("位置情報へのアクセス")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 10)
                
                // Explanation text
                VStack(spacing: 15) {
                    infoRow(
                        icon: "map.fill",
                        title: "Friend Maps",
                        description: "See where your friends are focusing in real-time on the map"
                    )
                    
                    infoRow(
                        icon: "location.circle.fill",
                        title: "Location Challenges",
                        description: "Participate in location-based focus challenges with friends"
                    )
                    
                    infoRow(
                        icon: "bell.fill",
                        title: "Privacy Focused",
                        description: "Location is only tracked during active focus sessions"
                    )
                }
                .padding(.horizontal, 5)
                
                // Important note
                Text("FLIP requires location access to enable these social features. You can change this permission later in your device settings.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                
                // Continue button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        animateButton = true
                    }
                    
                    // Add small delay before closing and requesting permission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            isPresented = false
                                            // Add another delay before continuing to ensure the animation has time to complete
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                                onContinue()
                                            }
                                        }
                }) {
                    Text("CONTINUE")
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
                        .scaleEffect(animateButton ? 0.95 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Small print
                Text("While limited, you can still use core features if you deny location access")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 15)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 26/255, green: 14/255, blue: 47/255),
                                    Color(red: 16/255, green: 24/255, blue: 57/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 25)
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
            .frame(maxWidth: 350)
            .shadow(color: Color.black.opacity(0.3), radius: 20)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
        .onAppear {
            // Start the pulse animation
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateContent = true
            }
        }
    }
    
    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


