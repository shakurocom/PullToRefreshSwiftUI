//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

struct CircleAnimationWithRepeatView: View {

    @State private var rotationDegrees: CGFloat = 0.0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.9)
            .stroke(Color.green, lineWidth: 5)
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: 270))
            .rotationEffect(Angle(degrees: rotationDegrees))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotationDegrees)
            .onAppear(perform: {
                rotationDegrees = 360
            })
    }

}
