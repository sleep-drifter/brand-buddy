import SwiftUI

// Lissajous curve playground ported from Koshimizu-Takehito's my-toybox
// (LissajousCurveDemoScreen1). Pure SwiftUI Canvas — no Metal.
// x = cos(k·t + phase),  y = sin(l·t)

// MARK: - Model

private struct LissajousCurve {
    var k: Double = 2
    var l: Double = 3
    var phase: Double = 0
    var samples: Int = 3000

    func point(at index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let t = 2 * .pi * Double(index) / Double(samples)
        let x = cos(k.rounded(.down) * t + phase)
        let y = sin(l.rounded(.down) * t)
        return CGPoint(x: radius * x + center.x, y: radius * y + center.y)
    }
}

private struct LissajousShape: Shape {
    var curve: LissajousCurve
    func path(in rect: CGRect) -> Path {
        Path { path in
            let side = min(rect.width, rect.height)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = side * 0.42
            path.move(to: curve.point(at: 0, center: center, radius: radius))
            for i in 1...curve.samples {
                path.addLine(to: curve.point(at: i, center: center, radius: radius))
            }
        }
    }
}

// MARK: - View

struct LissajousCurveView: View {
    @State private var curve = LissajousCurve()
    private let startDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TimelineView(.animation) { context in
                    let phase = context.date.timeIntervalSince(startDate)
                        .truncatingRemainder(dividingBy: 2 * .pi)
                    canvas
                        .onChange(of: phase, initial: true) { _, new in
                            curve.phase = new
                        }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                controls
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lissajous Curve")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canvas: some View {
        Canvas { context, size in
            let path = LissajousShape(curve: curve).path(in: CGRect(origin: .zero, size: size))
            context.stroke(path, with: .color(.lissajousBlend(curve)), lineWidth: 4)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                let phaseString = (curve.phase / .pi).formatted(.number.precision(.fractionLength(2)))
                Text(verbatim: "x = cos(\(Int(curve.k))t + \(phaseString)π)")
                Text(verbatim: "y = sin(\(Int(curve.l))t)")
            }
            .font(.callout.monospaced())
            .frame(maxWidth: .infinity, alignment: .leading)

            sliderRow("k", $curve.k, tint: .lissajousX(curve))
            sliderRow("l", $curve.l, tint: .lissajousY(curve))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .monospacedDigit()
        .contentTransition(.numericText())
        .animation(.default, value: curve.k)
        .animation(.default, value: curve.l)
    }

    private func sliderRow(_ label: String, _ value: Binding<Double>, tint: Color) -> some View {
        HStack(spacing: 12) {
            Text("\(label) = \(Int(value.wrappedValue))")
                .frame(width: 64, alignment: .leading)
            Slider(value: value.animation(), in: 1...10)
                .tint(tint)
        }
    }
}

// MARK: - Colors

private extension Color {
    static func lissajousBlend(_ c: LissajousCurve) -> Color {
        lissajousX(c).mix(with: lissajousY(c), by: 0.5)
    }
    static func lissajousX(_ c: LissajousCurve) -> Color {
        Color(hue: (1 + sin(c.k * (2 * .pi / 20))) / 2, saturation: 1, brightness: 1)
    }
    static func lissajousY(_ c: LissajousCurve) -> Color {
        Color(hue: (1 + sin(c.l * (2 * .pi / 20))) / 2, saturation: 1, brightness: 1)
    }
}

// MARK: - Preview

#Preview { NavigationStack { LissajousCurveView() } }
