//
//
//

import SwiftUI

extension View {

    internal func readSize(onChange: @escaping (ViewSizeData) -> Void) -> some View {
        background(
            GeometryReader(content: { (geometryProxy) in
                Color.clear
                    .preference(key: SizePreferenceKey.self, 
                                value: ViewSizeData(size: geometryProxy.size, safeAreaInsets: geometryProxy.safeAreaInsets))
            })
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

}

struct ViewSizeData: Equatable {
    let size: CGSize
    let safeAreaInsets: EdgeInsets
}

private struct SizePreferenceKey: PreferenceKey {

    static var defaultValue: ViewSizeData = ViewSizeData(size: .zero, safeAreaInsets: EdgeInsets())

    static func reduce(value: inout ViewSizeData, nextValue: () -> ViewSizeData) { }

}
