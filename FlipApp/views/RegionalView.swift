import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation
import MapKit

struct RegionalView: View {
    @StateObject private var viewModel = RegionalViewModel.shared
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
                    
                    // Building selection button - NEW
                    Button(action: {
                        viewModel.startBuildingIdentification()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CURRENT BUILDING")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(viewModel.selectedBuilding?.name ?? "Tap to select building")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .padding(.horizontal)
                    }
                    
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
            .sheet(isPresented: $viewModel.showBuildingSelection) {
                BuildingSelectionView(
                    isPresented: $viewModel.showBuildingSelection,
                    buildings: viewModel.suggestedBuildings,
                    onBuildingSelected: { building in
                        viewModel.selectBuilding(building)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showMap) {
            MapView()
                .environmentObject(viewRouter)
        }
        .onAppear {
            checkLocationPermission()
            viewModel.loadCurrentBuilding()
        }
    }
    
    private func checkLocationPermission() {
        let status = CLLocationManager().authorizationStatus
        if status == .denied || status == .restricted || status == .notDetermined {
            locationPermissionManager.requestPermissionWithCustomAlert()
        }
    }
}
class RegionalViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RegionalViewModel()
    
    @Published var leaderboardViewModel = RegionalLeaderboardViewModel()
    @Published var currentLocation: CLLocation?
    @Published var selectedBuilding: BuildingInfo?
    @Published var suggestedBuildings: [MKPlacemark] = []
    @Published var showBuildingSelection = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self // Critical: Set the delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        
        // Listen for location updates from LocationHandler
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
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location
        print("Location update received in RegionalViewModel: \(location.coordinate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    @MainActor
    func loadNearbyUsers() {
        // If we have a selected building, load building leaderboard
        if let building = selectedBuilding {
            leaderboardViewModel.loadBuildingLeaderboard(building: building)
            return
        }
        
        // Otherwise load regional leaderboard based on location
        let location = LocationHandler.shared.lastLocation
        if location.horizontalAccuracy > 0 {
            leaderboardViewModel.loadRegionalLeaderboard(near: location)
        } else if let managerLocation = currentLocation {
            leaderboardViewModel.loadRegionalLeaderboard(near: managerLocation)
        }
    }
    
    @MainActor
    func startBuildingIdentification() {
        // Request high-accuracy location for building identification
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        
        var location: CLLocation
        
        // Get the most accurate location available
        let lastLocation = LocationHandler.shared.lastLocation
        
        if lastLocation.horizontalAccuracy > 0 && lastLocation.horizontalAccuracy < 50 {
            location = lastLocation
        } else if let managerLocation = currentLocation,
                  managerLocation.horizontalAccuracy > 0 && managerLocation.horizontalAccuracy < 50 {
            location = managerLocation
        } else {
            // If we don't have an accurate location, use the last known location
            location = lastLocation
        }
        
        BuildingIdentificationService.shared.identifyNearbyBuildings(at: location) { buildings, error in
            if let error = error {
                print("Error identifying buildings: \(error.localizedDescription)")
                return
            }
            
            guard let buildings = buildings, !buildings.isEmpty else {
                print("No buildings found nearby")
                return
            }
            
            DispatchQueue.main.async {
                self.suggestedBuildings = buildings
                self.showBuildingSelection = true
            }
        }
    }
    
    // In RegionalViewModel.swift
    // Update the selectBuilding method

    func selectBuilding(_ building: BuildingInfo) {
        self.selectedBuilding = building
        
        // For debugging - print exact coordinate values and building ID
        let standardizedId = String(format: "building-%.6f-%.6f", building.coordinate.latitude, building.coordinate.longitude)
        print("🏢 Selected building: \(building.name)")
        print("🌐 Coordinates: \(building.coordinate.latitude), \(building.coordinate.longitude)")
        print("🆔 Standardized ID: \(standardizedId)")
        
        // Save the selected building to Firestore
        if let userId = Auth.auth().currentUser?.uid {
            let buildingData: [String: Any] = [
                "id": standardizedId, // Use standardized ID here
                "name": building.name,
                "latitude": building.coordinate.latitude,
                "longitude": building.coordinate.longitude,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            FirebaseManager.shared.db.collection("users").document(userId)
                .collection("settings").document("currentBuilding")
                .setData(buildingData) { error in
                    if let error = error {
                        print("Error saving building info: \(error.localizedDescription)")
                    } else {
                        print("Building info saved successfully with standardized ID: \(standardizedId)")
                        
                        // When loading the leaderboard, also check nearby sessions that might not have the exact building ID
                        DispatchQueue.main.async {
                            self.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                        }
                    }
                }
        }
    }
    
    func loadCurrentBuilding() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseManager.shared.db.collection("users").document(userId)
            .collection("settings").document("currentBuilding")
            .getDocument { [weak self] document, error in
                if let data = document?.data(),
                   let id = data["id"] as? String,
                   let name = data["name"] as? String,
                   let latitude = data["latitude"] as? Double,
                   let longitude = data["longitude"] as? Double {
                    
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let building = BuildingInfo(id: id, name: name, coordinate: coordinate)
                    
                    DispatchQueue.main.async {
                        self?.selectedBuilding = building
                        self?.leaderboardViewModel.loadBuildingLeaderboard(building: building)
                    }
                } else {
                    // No building set yet, load users based on GPS location
                    DispatchQueue.main.async {
                        self?.loadNearbyUsers()
                    }
                }
            }
    }
}