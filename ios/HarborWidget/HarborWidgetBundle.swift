import SwiftUI
import WidgetKit

@main
struct HarborWidgetBundle: WidgetBundle {
    var body: some Widget {
        HarborWidget()
        HarborLockScreenWidget()
    }
}
