import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct FlipApp: App {
    init() {
        // Register tasks first, before scheduling anything
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Manager.backgroundRefreshIdentifier,
            using: nil) { task in
                // Handle the task here
                Manager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        
        // Now it's safe to schedule
        Manager.shared.scheduleBackgroundRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

