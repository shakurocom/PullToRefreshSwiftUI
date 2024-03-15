import Foundation
import SwiftUI

struct ListBackport<Content> {

   let content: Content

    init(_ content: Content) {
        self.content = content
    }

}

extension View {
    var listBackport: ListBackport<Self> { ListBackport(self) }
}

extension ListBackport where Content: View {

    @ViewBuilder func scrollContentBackground(_ visibility: Visibility) -> some View {
        if #available(iOS 16, *) {
            content.scrollContentBackground(visibility)
        } else {
            content
        }
    }

    @ViewBuilder func contentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View {
        if #available(iOS 17, *) {
            content.contentMargins(edges, length)
        } else {
            content
        }
    }

}
