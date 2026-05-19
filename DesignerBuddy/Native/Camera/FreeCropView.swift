import SwiftUI

// MARK: - Free Crop View

struct FreeCropView: View {
    let image: UIImage
    @Binding var captures: [UIImage]
    var onDismiss: () -> Void

    @State private var cropRect: CGRect = .zero
    @State private var imageFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Full-bleed image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(GeometryReader { imgGeo in
                        Color.clear.onAppear {
                            let frame = imgGeo.frame(in: .global)
                            imageFrame = frame
                            cropRect = CGRect(
                                x: frame.minX + frame.width * 0.1,
                                y: frame.minY + frame.height * 0.1,
                                width: frame.width * 0.8,
                                height: frame.height * 0.8
                            )
                        }
                    })
                    .ignoresSafeArea()

                // Dark mask with crop window cutout
                if cropRect != .zero {
                    CropMaskView(cropRect: cropRect)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    // 8 drag handles
                    cropHandles(in: geo)
                }

                // Buttons
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            onDismiss()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: Capsule())

                        Button("Crop") {
                            if let cropped = cropImage() {
                                captures.append(cropped)
                            }
                            onDismiss()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Color.accentColor, in: Capsule())
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Crop Handles

    @ViewBuilder
    private func cropHandles(in geo: GeometryProxy) -> some View {
        let handles = handlePositions()
        ForEach(handles.indices, id: \.self) { i in
            let hp = handles[i]
            CropHandle()
                .position(hp.point)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            updateCropRect(handle: hp.role, translation: value.translation)
                        }
                )
        }
    }

    private struct HandlePoint {
        let point: CGPoint
        let role: HandleRole
    }

    private enum HandleRole {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
    }

    private func handlePositions() -> [HandlePoint] {
        let r = cropRect
        return [
            HandlePoint(point: CGPoint(x: r.minX, y: r.minY), role: .topLeft),
            HandlePoint(point: CGPoint(x: r.midX, y: r.minY), role: .top),
            HandlePoint(point: CGPoint(x: r.maxX, y: r.minY), role: .topRight),
            HandlePoint(point: CGPoint(x: r.minX, y: r.midY), role: .left),
            HandlePoint(point: CGPoint(x: r.maxX, y: r.midY), role: .right),
            HandlePoint(point: CGPoint(x: r.minX, y: r.maxY), role: .bottomLeft),
            HandlePoint(point: CGPoint(x: r.midX, y: r.maxY), role: .bottom),
            HandlePoint(point: CGPoint(x: r.maxX, y: r.maxY), role: .bottomRight),
        ]
    }

    private func updateCropRect(handle: HandleRole, translation: CGSize) {
        let minSize: CGFloat = 44
        var r = cropRect
        let dx = translation.width
        let dy = translation.height

        switch handle {
        case .topLeft:
            let nx = min(r.minX + dx, r.maxX - minSize)
            let ny = min(r.minY + dy, r.maxY - minSize)
            r = CGRect(x: nx, y: ny, width: r.maxX - nx, height: r.maxY - ny)
        case .top:
            let ny = min(r.minY + dy, r.maxY - minSize)
            r = CGRect(x: r.minX, y: ny, width: r.width, height: r.maxY - ny)
        case .topRight:
            let nx = max(r.maxX + dx, r.minX + minSize)
            let ny = min(r.minY + dy, r.maxY - minSize)
            r = CGRect(x: r.minX, y: ny, width: nx - r.minX, height: r.maxY - ny)
        case .left:
            let nx = min(r.minX + dx, r.maxX - minSize)
            r = CGRect(x: nx, y: r.minY, width: r.maxX - nx, height: r.height)
        case .right:
            let nx = max(r.maxX + dx, r.minX + minSize)
            r = CGRect(x: r.minX, y: r.minY, width: nx - r.minX, height: r.height)
        case .bottomLeft:
            let nx = min(r.minX + dx, r.maxX - minSize)
            let ny = max(r.maxY + dy, r.minY + minSize)
            r = CGRect(x: nx, y: r.minY, width: r.maxX - nx, height: ny - r.minY)
        case .bottom:
            let ny = max(r.maxY + dy, r.minY + minSize)
            r = CGRect(x: r.minX, y: r.minY, width: r.width, height: ny - r.minY)
        case .bottomRight:
            let nx = max(r.maxX + dx, r.minX + minSize)
            let ny = max(r.maxY + dy, r.minY + minSize)
            r = CGRect(x: r.minX, y: r.minY, width: nx - r.minX, height: ny - r.minY)
        }

        // Clamp within imageFrame
        if imageFrame != .zero {
            r.origin.x = max(r.origin.x, imageFrame.minX)
            r.origin.y = max(r.origin.y, imageFrame.minY)
            if r.maxX > imageFrame.maxX { r.size.width = imageFrame.maxX - r.origin.x }
            if r.maxY > imageFrame.maxY { r.size.height = imageFrame.maxY - r.origin.y }
        }

        cropRect = r
    }

    // MARK: - Crop Image

    private func cropImage() -> UIImage? {
        guard imageFrame != .zero else { return nil }

        let scaleX = image.size.width / imageFrame.width
        let scaleY = image.size.height / imageFrame.height

        let relCropRect = CGRect(
            x: (cropRect.minX - imageFrame.minX) * scaleX,
            y: (cropRect.minY - imageFrame.minY) * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )

        guard let cgImage = image.cgImage?.cropping(to: relCropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Crop Mask View

private struct CropMaskView: View {
    let cropRect: CGRect

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.addRect(geo.frame(in: .global))
                path.addRect(cropRect)
            }
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))

            // Crop border
            Path(cropRect)
                .stroke(Color.white, lineWidth: 1.5)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Crop Handle

private struct CropHandle: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 22, height: 22)
            .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
    }
}
