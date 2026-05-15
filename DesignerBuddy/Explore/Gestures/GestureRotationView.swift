import SwiftUI

// Named GestureRotationView to avoid collision with SwiftUI internals.
struct GestureRotationView: View {
    // MARK: - Rotation state
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero

    // MARK: - Combined pinch + rotation state
    @State private var comboScale: CGFloat = 1.0
    @State private var lastComboScale: CGFloat = 1.0
    @State private var comboRotation: Angle = .zero
    @State private var lastComboRotation: Angle = .zero

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

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
            }
            .padding(16)
        }
        .navigationTitle("Rotation")
        .navigationBarTitleDisplayMode(.inline)
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
