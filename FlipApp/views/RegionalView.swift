import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct RegionalView: View {
    @StateObject private var viewModel = RegionalViewModel()
    @EnvironmentObject var viewRouter: ViewRouter
    @State private var showMap = false
    @StateObject private var locationPermissionManager = LocationPermissionManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.mainGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Title
                    HStack {
                        Text("REGIONAL")
                            .font(.system(size: 24, weight: .black))
                            .tracking(8)
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
                            .padding(.leading)
                        
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                    
                    // Regional Leaderboard with reddish tint
                    RegionalLeaderboard(viewModel: viewModel.leaderboardViewModel)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Map Button - Fixed at bottom with a glowing effect
                    Button(action: {
                        showMap = true
                    }) {
                        ZStack {
                            // Button background
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.9),
                                            Color(red: 14/255, green: 165/255, blue: 233/255).opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(
                                    color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.7),
                                    radius: 15,
                                    x: 0,
                                    y: 0
                                )
                            
                            HStack(spacing: 14) {
                                // Map icon with glowing effect
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 42, height: 42)
                                    
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.white.opacity(0.8), radius: 2)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("FRIENDS MAP")
                                        .font(.system(size: 20, weight: .black))
                                        .tracking(3)
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.3), radius: 1)
                                    
                                    Text("See where your friends are flipping")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                // Arrow indicator
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(isPresented: $showMap) {
            MapView()
                .environmentObject(viewRouter)
        }
        .onAppear {
            checkLocationPermission()
            viewModel.loadNearbyUsers()
        }
    }
    
    private func checkLocationPermission() {
        let status = CLLocationManager().authorizationStatus
        if status == .denied || status == .restricted || status == .notDetermined {
            locationPermissionManager.requestPermissionWithCustomAlert()
        }
    }
}

// ViewModel for the Regional view
class RegionalViewModel: ObservableObject {
    @Published var leaderboardViewModel = RegionalLeaderboardViewModel()
    @Published var currentLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Listen for location updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("locationUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let location = notification.userInfo?["location"] as? CLLocation {
                self?.currentLocation = location
                self?.loadNearbyUsers()
            }
        }
    }
    
    @MainActor
        func loadNearbyUsers() {
            // This will trigger loading of the regional leaderboard
            let location = LocationHandler.shared.lastLocation
            if location.horizontalAccuracy > 0 {
                leaderboardViewModel.loadRegionalLeaderboard(near: location)
            } else if let managerLocation = currentLocation {
                leaderboardViewModel.loadRegionalLeaderboard(near: managerLocation)
            }
        }
}
