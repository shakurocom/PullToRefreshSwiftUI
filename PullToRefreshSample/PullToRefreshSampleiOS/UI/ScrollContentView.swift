import Lottie
import PullToRefreshSwiftUI
import SwiftUI

struct ScrollContentView: View {

    @State private var isRefreshing: Bool = false

//    @State var rotationDegrees: CGFloat = 0.0

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
//                Circle()
//                    .trim(from: 0, to: progress * 0.9)
//                    .stroke(Color.green, lineWidth: 5)
//                    .frame(width: 100, height: 100)
//                    .rotationEffect(Angle(degrees: 270))

//                ProgressView(value: progress, total: 1)
//                    .progressViewStyle(.linear)

                // TODO: implement
                LottieView(animation: .named("animation-pulling-shakuro_logo"))
                    .playbackMode(.paused(at: .progress(progress)))
            },
            refreshingViewBuilder: { (isTriggered) in
//                Circle()
//                    .trim(from: 0, to: 0.9)
//                    .stroke(Color.green, lineWidth: 5)
//                    .frame(width: 100, height: 100)
//                    .rotationEffect(Angle(degrees: 270))
//                    .rotationEffect(Angle(degrees: rotationDegrees))
//                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: rotationDegrees)
//                    .onAppear(perform: {
//                        rotationDegrees = 360
//                    })

//                ProgressView()
//                    .progressViewStyle(.circular)

                // TODO: implement
                LottieView(animation: .named("animation-refreshing-shakuro_logo"))
                    .playbackMode(isTriggered ? .playing(.fromProgress(0, toProgress: 1, loopMode: .loop)) : .paused)
            },
            contentViewBuilder: { _ in
                VStack(content: {
                    Text(isRefreshing ? "Refreshing" : "Idle")
                        .font(.largeTitle)
                        .foregroundStyle(isRefreshing ? .white : .black)
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    Color.clear
                })
                .background(Color(isRefreshing ? .darkGray : .lightGray))
                .frame(height: 1000)
            })
        .navigationTitle("Scroll View Example")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    ScrollContentView()
}
