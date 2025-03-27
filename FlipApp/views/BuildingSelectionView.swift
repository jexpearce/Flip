import FirebaseFirestore
import Foundation
import MapKit
import SwiftUI

struct BuildingSelectionView: View {
    @Binding var isPresented: Bool
    let buildings: [MKPlacemark]
    let onBuildingSelected: (BuildingInfo) -> Void

    @State private var frequentLocations: [BuildingInfo] = []
    @State private var showCustomLocationCreation = false
    @State private var nearbyCustomLocations: [BuildingInfo] = []
    @State private var sessionCounts: [String: Int] = [:]
    @State private var isLoadingCounts = true

    // Custom gradient for the selection view
    private let selectionGradient = LinearGradient(
        colors: [
            Color(red: 30 / 255, green: 14 / 255, blue: 50 / 255),  // Deep midnight purple
            Color(red: 38 / 255, green: 18 / 255, blue: 58 / 255),  // Lighter purple with slight red
            Color(red: 45 / 255, green: 20 / 255, blue: 60 / 255),  // Medium purple
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            // Main background
            selectionGradient
                .edgesIgnoringSafeArea(.all)

            // Additional decorative elements for visual interest
            VStack {
                // Top decorative element
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(
                                    red: 220 / 255, green: 38 / 255,
                                    blue: 38 / 255
                                ).opacity(0.1),
                                Color(
                                    red: 127 / 255, green: 29 / 255,
                                    blue: 29 / 255
                                ).opacity(0.0),
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 250
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: -100)
                    .blur(radius: 40)

                Spacer()
            }

            VStack(spacing: 20) {
                Text("SELECT YOUR BUILDING")
                    .font(.system(size: 24, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .shadow(
                        color: Color(
                            red: 220 / 255, green: 38 / 255, blue: 38 / 255
                        ).opacity(0.5), radius: 8)

                if buildings.isEmpty {
                    // No buildings view
                    VStack(spacing: 20) {
                        Image(systemName: "building.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.7))
                            .padding()

                        Text("No Buildings Detected Nearby")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(
                            "You don't appear to be near any recognizable buildings. You can create a custom location instead."
                        )
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                        Button(action: {
                            showCustomLocationCreation = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(
                                        Color(
                                            red: 220 / 255, green: 38 / 255,
                                            blue: 38 / 255))

                                Text("Create Custom Location")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                Color(
                                                    red: 220 / 255,
                                                    green: 38 / 255,
                                                    blue: 38 / 255
                                                ).opacity(0.5), lineWidth: 1.5)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 30)
                } else {
                    Text("Choose the building you're currently in:")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(buildings, id: \.self) { building in
                                Button(action: {
                                    let buildingName =
                                        BuildingIdentificationService.shared
                                        .getBuildingName(from: building)
                                    let buildingInfo = BuildingInfo(
                                        id: "",  // The BuildingInfo init will standardize this
                                        name: buildingName,
                                        coordinate: building.coordinate
                                    )
                                    onBuildingSelected(buildingInfo)
                                    isPresented = false
                                }) {
                                    HStack {
                                        // Building icon
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    Color(
                                                        red: 220 / 255,
                                                        green: 38 / 255,
                                                        blue: 38 / 255
                                                    ).opacity(0.2)
                                                )
                                                .frame(width: 36, height: 36)

                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(
                                                    Color(
                                                        red: 220 / 255,
                                                        green: 38 / 255,
                                                        blue: 38 / 255))
                                        }
                                        .padding(.trailing, 8)

                                        VStack(alignment: .leading, spacing: 4)
                                        {
                                            Text(
                                                BuildingIdentificationService
                                                    .shared.getBuildingName(
                                                        from: building)
                                            )
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .foregroundColor(.white)

                                            HStack(spacing: 4) {
                                                Text(
                                                    formatAddress(
                                                        from: building)
                                                )
                                                .font(.system(size: 14))
                                                .foregroundColor(
                                                    .white.opacity(0.7)
                                                )
                                                .lineLimit(1)

                                                Spacer()

                                                // Distance indicator
                                                Text(
                                                    formatDistance(to: building)
                                                )
                                                .font(
                                                    .system(
                                                        size: 12,
                                                        weight: .medium)
                                                )
                                                .foregroundColor(
                                                    Color(
                                                        red: 220 / 255,
                                                        green: 38 / 255,
                                                        blue: 38 / 255
                                                    ).opacity(0.9)
                                                )
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            Color(
                                                                red: 220 / 255,
                                                                green: 38 / 255,
                                                                blue: 38 / 255
                                                            ).opacity(0.1)
                                                        )
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(
                                                                    Color(
                                                                        red: 220
                                                                            / 255,
                                                                        green:
                                                                            38
                                                                            / 255,
                                                                        blue: 38
                                                                            / 255
                                                                    ).opacity(
                                                                        0.3),
                                                                    lineWidth: 1
                                                                )
                                                        )
                                                )
                                            }
                                        }

                                        Spacer()

                                        // Session count badge
                                        if let count = sessionCounts[
                                            buildingToKey(building)], count > 0
                                        {
                                            Text("\(count) sessions")
                                                .font(
                                                    .system(
                                                        size: 12, weight: .bold)
                                                )
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            Color(
                                                                red: 220 / 255,
                                                                green: 38 / 255,
                                                                blue: 38 / 255
                                                            ).opacity(0.3)
                                                        )
                                                        .overlay(
                                                            Capsule()
                                                                .stroke(
                                                                    Color(
                                                                        red: 220
                                                                            / 255,
                                                                        green:
                                                                            38
                                                                            / 255,
                                                                        blue: 38
                                                                            / 255
                                                                    ).opacity(
                                                                        0.5),
                                                                    lineWidth: 1
                                                                )
                                                        )
                                                )
                                                .padding(.trailing, 6)
                                        }

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(
                                                .white.opacity(0.6)
                                            )
                                            .padding(.trailing, 10)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.08))

                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(
                                                                0.5),
                                                            Color.white.opacity(
                                                                0.1),
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint:
                                                            .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        }
                                    )
                                    .shadow(
                                        color: Color.black.opacity(0.15),
                                        radius: 4)
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
                                            CustomLocationHandler.shared
                                                .incrementLocationUsage(
                                                    locationId: location.id)
                                            onBuildingSelected(location)
                                            isPresented = false
                                        }) {
                                            HStack {
                                                // Clock icon
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            Color(
                                                                red: 220 / 255,
                                                                green: 38 / 255,
                                                                blue: 38 / 255
                                                            ).opacity(0.2)
                                                        )
                                                        .frame(
                                                            width: 36,
                                                            height: 36)

                                                    Image(
                                                        systemName:
                                                            "clock.arrow.circlepath"
                                                    )
                                                    .font(.system(size: 16))
                                                    .foregroundColor(
                                                        Color(
                                                            red: 220 / 255,
                                                            green: 38 / 255,
                                                            blue: 38 / 255))
                                                }
                                                .padding(.trailing, 8)

                                                Text(location.name)
                                                    .font(
                                                        .system(
                                                            size: 16,
                                                            weight: .medium)
                                                    )
                                                    .foregroundColor(.white)

                                                Spacer()

                                                Image(
                                                    systemName: "chevron.right"
                                                )
                                                .foregroundColor(
                                                    .white.opacity(0.6)
                                                )
                                                .padding(.trailing, 10)
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 16)
                                            .background(
                                                ZStack {
                                                    RoundedRectangle(
                                                        cornerRadius: 12
                                                    )
                                                    .fill(
                                                        Color.white.opacity(
                                                            0.08))

                                                    RoundedRectangle(
                                                        cornerRadius: 12
                                                    )
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white
                                                                    .opacity(
                                                                        0.5),
                                                                Color.white
                                                                    .opacity(
                                                                        0.1),
                                                            ],
                                                            startPoint:
                                                                .topLeading,
                                                            endPoint:
                                                                .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                                }
                                            )
                                            .shadow(
                                                color: Color.black.opacity(
                                                    0.15), radius: 4)
                                        }
                                    }
                                }
                            }

                            // Custom building option
                            Button(action: {
                                showCustomLocationCreation = true
                            }) {
                                HStack {
                                    // Plus icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                Color(
                                                    red: 220 / 255,
                                                    green: 38 / 255,
                                                    blue: 38 / 255
                                                ).opacity(0.2)
                                            )
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(
                                                Color(
                                                    red: 220 / 255,
                                                    green: 38 / 255,
                                                    blue: 38 / 255))
                                    }
                                    .padding(.trailing, 8)

                                    Text("Add Custom Location")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.trailing, 10)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))

                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(
                                                            red: 220 / 255,
                                                            green: 38 / 255,
                                                            blue: 38 / 255
                                                        ).opacity(0.4),
                                                        Color(
                                                            red: 220 / 255,
                                                            green: 38 / 255,
                                                            blue: 38 / 255
                                                        ).opacity(0.1),
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                )
                                .shadow(
                                    color: Color.black.opacity(0.15), radius: 4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Cancel button
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color.white.opacity(0.2),
                                            lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectionGradient)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.7))
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showCustomLocationCreation) {
            // Use the first building's coordinate as the base for custom location
            let coordinate =
                buildings.first?.coordinate ?? CLLocationCoordinate2D()

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
            address =
                address.isEmpty
                ? subThoroughfare : "\(subThoroughfare) \(address)"
        }

        if let locality = placemark.locality {
            address = address.isEmpty ? locality : "\(address), \(locality)"
        }

        return address.isEmpty ? "No address available" : address
    }

    private func formatDistance(to building: MKPlacemark) -> String {
        let buildingLocation = CLLocation(
            latitude: building.coordinate.latitude,
            longitude: building.coordinate.longitude)
        let userLocation = LocationHandler.shared.lastLocation

        let distance = userLocation.distance(from: buildingLocation)

        if distance < 50 {
            return "< 50m"
        } else if distance < 100 {
            return "< 100m"
        } else if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let kilometers = distance / 1000.0
            return String(format: "%.1f km", kilometers)
        }
    }

    // Helper method to convert MKPlacemark to a key string for dictionary
    private func buildingToKey(_ building: MKPlacemark) -> String {
        return
            "\(building.coordinate.latitude),\(building.coordinate.longitude)"
    }

    private func loadSessionCounts() {
        isLoadingCounts = true
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(
            byAdding: .weekOfYear, value: -1, to: Date())!

        // For each building, count sessions from the past week
        let dispatchGroup = DispatchGroup()
        var tempCounts: [String: Int] = [:]

        for building in buildings {
            let buildingKey = buildingToKey(building)
            dispatchGroup.enter()

            let buildingLocation = CLLocation(
                latitude: building.coordinate.latitude,
                longitude: building.coordinate.longitude)
            let radius = 60.0  // 100 meters around building

            // Query all sessions from the past week
            db.collection("session_locations")
                .whereField(
                    "sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo)
                )
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }

                    if let error = error {
                        print(
                            "Error fetching session data: \(error.localizedDescription)"
                        )
                        tempCounts[buildingKey] = 0
                        return
                    }

                    // Count sessions within radius of this building
                    var count = 0
                    for document in snapshot?.documents ?? [] {
                        if let geoPoint = document.data()["location"]
                            as? GeoPoint
                        {
                            let sessionLocation = CLLocation(
                                latitude: geoPoint.latitude,
                                longitude: geoPoint.longitude)
                            let distance = buildingLocation.distance(
                                from: sessionLocation)

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
