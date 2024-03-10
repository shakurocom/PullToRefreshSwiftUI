import Lottie
import PullToRefreshSwiftUI
import SwiftUI

struct ScrollContentView: View {

    @State private var isRefreshing: Bool = false

    var body: some View {
        let options = PullToRefreshScrollViewOptions()
        PullToRefreshScrollView(
            options: options,
            isRefreshing: $isRefreshing,
            onRefresh: {
                debugPrint("Refreshing")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
                    isRefreshing = false
                })
            },
            pullingViewBuilder: { (progress) in
                LottieView(animation: .named("animation-pulling-shakuro_logo"))
                    .playbackMode(.paused(at: .progress(progress)))
            },
            refreshingViewBuilder: { (isTriggered) in
                LottieView(animation: .named("animation-refreshing-shakuro_logo"))
                    .playbackMode(isTriggered ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
            },
            contentViewBuilder: { _ in
                Rectangle()
                    .fill(.gray)
                    .frame(height: 1000)
            })
        .navigationTitle("Scroll View Example")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    ScrollContentView()
}
