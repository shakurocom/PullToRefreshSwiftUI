import Lottie
import PullToRefreshSwiftUI
import SwiftUI

struct ScrollContentView: View {

    private enum AnimationType {
        case native
        case progressView
        case lottie
    }

    @State private var isRefreshing: Bool = false
    @State private var animationType: AnimationType = .native

    var body: some View {
        PullToRefreshScrollView(
            options: PullToRefreshScrollViewOptions(pullToRefreshAnimationHeight: 100,
                                                    animationDuration: 0.3,
                                                    animatePullingViewPresentation: true,
                                                    animateRefreshingViewPresentation: true),
            isRefreshing: $isRefreshing,
            onRefresh: {
                debugPrint("Refreshing")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
                    isRefreshing = false
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
                        CircularProgressView(progress: progress)
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
                VStack(spacing: 16, content: {
                    Text(isRefreshing ? "Refreshing" : "Idle")
                        .font(.largeTitle)
                        .foregroundStyle(isRefreshing ? .white : .black)
                    Picker("Current animation type", selection: $animationType) {
                        Text("Native").tag(AnimationType.native)
                        Text("ProgressView").tag(AnimationType.progressView)
                        Text("Lottie").tag(AnimationType.lottie)
                    }
                    .pickerStyle(.segmented)
                    Color.clear
                })
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .background(Color(isRefreshing ? .darkGray : .lightGray))
                .animation(.linear(duration: 0.3), value: isRefreshing)
                .frame(height: 1000)
            })
        .navigationTitle("Scroll View Example")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    ScrollContentView()
}
