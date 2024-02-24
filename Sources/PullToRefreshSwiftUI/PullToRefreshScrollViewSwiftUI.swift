import SwiftUI

public struct PullToRefreshScrollViewSwiftUIOptions {

    public enum Constant {
        static let animationDuration: TimeInterval = 0.3
    }

    public let lottieViewBackgroundColor: UIColor
    public let pullingLottieFileName: String
    public let refreshingLottieFileName: String

    public init(lottieViewBackgroundColor: UIColor, pullingLottieFileName: String, refreshingLottieFileName: String) {
        self.lottieViewBackgroundColor = lottieViewBackgroundColor
        self.pullingLottieFileName = pullingLottieFileName
        self.refreshingLottieFileName = refreshingLottieFileName
    }

}

public enum PullToRefreshScrollViewSwiftUIConstant {
    public static let coordinateSpace: String = "PullToRefreshScrollViewSwiftUI.CoordinateSpace"
    public static let height: CGFloat = 100
    public static let offset: CGFloat = 0
}

public struct PullToRefreshScrollViewSwiftUI<ContentViewType: View>: View {

    private let options: PullToRefreshScrollViewSwiftUIOptions
    private let refreshViewHeight: CGFloat
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState = ScrollViewState()

    // MARK: - Initialization

    public init(options: PullToRefreshScrollViewSwiftUIOptions,
                refreshViewHeight: CGFloat = (PullToRefreshScrollViewSwiftUIConstant.offset * 2 + PullToRefreshScrollViewSwiftUIConstant.height),
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.options = options
        self.refreshViewHeight = refreshViewHeight
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.contentViewBuilder = contentViewBuilder
    }

    // MARK: - UI

    public var body: some View {
        let defaultAnimation: Animation = .easeInOut(duration: PullToRefreshScrollViewSwiftUIOptions.Constant.animationDuration)
        ZStack(alignment: .top, content: {
            ZStack(alignment: .center, content: {
                refreshingView()
                    .frame(height: PullToRefreshScrollViewSwiftUIConstant.height)
                    .offset(y: PullToRefreshScrollViewSwiftUIConstant.offset)
                    .opacity(scrollViewState.isTriggered ? 1 : 0)
                    .animation(defaultAnimation, value: scrollViewState.isTriggered)
                pullingView()
                    .frame(height: PullToRefreshScrollViewSwiftUIConstant.height)
                    .offset(y: PullToRefreshScrollViewSwiftUIConstant.offset)
                    .opacity(scrollViewState.isTriggered ? 0 : 1)
                    .animation(defaultAnimation, value: scrollViewState.isTriggered)
            })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            GeometryReader(content: { geometryProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators, content: {
                    VStack(spacing: 0, content: {
                        Color.clear
                            .frame(height: refreshViewHeight * scrollViewState.progress)
                        if #available(iOS 17.0, *) {
                            contentViewBuilder(geometryProxy.size)
                            // https://medium.com/the-swift-cooperative/swiftui-geometrygroup-guide-from-theory-to-practice-1a7f4b04c4ec
                                .geometryGroup()
                        } else {
                            contentViewBuilder(geometryProxy.size)
                                .transformEffect(.identity)
                        }
                    })
                    .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
                    .offset(coordinateSpace: PullToRefreshScrollViewSwiftUIConstant.coordinateSpace, offset: { offset in
                        scrollViewState.contentOffset = offset
                        updateProgressIfNeeded()
                        stopIfNeeded()
                        resetReadyToTriggerIfNeeded()
                        startIfNeeded()
                    })
                })
                .scrollClipDisabled(true)
                .coordinateSpace(name: PullToRefreshScrollViewSwiftUIConstant.coordinateSpace)
            })
            .onChange(of: scrollViewState.isTriggered, { (_, isTriggered) in
                guard isTriggered else {
                    return
                }
                isRefreshing.wrappedValue = true
            })
            .onChange(of: isRefreshing.wrappedValue, { (_, isRefreshing) in
                if !isRefreshing {
                    scrollViewState.isRefreshing = false
                    stopIfNeeded()
                    resetReadyToTriggerIfNeeded()
                }
            })
            .onChange(of: scrollViewState.isDragging, {
                stopIfNeeded()
                resetReadyToTriggerIfNeeded()
            })
        })
        .onAppear(perform: {
            scrollViewState.addGestureRecognizer()
        })
        .onDisappear(perform: {
            scrollViewState.removeGestureRecognizer()
        })
    }

    // MARK: - Private

    private func pullingView() -> some View {
        let options = LottieViewSwiftUIOptions(lottieFileName: options.pullingLottieFileName, backgroundColor: options.lottieViewBackgroundColor)
        return LottieViewSwiftUI(options: options, isPlaying: nil, currentProgress: $scrollViewState.progress)
    }

    private func refreshingView() -> some View {
        let options = LottieViewSwiftUIOptions(lottieFileName: options.refreshingLottieFileName, backgroundColor: options.lottieViewBackgroundColor)
        return LottieViewSwiftUI(options: options, isPlaying: $scrollViewState.isTriggered, currentProgress: nil)
    }

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

struct PullToRefreshScrollViewSwiftUI_Previews: PreviewProvider {

    static var previews: some View {
        let options = PullToRefreshScrollViewSwiftUIOptions(lottieViewBackgroundColor: .green,
                                                            pullingLottieFileName: "animation-pulling-shakuro_logo",
                                                            refreshingLottieFileName: "animation-refreshing-shakuro_logo")
        PullToRefreshScrollViewSwiftUI(
            options: options,
            isRefreshing: .constant(true),
            onRefresh: {
                debugPrint("Refreshing")
            },
            contentViewBuilder: { _ in
                Rectangle()
                    .fill(.red)
                    .frame(height: 1000)
            })
    }
}

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

// MARK: - ScrollView Offset

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
