import SwiftUI

public struct PullToRefreshListViewOptions {

    public let animationDuration: TimeInterval

    public init(animationDuration: TimeInterval = 0.3) {
        self.animationDuration = animationDuration
    }

}

public enum PullToRefreshListViewConstant { // TODO: implement
    public static let coordinateSpace: String = "PullToRefreshListView.CoordinateSpace"
    public static let height: CGFloat = 100
    public static let offset: CGFloat = 0
}

public struct PullToRefreshListView<PullingViewType: View, RefreshingViewType: View, ContentViewType: View, Style: ListStyle>: View {

    private let options: PullToRefreshListViewOptions
    private let refreshViewHeight: CGFloat
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let isRefreshing: Binding<Bool>
    private let listStyle: Style
    private let listTopPadding: CGFloat
    private let onRefresh: () -> Void
    private let pullingViewBuilder: (_ progress: CGFloat) -> PullingViewType
    private let refreshingViewBuilder: (_ isTriggered: Bool) -> RefreshingViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState = ScrollViewState()

    @State private var safeAreaTopInset: CGFloat = 0
    @State private var offsetValue: CGFloat = 0

    // MARK: - Initialization

    public init(options: PullToRefreshListViewOptions,
                refreshViewHeight: CGFloat = (PullToRefreshListViewConstant.offset * 2 + PullToRefreshListViewConstant.height),
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                isRefreshing: Binding<Bool>,
                listStyle: Style = .automatic,
                listTopPadding: CGFloat = 0,
                onRefresh: @escaping () -> Void,
                @ViewBuilder pullingViewBuilder: @escaping (_ progress: CGFloat) -> PullingViewType,
                @ViewBuilder refreshingViewBuilder: @escaping (_ isTriggered: Bool) -> RefreshingViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.options = options
        self.refreshViewHeight = refreshViewHeight
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.isRefreshing = isRefreshing
        self.listStyle = listStyle
        self.listTopPadding = listTopPadding
        self.onRefresh = onRefresh
        self.pullingViewBuilder = pullingViewBuilder
        self.refreshingViewBuilder = refreshingViewBuilder
        self.contentViewBuilder = contentViewBuilder
    }

    // MARK: - UI

