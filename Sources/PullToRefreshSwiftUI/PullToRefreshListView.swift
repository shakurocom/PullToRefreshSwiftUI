//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

public enum PullToRefreshListViewState: Equatable {
    case idle
    case pulling(progress: CGFloat)
    case refreshing
    case finishing  // state after refreshing - view returning to idle state
}

public struct PullToRefreshListView<AnimationViewType: View, ContentViewType: View>: View {

    private let pullToRefreshAnimationHeight: CGFloat
    private let pullToRefreshPullHeight: CGFloat
    private let offsetAboveRefreshingAnimation: CGFloat
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let onScroll: (_ oldOffsetY: CGFloat, _ newOffsetY: CGFloat, _ isInteracting: Bool) -> Void
    private let onEndDragging: () -> Void
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let animationViewBuilder: (_ state: PullToRefreshListViewState) -> AnimationViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    // MARK: - Initialization

    /// - parameter onScroll: iOS 18+
    /// - parameter onEndDragging: iOS 18+
    public init(pullToRefreshAnimationHeight: CGFloat,
                pullToRefreshPullHeight: CGFloat,
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                offsetAboveRefreshingAnimation: CGFloat = 0,
                onScroll: @escaping (_ oldOffsetY: CGFloat, _ newOffsetY: CGFloat, _ isInteracting: Bool) -> Void = { _, _, _ in },
                onEndDragging: @escaping () -> Void = { },
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder animationViewBuilder: @escaping (_ state: PullToRefreshListViewState) -> AnimationViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.pullToRefreshAnimationHeight = pullToRefreshAnimationHeight
        self.pullToRefreshPullHeight = pullToRefreshPullHeight
        self.offsetAboveRefreshingAnimation = offsetAboveRefreshingAnimation
        self.showsIndicators = showsIndicators
        self.isPullToRefreshEnabled = isPullToRefreshEnabled
        self.onScroll = onScroll
        self.onEndDragging = onEndDragging
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.animationViewBuilder = animationViewBuilder
        self.contentViewBuilder = contentViewBuilder
    }

    // MARK: - UI

    public var body: some View {
        if #available(iOS 18.0, *) {
            PullToRefreshListView18IOS(pullToRefreshAnimationHeight: pullToRefreshAnimationHeight,
                                       pullToRefreshPullHeight: pullToRefreshPullHeight,
                                       showsIndicators: showsIndicators,
                                       isPullToRefreshEnabled: isPullToRefreshEnabled,
                                       offsetAboveRefreshingAnimation: offsetAboveRefreshingAnimation,
                                       onScroll: onScroll,
                                       onEndDragging: onEndDragging,
                                       isRefreshing: isRefreshing,
                                       onRefresh: onRefresh,
                                       animationViewBuilder: animationViewBuilder,
                                       contentViewBuilder: contentViewBuilder)
        } else {
            PullToRefreshListViewOldIOS(pullToRefreshAnimationHeight: pullToRefreshAnimationHeight,
                                        showsIndicators: showsIndicators,
                                        isPullToRefreshEnabled: isPullToRefreshEnabled,
                                        offsetAboveRefreshingAnimation: offsetAboveRefreshingAnimation,
                                        isRefreshing: isRefreshing,
                                        onRefresh: onRefresh,
                                        animationViewBuilder: animationViewBuilder,
                                        contentViewBuilder: contentViewBuilder)
        }
    }

}

// MARK: - Preview

#Preview(body: {
    PullToRefreshListView(
        pullToRefreshAnimationHeight: 100,
        pullToRefreshPullHeight: 100,
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
            case .finishing:
                ProgressView()
                    .progressViewStyle(.circular)
            }
        },
        contentViewBuilder: { _ in
            ForEach(0..<5, content: { (item) in
                Text("Item \(item)")
            })
        })
})
