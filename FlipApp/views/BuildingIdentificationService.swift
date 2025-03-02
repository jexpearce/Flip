import Foundation
import CoreLocation
import MapKit

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
                // Remove duplicates by comparing coordinates
                var uniqueResults: [MKPlacemark] = []
                var seenCoordinates = Set<String>()
                
                for placemark in allResults {
                    let coordKey = "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude)"
                    if !seenCoordinates.contains(coordKey) {
                        uniqueResults.append(placemark)
                        seenCoordinates.insert(coordKey)
                    }
                }
                
                // Prioritize by distance from user
                let sortedResults = uniqueResults.sorted { placemark1, placemark2 in
                    let location1 = CLLocation(latitude: placemark1.coordinate.latitude, longitude: placemark1.coordinate.longitude)
                    let location2 = CLLocation(latitude: placemark2.coordinate.latitude, longitude: placemark2.coordinate.longitude)
                    
                    return location.distance(from: location1) < location.distance(from: location2)
                }
                
                // Limit to 5 closest results
                let limitedResults = Array(sortedResults.prefix(5))
                completion(limitedResults, nil)
            }
        }
    }
    
    // Correctly place this method inside the class
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