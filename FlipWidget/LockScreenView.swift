import ActivityKit
import SwiftUI
import WidgetKit

struct LockScreenView: View {
  let context: ActivityViewContext<FlipActivityAttributes>

  var body: some View {
    ZStack {
      Color.black
      VStack(spacing: 12) {
        if context.state.isFailed {
          FailedStateView()
        } else {
          ActiveStateView(context: context)
        }
      }
      .padding()
    }
  }
}
