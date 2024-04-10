import SwiftUI

struct CircularProgressView: View {

    private let tintColor: Color
    private let dashesesCount: Int
    private let size: CGFloat
    private let totalDashesCount = 8

    init(progress: CGFloat, tintColor: Color = .secondary, size: CGFloat = 20.0) {
        self.dashesesCount = Int(CGFloat(totalDashesCount) * progress)
        self.tintColor = tintColor
        self.size = size
    }

    var body: some View {
        ZStack {
            ForEach(0..<dashesesCount, id: \.self, content: { dashNumber in
                Capsule()
                    .fill(tintColor)
                    .frame(width: size / CGFloat(totalDashesCount), height: size / 3.0)
                    .transformEffect(CGAffineTransform(translationX: 0, y: size / -3.0))
                    .rotationEffect(Angle(radians: CGFloat.pi * 2 * CGFloat(dashNumber) / CGFloat(totalDashesCount)))
            })
        }
        .frame(width: size, height: size)
        .opacity(0.7)
    }

}

#Preview {
    CircularProgressView(progress: 0.8)
}

private struct StoppedActivityIndicator: UIViewRepresentable {

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) { }

    func makeUIView(context: UIViewRepresentableContext<StoppedActivityIndicator>) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = false
        spinner.stopAnimating()
        return spinner
    }

}
