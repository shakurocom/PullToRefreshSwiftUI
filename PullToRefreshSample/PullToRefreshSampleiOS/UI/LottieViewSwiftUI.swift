//
//
//

import Lottie // TODO: implement - use native LottieView
import SwiftUI

// TODO: implement - use SwiftUI LottieView
internal struct LottieViewSwiftUIOptions {

    internal let lottieFileName: String
    internal let backgroundColor: UIColor
    internal let animationSpeed: CGFloat
    internal let contentMode: UIView.ContentMode
    internal let configurationBlock: ((_ animationView: LottieAnimationView) -> Void)?

    internal init(lottieFileName: String,
                  backgroundColor: UIColor = UIColor.clear,
                  animationSpeed: CGFloat = 1,
                  contentMode: UIView.ContentMode = .scaleAspectFit,
                  configurationBlock: ((_ animationView: LottieAnimationView) -> Void)? = nil) {
        self.lottieFileName = lottieFileName
        self.backgroundColor = backgroundColor
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
        self.configurationBlock = configurationBlock
    }

}

internal struct LottieViewSwiftUI: UIViewRepresentable {

    private class AnimationViewContainer: UIView {

        internal let animationView: LottieAnimationView

        init(animationView: LottieAnimationView) {
            self.animationView = animationView
            super.init(frame: CGRect.zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

    private let options: LottieViewSwiftUIOptions
    private var isPlaying: Binding<Bool>?
    private var currentProgress: Binding<AnimationProgressTime>?

    internal init(options: LottieViewSwiftUIOptions,
                  isPlaying: Binding<Bool>?,
                  currentProgress: Binding<AnimationProgressTime>?) {
        self.options = options
        self.isPlaying = isPlaying
        self.currentProgress = currentProgress
    }

    // MARK: - UIViewRepresentable

    internal func makeUIView(context: UIViewRepresentableContext<LottieViewSwiftUI>) -> UIView {
        let animationView = LottieAnimationView(name: options.lottieFileName, bundle: .main)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundColor = options.backgroundColor
        animationView.contentMode = options.contentMode
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.animationSpeed = options.animationSpeed
        let container = AnimationViewContainer(animationView: animationView)
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.backgroundColor = UIColor.clear
        container.addSubview(animationView)
        container.addConstraints([
            animationView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            animationView.widthAnchor.constraint(equalTo: container.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: container.heightAnchor)
        ])
        return container
    }

    internal func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<LottieViewSwiftUI>) {
        guard let animationView = (uiView as? AnimationViewContainer)?.animationView else {
            return
        }
        options.configurationBlock?(animationView)
        if let isPlaying = isPlaying?.wrappedValue {
            if isPlaying {
                animationView.play()
            } else {
                animationView.pause()
            }
        }
        if let currentProgress = currentProgress?.wrappedValue {
            animationView.currentProgress = currentProgress
        }
    }

}
