import PullToRefreshSwiftUI
import SwiftUI

struct ScrollContentView: View {

    @State private var isRefreshing: Bool = false

    var body: some View {
        let options = PullToRefreshScrollViewSwiftUIOptions(lottieViewBackgroundColor: .clear,
                                                            pullingLottieFileName: "animation-pulling-shakuro_logo",
                                                            refreshingLottieFileName: "animation-refreshing-shakuro_logo")
        PullToRefreshScrollViewSwiftUI(
            options: options,
            isRefreshing: $isRefreshing,
            onRefresh: {
                debugPrint("Refreshing")
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(5), execute: {
                    isRefreshing = false
                })
            },
            contentViewBuilder: { _ in
                Rectangle()
                    .fill(.gray)
                    .frame(height: 1000)
            })
    }

}

#Preview {
    ScrollContentView()
}
