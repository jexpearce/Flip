import BackgroundTasks
import SwiftUI
import UserNotifications

@main
struct FlipApp: App {
  @StateObject private var manager = Manager.shared

  init() {
    // Register tasks first, before scheduling anything
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: Manager.backgroundRefreshIdentifier,
      using: nil
    ) { task in
      // Handle the task here
      Manager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
    }

    // Now it's safe to schedule
    manager.scheduleBackgroundRefresh()
  }

  var body: some Scene {
    WindowGroup {
      MainView()
    }.environmentObject(manager)
  }
}
