import BackgroundTasks
import SwiftUI
import UserNotifications

@main
struct FlipApp: App {

  init() {
    // Register tasks first, before scheduling anything
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: AppManager.backgroundRefreshIdentifier,
      using: nil
    ) { task in
      // Handle the task here
      AppManager.shared.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
    }

    // Now it's safe to schedule
    AppManager.shared.scheduleBackgroundRefresh()
  }

  @StateObject private var appManager = AppManager.shared
  var body: some Scene {
    WindowGroup {
      MainView()
    }.environmentObject(appManager)
  }
}
