import SwiftUI
import MapKit
import FirebaseFirestore
import Foundation

struct BuildingSelectionView: View {
    @Binding var isPresented: Bool
    let buildings: [MKPlacemark]
    let onBuildingSelected: (BuildingInfo) -> Void
    
    @State private var frequentLocations: [BuildingInfo] = []
    @State private var showCustomLocationCreation = false
    @State private var nearbyCustomLocations: [BuildingInfo] = []
    @State private var sessionCounts: [String: Int] = [:]
    @State private var isLoadingCounts = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SELECT YOUR BUILDING")
                .font(.system(size: 24, weight: .black))
                .tracking(4)
                .foregroundColor(.white)
                .shadow(color: Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.5), radius: 8)
            
            Text("Choose the building you're currently in:")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(buildings, id: \.self) { building in
                        Button(action: {
                            let buildingName = BuildingIdentificationService.shared.getBuildingName(from: building)
                            let buildingInfo = BuildingInfo(
                                id: "\(building.coordinate.latitude)-\(building.coordinate.longitude)",
                                name: buildingName,
                                coordinate: building.coordinate
                            )
                            onBuildingSelected(buildingInfo)
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(BuildingIdentificationService.shared.getBuildingName(from: building))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(formatAddress(from: building))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                                .padding(.leading, 10)
                                
                                Spacer()
                                
                                // Session count badge
                                if let count = sessionCounts[buildingToKey(building)], count > 0 {
                                    Text("\(count) sessions")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.3))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color(red: 234/255, green: 179/255, blue: 8/255).opacity(0.5), lineWidth: 1)
                                                )
                                        )
                                        .padding(.trailing, 6)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.trailing, 10)
                            }
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // Frequent locations section
                    if !frequentLocations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FREQUENT LOCATIONS")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 10)
                                .padding(.horizontal, 10)
                            
                            ForEach(frequentLocations) { location in
                                Button(action: {
                                    // Increment usage count when selected
                                    CustomLocationHandler.shared.incrementLocationUsage(locationId: location.id)
                                    onBuildingSelected(location)
                                    isPresented = false
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                                            .padding(.leading, 10)
                                        
                                        Text(location.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.6))
                                            .padding(.trailing, 10)
                                    }
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                    
                    // Custom building option
                    Button(action: {
                        showCustomLocationCreation = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 56/255, green: 189/255, blue: 248/255))
                                .padding(.leading, 10)
                            
                            Text("Add Custom Location")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 56/255, green: 189/255, blue: 248/255).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.mainGradient)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showCustomLocationCreation) {
            // Use the first building's coordinate as the base for custom location
            let coordinate = buildings.first?.coordinate ?? CLLocationCoordinate2D()
            
            CustomLocationCreationView(
                isPresented: $showCustomLocationCreation,
                coordinate: coordinate,
                onLocationCreated: { buildingInfo in
                    onBuildingSelected(buildingInfo)
                }
            )
        }
        .onAppear {
            // Load frequent locations
            CustomLocationHandler.shared.getFrequentLocations { locations in
                self.frequentLocations = locations
            }
            
            // Load nearby custom locations
            if let firstBuilding = buildings.first {
                CustomLocationHandler.shared.getNearbyCustomLocations(
                    coordinate: firstBuilding.coordinate,
                    radiusInMeters: 200  // 200 meters radius
                ) { locations in
                    self.nearbyCustomLocations = locations
                }
            }
            
            // Load session counts for buildings
            loadSessionCounts()
        }
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        var address = ""
        
        if let thoroughfare = placemark.thoroughfare {
            address += thoroughfare
        }
        
        if let subThoroughfare = placemark.subThoroughfare {
            address = address.isEmpty ? subThoroughfare : "\(subThoroughfare) \(address)"
        }
        
        if let locality = placemark.locality {
            address = address.isEmpty ? locality : "\(address), \(locality)"
        }
        
        return address.isEmpty ? "No address available" : address
    }
    // Add these methods to your BuildingSelectionView

    // Helper method to convert MKPlacemark to a key string for dictionary
    private func buildingToKey(_ building: MKPlacemark) -> String {
        return "\(building.coordinate.latitude),\(building.coordinate.longitude)"
    }

    private func loadSessionCounts() {
        isLoadingCounts = true
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        // For each building, count sessions from the past week
        let dispatchGroup = DispatchGroup()
        var tempCounts: [String: Int] = [:]
        
        for building in buildings {
            let buildingKey = buildingToKey(building)
            dispatchGroup.enter()
            
            let buildingLocation = CLLocation(latitude: building.coordinate.latitude, longitude: building.coordinate.longitude)
            let radius = 100.0 // 100 meters around building
            
            // Query all sessions from the past week
            db.collection("session_locations")
                .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo))
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching session data: \(error.localizedDescription)")
                        tempCounts[buildingKey] = 0
                        return
                    }
                    
                    // Count sessions within radius of this building
                    var count = 0
                    for document in snapshot?.documents ?? [] {
                        if let geoPoint = document.data()["location"] as? GeoPoint {
                            let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                            let distance = buildingLocation.distance(from: sessionLocation)
                            
                            if distance <= radius {
                                count += 1
                            }
                        }
                    }
                    
                    tempCounts[buildingKey] = count
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.sessionCounts = tempCounts
            self.isLoadingCounts = false
        }
    }
}