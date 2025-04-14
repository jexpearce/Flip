import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation

class CustomLocationHandler {
    static let shared = CustomLocationHandler()
    private let db = Firestore.firestore()

    func createCustomLocation(
        name: String,
        at coordinate: CLLocationCoordinate2D,
        completion: @escaping (BuildingInfo?, Error?) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(
                nil,
                NSError(
                    domain: "CustomLocationError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
                )
            )
            return
        }

        // Create a unique ID for the custom location
        let locationId = String(
            format: "building-%.6f-%.6f",
            coordinate.latitude,
            coordinate.longitude
        )

        let locationData: [String: Any] = [
            "id": locationId, "name": name, "latitude": coordinate.latitude,
            "longitude": coordinate.longitude, "createdBy": userId,
            "creatorName": FirebaseManager.shared.currentUser?.username ?? "User", "isCustom": true,
            "created": FieldValue.serverTimestamp(), "usageCount": 1,
        ]

        // Store the custom location in a global collection
        db.collection("custom_locations").document(locationId)
            .setData(locationData) { error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                // Also add to user's frequent locations
                self.db.collection("users").document(userId).collection("frequentLocations")
                    .document(locationId)
                    .setData([
                        "id": locationId, "name": name, "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude, "lastUsed": FieldValue.serverTimestamp(),
                        "usageCount": 1,
                    ])

                // Return the building info
                let buildingInfo = BuildingInfo(id: locationId, name: name, coordinate: coordinate)

                completion(buildingInfo, nil)
            }
    }

    func getFrequentLocations(completion: @escaping ([BuildingInfo]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }

        db.collection("users").document(userId).collection("frequentLocations")
            .order(by: "usageCount", descending: true).limit(to: 5)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting frequent locations: \(error.localizedDescription)")
                    completion([])
                    return
                }

                var locations: [BuildingInfo] = []

                for document in snapshot?.documents ?? [] {
                    if let id = document.data()["id"] as? String,
                        let name = document.data()["name"] as? String,
                        let latitude = document.data()["latitude"] as? Double,
                        let longitude = document.data()["longitude"] as? Double
                    {

                        let coordinate = CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        )
                        let building = BuildingInfo(id: id, name: name, coordinate: coordinate)
                        locations.append(building)
                    }
                }

                completion(locations)
            }
    }

    func getNearbyCustomLocations(
        coordinate: CLLocationCoordinate2D,
        radiusInMeters: Double,
        completion: @escaping ([BuildingInfo]) -> Void
    ) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        db.collection("custom_locations")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting custom locations: \(error.localizedDescription)")
                    completion([])
                    return
                }

                var locations: [BuildingInfo] = []

                for document in snapshot?.documents ?? [] {
                    if let id = document.data()["id"] as? String,
                        let name = document.data()["name"] as? String,
                        let latitude = document.data()["latitude"] as? Double,
                        let longitude = document.data()["longitude"] as? Double
                    {

                        let customLocation = CLLocation(latitude: latitude, longitude: longitude)

                        // Check if within radius
                        if location.distance(from: customLocation) <= radiusInMeters {
                            let coordinate = CLLocationCoordinate2D(
                                latitude: latitude,
                                longitude: longitude
                            )
                            let building = BuildingInfo(id: id, name: name, coordinate: coordinate)
                            locations.append(building)
                        }
                    }
                }

                completion(locations)
            }
    }

    func incrementLocationUsage(locationId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Increment in user's frequent locations
        let userLocationRef = db.collection("users").document(userId)
            .collection("frequentLocations").document(locationId)

        userLocationRef.getDocument { document, error in
            if let document = document, document.exists {
                // Location exists, increment usage
                userLocationRef.updateData([
                    "usageCount": FieldValue.increment(Int64(1)),
                    "lastUsed": FieldValue.serverTimestamp(),
                ])
            }
            else {
                // Get data from global collection to create local entry
                self.db.collection("custom_locations").document(locationId)
                    .getDocument { document, error in
                        if let data = document?.data(), let name = data["name"] as? String,
                            let latitude = data["latitude"] as? Double,
                            let longitude = data["longitude"] as? Double
                        {

                            // Create new entry in user's frequent locations
                            userLocationRef.setData([
                                "id": locationId, "name": name, "latitude": latitude,
                                "longitude": longitude, "lastUsed": FieldValue.serverTimestamp(),
                                "usageCount": 1,
                            ])
                        }
                    }
            }
        }

        // Also increment in global custom locations if it's a custom location
        if locationId.starts(with: "custom-") {
            db.collection("custom_locations").document(locationId)
                .updateData(["usageCount": FieldValue.increment(Int64(1))])
        }
    }
}
