import SwiftUI

// Implicit-equation explorer ported from Koshimizu-Takehito's my-toybox.
// Renders f(x,y) = sin(a·(x²+y²)) − cos(b·xy) as a contour via a Metal
// layerEffect (implicitEquation in SDFShaders.metal) over a radial gradient.

struct ImplicitEquationView: View {
    @State private var radialFreq: Double = 1.0   // a
    @State private var mixFreq:    Double = 1.0   // b
    @State private var isoLevel:   Double = 0.0
    @State private var zoom:       Double = 0.15

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GeometryReader { geo in
                    Rectangle().fill(gradient(size: geo.size))
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .layerEffect(shader, maxSampleOffset: .zero)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                Text(verbatim: "f(x,y) = sin(\(fmt(radialFreq))(x²+y²)) − cos(\(fmt(mixFreq))xy)")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)

                controls

                Text("A Metal `layerEffect` that shades a contour of an implicit equation over a "
                     + "radial gradient. Radial/Mix frequency reshape the field, Iso Level picks "
                     + "which contour to draw, and Zoom scales the view. From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .animation(.default, value: radialFreq + mixFreq + isoLevel + zoom)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Implicit Equation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 0) {
            row("Radial Freq", $radialFreq, 0...10, fmt(radialFreq))
            divider
            row("Mix Freq",    $mixFreq,    0...10, fmt(mixFreq))
            divider
            row("Iso Level",   $isoLevel,  -1...1,  String(format: "%.2f", isoLevel))
            divider
            row("Zoom",        $zoom,       0.01...1, String(format: "%.2f", zoom))
            divider
            Button("Reset") {
                radialFreq = 1; mixFreq = 1; isoLevel = 0; zoom = 0.15
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
                .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var divider: some View { Divider().padding(.leading, 16) }

    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }

    private var shader: Shader {
        ShaderLibrary.implicitEquation(
            .float(Float(radialFreq)),
            .float(Float(mixFreq)),
            .float(Float(isoLevel)),
            .float(Float(zoom)),
            .boundingRect
        )
    }

    private func gradient(size: CGSize) -> RadialGradient {
        let colors = stride(from: 0.0, to: 2.0, by: 1.0 / 7.0).map { hue in
            Color(hue: hue.truncatingRemainder(dividingBy: 1), saturation: 0.25, brightness: 1)
        }
        return RadialGradient(colors: colors, center: .center,
                              startRadius: 0, endRadius: min(size.width, size.height) / sqrt(2))
    }
}

// MARK: - Preview

#Preview { NavigationStack { ImplicitEquationView().preferredColorScheme(.dark) } }
