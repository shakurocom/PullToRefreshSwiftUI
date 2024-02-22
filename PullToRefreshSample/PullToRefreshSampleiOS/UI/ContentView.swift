import SwiftUI

struct ContentView: View {

    @State private var preferredColumn = NavigationSplitViewColumn.detail

//https://developer.apple.com/documentation/swiftui/navigationsplitview
//    navigationsplitview + navigationstack
    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            Color.yellow
        } detail: {
            ScrollContentView()
        }
    }

}

#Preview {
    ContentView()
}
