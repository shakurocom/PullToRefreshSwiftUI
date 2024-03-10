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
                Circle()
                    .trim(from: 0, to: progress * 0.9)
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: 360))

                // TODO: implement
//                LottieView(animation: .named("animation-pulling-shakuro_logo"))
//                    .playbackMode(.paused(at: .progress(progress)))
            },
            refreshingViewBuilder: { (isTriggered) in
                Circle()
                    .trim(from: 0, to: 0.9)
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: isTriggered ? 360 : 0))
                    .animation(isTriggered ? .linear(duration: 1).repeatForever(autoreverses: false) : nil, value: isTriggered)

                // TODO: implement
//                LottieView(animation: .named("animation-refreshing-shakuro_logo"))
//                    .playbackMode(isTriggered ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
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
