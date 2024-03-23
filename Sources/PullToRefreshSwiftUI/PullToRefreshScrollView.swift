import SwiftUI

public struct PullToRefreshScrollViewOptions {

    public let pullToRefreshAnimationHeight: CGFloat
    public let animationDuration: TimeInterval
    public let animatePullingViewPresentation: Bool
    public let animateRefreshingViewPresentation: Bool

    public init(pullToRefreshAnimationHeight: CGFloat = 100,
                animationDuration: TimeInterval = 0.3,
                animatePullingViewPresentation: Bool = true,
                animateRefreshingViewPresentation: Bool = true) {
        self.pullToRefreshAnimationHeight = pullToRefreshAnimationHeight
        self.animationDuration = animationDuration
        self.animatePullingViewPresentation = animatePullingViewPresentation
        self.animateRefreshingViewPresentation = animateRefreshingViewPresentation
    }

}

private enum PullToRefreshScrollViewConstant {
    static let coordinateSpace: String = "PullToRefreshScrollView.CoordinateSpace"
}

public enum PullToRefreshScrollViewState {
    case idle
    case pulling(progress: CGFloat)
    case refreshing
}

public struct PullToRefreshScrollView<AnimationViewType: View, ContentViewType: View>: View {

    private let options: PullToRefreshScrollViewOptions
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let animationViewBuilder: (_ state: PullToRefreshScrollViewState) -> AnimationViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState = ScrollViewState()

    // MARK: - Initialization

    public init(options: PullToRefreshScrollViewOptions,
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder animationViewBuilder: @escaping (_ state: PullToRefreshScrollViewState) -> AnimationViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.options = options
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.animationViewBuilder = animationViewBuilder
        self.contentViewBuilder = contentViewBuilder
    }

    // MARK: - UI

    public var body: some View {
        let defaultAnimation: Animation = .easeInOut(duration: options.animationDuration)
        ZStack(alignment: .top, content: {
            // Animations
            VStack(spacing: 0, content: {
                ZStack(alignment: .center, content: {
                    animationViewBuilder(scrollViewState.state)
                        .modifier(GeometryGroupModifier())
                })
                .frame(height: options.pullToRefreshAnimationHeight)
                Color.clear
            })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            // Scroll content
            GeometryReader(content: { geometryProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators, content: {
                    VStack(spacing: 0, content: {
                        Color.clear
                            .frame(height: options.pullToRefreshAnimationHeight * scrollViewState.progress)
                        contentViewBuilder(geometryProxy.size)
                            .modifier(GeometryGroupModifier())
                    })
                    .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
                    .readLayoutData(coordinateSpace: .named(PullToRefreshScrollViewConstant.coordinateSpace), onChange: { (data) in
                        scrollViewState.contentOffset = data.frameInCoordinateSpace.minY
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
           (scrollViewState.contentOffset * 2) >  options.pullToRefreshAnimationHeight,
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
            scrollViewState.progress = min(max((scrollViewState.contentOffset * 2) /  options.pullToRefreshAnimationHeight, 0), 1)
        }
    }

}

// MARK: - Preview

//#Preview {
//    PullToRefreshScrollView(
//        options: PullToRefreshScrollViewOptions(pullToRefreshAnimationHeight: 100,
//                                                animationDuration: 0.3,
//                                                animatePullingViewPresentation: true,
//                                                animateRefreshingViewPresentation: true),
//        isRefreshing: .constant(true),
//        onRefresh: {
//            debugPrint("Refreshing")
//        },
//        pullingViewBuilder: { (progress) in
//            ProgressView(value: progress, total: 1)
//                .progressViewStyle(.linear)
//        },
//        refreshingViewBuilder: { (isTriggered) in
//            ProgressView()
//                .progressViewStyle(.circular)
//        },
//        contentViewBuilder: { _ in
//            Color(.lightGray)
//                .frame(height: 1000)
//        })
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

    var state: PullToRefreshScrollViewState {
        if isTriggered {
            return .refreshing
        } else if progress > 0 {
            return .pulling(progress: progress)
        } else {
            return .idle
        }
    }

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
