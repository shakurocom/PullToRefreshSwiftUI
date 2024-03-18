import SwiftUI

struct ContentView: View {

    private enum Option {
        case list
        case scroll
    }

    @State private var options: [Option] = [.list, .scroll]

    var body: some View {
        NavigationView(content: {
            List(content: {
                ForEach(options, id: \.self, content: { (option) in
                    NavigationLink(destination: {
                        switch option {
                        case .list:
                            ListContentView()
                        case .scroll:
                            ScrollContentView()
                        }
                    }, label: {
                        switch option {
                        case .list:
                            Text("List View")
                        case .scroll:
                            Text("Scroll View")
                        }
                    })
                })
            })
            .navigationTitle("Options")
        })
    }

}

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
                ListContentView()
            case .scroll:
                ScrollContentView()
            case .none:
                Text("Choose an item from the content")
            }
        }
    }

}

#Preview {
    if #available(iOS 17.0, *) {
        ContentViewWithSplitView()
    } else {
        ContentView()
    }
}
