//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

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

#Preview {
    ContentView()
}
