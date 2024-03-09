import SwiftUI

@main
struct PullToRefreshSampleApp: App {

    var body: some Scene {
        WindowGroup {
            if #available(iOS 17.0, *) {
                ContentView()
            } else {
                Color.red // TODO: implement
            }
        }
    }

}
