import CoreLocation
import Foundation
import SwiftUI

class LocationPermissionManager: NSObject, ObservableObject,
    CLLocationManagerDelegate
{
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
        hasShownCustomAlert = UserDefaults.standard.bool(
            forKey: "hasShownLocationAlert")
    }

    func requestPermissionWithCustomAlert() {
        // Check if we've already shown the alert and user denied
        if hasShownCustomAlert && authorizationStatus == .denied {
            // Show settings alert instead
            showSettingsAlert = true
            return
        }

        // Show our enhanced alert first (NotificationCenter will handle it)
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowEnhancedLocationAlert"), object: nil)
        showCustomAlert = true

        // Mark that we've shown the alert
        hasShownCustomAlert = true
        UserDefaults.standard.set(true, forKey: "hasShownLocationAlert")
    }

    func checkRegionalAvailability(completion: @escaping (Bool) -> Void) {
        // If permissions are already granted, return true
        if authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
        {
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
            print(
                "Location permission status updated: \(self.authorizationStatus.rawValue)"
            )

            // Notify observers that permissions changed
            NotificationCenter.default.post(
                name: Notification.Name("locationPermissionChanged"),
                object: nil)
        }
    }
}

struct LocationPermissionAlert: View {
    @Binding var isPresented: Bool
    let onContinue: () -> Void
    @State private var animateContent = false
    @State private var animateButton = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismissing by tapping outside
                }

            // Alert content
            VStack(spacing: 20) {
                // Header with icon
                ZStack {
                    Circle()
                        .fill(
                            Color(
                                red: 56 / 255, green: 189 / 255, blue: 248 / 255
                            ).opacity(0.2)
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(animateContent ? 1.3 : 0.8)
                        .opacity(animateContent ? 0.0 : 0.5)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(
                                        red: 56 / 255, green: 189 / 255,
                                        blue: 248 / 255),
                                    Color(
                                        red: 14 / 255, green: 165 / 255,
                                        blue: 233 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "location.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.5), radius: 4)
                }

                Text("LOCATION ACCESS")
                    .font(.system(size: 22, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .shadow(
                        color: Color(
                            red: 56 / 255, green: 189 / 255, blue: 248 / 255
                        ).opacity(0.6), radius: 8)

                // Privacy explanation
                Text(
                    "Flip protects your privacy. Location data is only during active sessions and your last 3 sessions. Visibility can be changed anytime in the Regional tab."
                )
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                // Feature explanation
                VStack(spacing: 15) {
                    featureRow(
                        icon: "map.fill",
                        title: "FlipMaps",
                        description:
                            "See where friends are focusing in real-time"
                    )

                    featureRow(
                        icon: "building.2.fill",
                        title: "Building Leaderboards",
                        description:
                            "Compete with others in the same location (ex. coffee shops, libraries)"
                    )

                    featureRow(
                        icon: "moon.stars.fill",
                        title: "Enhances Functionality",
                        description:
                            "Enables continuous session tracking even when your phone is idle"
                    )
                }
                .padding(.vertical, 5)

                // Privacy policy link
                Button(action: {
                    showPrivacyPolicy = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                        Text("View Full Privacy Policy")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(
                        Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255)
                    )
                    .padding(.vertical, 8)
                }

                // Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        withAnimation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                        ) {
                            animateButton = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.8
                            ) {
                                onContinue()
                            }
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 48)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(
                                                        red: 56 / 255,
                                                        green: 189 / 255,
                                                        blue: 248 / 255),
                                                    Color(
                                                        red: 14 / 255,
                                                        green: 165 / 255,
                                                        blue: 233 / 255),
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))

                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color.white.opacity(0.3),
                                            lineWidth: 1)
                                }
                            )
                            .shadow(
                                color: Color(
                                    red: 56 / 255, green: 189 / 255,
                                    blue: 248 / 255
                                ).opacity(0.5), radius: 8
                            )
                            .scaleEffect(animateButton ? 0.95 : 1.0)
                    }
                }
                .padding(.top, 10)

                Text("You can change this later in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 10)
            }
            .padding(25)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(
                                        red: 26 / 255, green: 14 / 255,
                                        blue: 47 / 255),
                                    Color(
                                        red: 16 / 255, green: 24 / 255,
                                        blue: 57 / 255),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1),
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
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8), value: isPresented
            )
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2).repeatForever(
                    autoreverses: true)
            ) {
                animateContent = true
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String)
        -> some View
    {
        HStack(alignment: .top, spacing: 15) {
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
