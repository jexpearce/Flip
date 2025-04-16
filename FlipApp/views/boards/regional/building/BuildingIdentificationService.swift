import CoreLocation
import FirebaseFirestore
import MapKit

class BuildingIdentificationService {
    static let shared = BuildingIdentificationService()
    
    // Maximum distance (in meters) to consider a building as "nearby"
    private let maxBuildingDistanceRadius: Double = 150.0
    
    // Distance in meters that triggers a building update
    private let buildingUpdateDistance: Double = 100.0
    
    // Check if user has moved far enough from current building to update
    func shouldUpdateBuilding(currentLocation: CLLocation, currentBuilding: BuildingInfo?) -> Bool {
        guard let building = currentBuilding else {
            // If no building is selected, we should definitely update
            return true
        }
        
        // Calculate distance between current location and building
        let buildingLocation = CLLocation(
            latitude: building.coordinate.latitude,
            longitude: building.coordinate.longitude
        )
        
        let distance = currentLocation.distance(from: buildingLocation)
        
        // Return true if the user has moved more than the threshold distance
        return distance > buildingUpdateDistance
    }
    
    func identifyNearbyBuildings(
        at location: CLLocation,
        completion: @escaping ([MKPlacemark]?, Error?) -> Void
    ) {
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }

            // Get main placemark
            guard let mainPlacemark = placemarks?.first else {
                completion(
                    nil,
                    NSError(
                        domain: "BuildingIdentificationError",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No placemark found"]
                    )
                )
                return
            }

            // Create a dispatch group to handle multiple searches
            let dispatchGroup = DispatchGroup()
            var allResults: [MKPlacemark] = [MKPlacemark(placemark: mainPlacemark)]

            // Function to perform a search with a specific query
            let performSearch = { (query: String) in
                dispatchGroup.enter()

                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                // Use a tighter radius to ensure we're getting buildings that are very close by
                // Reduced from 0.002 to 0.001 for more precision (roughly 100m)
                request.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                )

                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    defer { dispatchGroup.leave() }

                    if let error = error {
                        print("Search error for '\(query)': \(error.localizedDescription)")
                        return
                    }

