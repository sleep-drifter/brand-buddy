import SwiftUI

// Flow-distortion playground ported from Koshimizu-Takehito's my-toybox.
// A curl-noise flow field advects a tiled image (Metal .layerEffect —
// flowDistortion in SDFShaders.metal), with a little chromatic aberration.
// The original ships a "waterwheel" asset; here we reuse PreviewBackground.

struct FlowDistortionView: View {
    private let startDate = Date()
    @State private var distortionStrength: Double = 0.021
    @State private var damping: Double = 0.95
    @State private var noiseScale: Double = 2.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince(startDate)
                    Image("PreviewBackground")
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .layerEffect(shader(time: time), maxSampleOffset: .zero)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                controls

                Text("A curl-noise flow field advects a tiled image via a Metal `layerEffect`, "
                     + "with RGB channels split for chromatic aberration. Strength sets the flow "
                     + "magnitude, Damping how fast it relaxes, and Noise Scale the swirl frequency. "
                     + "From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .animation(.default, value: distortionStrength + damping + noiseScale)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flow Distortion")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 0) {
            row("Strength",    $distortionStrength, 0.01...0.03, String(format: "%.3f", distortionStrength))
            divider
            row("Damping",     $damping,            0.10...1.00, String(format: "%.2f", damping))
            divider
            row("Noise Scale", $noiseScale,         1.0...3.0,   String(format: "%.2f", noiseScale))
            divider
            Button("Reset") {
                distortionStrength = 0.021; damping = 0.95; noiseScale = 2.0
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ label: String, _ value: Binding<Double>,
                     _ range: ClosedRange<Double>, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(label).frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
            Text(text).font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var divider: some View { Divider().padding(.leading, 16) }

    private func shader(time: TimeInterval) -> Shader {
        ShaderLibrary.flowDistortion(
            .float(Float(time)),
            .float(Float(distortionStrength)),
            .float(Float(damping)),
            .float(Float(noiseScale)),
            .boundingRect
        )
    }
}

// MARK: - Preview

#Preview { NavigationStack { FlowDistortionView() } }
