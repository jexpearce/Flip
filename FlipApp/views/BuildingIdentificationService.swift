import Foundation
import CoreLocation
import MapKit
import FirebaseFirestore

class BuildingIdentificationService {
    static let shared = BuildingIdentificationService()
    
    func identifyNearbyBuildings(at location: CLLocation, completion: @escaping ([MKPlacemark]?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Get main placemark
            guard let mainPlacemark = placemarks?.first else {
                completion(nil, NSError(domain: "BuildingIdentificationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No placemark found"]))
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
                        DispatchQueue.main.async {
                            allResults.append(contentsOf: results)
                        }
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
                    let coordKey = "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude)"
                    
                    // Skip if we've seen this name or exact coordinate before
                    if !seenNames.contains(name) && !seenCoordinates.contains(coordKey) {
                        uniqueResults.append(placemark)
                        seenNames.insert(name)
                        seenCoordinates.insert(coordKey)
                    }
                }
                
                // Before sorting, get session counts for each building
                self.getSessionCountsForBuildings(placemarks: uniqueResults) { buildingsWithCounts in
                    // Sort buildings by session count (most active first)
                    let sortedResults = buildingsWithCounts.sorted { building1, building2 in
                        let count1 = building1.1
                        let count2 = building2.1
                        
                        if count1 == count2 {
                            // If same count, sort by distance from user
                            let location1 = CLLocation(latitude: building1.0.coordinate.latitude, longitude: building1.0.coordinate.longitude)
                            let location2 = CLLocation(latitude: building2.0.coordinate.latitude, longitude: building2.0.coordinate.longitude)
                            
                            return location.distance(from: location1) < location.distance(from: location2)
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
    
    // New method to get session counts for buildings
    private func getSessionCountsForBuildings(placemarks: [MKPlacemark], completion: @escaping ([(MKPlacemark, Int)]) -> Void) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        
        // For each placemark, we'll determine how many sessions occurred there
        var buildingsWithCounts: [(MKPlacemark, Int)] = []
        let dispatchGroup = DispatchGroup()
        
        for placemark in placemarks {
            dispatchGroup.enter()
            
            // Create a buildingId based on coordinates
            let buildingId = "building-\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)"
            
            // Query for sessions in this building from the past week
            db.collection("session_locations")
                .whereField("sessionEndTime", isGreaterThan: Timestamp(date: oneWeekAgo))
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error getting session counts: \(error.localizedDescription)")
                        buildingsWithCounts.append((placemark, 0))
                        return
                    }
                    
                    // Count sessions near this building (within 100m)
                    let buildingLocation = CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
                    var sessionCount = 0
                    
                    for document in snapshot?.documents ?? [] {
                        if let geoPoint = document.data()["location"] as? GeoPoint {
                            let sessionLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                            if buildingLocation.distance(from: sessionLocation) <= 100 { // Within 100 meters
                                sessionCount += 1
                            }
                        }
                    }
                    
                    buildingsWithCounts.append((placemark, sessionCount))
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(buildingsWithCounts)
        }
    }
    
    func getBuildingName(from placemark: MKPlacemark) -> String {
        // Try to get the building name using various properties
        if let name = placemark.name, !name.isEmpty {
            return name
        }
        
        if let thoroughfare = placemark.thoroughfare {
            if let subThoroughfare = placemark.subThoroughfare {
                return "\(subThoroughfare) \(thoroughfare)"
            }
            return thoroughfare
        }
        
        if let locality = placemark.locality {
            return locality
        }
        
        return "Unknown Building"
    }
}