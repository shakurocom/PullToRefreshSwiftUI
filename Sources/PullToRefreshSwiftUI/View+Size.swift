//
//
// Copyright (c) 2024 Shakuro (https://shakuro.com/)
//
//

import SwiftUI

struct LayoutData: Equatable {
    let size: CGSize
    let frameInCoordinateSpace: CGRect
    let safeAreaInsets: EdgeInsets
}

extension View {

    func readLayoutData(coordinateSpace: CoordinateSpace, onChange: @escaping (LayoutData) -> Void) -> some View {
        self
            .background(
                GeometryReader(content: { (geometryProxy) in
                    Color.clear
                        .preference(key: SizePreferenceKey.self,
                                    value: LayoutData(size: geometryProxy.size,
                                                      frameInCoordinateSpace: geometryProxy.frame(in: coordinateSpace),
                                                      safeAreaInsets: geometryProxy.safeAreaInsets))
                })
            )
            .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

}

private struct SizePreferenceKey: PreferenceKey {

    static var defaultValue: LayoutData = LayoutData(size: .zero, frameInCoordinateSpace: CGRect.zero, safeAreaInsets: EdgeInsets())

    static func reduce(value: inout LayoutData, nextValue: () -> LayoutData) { }

}
