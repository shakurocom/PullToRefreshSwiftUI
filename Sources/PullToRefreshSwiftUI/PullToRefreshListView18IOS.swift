//
//
// Copyright (c) 2025 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

@available(iOS 18.0, *)
public struct PullToRefreshListView18IOS<AnimationViewType: View, ContentViewType: View>: View {

    private let pullToRefreshAnimationHeight: CGFloat
    private let pullToRefreshPullHeight: CGFloat
    private let animationDuration: TimeInterval
    private let offsetAboveRefreshingAnimation: CGFloat
    private let showsIndicators: Bool
    private let isPullToRefreshEnabled: Bool
    private let onScroll: (_ oldOffsetY: CGFloat, _ newOffsetY: CGFloat) -> Void
    private let onEndDragging: () -> Void
    private let isRefreshing: Binding<Bool>
    private let onRefresh: () -> Void
    private let animationViewBuilder: (_ state: PullToRefreshListViewState) -> AnimationViewType
    private let contentViewBuilder: (_ scrollViewSize: CGSize) -> ContentViewType

    @State private var scrollViewSize: CGSize = .zero   // needed to build content
    @State private var animationOffsetY: CGFloat = 0    // offset to keep refreshing animation in proper place
    @State private var pullToRefreshProgressPoints: CGFloat = 0 // progress of pull-to-refresh
    @State private var pullToRefreshIsInteracting: Bool = false // user is actively dragging scroll
    @State private var pullToRefreshState: PullToRefreshListViewState = .idle // state of the animation

    // MARK: - Initialization

    public init(pullToRefreshAnimationHeight: CGFloat,
                pullToRefreshPullHeight: CGFloat,
                animationDuration: TimeInterval = 0.3,
                showsIndicators: Bool = true,
                isPullToRefreshEnabled: Bool = true,
                offsetAboveRefreshingAnimation: CGFloat = 0,
                onScroll: @escaping (_ oldOffsetY: CGFloat, _ newOffsetY: CGFloat) -> Void = { _, _ in },
                onEndDragging: @escaping () -> Void = { },
                isRefreshing: Binding<Bool>,
                onRefresh: @escaping () -> Void,
                @ViewBuilder animationViewBuilder: @escaping (_ state: PullToRefreshListViewState) -> AnimationViewType,
                @ViewBuilder contentViewBuilder: @escaping (_ scrollViewSize: CGSize) -> ContentViewType) {
        self.pullToRefreshAnimationHeight = pullToRefreshAnimationHeight
        self.pullToRefreshPullHeight = pullToRefreshPullHeight
        self.animationDuration = animationDuration
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
        ZStack(alignment: .top, content: {
            mainListView()
            pullToRefreshAnimationView()
        })
            .clipped()
            .onChange(of: isRefreshing.wrappedValue, { (_, newIsRefreshing: Bool) -> Void in
                if newIsRefreshing {
                    showPullToRefreshAnimationIfNeeded()
                } else {
                    endPullToRefreshAnimationIfNeeded()
                }
            })
    }

    @ViewBuilder
    private func mainListView() -> some View {
        List(content: {
            Color.clear
                .frame(height: offsetAboveRefreshingAnimation)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .id("above-offset")
            if pullToRefreshState == .refreshing {
                Color.clear
                    .frame(height: pullToRefreshPullHeight)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .id("refreshing-spacer")
            }
            contentViewBuilder(scrollViewSize)
                .modifier(GeometryGroupModifier())
        })
            .environment(\.defaultMinListRowHeight, 0)
            .listStyle(PlainListStyle())
            .animation(.easeInOut(duration: animationDuration), value: pullToRefreshState)
            .onScrollGeometryChange(
                for: ScrollGeometry.self,
                of: { return $0 },
                action: { (oldValue: ScrollGeometry, newValue: ScrollGeometry) -> Void in
                    scrollViewSize = newValue.bounds.size
                    // top inset is usually added by standard navigation bar
                    let oldOffsetY = oldValue.contentOffset.y + oldValue.contentInsets.top
                    let newOffsetY = newValue.contentOffset.y + newValue.contentInsets.top
                    onScroll(oldOffsetY, newOffsetY)
                    updateAnimationOffset(contentOffset: newOffsetY)
                })
            .onScrollPhaseChange({ (oldPhase: ScrollPhase, newPhase: ScrollPhase) -> Void in
                pullToRefreshIsInteracting = newPhase == .interacting
                if oldPhase == .interacting && newPhase != .interacting {
                    // user released finger
                    onEndDragging()
                    triggerPullToRefreshIfNeeded()
                }
            })
    }

    @ViewBuilder
    private func pullToRefreshAnimationView() -> some View {
        ZStack(alignment: .top, content: {
            animationViewBuilder(pullToRefreshState)
                .frame(height: pullToRefreshAnimationHeight)
                .modifier(GeometryGroupModifier())
        })
            .opacity(isPullToRefreshEnabled ? 1 : 0)
            .frame(height: pullToRefreshState == .refreshing ? pullToRefreshAnimationHeight : pullToRefreshProgressPoints,
                   alignment: .top)
            .frame(maxWidth: .infinity)
            .clipped()
            .offset(x: 0, y: animationOffsetY + offsetAboveRefreshingAnimation)
    }

    // MARK: - Private

    private func updateAnimationOffset(contentOffset: CGFloat) {
        if contentOffset > 0 {
            animationOffsetY = -contentOffset
            pullToRefreshProgressPoints = 0
        } else {
            animationOffsetY = 0
            pullToRefreshProgressPoints = -contentOffset
        }
        updatePullToRefreshPullingState()
    }

    private func updatePullToRefreshPullingState() {
        switch pullToRefreshState {
        case .idle,
                .pulling:
            if pullToRefreshProgressPoints <= 0.5 {
                pullToRefreshState = .idle
            } else {
                let progress = pullToRefreshProgressPoints / pullToRefreshPullHeight
                pullToRefreshState = .pulling(progress: progress)
            }

        case .refreshing:
            // need to wait for external signal that refreshing has ended
            break

        case .finishing:
            if pullToRefreshProgressPoints <= 0.5 {
                pullToRefreshState = .idle
            } else {
                pullToRefreshState = .finishing
            }
        }
    }

    private func triggerPullToRefreshIfNeeded() {
        guard isPullToRefreshEnabled else {
            return
        }
        switch pullToRefreshState {
        case .idle,
                .refreshing,
                .finishing:
            // wrong state
            break

        case .pulling(let progress):
            if progress >= 1.0 {
                pullToRefreshState = .refreshing
                isRefreshing.wrappedValue = true
                onRefresh()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func showPullToRefreshAnimationIfNeeded() {
        switch pullToRefreshState {
        case .idle,
                .pulling,
                .finishing:
            pullToRefreshState = .refreshing

        case .refreshing:
            // already refreshing
            break
        }
    }

    private func endPullToRefreshAnimationIfNeeded() {
        switch pullToRefreshState {
        case .idle:
            // should not be here
            break

        case .pulling:
            // no need to finish - deceleration will do the trick
            break

        case .refreshing:
            withAnimation(.easeInOut(duration: animationDuration), {
                pullToRefreshState = .finishing
            })

        case .finishing:
            // already finishing
            break
        }
    }

}

// MARK: - Preview

#Preview(body: {
    if #available(iOS 18.0, *) {
        PullToRefreshListView18IOS(
            pullToRefreshAnimationHeight: 100,
            pullToRefreshPullHeight: 100,
            isRefreshing: .constant(true),
            onRefresh: {
                print("Refreshing")
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
    } else {
        // Fallback on earlier versions
    }
})
