import SwiftUI

public struct PullToRefreshScrollViewOptions {

    public let animationDuration: TimeInterval

    public init(animationDuration: TimeInterval = 0.3) {
        self.animationDuration = animationDuration
    }

}

public enum PullToRefreshScrollViewConstant {
    public static let coordinateSpace: String = "PullToRefreshScrollView.CoordinateSpace"
    public static let height: CGFloat = 100
    public static let offset: CGFloat = 0
}

public struct PullToRefreshScrollView<PullingViewType: View, RefreshingViewType: View, ContentViewType: View>: View {

    private let options: PullToRefreshScrollViewOptions
    private let refreshViewHeight: CGFloat
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let pullingViewBuilder: (_ progress: CGFloat) -> PullingViewType
    private let refreshingViewBuilder: (_ isTriggered: Bool) -> RefreshingViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState = ScrollViewState()

    // MARK: - Initialization

    public init(options: PullToRefreshScrollViewOptions,
                refreshViewHeight: CGFloat = (PullToRefreshScrollViewConstant.offset * 2 + PullToRefreshScrollViewConstant.height),
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder pullingViewBuilder: @escaping (_ progress: CGFloat) -> PullingViewType,
                @ViewBuilder refreshingViewBuilder: @escaping (_ isTriggered: Bool) -> RefreshingViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.options = options
        self.refreshViewHeight = refreshViewHeight
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.isRefreshing = isRefreshing
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
                        .animation(defaultAnimation, value: scrollViewState.isTriggered)
                    refreshingViewBuilder(scrollViewState.isTriggered)
                        .modifier(GeometryGroupModifier())
                        .opacity(scrollViewState.isTriggered ? 1 : 0)
                        .animation(defaultAnimation, value: scrollViewState.isTriggered)
                })
                .frame(height: PullToRefreshScrollViewConstant.height) // TODO: implement
                .offset(y: PullToRefreshScrollViewConstant.offset) // TODO: implement
                Color.clear
            })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            // Scroll content
            GeometryReader(content: { geometryProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators, content: {
                    VStack(spacing: 0, content: {
                        Color.clear
                            .frame(height: refreshViewHeight * scrollViewState.progress)
                        contentViewBuilder(geometryProxy.size)
                            .modifier(GeometryGroupModifier())
                    })
                    .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
                    .offset(coordinateSpace: PullToRefreshScrollViewConstant.coordinateSpace, offset: { offset in
                        scrollViewState.contentOffset = offset
                        updateProgressIfNeeded()
                        stopIfNeeded()
                        resetReadyToTriggerIfNeeded()
                        startIfNeeded()
                    })
                })
                .coordinateSpace(name: PullToRefreshScrollViewConstant.coordinateSpace)
            })
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
        if !scrollViewState.isRefreshing && !scrollViewState.isDragging && scrollViewState.isTriggered {
            scrollViewState.progress = 0
            scrollViewState.isTriggered = false
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
            // isRefreshing check is here because we need to remove conflict between setting progress.
            scrollViewState.progress = min(max(scrollViewState.contentOffset / refreshViewHeight, 0), 1)
        }
    }

}

// MARK: - Preview

// TODO: implement
//struct PullToRefreshScrollView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        let options = PullToRefreshScrollViewOptions(lottieViewBackgroundColor: .green,
//                                                     pullingLottieFileName: "animation-pulling-shakuro_logo",
//                                                     refreshingLottieFileName: "animation-refreshing-shakuro_logo")
//        PullToRefreshScrollView(
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
