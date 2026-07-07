import SwiftUI

// MARK: - Palette

enum FluidPalette: String, CaseIterable {
    case sunset = "Sunset"
    case aurora = "Aurora"
    case candy  = "Candy"

    var index: Float { Float(FluidPalette.allCases.firstIndex(of: self) ?? 0) }
}

// MARK: - View

struct FluidGradientView: View {
    // Elapsed time from launch. Feeding `timeIntervalSinceReferenceDate` (~8e8)
    // into a 32-bit Float quantizes to ~64s steps, freezing the animation.
    private let startDate = Date()

    @State private var blobSize:   Float = 0.5
    @State private var speed:      Float = 0.4
    @State private var grain:      Float = 0.35
    @State private var saturation: Float = 0.85
    @State private var palette:    FluidPalette = .sunset

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
        .navigationTitle("Fluid Gradient")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Preview

    private var preview: some View {
        TimelineView(.animation) { tl in
            let t = Float(tl.date.timeIntervalSince(startDate))
            GeometryReader { geo in
                Color.black
                    .colorEffect(ShaderLibrary.fluidGradientArt(
                        .float2(geo.size),
                        .float(t),
                        .float(0.05 + blobSize * 0.6),
                        .float(0.1 + speed * 1.6),
                        .float(grain * 0.35),
                        .float(saturation * 1.4),
                        .float(palette.index)
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
            row {
                HStack {
                    Text("Palette").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Palette", selection: $palette) {
                        ForEach(FluidPalette.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .labelsHidden()
                }
            }
            divider
            sliderRow("Blob Size",  $blobSize)
            divider
            sliderRow("Speed",      $speed)
            divider
            sliderRow("Grain",      $grain)
            divider
            sliderRow("Saturation", $saturation)
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var caption: some View {
        Text("A generative, self-contained Metal shader: five drifting metaball blobs blended "
             + "into a soft field, dusted with film grain, animated with TimelineView. "
             + "Inspired by iShader's FluidGradient.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private func sliderRow(_ label: String, _ value: Binding<Float>) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                Slider(value: value)
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
        FluidGradientView()
    }
}
