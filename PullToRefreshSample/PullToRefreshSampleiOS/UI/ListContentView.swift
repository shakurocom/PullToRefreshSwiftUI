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
        List {
            ForEach(items) { (item) in
                ListContentItemView(listItem: item)
                    .offset(coordinateSpace: ListContentViewConstant.coordinateSpace, offset: { (offset) in
                        if item.id == items.first?.id {
                            print("offset = \(offset)")
                        }
                    })
            }
            .onDelete { (indexSet) in
                items.remove(atOffsets: indexSet)
            }
            .onMove { (indices, newOffset) in
                items.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .background(
            ZStack{
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.9),
                                                           Color.blue.opacity(0.6)]),
                               startPoint: .top,
                               endPoint: .bottom)
            }
        )
        .listStyle(PlainListStyle())
        .coordinateSpace(name: ListContentViewConstant.coordinateSpace)
        .navigationTitle("Items")
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