                    if let results = response?.mapItems.map({ $0.placemark }) {
                        DispatchQueue.main.async { allResults.append(contentsOf: results) }
                    }
                }
            }

            // Search for different types of buildings and departments
            performSearch("department")
            performSearch("building")
            performSearch("library")
            performSearch("hall")
            performSearch("center")
            performSearch("cafe")
            performSearch("coffee")
            performSearch("restaurant")
            performSearch("hotel")
            performSearch("office")
            performSearch("university")
            performSearch("school")
            performSearch("college")

            // When all searches complete
            dispatchGroup.notify(queue: .main) {
                // Deduplicate results more effectively
                var uniqueResults: [MKPlacemark] = []
                var seenNames = Set<String>()
                var seenCoordinates = Set<String>()

                for placemark in allResults {
                    let name = self.getBuildingName(from: placemark).lowercased()
                    let coordKey =
                        "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude)"

                    // Skip if name is empty or we've seen this name or exact coordinate before
                    if !name.isEmpty && name != "unknown building" && !seenNames.contains(name)
                        && !seenCoordinates.contains(coordKey)
                    {
                        // Only include buildings within our maximum radius
                        let placemarkLocation = CLLocation(
                            latitude: placemark.coordinate.latitude,
                            longitude: placemark.coordinate.longitude
                        )
                        let distance = location.distance(from: placemarkLocation)
                        
                        if distance <= self.maxBuildingDistanceRadius {
                            uniqueResults.append(placemark)
                            seenNames.insert(name)
                            seenCoordinates.insert(coordKey)
                            print("🏢 Found building: \(name) at distance: \(Int(distance))m")
                        } else {
                            print("⚠️ Skipping distant building: \(name) at distance: \(Int(distance))m")
                        }
                    }
                }
                print("🏢 Found \(uniqueResults.count) unique buildings within \(self.maxBuildingDistanceRadius)m")
                
                // If no buildings were found within our strict radius, try the main placemark as a fallback
                if uniqueResults.isEmpty && !allResults.isEmpty {
                    print("⚠️ No buildings found within strict radius, using main placemark as fallback")
                    uniqueResults = [allResults[0]]
                }

                // Before sorting, get session counts for each building
                self.getSessionCountsForBuildings(placemarks: uniqueResults) {
                    buildingsWithCounts in
                    
                    // First, classify buildings into proximity tiers
                    let tierSize = self.maxBuildingDistanceRadius / 3 // Create 3 tiers of proximity
                    
                    var tierBuildings: [[(MKPlacemark, Int, Double)]] = [[], [], []]
                    
                    for building in buildingsWithCounts {
                        let buildingLocation = CLLocation(
                            latitude: building.0.coordinate.latitude,
                            longitude: building.0.coordinate.longitude
                        )
                        let distance = location.distance(from: buildingLocation)
                        
                        if distance <= tierSize {
                            // Tier 1 - Very close (within 1/3 of max radius)
                            tierBuildings[0].append((building.0, building.1, distance))
                        } else if distance <= tierSize * 2 {
                            // Tier 2 - Moderately close (within 2/3 of max radius)
                            tierBuildings[1].append((building.0, building.1, distance))
                        } else {
                            // Tier 3 - Farther but still within max radius
                            tierBuildings[2].append((building.0, building.1, distance))
                        }
                    }
                    
                    // Within each tier, sort by session count first, then by distance
                    for i in 0..<tierBuildings.count {
                        tierBuildings[i].sort { building1, building2 in
                            let count1 = building1.1
                            let count2 = building2.1
                            
                            // If session counts vary significantly (more than 5), prioritize count
                            if abs(count1 - count2) > 5 {
                                return count1 > count2
                            }
                            
                            // Otherwise, prioritize proximity
                            return building1.2 < building2.2
                        }
                    }
                    
                    // Combine tiers into a single sorted list, prioritizing closer tiers
                    let sortedBuildings = tierBuildings[0] + tierBuildings[1] + tierBuildings[2]
                    
                    // Return just the placemarks, sorted by tier and then by our custom criteria
                    let finalPlacemarks = sortedBuildings.map { $0.0 }
                    
                    // Debug output for the first few buildings
                    for (i, building) in sortedBuildings.prefix(3).enumerated() {
                        let placemark = building.0
                        let sessionCount = building.1
                        let distance = building.2
                        
                        let buildingName = self.getBuildingName(from: placemark)
                        let buildingId = String(
                            format: "building-%.6f-%.6f",
                            placemark.coordinate.latitude,
                            placemark.coordinate.longitude
                        )
                        
                        print(
                            "🏢 Building \(i+1): \(buildingName) - Distance: \(Int(distance))m - Sessions: \(sessionCount) - ID: \(buildingId)"
                        )
                    }

                    // Limit to 5 results
                    let limitedResults = Array(finalPlacemarks.prefix(5))
                    completion(limitedResults, nil)
                }
            }
        }
    }

    // Update this method too to match the ID format consistently
    private func getSessionCountsForBuildings(
        placemarks: [MKPlacemark],
        completion: @escaping ([(MKPlacemark, Int)]) -> Void
    ) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!

        // For each placemark, we'll determine how many sessions occurred there
        var buildingsWithCounts: [(MKPlacemark, Int)] = []
        let dispatchGroup = DispatchGroup()

        for placemark in placemarks {
            dispatchGroup.enter()

            // Create standardized building ID
            let buildingId = String(
                format: "building-%.6f-%.6f",
                placemark.coordinate.latitude,
                placemark.coordinate.longitude
            )
            // Get the building location
            let buildingLocation = CLLocation(
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            )
            // Tighter search radius for counting sessions (50m instead of 100m)
            let radius = 50.0

            // First try direct building ID query for sessions
            db.collection("session_locations").whereField("buildingId", isEqualTo: buildingId)
                .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo))
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error getting session counts by ID: \(error.localizedDescription)")
                        // Don't exit yet - we'll do a location-based query too
                    }
                    // Get count from this query
                    let idMatchCount = snapshot?.documents.count ?? 0
                    print("Found \(idMatchCount) sessions for building ID: \(buildingId)")
                    // Now do a location proximity query
                    // This will get sessions that are within the radius but may not have exact building ID
                    db.collection("session_locations")
                        .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo))
                        .getDocuments { snapshot, error in
                            defer { dispatchGroup.leave() }
                            if let error = error {
                                print(
                                    "Error getting sessions for location query: \(error.localizedDescription)"
                                )
                                buildingsWithCounts.append((placemark, idMatchCount))
                                return
                            }
                            // Count sessions that have coordinates within our radius
                            var proximityCount = 0
                            for document in snapshot?.documents ?? [] {
                                // Skip if this document already matched the exact building ID
                                if document.data()["buildingId"] as? String == buildingId {
                                    continue
                                }
                                // Check if coordinates are within our radius
                                if let geoPoint = document.data()["location"] as? GeoPoint {
                                    let sessionLocation = CLLocation(
                                        latitude: geoPoint.latitude,
                                        longitude: geoPoint.longitude
                                    )
                                    let distance = buildingLocation.distance(from: sessionLocation)
                                    if distance <= radius { proximityCount += 1 }
                                }
                                // Also check buildingLatitude/buildingLongitude fields
                                if let lat = document.data()["buildingLatitude"] as? Double,
                                    let lon = document.data()["buildingLongitude"] as? Double
                                {
                                    let storedBuildingLocation = CLLocation(
                                        latitude: lat,
                                        longitude: lon
                                    )
                                    let distance = buildingLocation.distance(
                                        from: storedBuildingLocation
                                    )
                                    if distance <= radius { proximityCount += 1 }
                                }
                            }
                            // Combine counts (direct ID matches + proximity matches)
                            let totalCount = idMatchCount + proximityCount
                            print(
                                "Total sessions for \(self.getBuildingName(from: placemark)): \(totalCount)"
                            )
                            buildingsWithCounts.append((placemark, totalCount))
                        }
                }
        }

        dispatchGroup.notify(queue: .main) { completion(buildingsWithCounts) }
    }

    func getBuildingName(from placemark: MKPlacemark) -> String {
        // Try to get the building name using various properties
        if let name = placemark.name, !name.isEmpty { return name }

        if let thoroughfare = placemark.thoroughfare {
            if let subThoroughfare = placemark.subThoroughfare {
                return "\(subThoroughfare) \(thoroughfare)"
            }
            return thoroughfare
        }

        if let locality = placemark.locality { return locality }

        return "Unknown Building"
    }
}