    public var body: some View {
        let defaultAnimation: Animation = .easeInOut(duration: options.animationDuration)
        ZStack(alignment: .top, content: {
            // animations
            VStack(spacing: 0, content: {
                ZStack(alignment: .center, content: {
                    pullingViewBuilder(scrollViewState.progress)
                        .modifier(GeometryGroupModifier())
                        .opacity(scrollViewState.progress == 0 || scrollViewState.isTriggered ? 0 : 1)
                    refreshingViewBuilder(scrollViewState.isTriggered)
                        .modifier(GeometryGroupModifier())
                        .opacity(scrollViewState.isTriggered ? 1 : 0)
                })
                .frame(height: PullToRefreshScrollViewConstant.height) // TODO: implement
                .offset(y: PullToRefreshScrollViewConstant.offset) // TODO: implement
                Color.clear
            })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            // List content
            GeometryReader(content: { (geometryProxy) in
                VStack(spacing: 0, content: {
                    // view to show pull to refresh animations
                    // List inset is calculated as safeAreaTopInset + this view height
                    Color.clear
                        .frame(height: offsetValue)
                    List(content: {
                        // view for offset calculation
                        Color.clear
                            .listRowSeparator(.hidden, edges: .top)
                            .frame(height: 0)
                            .listRowInsets(EdgeInsets())
                            .offset(coordinateSpace: PullToRefreshListViewConstant.coordinateSpace, offset: { (offset) in
                                let offsetConclusive = offset - safeAreaTopInset - listTopPadding
                                let offsetOld = scrollViewState.contentOffset
                                scrollViewState.contentOffset = offsetConclusive
                                updateProgressIfNeeded()
                                updateOffsetValueIfNeeded(oldContentOffset: offsetOld)
                                stopIfNeeded()
                                resetReadyToTriggerIfNeeded()
                                startIfNeeded()
                            })
                        contentViewBuilder(geometryProxy.size)
                            .modifier(GeometryGroupModifier())
                    })
                    .environment(\.defaultMinListRowHeight, 0)
                    .coordinateSpace(name: PullToRefreshListViewConstant.coordinateSpace)
                    .listStyle(listStyle)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.vertical, listTopPadding)
                })
                .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
            })
        })
        .readSize(onChange: { (data) in
            safeAreaTopInset = data.safeAreaInsets.top
        })
        .onAppear(perform: {
            scrollViewState.addGestureRecognizer()
        })
        .onDisappear(perform: {
            scrollViewState.removeGestureRecognizer()
        })
        .onChange(of: scrollViewState.isTriggered, perform: { (isTriggered) in
            guard isTriggered else {
                return
            }
            isRefreshing.wrappedValue = true
        })
        .onChange(of: isRefreshing.wrappedValue, perform: { (isRefreshing) in
            if !isRefreshing {
                scrollViewState.isRefreshing = false
                stopIfNeeded()
                resetReadyToTriggerIfNeeded()
                withAnimation {
                    offsetValue = 0
                }
            }
        })
        .onChange(of: scrollViewState.isDragging, perform: { (_) in
            stopIfNeeded()
            resetReadyToTriggerIfNeeded()
        })
    }

    // MARK: - Private

    private func startIfNeeded() {
        if isPullToRefreshEnabled,
           scrollViewState.contentOffset > refreshViewHeight,
           scrollViewState.isReadyToTrigger &&
            !scrollViewState.isRefreshing &&
            !scrollViewState.isTriggered {

            scrollViewState.isReadyToTrigger = false
            scrollViewState.isTriggered = true
            scrollViewState.isRefreshing = true
            isRefreshing.wrappedValue = true
            onRefresh()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func stopIfNeeded() {
        if !scrollViewState.isRefreshing && !scrollViewState.isDragging {
            if scrollViewState.progress > 0 {
                scrollViewState.progress = 0
            }
            if scrollViewState.isTriggered {
                scrollViewState.isTriggered = false
            }
        }
    }

    private func updateOffsetValueIfNeeded(oldContentOffset: CGFloat) {
        // when user touched up in triggered state and List is moving up,
        // we wait for the moment when top offset of List becomes equal to refreshViewHeight
        // then set offsetValue to refreshViewHeight to make space above the List
        if !scrollViewState.isDragging,
           scrollViewState.isTriggered,
           scrollViewState.contentOffset <= refreshViewHeight,
           oldContentOffset > scrollViewState.contentOffset,
           offsetValue == 0 {
            offsetValue = refreshViewHeight
        }
    }

    private func resetReadyToTriggerIfNeeded() {
        if scrollViewState.contentOffset <= 1 &&
            !scrollViewState.isReadyToTrigger &&
            !scrollViewState.isRefreshing &&
            !scrollViewState.isDragging &&
            !scrollViewState.isTriggered {

            scrollViewState.isReadyToTrigger = true
        }
    }

    private func updateProgressIfNeeded() {
        if !scrollViewState.isTriggered && !scrollViewState.isRefreshing && scrollViewState.isReadyToTrigger {
            // initial pulling will increase progress to 1; then when drag finished or
            // fetch finished stopIfNeeded() will be called where progress will be set to 0.
            scrollViewState.progress = min(max(scrollViewState.contentOffset / refreshViewHeight, 0), 1)
        }
    }

}

// MARK: - Preview

// TODO: implement
//struct PullToRefreshListView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        let options = PullToRefreshListViewOptions(lottieViewBackgroundColor: .green,
//                                                   pullingLottieFileName: "animation-pulling-shakuro_logo",
//                                                   refreshingLottieFileName: "animation-refreshing-shakuro_logo")
//        PullToRefreshListView(
//            options: options,
//            isRefreshing: .constant(true),
//            onRefresh: {
//                debugPrint("Refreshing")
//            },
//            contentViewBuilder: { _ in
//                Rectangle()
//                    .fill(.red)
//                    .frame(height: 1000)
//            })
//    }
//}

// MARK: - ScrollViewState

private class ScrollViewState: NSObject, ObservableObject, UIGestureRecognizerDelegate {

    @Published var isDragging: Bool = false
    @Published var isReadyToTrigger: Bool = true
    @Published var isTriggered: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var contentOffset: CGFloat = 0
    @Published var progress: CGFloat = 0

    private var panGestureRecognizer: UIPanGestureRecognizer?

    // MARK: - Public

    internal func addGestureRecognizer() {
        guard let controller = getRootViewController() else {
            return
        }
        // there is no ability to get isDragging state from SwiftUI ScrollView,
        // because ScrollView gesture recognizer intercepts event.
        // That's why custom gesture recognizer is added to application window rootViewController view.
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer = recognizer
        recognizer.delegate = self
        controller.view.addGestureRecognizer(recognizer)
    }

    internal func removeGestureRecognizer() {
        guard let controller = getRootViewController(),
              let recognizer = panGestureRecognizer
        else {
            return
        }
        controller.view.removeGestureRecognizer(recognizer)
    }

    // MARK: - UIGestureRecognizerDelegate

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - Interface Callbacks

    @objc
    private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {

        case .possible,
                .changed:
            break
        case .began:
            isDragging = true
        case .ended,
                .cancelled,
                .failed:
            isDragging = false
        @unknown default:
            break
        }
    }

    // MARK: - Private

    private func getRootViewController() -> UIViewController? {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }

}
