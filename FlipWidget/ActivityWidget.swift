import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct ActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FlipActivityAttributes.self) { context in
      LockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIslandView(context: context)
    }
  }
}
