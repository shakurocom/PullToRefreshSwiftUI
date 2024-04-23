//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

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
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: 270))
    }

}
