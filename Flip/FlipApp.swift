import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct FlipApp: App {
    init() {
        FlipManager.shared.registerBackgroundTasks()
        FlipManager.shared.scheduleBackgroundRefresh() // Changed this line
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
