import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import SwiftUI

class MapPrivacyViewModel: ObservableObject {
    @Published var visibilityLevel: LocationVisibilityLevel = .friendsOnly
    @Published var showSessionHistory: Bool = true
    private let db = Firestore.firestore()

    init() { loadSettings() }

    func loadSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .getDocument { [weak self] document, error in
                guard let self = self else { return }

                if let document = document, document.exists {
                    if let visibilityString = document.data()?["visibilityLevel"] as? String,
                        let level = LocationVisibilityLevel(rawValue: visibilityString)
                    {
                        DispatchQueue.main.async { self.visibilityLevel = level }
                    }

                    if let showHistory = document.data()?["showSessionHistory"] as? Bool {
                        DispatchQueue.main.async { self.showSessionHistory = showHistory }
                    }
                }
                else {
                    // Create default settings if they don't exist
                    self.saveSettings()
                }
            }
    }

    func updateVisibilityLevel(_ level: LocationVisibilityLevel) {
        visibilityLevel = level
        saveSettings()
    }

    private func saveSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let settings: [String: Any] = [
            "visibilityLevel": visibilityLevel.rawValue, "showSessionHistory": showSessionHistory,
            "lastUpdated": FieldValue.serverTimestamp(),
        ]

        db.collection("users").document(userId).collection("settings").document("mapPrivacy")
            .setData(settings, merge: true) { error in
                if let error = error {
                    print("Error saving map privacy settings: \(error.localizedDescription)")
                }
            }
    }
}
