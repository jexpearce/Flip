import SwiftUI
import WidgetKit

@main
struct FlipWidget: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            ActivityWidget()
        }
    }
}
