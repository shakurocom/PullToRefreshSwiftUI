import SwiftUI

struct CircularProgressView: View {

    private var progress: CGFloat = 0.0

    init(progress: CGFloat) {
        self.progress = progress
    }

    var body: some View {
        StoppedActivityIndicator()
            .rotationEffect(Angle(degrees: 90))
            .rotationEffect(Angle(degrees: progress * 360.0))
    }

}

#Preview {
    CircularProgressView(progress: 0)
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
