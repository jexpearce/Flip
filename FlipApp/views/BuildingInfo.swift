import CoreLocation
import Foundation

// Building info model
struct BuildingInfo: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
    }

    init(id: String, name: String, coordinate: CLLocationCoordinate2D) {
        // Standardize building ID format regardless of what was passed in
        self.id = String(format: "building-%.6f-%.6f", coordinate.latitude, coordinate.longitude)
        self.name = name
        self.coordinate = coordinate
        
        print("📍 Created BuildingInfo with standardized ID: \(self.id)")
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Standardize ID regardless of what was decoded
        id = String(format: "building-%.6f-%.6f", latitude, longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
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