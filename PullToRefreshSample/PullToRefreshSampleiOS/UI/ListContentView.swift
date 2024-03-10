import Lottie
import PullToRefreshSwiftUI
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

    @State private var isRefreshing: Bool = false

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
        let options = PullToRefreshListViewOptions()
        PullToRefreshListView(
            options: options,
            isRefreshing: $isRefreshing,
            onRefresh: {
                debugPrint("Refreshing")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
                    isRefreshing = false
                })
            },
            pullingViewBuilder: { (progress) in
                LottieView(animation: .named("animation-pulling-shakuro_logo"))
                    .playbackMode(.paused(at: .progress(progress)))
            },
            refreshingViewBuilder: { (isTriggered) in
                LottieView(animation: .named("animation-refreshing-shakuro_logo"))
                    .playbackMode(isTriggered ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
            },
            contentViewBuilder: { _ in
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
        .navigationTitle("Items")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: EditButton())
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
