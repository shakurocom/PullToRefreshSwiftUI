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

    private enum AnimationType {
        case native
        case progressView
        case lottie
    }

    @State private var isRefreshing: Bool = false
    @State private var animationType: AnimationType = .native

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
        PullToRefreshListView(
            options: PullToRefreshListViewOptions(pullToRefreshAnimationHeight: 100,
                                                  animationDuration: 0.3,
                                                  animatePullingViewPresentation: true,
                                                  animateRefreshingViewPresentation: true),
            isRefreshing: $isRefreshing,
            onRefresh: {
                debugPrint("Refreshing")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
                    isRefreshing = false
                    items.shuffle()
                })
            },
            animationViewBuilder: { (state) in
                switch state {
                case .idle:
                    Color.clear
                case .pulling(let progress):
                    switch animationType {
                    case .native:
                        CircleAnimationWithProgressView(progress: progress)
                    case .progressView:
                        ProgressView(value: progress, total: 1)
                            .progressViewStyle(.linear)
                    case .lottie:
                        LottieView(animation: .named("animation-pulling-shakuro_logo"))
                            .playbackMode(.paused(at: .progress(progress)))
                    }
                case .refreshing:
                    switch animationType {
                    case .native:
                        CircleAnimationWithRepeatView()
                    case .progressView:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .lottie:
                        LottieView(animation: .named("animation-refreshing-shakuro_logo"))
                            .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                    }
                }
            },
            contentViewBuilder: { _ in
                Picker("Current animation type", selection: $animationType) {
                    Text("Native").tag(AnimationType.native)
                    Text("ProgressView").tag(AnimationType.progressView)
                    Text("Lottie").tag(AnimationType.lottie)
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden, edges: .top)
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
