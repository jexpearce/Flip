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
            
            // Start a search for nearby buildings
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "building"
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                let results = response?.mapItems.map { $0.placemark } ?? []
                
                // Add the main placemark to the results
                var allPlacemarks = [MKPlacemark(placemark: mainPlacemark)]
                allPlacemarks.append(contentsOf: results)
                
                // Limit to 5 results
                let limitedResults = Array(allPlacemarks.prefix(5))
                
                completion(limitedResults, nil)
            }
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