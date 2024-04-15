import SwiftUI

public struct PullToRefreshListViewOptions {

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

public enum PullToRefreshListViewState {
    case idle
    case pulling(progress: CGFloat)
    case refreshing
    case finishing(progress: CGFloat, isTriggered: Bool)
}

public struct PullToRefreshListView<AnimationViewType: View, ContentViewType: View>: View {

    private let options: PullToRefreshListViewOptions
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let animationViewBuilder: (_ state: PullToRefreshListViewState) -> AnimationViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState

    @State private var topOffset: CGFloat = 0

    // MARK: - Initialization

    public init(options: PullToRefreshListViewOptions,
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder animationViewBuilder: @escaping (_ state: PullToRefreshListViewState) -> AnimationViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.options = options
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.animationViewBuilder = animationViewBuilder
        self.contentViewBuilder = contentViewBuilder
        _scrollViewState = StateObject(wrappedValue: ScrollViewState(pullToRefreshAnimationHeight: options.pullToRefreshAnimationHeight))
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
            // List content
            GeometryReader(content: { (geometryProxy) in
                VStack(spacing: 0, content: {
                    // view to show pull to refresh animations
                    // List inset is calculated as safeAreaTopInset + this view height
                    Color.clear
                        .frame(height: options.pullToRefreshAnimationHeight * scrollViewState.progress)
                    List(content: {
                        // view for offset calculation
                        Color.clear
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .frame(height: 1)
                            .listRowInsets(EdgeInsets())
                            .readLayoutData(coordinateSpace: .global, onChange: { (data) in
                                let offsetConclusive = data.frameInCoordinateSpace.minY - topOffset
                                scrollViewState.contentOffset = offsetConclusive
                                updateProgressIfNeeded()
                                stopIfNeeded()
                                resetReadyTriggeredStateIfNeeded()
                                startIfNeeded()
                            })
                        contentViewBuilder(geometryProxy.size)
                            .modifier(GeometryGroupModifier())
                    })
                    .environment(\.defaultMinListRowHeight, 0)
                    .listStyle(PlainListStyle())
                })
                .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
            })
        })
        .readLayoutData(coordinateSpace: .global, onChange: { (data) in
            topOffset = data.frameInCoordinateSpace.minY
        })
        .onAppear(perform: {
            scrollViewState.addGestureRecognizer()
        })
        .onDisappear(perform: {
            scrollViewState.removeGestureRecognizer()
        })
        .onChange(of: isRefreshing.wrappedValue, perform: { (isRefreshing) in
            if !isRefreshing {
                scrollViewState.isRefreshing = false
                stopIfNeeded()
                resetReadyTriggeredStateIfNeeded()
            }
        })
        .onChange(of: scrollViewState.isDragging, perform: { (_) in
            stopIfNeeded()
            resetReadyTriggeredStateIfNeeded()
        })
    }

    // MARK: - Private

    private func startIfNeeded() {
        if isPullToRefreshEnabled,
           scrollViewState.contentOffset > options.pullToRefreshAnimationHeight,
           !scrollViewState.isTriggered &&
            !scrollViewState.isRefreshing {

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
        }
    }

    private func resetReadyTriggeredStateIfNeeded() {
        if scrollViewState.contentOffset <= 1 &&
            scrollViewState.isTriggered &&
            !scrollViewState.isRefreshing &&
            !scrollViewState.isDragging {

            scrollViewState.isTriggered = false
        }
    }

    private func updateProgressIfNeeded() {
        if !scrollViewState.isRefreshing && !scrollViewState.isTriggered {
            // initial pulling will increase progress to 1; then when drag finished or
            // fetch finished stopIfNeeded() will be called where progress will be set to 0.
            // isRefreshing check is here because we need to remove conflict between setting progress.
            let progress = min(max(scrollViewState.contentOffset / options.pullToRefreshAnimationHeight, 0), 1)
            if progress > scrollViewState.progress {
                scrollViewState.progress = progress
            }
        }
    }

}

// MARK: - Preview

#Preview(body: {
    PullToRefreshListView(
        options: PullToRefreshListViewOptions(pullToRefreshAnimationHeight: 100,
                                              animationDuration: 0.3,
                                              animatePullingViewPresentation: true,
                                              animateRefreshingViewPresentation: true),
        isRefreshing: .constant(true),
        onRefresh: {
            debugPrint("Refreshing")
        },
        animationViewBuilder: { (state) in
            switch state {
            case .idle:
                Color.clear
            case .pulling(let progress):
                ProgressView(value: progress, total: 1)
                    .progressViewStyle(.linear)
            case .refreshing:
                ProgressView()
                    .progressViewStyle(.circular)
            case .finishing(let progress, let isTriggered):
                if isTriggered {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    ProgressView(value: progress, total: 1)
                        .progressViewStyle(.linear)
                }
            }
        },
        contentViewBuilder: { _ in
            ForEach(0..<5, content: { (item) in
                Text("Item \(item)")
            })
        })
})

// MARK: - ScrollViewState

private class ScrollViewState: NSObject, ObservableObject, UIGestureRecognizerDelegate {

    @Published var isDragging: Bool = false
    @Published var isTriggered: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var contentOffset: CGFloat = 0
    @Published var progress: CGFloat = 0

    private var panGestureRecognizer: UIPanGestureRecognizer?

    let pullToRefreshAnimationHeight: CGFloat

    var state: PullToRefreshListViewState {
        if isRefreshing {
            return .refreshing
        } else if progress > 0 && !isTriggered {
            return .pulling(progress: progress)
        } else if contentOffset > 0 {
            let progress = min(max(contentOffset / pullToRefreshAnimationHeight, 0), 1)
            return .finishing(progress: progress, isTriggered: isTriggered)
        } else {
            return .idle
        }
    }

    // MARK: - Initialization

    init(pullToRefreshAnimationHeight: CGFloat) {
        self.pullToRefreshAnimationHeight = pullToRefreshAnimationHeight
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
