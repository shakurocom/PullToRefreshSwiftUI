import SwiftUI

struct ListItem: Identifiable {

    var title: String

    // MARK: - Identifiable

    var id: String {
        return title
    }

}

enum ListContentViewConstant {
    public static let coordinateSpace: String = "ListContentView.CoordinateSpace"
}

struct ListContentView: View {

    @State private var safeAreaTopInset: CGFloat = 0

    @State private var items: [ListItem] = [
        ListItem(title: "Item 1"),
        ListItem(title: "Item 2"),
        ListItem(title: "Item 3"),
        ListItem(title: "Item 4"),
        ListItem(title: "Item 5"),
        ListItem(title: "Item 6"),
        ListItem(title: "Item 7"),
        ListItem(title: "Item 8"),
        ListItem(title: "Item 9"),
        ListItem(title: "Item 10"),
        ListItem(title: "Item 11"),
        ListItem(title: "Item 12"),
        ListItem(title: "Item 13"),
        ListItem(title: "Item 14"),
        ListItem(title: "Item 15"),
        ListItem(title: "Item 16"),
        ListItem(title: "Item 17"),
        ListItem(title: "Item 18"),
        ListItem(title: "Item 19"),
        ListItem(title: "Item 20"),
        ListItem(title: "Item 21"),
    ]

    var body: some View {
        List(content: {
            Color.red
                .listRowSeparator(.hidden, edges: .top)
                .frame(height: 1)
                .listRowInsets(EdgeInsets())
                .offset(coordinateSpace: ListContentViewConstant.coordinateSpace, offset: { (offset) in
                    print("offset = \(offset - safeAreaTopInset)")
                })
            // content
            ForEach(items, content: { (item) in
                ListContentItemView(listItem: item)
            })
            .onDelete(perform: { (indexSet) in
                items.remove(atOffsets: indexSet)
            })
            .onMove(perform: { (indices, newOffset) in
                items.move(fromOffsets: indices, toOffset: newOffset)
            })
        })
        .environment(\.defaultMinListRowHeight, 0)
        .coordinateSpace(name: ListContentViewConstant.coordinateSpace)
        .listStyle(PlainListStyle())
        .readSize(onChange: { (data) in
            safeAreaTopInset = data.safeAreaInsets.top
        })
        .navigationTitle("Items")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: EditButton())
    }

}

private struct ScrollViewOffsetPreferenceKey: PreferenceKey {

    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }

}

private extension View {

    @ViewBuilder
    func offset(coordinateSpace: String, offset: @escaping (CGFloat) -> Void) -> some View {
        self
            .background {
                GeometryReader(content: { geometryProxy in
                    let minY = geometryProxy.frame(in: .named(coordinateSpace)).minY
                    Color.clear
                        .preference(key: ScrollViewOffsetPreferenceKey.self, value: minY)
                        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self, perform: { value in
                            offset(value)
                        })

                })
            }
    }

}

struct ListContentItemView: View {

    let listItem: ListItem

    var body: some View {
        NavigationLink(destination: ListContentItemDetailView(listItem: listItem)) {
            HStack {
                Text(listItem.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

struct ListContentItemDetailView: View {

    let listItem: ListItem

    var body: some View {
        ZStack {
            VStack {
                Text(listItem.title)
                    .font(.largeTitle)
                    .padding(.bottom, 10)
                Spacer()
            }
        }
        .navigationTitle(listItem.title)
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    ListContentView()
}
