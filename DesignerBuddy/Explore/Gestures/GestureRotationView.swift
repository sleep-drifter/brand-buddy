import SwiftUI
import UIKit

// Named GestureRotationView to avoid collision with SwiftUI internals.
struct GestureRotationView: View {
    // MARK: - Rotation state
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero

    // MARK: - Scale (pinch) state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    // MARK: - Pan (translate) state
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Combined pinch + rotation state
    @State private var comboScale: CGFloat = 1.0
    @State private var lastComboScale: CGFloat = 1.0
    @State private var comboRotation: Angle = .zero
    @State private var lastComboRotation: Angle = .zero

    // MARK: - Free transform state (UIKit-backed, delta-based)
    @State private var freeScale: CGFloat = 1.0
    @State private var freeAngle: Angle = .zero
    @State private var freeOffset: CGSize = .zero
    @State private var isFreeTransforming = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Free Transform (Pinch + Rotate + Drag)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Free Transform", systemImage: "move.3d")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.purple.opacity(0.08))
                            .frame(height: 440)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            )
                            .scaleEffect(freeScale)
                            .rotationEffect(freeAngle)
                            .offset(freeOffset)
                    }
                    .overlay(
                        FreeTransformGestureOverlay(
                            isActive: $isFreeTransforming,
                            onTranslate: { delta in
                                freeOffset = CGSize(
                                    width: freeOffset.width + delta.width,
                                    height: freeOffset.height + delta.height
                                )
                            },
                            onScale: { delta in
                                freeScale = (freeScale * delta).clamped(to: 0.3...4.0)
                            },
                            onRotate: { delta in
                                freeAngle += delta
                            }
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("x: \(freeOffset.width, specifier: "%.1f")  y: \(freeOffset.height, specifier: "%.1f")  scale: \(freeScale, specifier: "%.2f")×  angle: \(freeAngle.degrees, specifier: "%.1f")°")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button("Reset") {
                        withAnimation(.spring()) {
                            freeScale = 1.0
                            freeAngle = .zero
                            freeOffset = .zero
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    HStack(spacing: 6) {
                        ForEach(["UIPanGestureRecognizer", "UIPinchGestureRecognizer", "UIRotationGestureRecognizer"], id: \.self) { token in
                            Text(token)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    Text("UIKit gesture recognizers enable true two-finger free transform. UIPanGestureRecognizer (min 2 touches) tracks the centroid translation. All three recognizers fire simultaneously via UIGestureRecognizerDelegate. Each handler resets its value to zero after reading so the SwiftUI state accumulates deltas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Combined Pinch + Rotation
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Pinch + Rotation Combined", systemImage: "rotate.3d")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.pink.opacity(0.08))
                            .frame(height: 220)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            )
                            .scaleEffect(comboScale)
                            .rotationEffect(comboRotation)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture(),
                                    RotationGesture()
                                )
                                .onChanged { value in
                                    if let magnification = value.first {
                                        comboScale = (lastComboScale * magnification)
                                            .clamped(to: 0.4...4.0)
                                    }
                                    if let rotationAngle = value.second {
                                        comboRotation = lastComboRotation + rotationAngle
                                    }
                                }
                                .onEnded { _ in
                                    lastComboScale = comboScale
                                    lastComboRotation = comboRotation
                                }
                            )
                        VStack {
                            Spacer()
                            Text("Pinch + rotate simultaneously")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 6)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack {
                        Text("Scale: \(comboScale, specifier: "%.2f")×  Angle: \(comboRotation.degrees, specifier: "%.1f")°")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                comboScale = 1.0
                                lastComboScale = 1.0
                                comboRotation = .zero
                                lastComboRotation = .zero
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("SimultaneousGesture wraps MagnificationGesture and RotationGesture. Each value comes from a tuple — value.first for scale, value.second for rotation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - RotationGesture
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("RotationGesture", systemImage: "arrow.clockwise")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.indigo.opacity(0.08))
                            .frame(height: 200)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.indigo.gradient)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "arrow.clockwise")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                            )
                            .rotationEffect(rotation)
                            .gesture(
                                RotationGesture()
                                    .onChanged { angle in
                                        rotation = lastRotation + angle
                                    }
                                    .onEnded { angle in
                                        lastRotation = rotation
                                    }
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack {
                        Text("Angle: \(rotation.degrees, specifier: "%.1f")°")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                rotation = .zero
                                lastRotation = .zero
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Use two fingers to rotate. Accumulate lastRotation + current angle to persist rotation across gesture sessions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - MagnificationGesture (Pinch / Scale)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("MagnificationGesture", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.teal.opacity(0.08))
                            .frame(height: 200)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.teal.gradient)
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = (lastScale * value).clamped(to: 0.3...4.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack {
                        Text("Scale: \(scale, specifier: "%.2f")×")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Multiply lastScale × gesture value each session. Clamp to avoid runaway scale.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - DragGesture (Pan / Translate)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("DragGesture — Pan", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.08))
                            .frame(height: 200)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.orange.gradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "hand.draw")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            )
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    HStack {
                        Text("x: \(offset.width, specifier: "%.1f")  y: \(offset.height, specifier: "%.1f")")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Accumulate lastOffset + translation each session so position persists between drags.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .scrollDisabled(isFreeTransforming)
        .navigationTitle("Rotation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UIKit-backed free transform overlay

private struct FreeTransformGestureOverlay: UIViewRepresentable {
    @Binding var isActive: Bool
    var onTranslate: (CGSize) -> Void
    var onScale: (CGFloat) -> Void
    var onRotate: (Angle) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator

        let rotation = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        rotation.delegate = context.coordinator

        [pan, pinch, rotation].forEach { view.addGestureRecognizer($0) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTranslate = onTranslate
        context.coordinator.onScale = onScale
        context.coordinator.onRotate = onRotate
        context.coordinator.setIsActive = { [isActive = $isActive] active in
            isActive.wrappedValue = active
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isActive: $isActive, onTranslate: onTranslate, onScale: onScale, onRotate: onRotate)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var setIsActive: (Bool) -> Void
        var onTranslate: (CGSize) -> Void
        var onScale: (CGFloat) -> Void
        var onRotate: (Angle) -> Void

        private var activeCount = 0 {
            didSet { setIsActive(activeCount > 0) }
        }

        init(isActive: Binding<Bool>,
             onTranslate: @escaping (CGSize) -> Void,
             onScale: @escaping (CGFloat) -> Void,
             onRotate: @escaping (Angle) -> Void) {
            self.setIsActive = { isActive.wrappedValue = $0 }
            self.onTranslate = onTranslate
            self.onScale = onScale
            self.onRotate = onRotate
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            switch g.state {
            case .began: activeCount += 1
            case .ended, .cancelled, .failed: activeCount -= 1
            case .changed:
                let t = g.translation(in: g.view)
                g.setTranslation(.zero, in: g.view)
                onTranslate(CGSize(width: t.x, height: t.y))
            default: break
            }
        }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            switch g.state {
            case .began: activeCount += 1
            case .ended, .cancelled, .failed: activeCount -= 1
            case .changed:
                let s = g.scale
                g.scale = 1.0
                onScale(s)
            default: break
            }
        }

        @objc func handleRotation(_ g: UIRotationGestureRecognizer) {
            switch g.state {
            case .began: activeCount += 1
            case .ended, .cancelled, .failed: activeCount -= 1
            case .changed:
                let r = g.rotation
                g.rotation = 0
                onRotate(Angle(radians: Double(r)))
            default: break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}

#Preview {
    NavigationStack { GestureRotationView() }
}
