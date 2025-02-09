import ActivityKit
import SwiftUI
import WidgetKit

struct FailedLockView: View {
  var body: some View {
    VStack(spacing: 15) {
      Image(systemName: "xmark.circle.fill")
        .font(.system(size: 40))
        .foregroundColor(.red)

      Text("Session Failed")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.red)

      Text("Phone was moved too many times")
        .font(.system(size: 16))
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
    }
  }
}
