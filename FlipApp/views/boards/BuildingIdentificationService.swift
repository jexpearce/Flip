import CoreLocation
import FirebaseFirestore
import Foundation
import MapKit

class BuildingIdentificationService {
    static let shared = BuildingIdentificationService()
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
                // Use a radius of 100 meters to get places in the vicinity
                request.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
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
                        uniqueResults.append(placemark)
                        seenNames.insert(name)
                        seenCoordinates.insert(coordKey)
                    }
                }
                print("🏢 Found \(uniqueResults.count) unique buildings near location")

                // Before sorting, get session counts for each building
                self.getSessionCountsForBuildings(placemarks: uniqueResults) {
                    buildingsWithCounts in
                    // Sort buildings by session count (most active first)
                    let sortedResults = buildingsWithCounts.sorted { building1, building2 in
                        let count1 = building1.1
                        let count2 = building2.1

                        if count1 == count2 {
                            // If same count, sort by distance from user
                            let location1 = CLLocation(
                                latitude: building1.0.coordinate.latitude,
                                longitude: building1.0.coordinate.longitude
                            )
                            let location2 = CLLocation(
                                latitude: building2.0.coordinate.latitude,
                                longitude: building2.0.coordinate.longitude
                            )

                            return location.distance(from: location1)
                                < location.distance(from: location2)
                        }

                        return count1 > count2
                    }

                    // Return just the placemarks, sorted by popularity
                    let finalPlacemarks = sortedResults.map { $0.0 }
                    // Debug output
                    for (i, placemark) in finalPlacemarks.prefix(3).enumerated() {
                        let buildingName = self.getBuildingName(from: placemark)
                        let buildingId = String(
                            format: "building-%.6f-%.6f",
                            placemark.coordinate.latitude,
                            placemark.coordinate.longitude
                        )
                        let sessionCount = buildingsWithCounts.first { $0.0 == placemark }?.1 ?? 0
                        print(
                            "🏢 Building \(i+1): \(buildingName) - Sessions: \(sessionCount) - ID: \(buildingId)"
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
            // Search radius (in meters)
            let radius = 100.0

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
