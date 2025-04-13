import CoreLocation
import Foundation

// Building info model
struct BuildingInfo: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D

    enum CodingKeys: String, CodingKey { case id, name, latitude, longitude }

    init(id: String, name: String, coordinate: CLLocationCoordinate2D) {
        // Standardize building ID format regardless of what was passed in
        self.id = String(format: "building-%.6f-%.6f", coordinate.latitude, coordinate.longitude)
        self.name = name
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }

    static func == (lhs: BuildingInfo, rhs: BuildingInfo) -> Bool { return lhs.id == rhs.id }
}
extension BuildingInfo {
    // Create a static method to ensure consistent ID generation
    static func generateStandardBuildingId(for coordinate: CLLocationCoordinate2D) -> String {
        // Always use 6 decimal places
        return String(format: "building-%.6f-%.6f", coordinate.latitude, coordinate.longitude)
    }
}