import SwiftUI

// MARK: - Circular Crop View

struct CircularCropView: View {
    let image: UIImage
    @Binding var captures: [UIImage]
    var onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let circleSize: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // Pan/zoom image underneath the fixed circle
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { v in scale = max(0.5, lastScale * v) }
                                .onEnded { _ in lastScale = scale },
                            DragGesture()
                                .onChanged { v in
                                    offset = CGSize(
                                        width: lastOffset.width + v.translation.width,
                                        height: lastOffset.height + v.translation.height
                                    )
                                }
                                .onEnded { _ in lastOffset = offset }
                        )
                    )

                // Dark mask with circular cutout
                CircleMaskView(circleSize: circleSize)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // White circle border
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: circleSize, height: circleSize)
                    .allowsHitTesting(false)

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
                            if let cropped = cropToCircle(size: geo.size) {
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

    // MARK: - Circular Crop

    private func cropToCircle(size: CGSize) -> UIImage? {
        let diameter = circleSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            // Clip to circle
            let clipPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter))
            clipPath.addClip()

            // Draw the image accounting for scale and offset within the circle region
            let circleCenterX = size.width / 2
            let circleCenterY = size.height / 2

            let imgAspect = image.size.width / image.size.height
            let viewAspect = size.width / size.height

            let baseW: CGFloat
            let baseH: CGFloat
            if imgAspect > viewAspect {
                baseH = size.height
                baseW = baseH * imgAspect
            } else {
                baseW = size.width
                baseH = baseW / imgAspect
            }

            let scaledW = baseW * scale
            let scaledH = baseH * scale

            let drawX = (size.width - scaledW) / 2 + offset.width
            let drawY = (size.height - scaledH) / 2 + offset.height

            // Map circle region into image draw space
            let circleOriginX = circleCenterX - diameter / 2 - drawX
            let circleOriginY = circleCenterY - diameter / 2 - drawY

            image.draw(in: CGRect(
                x: -circleOriginX,
                y: -circleOriginY,
                width: scaledW,
                height: scaledH
            ))
        }
    }
}

// MARK: - Circle Mask View

private struct CircleMaskView: View {
    let circleSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = circleSize / 2

            Path { path in
                path.addRect(CGRect(origin: .zero, size: geo.size))
                path.addEllipse(in: CGRect(
                    x: center.x - r,
                    y: center.y - r,
                    width: circleSize,
                    height: circleSize
                ))
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
        }
        .ignoresSafeArea()
    }
}
