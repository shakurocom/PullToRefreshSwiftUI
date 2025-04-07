//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

public struct GeometryGroupModifier: ViewModifier {

    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
            // https://medium.com/the-swift-cooperative/swiftui-geometrygroup-guide-from-theory-to-practice-1a7f4b04c4ec
                .geometryGroup()
        } else {
            content
                .transformEffect(.identity)
        }
    }

}
