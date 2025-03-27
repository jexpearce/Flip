import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct ActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlipActivityAttributes.self) { context in
            LockView(context: context)
        } dynamicIsland: { context in
            DynamicIslandView(context: context)
        }
        .configurationDisplayName("FLIP Session")
        .description("Track your focus sessions in real-time")
        // Add a stale date so the activity naturally expires
        .contentMarginsDisabled()
    }
}
