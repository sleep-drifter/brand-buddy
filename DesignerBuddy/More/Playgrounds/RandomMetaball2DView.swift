import SwiftUI

// MARK: - View

/// Generative 2D metaballs: randomly-sized balls wander the frame and fuse into
/// smooth liquid blobs where their inverse-square fields overlap. Rendered on the
/// GPU via `randomMetaball2D` (ShadersPlayground.metal), driven by TimelineView.
struct RandomMetaball2DView: View {
    @State private var ballCount: Float = 6
    @State private var ballSize:  Float = 0.5
    @State private var speed:     Float = 0.4
    @State private var smoothing: Float = 0.35
    @State private var hue:       Float = 0.83   // magenta, matching the concept art

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                preview
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Random Metaball 2D")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Preview

    private var preview: some View {
        TimelineView(.animation) { tl in
            let t = Float(tl.date.timeIntervalSinceReferenceDate)
            GeometryReader { geo in
                Color.black
                    .colorEffect(ShaderLibrary.randomMetaball2D(
                        .float2(geo.size),
                        .float(t),
                        .float(ballCount.rounded()),
                        .float(0.06 + ballSize * 0.28),
                        .float(0.1 + speed * 1.4),
                        .float(0.05 + smoothing * 0.5),
                        .float(hue)
                    ))
            }
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Balls",     $ballCount, range: 1...16, step: 1, value: "\(Int(ballCount.rounded()))")
            divider
            sliderRow("Size",      $ballSize)
            divider
            sliderRow("Speed",     $speed)
            divider
            sliderRow("Merge",     $smoothing)
            divider
            row {
                HStack(spacing: 12) {
                    Text("Hue").frame(width: 96, alignment: .leading)
                    Slider(value: $hue)
                        .tint(Color(hue: Double(hue), saturation: 0.85, brightness: 1.0))
                    Circle()
                        .fill(Color(hue: Double(hue), saturation: 0.85, brightness: 1.0))
                        .frame(width: 22, height: 22)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("A generative Metal shader: randomly-sized balls wander on Lissajous "
             + "paths, each emitting an inverse-square field. Where the summed field "
             + "crosses a threshold we fill solid colour, so neighbours fuse with smooth "
             + "liquid bridges. \u{201C}Merge\u{201D} softens the edge and how eagerly they "
             + "join. Inspired by iShader\u{2019}s RandomMetaball.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private func sliderRow(_ label: String,
                           _ value: Binding<Float>,
                           range: ClosedRange<Float> = 0...1,
                           step: Float = 0,
                           value valueText: String? = nil) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                if let valueText {
                    Text(valueText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RandomMetaball2DView()
    }
}
