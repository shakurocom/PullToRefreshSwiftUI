import SwiftUI

struct CircleAnimationWithRepeatView: View {

    @State private var rotationDegrees: CGFloat = 0.0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.9)
            .stroke(Color.green, lineWidth: 5)
            .frame(width: 100, height: 100)
            .rotationEffect(Angle(degrees: 270))
            .rotationEffect(Angle(degrees: rotationDegrees))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotationDegrees)
            .onAppear(perform: {
                rotationDegrees = 360
            })
    }

}
