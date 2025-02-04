
import WidgetKit
import SwiftUI

@main
struct Widget2: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            FlipActivityWidget()
        }
    }
}
