import SwiftUI
import VisionKit

// MARK: - Document Scanner View

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var captures: [UIImage]
    var onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(captures: $captures, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var captures: [UIImage]
        let onDismiss: () -> Void

        init(captures: Binding<[UIImage]>, onDismiss: @escaping () -> Void) {
            _captures = captures
            self.onDismiss = onDismiss
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            for i in 0 ..< scan.pageCount {
                let raw = scan.imageOfPage(at: i)
                let badged = addDocBadge(to: raw)
                captures.append(badged)
            }
            controller.dismiss(animated: true) { self.onDismiss() }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) { self.onDismiss() }
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true) { self.onDismiss() }
        }

        // Stamp a doc.viewfinder badge in the corner of the scan thumbnail
        private func addDocBadge(to image: UIImage) -> UIImage {
            let size = image.size
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                image.draw(at: .zero)

                let badgeSize: CGFloat = min(size.width, size.height) * 0.15
                let margin: CGFloat = badgeSize * 0.2
                let badgeRect = CGRect(
                    x: size.width - badgeSize - margin,
                    y: margin,
                    width: badgeSize,
                    height: badgeSize
                )

                // Badge background circle
                UIColor.systemBlue.withAlphaComponent(0.85).setFill()
                UIBezierPath(ovalIn: badgeRect).fill()

                // SF Symbol icon
                let config = UIImage.SymbolConfiguration(pointSize: badgeSize * 0.5, weight: .semibold)
                if let icon = UIImage(systemName: "doc.viewfinder", withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let iconSize = icon.size
                    let iconOrigin = CGPoint(
                        x: badgeRect.midX - iconSize.width / 2,
                        y: badgeRect.midY - iconSize.height / 2
                    )
                    icon.draw(at: iconOrigin)
                }
            }
        }
    }
}
