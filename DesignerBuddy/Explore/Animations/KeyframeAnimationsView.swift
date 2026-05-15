import SwiftUI

struct KeyframeAnimationsView: View {
    @State private var trigger = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - KeyframeAnimator demo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("KeyframeAnimator", systemImage: "timeline.selection")
                            .font(.headline)
                        Spacer()
                    }

                    // The animated target
                    KeyframeAnimator(
                        initialValue: CardAnimationValues(),
                        trigger: trigger
                    ) { values in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.indigo.opacity(0.1))
                                .frame(height: 200)
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.indigo.gradient)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "wand.and.sparkles")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                )
                                .scaleEffect(values.scale)
                                .opacity(values.opacity)
                                .offset(y: values.verticalOffset)
                        }
                    } keyframes: { _ in
                        KeyframeTrack(\.verticalOffset) {
                            LinearKeyframe(0, duration: 0.1)
                            SpringKeyframe(-60, duration: 0.35, spring: .bouncy)
                            SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                        }
                        KeyframeTrack(\.scale) {
                            LinearKeyframe(1.0, duration: 0.1)
                            SpringKeyframe(1.3, duration: 0.2, spring: .snappy)
                            SpringKeyframe(1.0, duration: 0.4, spring: .bouncy)
                        }
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(1.0, duration: 0.1)
                            LinearKeyframe(0.6, duration: 0.2)
                            LinearKeyframe(1.0, duration: 0.3)
                        }
                    }

                    Button("Trigger Animation") {
                        trigger.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Text("KeyframeAnimator drives multiple properties along independent timelines simultaneously. Each KeyframeTrack targets one property via a key path.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Keyframe Types Reference
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Keyframe Types", systemImage: "list.bullet.clipboard")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 8) {
                        keyframeRow(
                            name: "LinearKeyframe",
                            desc: "Constant easing. Good for opacity or color."
                        )
                        keyframeRow(
                            name: "SpringKeyframe",
                            desc: "Physics spring curve. Great for scale and position."
                        )
                        keyframeRow(
                            name: "CubicKeyframe",
                            desc: "Cubic Bézier easing. Precise control over acceleration."
                        )
                        keyframeRow(
                            name: "MoveKeyframe",
                            desc: "Instant jump to a value with no interpolation."
                        )
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Keyframe Animations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func keyframeRow(name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(name)
                .font(.caption.monospaced().weight(.semibold))
                .frame(width: 130, alignment: .leading)
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(10)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Animation Values

private struct CardAnimationValues {
    var verticalOffset: CGFloat = 0
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}

#Preview {
    NavigationStack { KeyframeAnimationsView() }
}
