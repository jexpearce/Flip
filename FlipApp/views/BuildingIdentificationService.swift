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
                // Use a very tight radius to get only very nearby places
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

                    // Skip if we've seen this name or exact coordinate before
                    if !seenNames.contains(name) && !seenCoordinates.contains(coordKey) {
                        uniqueResults.append(placemark)
                        seenNames.insert(name)
                        seenCoordinates.insert(coordKey)
                    }
                }

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

                    // Limit to 5 results
                    let limitedResults = Array(finalPlacemarks.prefix(5))
                    completion(limitedResults, nil)
                }
            }
        }
    }

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

            // Create standardized building ID - THIS IS THE KEY CHANGE
            let buildingId = String(
                format: "building-%.6f-%.6f",
                placemark.coordinate.latitude,
                placemark.coordinate.longitude
            )

            // Debug output to verify building ID format
            print("Checking sessions for building ID: \(buildingId)")

            // Query for sessions with this building ID directly
            db.collection("session_locations").whereField("buildingId", isEqualTo: buildingId)
                .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo))
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }

                    if let error = error {
                        print("Error getting session counts: \(error.localizedDescription)")
                        buildingsWithCounts.append((placemark, 0))
                        return
                    }

                    let sessionCount = snapshot?.documents.count ?? 0
                    print("Found \(sessionCount) sessions for building ID: \(buildingId)")
                    buildingsWithCounts.append((placemark, sessionCount))
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
