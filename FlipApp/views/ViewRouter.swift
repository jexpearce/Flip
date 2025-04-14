import FirebaseAuth
import SwiftUI

class ViewRouter: ObservableObject {
    @Published var selectedTab: Int = 2  // Home tab as default (center)
    init() {
        // Set up notification to handle tab switching from other parts of the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabSwitch),
            name: Notification.Name("SwitchToHomeTab"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRegionalTabSwitch),
            name: Notification.Name("SwitchToRegionalTab"),
            object: nil
        )
    }

    // ADD THIS METHOD
    @objc func handleTabSwitch() {
        // Switch to home tab (index 2)
        selectedTab = 2
    }
    @objc func handleRegionalTabSwitch() {
        // Switch to regional tab (index 1)
        selectedTab = 1
    }
    deinit { NotificationCenter.default.removeObserver(self) }
}
