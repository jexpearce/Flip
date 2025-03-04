import SwiftUI
import CoreLocation
import CoreMotion
import UserNotifications
import ActivityKit

class PermissionManager: NSObject, ObservableObject {
    static let shared = PermissionManager()
    
    // Location
    private let locationManager = CLLocationManager()
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @Published var showLocationAlert = false
    
    // Motion
    private let motionManager = CMMotionManager()
    @Published var motionPermissionGranted = false
    @Published var showMotionAlert = false
    
    // Notifications
    @Published var notificationPermissionGranted = false
    @Published var showNotificationAlert = false
    
    // Live Activities
    @Published var liveActivitiesEnabled = false
    
    // Overall permission state
    @Published var allPermissionsGranted = false
    
    // Alert for missing permissions when Begin is tapped
    @Published var showPermissionRequiredAlert = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationAuthStatus = locationManager.authorizationStatus
        checkPermissions()
    }
    
    func checkPermissions() {
        // Check location
        locationAuthStatus = locationManager.authorizationStatus
        
        // Check motion
        let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
        motionPermissionGranted = (motionAuthStatus == .authorized)
        
        // Check notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = (settings.authorizationStatus == .authorized)
                
                // Check Live Activities
                if #available(iOS 16.1, *) {
                    self.liveActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
                }
                
                // Update overall permission state
                self.updatePermissionState()
            }
        }
    }
    
    private func updatePermissionState() {
        let locationGranted = locationAuthStatus == .authorizedWhenInUse || locationAuthStatus == .authorizedAlways
        
        allPermissionsGranted = locationGranted &&
                                motionPermissionGranted &&
                                notificationPermissionGranted
    }
    
    // Full permission request sequence
    func requestAllPermissions() {
        // Start with location
        showLocationAlert = true
    }
    
    // Step 1: Show custom location alert, then request system permission
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // Step 2: Request motion permission
    func requestMotionPermission() {
        let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
            if motionAuthStatus == .authorized {
                // Already authorized, skip to next step
                self.motionPermissionGranted = true
                self.requestNotificationPermission()
                return
            }
        showMotionAlert = true
        
        // After user acknowledges, request actual permission
        let motionManager = CMMotionActivityManager()
        let today = Date()
        motionManager.queryActivityStarting(from: today, to: today, to: .main) { _, _ in
            DispatchQueue.main.async {
                self.motionPermissionGranted = (CMMotionActivityManager.authorizationStatus() == .authorized)
                self.requestNotificationPermission()
            }
        }
    }
    
    // Step 3: Request notification permission
    func requestNotificationPermission() {
        // First check if we already have permission before showing the alert
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    // Already authorized, no need to show alert or request again
                    self.notificationPermissionGranted = true
                    self.updatePermissionState()
                } else {
                    // Show alert and then request permission
                    self.showNotificationAlert = true
                }
            }
        }
    }
}

// Extension for CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationAuthStatus = manager.authorizationStatus
            
            // If location permission granted, move to next permission
            if self.locationAuthStatus == .authorizedWhenInUse || self.locationAuthStatus == .authorizedAlways {
                self.requestMotionPermission()
            }
            
            self.updatePermissionState()
        }
    }
}
struct MotionPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Motion icon with animation
                    ZStack {
                        // Outer pulse
                        Circle()
                            .fill(Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.3))
                            .frame(width: 90, height: 90)
                            .scaleEffect(animateContent ? 1.3 : 0.8)
                            .opacity(animateContent ? 0.0 : 0.5)
                        
                        // Inner circle
                        Circle()
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 139/255, green: 92/255, blue: 246/255),
                                    Color(red: 124/255, green: 58/255, blue: 237/255)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: 70, height: 70)
                        
                        // Icon
                        Image(systemName: "figure.walk")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }
                    
                    Text("MOTION ACCESS")
                        .font(.system(size: 20, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.6), radius: 8)
                    
                    Text("モーションアクセス")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 10)
                
                // Explanation text
                VStack(spacing: 15) {
                    infoRow(
                        icon: "arrow.2.squarepath",
                        title: "Detect Phone Flipping",
                        description: "Motion data is used to know when your phone is face down"
                    )
                    
                    infoRow(
                        icon: "exclamationmark.bubble.fill",
                        title: "Critical Feature",
                        description: "The core focus tracking feature requires motion detection"
                    )
                    
                    infoRow(
                        icon: "lock.shield.fill",
                        title: "Privacy Protected",
                        description: "Motion data is only processed on your device, never sent to our servers"
                    )
                }
                .padding(.horizontal, 5)
                
                // Important note
                Text("FLIP requires motion access to detect when your phone is flipped. Without this permission, the app cannot function properly.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                
                // Continue button
                Button(action: {
                    isPresented = false
                    PermissionManager.shared.showMotionAlert = false
                    onContinue()
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
                        .shadow(color: Color(red: 139/255, green: 92/255, blue: 246/255).opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
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

struct NotificationPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Alert content
            VStack(spacing: 25) {
                // Header with icon
                VStack(spacing: 12) {
                    // Notification icon with pulse animation
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
                        Image(systemName: "bell.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.5), radius: 4)
                    }
                    
                    Text("NOTIFICATIONS")
                        .font(.system(size: 20, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.6), radius: 8)
                    
                    Text("通知へのアクセス")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 10)
                
                // Explanation text
                VStack(spacing: 15) {
                    infoRow(
                        icon: "clock.fill",
                        title: "Session Alerts",
                        description: "Get notified about your focus session status and results"
                    )
                    
                    infoRow(
                        icon: "person.2.fill",
                        title: "Friend Activity",
                        description: "Know when friends join your sessions or invite you"
                    )
                    
                    infoRow(
                        icon: "bell.badge.fill",
                        title: "Session Reminders",
                        description: "Receive gentle reminders to flip your phone back over"
                    )
                }
                .padding(.horizontal, 5)
                
                // Important note
                Text("FLIP uses notifications to keep you updated on your focus sessions and social activities.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                
                // Continue button
                Button(action: {
                    isPresented = false
                    PermissionManager.shared.showNotificationAlert = false
                    onContinue()
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Small print
                Text("You can change notification settings later in your device settings")
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