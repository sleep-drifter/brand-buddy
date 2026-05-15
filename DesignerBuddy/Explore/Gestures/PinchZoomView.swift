import SwiftUI

struct PinchZoomView: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var clampedScale: CGFloat = 1.0

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Basic MagnificationGesture
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("MagnificationGesture", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.08))
                            .frame(height: 200)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.blue.gradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            )
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = scale
                                    }
                            )
                    }
                    HStack {
                        Text("Scale: \(scale, specifier: "%.2f")×")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Pinch on the square to scale it. Multiply the cumulative lastScale by the current gesture value to maintain state across interactions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Scale Clamping
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Scale Clamping (\(minScale, specifier: "%.1f")× – \(maxScale, specifier: "%.1f")×)", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.headline)
                        Spacer()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.08))
                            .frame(height: 200)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.gradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            )
                            .scaleEffect(clampedScale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let proposed = lastScale * value
                                        clampedScale = proposed.clamped(to: minScale...maxScale)
                                    }
                                    .onEnded { _ in
                                        lastScale = clampedScale
                                    }
                            )
                        // Min/max indicators
                        VStack {
                            Spacer()
                            HStack {
                                Text("Min \(minScale, specifier: "%.1f")×")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Max \(maxScale, specifier: "%.1f")×")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                        }
                    }
                    // Visual scale indicator
                    GeometryReader { geo in
                        let fraction = (clampedScale - minScale) / (maxScale - minScale)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.green.opacity(0.2)).frame(height: 6)
                            Capsule().fill(Color.green).frame(width: geo.size.width * fraction, height: 6)
                        }
                    }
                    .frame(height: 6)
                    HStack {
                        Text("Scale: \(clampedScale, specifier: "%.2f")×")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(duration: 0.35, bounce: 0.3)) {
                                clampedScale = 1.0
                                lastScale = 1.0
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("Clamp the proposed scale with .clamped(to:) before applying. Store the clamped value in lastScale on release so the user can't exceed the bounds across gestures.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Pinch & Zoom")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(range.upperBound, self))
    }
}

#Preview {
    NavigationStack { PinchZoomView() }
}
