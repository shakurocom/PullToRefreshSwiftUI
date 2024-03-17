import SwiftUI

struct CircleAnimationWithProgressView: View {

    private var progress: CGFloat

    init(progress: CGFloat) {
        self.progress = progress
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: progress * 0.9)
            .stroke(Color.green, lineWidth: 5)
            .frame(width: 100, height: 100)
            .rotationEffect(Angle(degrees: 270))
    }

}
