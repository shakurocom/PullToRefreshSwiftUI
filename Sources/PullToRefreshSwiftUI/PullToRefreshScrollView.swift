//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

public enum PullToRefreshScrollViewState {
    case idle
    case pulling(progress: CGFloat)
    case refreshing
    case finishing(progress: CGFloat, isTriggered: Bool)
}

public struct PullToRefreshScrollView<AnimationViewType: View, ContentViewType: View>: View {

    private let pullToRefreshAnimationHeight: CGFloat
    private let animationDuration: TimeInterval
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let offsetAboveRefreshingAnimation: CGFloat
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let animationViewBuilder: (_ state: PullToRefreshScrollViewState) -> AnimationViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @StateObject private var scrollViewState: ScrollViewState

    @State private var topOffset: CGFloat = 0

    private let isLogEnabled: Bool = false

    // MARK: - Initialization

    public init(pullToRefreshAnimationHeight: CGFloat,
                animationDuration: TimeInterval = 0.3,
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                offsetAboveRefreshingAnimation: CGFloat = 0,
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder animationViewBuilder: @escaping (_ state: PullToRefreshScrollViewState) -> AnimationViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.pullToRefreshAnimationHeight = pullToRefreshAnimationHeight
        self.animationDuration = animationDuration
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.offsetAboveRefreshingAnimation = offsetAboveRefreshingAnimation
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.animationViewBuilder = animationViewBuilder
        self.contentViewBuilder = contentViewBuilder
        _scrollViewState = StateObject(wrappedValue: ScrollViewState(pullToRefreshAnimationHeight: pullToRefreshAnimationHeight))
    }

    // MARK: - UI

    public var body: some View {
        let defaultAnimation: Animation = .easeInOut(duration: animationDuration)
        ZStack(alignment: .top, content: {
            // Animations
            VStack(spacing: 0, content: {
                Color.clear
                    .frame(height: offsetAboveRefreshingAnimation)
                ZStack(alignment: .center, content: {
                    animationViewBuilder(scrollViewState.state)
                        .modifier(GeometryGroupModifier())
                })
                    .frame(height: pullToRefreshAnimationHeight)
                Color.clear
            })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            // Scroll content
            GeometryReader(content: { geometryProxy in
                ScrollView(.vertical, showsIndicators: showsIndicators, content: {
                    VStack(spacing: 0, content: {
                        Color.clear
                            .frame(height: offsetAboveRefreshingAnimation)
                        Color.clear
                            .frame(height: pullToRefreshAnimationHeight * scrollViewState.progress)
                        contentViewBuilder(geometryProxy.size)
                            .modifier(GeometryGroupModifier())
                    })
                    .animation(scrollViewState.isDragging ? nil : defaultAnimation, value: scrollViewState.progress)
                    .readLayoutData(coordinateSpace: .global, onChange: { (data) in
                        let offsetConclusive = data.frameInCoordinateSpace.minY - topOffset
                        if isLogEnabled {
                            debugPrint("Current offset: \(offsetConclusive) = \(data.frameInCoordinateSpace.minY) - \(topOffset)")
                        }
                        scrollViewState.contentOffset = offsetConclusive
                        updateProgressIfNeeded()
                        resetReadyTriggeredStateIfNeeded()
                        startIfNeeded()
                    })
                })
            })
        })
        .readLayoutData(coordinateSpace: .global, onChange: { (data) in
            topOffset = data.frameInCoordinateSpace.minY
            if isLogEnabled {
                debugPrint("Setting topOffset = \(topOffset)")
            }
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
                scrollViewState.isFinishing = true
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
           (scrollViewState.contentOffset * 2) >  pullToRefreshAnimationHeight,
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
                if scrollViewState.isTriggered {
                    scrollViewState.isFinishing = true
                    Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true, block: { (timer) in
                        let progressLocal = scrollViewState.progress - 0.03
                        if progressLocal <= 0 {
                            scrollViewState.isFinishing = false
                            scrollViewState.progress = 0
                            resetReadyTriggeredStateIfNeeded()
                            timer.invalidate()
                        } else {
                            scrollViewState.progress = progressLocal
                        }
                    })
                } else {
                    scrollViewState.progress = 0
                    resetReadyTriggeredStateIfNeeded()
                }
            }
        }
    }

    private func resetReadyTriggeredStateIfNeeded() {
        if scrollViewState.contentOffset <= 1 &&
            scrollViewState.progress == 0 &&
            scrollViewState.isTriggered &&
            !scrollViewState.isRefreshing &&
            !scrollViewState.isDragging {

            scrollViewState.isTriggered = false
        }
    }

    private func updateProgressIfNeeded() {
        if !scrollViewState.isRefreshing && !scrollViewState.isTriggered && !scrollViewState.isFinishing {
            // initial pulling will increase progress to 1; then when drag finished or
            // fetch finished stopIfNeeded() will be called where progress will be set to 0.
            // isRefreshing check is here because we need to remove conflict between setting progress.
            scrollViewState.progress = min(max((scrollViewState.contentOffset * 2) /  pullToRefreshAnimationHeight, 0), 1)
        }
    }

}

// MARK: - Preview

#Preview(body: {
    PullToRefreshScrollView(
        pullToRefreshAnimationHeight: 100,
        animationDuration: 0.3,
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
            Color(.lightGray)
                .frame(height: 1000)
        })
})

// MARK: - ScrollViewState

private class ScrollViewState: NSObject, ObservableObject, UIGestureRecognizerDelegate {

    @Published var isDragging: Bool = false
    var isTriggered: Bool = false
    var isRefreshing: Bool = false
    var isFinishing: Bool = false
    var contentOffset: CGFloat = 0
    @Published var progress: CGFloat = 0

    private var panGestureRecognizer: UIPanGestureRecognizer?

    let pullToRefreshAnimationHeight: CGFloat

    var state: PullToRefreshScrollViewState {
        if isRefreshing {
            return .refreshing
        } else if progress > 0 && !isTriggered && !isFinishing {
            return .pulling(progress: progress)
        } else if isFinishing {
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
