import SwiftUI

// Oscilla Logomark — a brand lab for the visual-synth concept (OSCILLA.md).
// The mark is a Lissajous figure: two oscillators drawing light, the
// original visual synthesis. Integer frequency ratios produce stable knots
// (visible consonance); the phase slowly drifts so the mark is alive.
//
// x = sin(a·t + δ), y = sin(b·t) — closed over 0…2π for integer a, b.

struct OscillaLogomarkView: View {

    // Oscillators
    @State private var a = 3
    @State private var b = 2
    @State private var basePhase = Double.pi / 2
    @State private var drift = true

    // Trace
    private enum TraceStyle: String, CaseIterable {
        case solid = "Solid", beam = "Beam"
    }
    @State private var traceStyle: TraceStyle = .solid
    @State private var lineWidth = 3.0
    @State private var glow = 0.7

    private enum Tint: String, CaseIterable {
        case white = "White", phosphor = "Phosphor", signal = "Signal"
        var color: Color {
            switch self {
            case .white:    return .white
            case .phosphor: return Color(red: 0.45, green: 1.0, blue: 0.65)
            case .signal:   return Color(red: 0.45, green: 0.75, blue: 1.0)
            }
        }
    }
    @State private var tint: Tint = .white

    /// Reset on every preset/ratio change so the draw-on intro replays.
    @State private var birth = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── The mark ───────────────────────────────────────────────
                heroCanvas
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(.white.opacity(0.08))
                    }

                HStack {
                    Text("\(reducedRatio.0):\(reducedRatio.1)")
                        .font(.system(.title3, design: .monospaced).weight(.semibold))
                    Text(intervalName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        replay()
                    } label: {
                        Label("Redraw", systemImage: "scope")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 4)

                // ── Presets ────────────────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        presetChip("The Mark", a: 3, b: 2, style: .solid, tint: .white)
                        presetChip("Infinity", a: 2, b: 1, style: .solid, tint: .white)
                        presetChip("Orbit",    a: 1, b: 1, style: .beam,  tint: .phosphor)
                        presetChip("Knot",     a: 5, b: 4, style: .solid, tint: .signal)
                        presetChip("Tangle",   a: 9, b: 7, style: .beam,  tint: .phosphor)
                    }
                    .padding(.horizontal, 4)
                }

                // ── Oscillators ────────────────────────────────────────────
                controlCard("Oscillators") {
                    Stepper("Horizontal: \(a)", value: $a, in: 1...9)
                        .onChange(of: a) { _, _ in replay() }
                    Stepper("Vertical: \(b)", value: $b, in: 1...9)
                        .onChange(of: b) { _, _ in replay() }
                    HStack {
                        Text("Phase")
                        Slider(value: $basePhase, in: 0...(2 * .pi))
                    }
                    Toggle("Phase drift (the mark is alive)", isOn: $drift)
                }

                // ── Trace ──────────────────────────────────────────────────
                controlCard("Trace") {
                    Picker("Style", selection: $traceStyle) {
                        ForEach(TraceStyle.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Tint", selection: $tint) {
                        ForEach(Tint.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Weight")
                        Slider(value: $lineWidth, in: 1...8)
                    }
                    HStack {
                        Text("Glow")
                        Slider(value: $glow, in: 0...1)
                    }
                }

                // ── Lockup ─────────────────────────────────────────────────
                controlCard("Lockup") {
                    HStack(spacing: 20) {
                        ForEach([20.0, 34.0, 56.0], id: \.self) { size in
                            staticMark(size: size)
                        }
                        HStack(spacing: 10) {
                            staticMark(size: 28)
                            Text("oscilla")
                                .font(.system(size: 26, design: .rounded).weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                    Text("How the mark survives at icon sizes — simple ratios stay legible where dense ones turn to mush. Another argument for 3:2.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Integer ratios close into stable figures — consonance you can see. The same ratios that sound like musical intervals draw the calmest knots.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Oscilla Logomark")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(birth)
                let phase = basePhase + (drift ? elapsed * 0.12 : 0)
                let rect = CGRect(origin: .zero, size: size)
                    .insetBy(dx: size.width * 0.16, dy: size.height * 0.16)
                let color = tint.color

                switch traceStyle {
                case .solid:
                    // Scope-style draw-on over the first two seconds.
                    let progress = min(1, max(0.02, elapsed / 2.0))
                    let path = lissajousPath(in: rect, phase: phase, fraction: progress)
                    strokeGlowing(path, in: &context, color: color)
                    if progress < 1 {
                        beamHead(at: point(t: progress * 2 * .pi, phase: phase, in: rect),
                                 in: &context, color: color)
                    }
                case .beam:
                    // A comet endlessly tracing the figure: fading tail segments.
                    let head = (elapsed * 0.7).truncatingRemainder(dividingBy: 2 * .pi)
                    let tail = 1.9
                    let steps = 24
                    for i in 0..<steps {
                        let f0 = head - tail * Double(i + 1) / Double(steps)
                        let f1 = head - tail * Double(i) / Double(steps)
                        let fade = pow(1 - Double(i) / Double(steps), 2)
                        let segment = lissajousPath(in: rect, phase: phase,
                                                    from: f0, to: f1)
                        context.stroke(segment,
                                       with: .color(color.opacity(fade)),
                                       style: StrokeStyle(lineWidth: lineWidth,
                                                          lineCap: .round))
                    }
                    beamHead(at: point(t: head, phase: phase, in: rect),
                             in: &context, color: color)
                }
            }
        }
        .padding(8)
    }

    private func strokeGlowing(_ path: Path, in context: inout GraphicsContext,
                               color: Color) {
        if glow > 0.01 {
            var halo = context
            halo.addFilter(.blur(radius: 4 + 10 * glow))
            halo.stroke(path, with: .color(color.opacity(0.9 * glow)),
                        style: StrokeStyle(lineWidth: lineWidth * 2.4,
                                           lineCap: .round, lineJoin: .round))
        }
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth,
                                          lineCap: .round, lineJoin: .round))
    }

    private func beamHead(at p: CGPoint, in context: inout GraphicsContext,
                          color: Color) {
        let r = lineWidth * 1.6
        var spark = context
        spark.addFilter(.blur(radius: 6))
        spark.fill(Path(ellipseIn: CGRect(x: p.x - r * 2, y: p.y - r * 2,
                                          width: r * 4, height: r * 4)),
                   with: .color(color.opacity(0.9)))
        context.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r,
                                            width: r * 2, height: r * 2)),
                     with: .color(.white))
    }

    // MARK: - Geometry

    private func point(t: Double, phase: Double, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.midX + rect.width / 2 * sin(Double(a) * t + phase),
            y: rect.midY + rect.height / 2 * sin(Double(b) * t)
        )
    }

    /// Path over t ∈ [from, to] (radians along the parameter, full figure = 2π).
    private func lissajousPath(in rect: CGRect, phase: Double,
                               from: Double = 0, to: Double = 2 * .pi) -> Path {
        Path { p in
            let samples = 540
            for i in 0...samples {
                let t = from + (to - from) * Double(i) / Double(samples)
                let pt = point(t: t, phase: phase, in: rect)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }

    /// Convenience: leading fraction of the full figure (for draw-on).
    private func lissajousPath(in rect: CGRect, phase: Double,
                               fraction: Double) -> Path {
        lissajousPath(in: rect, phase: phase, from: 0, to: 2 * .pi * fraction)
    }

    // MARK: - Ratio math

    private var reducedRatio: (Int, Int) {
        func gcd(_ x: Int, _ y: Int) -> Int { y == 0 ? x : gcd(y, x % y) }
        let g = gcd(a, b)
        return (a / g, b / g)
    }

    private var intervalName: String {
        switch reducedRatio {
        case (1, 1): return "Unison"
        case (2, 1), (1, 2): return "Octave"
        case (3, 2), (2, 3): return "Perfect fifth"
        case (4, 3), (3, 4): return "Perfect fourth"
        case (5, 4), (4, 5): return "Major third"
        case (6, 5), (5, 6): return "Minor third"
        case (5, 3), (3, 5): return "Major sixth"
        case (8, 5), (5, 8): return "Minor sixth"
        case (9, 8), (8, 9): return "Major second"
        default:     return "Dissonant — watch it tumble"
        }
    }

    // MARK: - Pieces

    private func replay() {
        birth = Date()
    }

    private func presetChip(_ name: String, a pa: Int, b pb: Int,
                            style: TraceStyle, tint pt: Tint) -> some View {
        Button {
            a = pa
            b = pb
            traceStyle = style
            tint = pt
            basePhase = .pi / 2
            replay()
        } label: {
            Text(name)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(.white.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
    }

    private func controlCard<Content: View>(_ title: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func staticMark(size: CGFloat) -> some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
                .insetBy(dx: canvasSize.width * 0.12, dy: canvasSize.height * 0.12)
            let path = lissajousPath(in: rect, phase: basePhase)
            context.stroke(path, with: .color(tint.color),
                           style: StrokeStyle(lineWidth: max(1, size / 16),
                                              lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .padding(6)
        .background(Color.black, in: RoundedRectangle(cornerRadius: size / 4))
    }
}

#Preview {
    NavigationStack { OscillaLogomarkView() }
}
