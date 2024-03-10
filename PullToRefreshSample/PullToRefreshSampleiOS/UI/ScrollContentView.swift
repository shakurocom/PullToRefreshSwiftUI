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
                let options = LottieViewSwiftUIOptions(lottieFileName: "animation-pulling-shakuro_logo", backgroundColor: .clear)
                LottieViewSwiftUI(options: options, isPlaying: nil, currentProgress: .constant(progress))
            },
            refreshingViewBuilder: { (isTriggered) in
                let options = LottieViewSwiftUIOptions(lottieFileName: "animation-refreshing-shakuro_logo", backgroundColor: .clear)
                LottieViewSwiftUI(options: options, isPlaying: .constant(isTriggered), currentProgress: nil)
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
