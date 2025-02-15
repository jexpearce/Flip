import ActivityKit
import SwiftUI
import WidgetKit

struct LockView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    ZStack {
      Color.gray
      VStack(spacing: 12) {
        if context.state.isFailed {
          FailedLockView()
        } else {
          ActiveLockView(context: context)
        }
      }
      .padding()
    }
  }
}
