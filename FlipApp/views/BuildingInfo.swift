import CoreLocation
import Foundation

// Building info model
struct BuildingInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    init(id: String = "", name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
        
        // If no ID provided, generate one with consistent precision
        if id.isEmpty {
            // Round coordinates to 6 decimal places for consistency
            let lat = round(coordinate.latitude * 1000000) / 1000000
            let lon = round(coordinate.longitude * 1000000) / 1000000
            self.id = "building-\(lat)-\(lon)"
        } else {
            self.id = id
        }
    }
    
    static func == (lhs: BuildingInfo, rhs: BuildingInfo) -> Bool {
        // Compare based on coordinates proximity rather than exact ID match
        let lhsLocation = CLLocation(latitude: lhs.coordinate.latitude, longitude: lhs.coordinate.longitude)
        let rhsLocation = CLLocation(latitude: rhs.coordinate.latitude, longitude: rhs.coordinate.longitude)
        
        // If within 10 meters, consider them the same building
        let distance = lhsLocation.distance(from: rhsLocation)
        return distance <= 10.0
    }
    
    // Helper method to check if a coordinate is near this building
    func isNearby(coordinate otherCoordinate: CLLocationCoordinate2D, withinMeters: Double = 100.0) -> Bool {
        let buildingLocation = CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
        let otherLocation = CLLocation(latitude: otherCoordinate.latitude, longitude: otherCoordinate.longitude)
        
        return buildingLocation.distance(from: otherLocation) <= withinMeters
    }
}