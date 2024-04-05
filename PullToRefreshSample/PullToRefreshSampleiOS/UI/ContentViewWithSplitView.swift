//
//
//

import SwiftUI

@available(iOS 17.0, *)
struct ContentViewWithSplitView: View {

    private enum Option {
        case list
        case scroll
    }

    @State private var options: [Option] = [.list, .scroll]
    @State private var preferredColumn = NavigationSplitViewColumn.sidebar
    @State private var selectedOption: Option?

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            List(selection: $selectedOption) {
                ForEach(Array(options), id: \.self) { (option) in
                    NavigationLink(value: option) {
                        switch option {
                        case .list:
                            Text("List View")
                        case .scroll:
                            Text("Scroll View")
                        }
                    }
                }
            }
            .navigationTitle("Options")
        } detail: {
            switch selectedOption {
            case .list:
                NavigationStack {
                    ListContentView()
                }
            case .scroll:
                ScrollContentView()
            case .none:
                Text("Choose an item from the content")
            }
        }
    }

}

@available(iOS 17.0, *)
#Preview(body: {
    ContentViewWithSplitView()
})
