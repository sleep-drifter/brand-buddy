import SwiftUI

// Implicit-equation explorer ported from Koshimizu-Takehito's my-toybox, extended
// with a function family, multi-level contours, line thickness, palette, and a
// self-animate toggle. Renders via a Metal layerEffect (implicitEquation in
// SDFShaders.metal) over a radial gradient.

private enum ImplicitFunction: Int, CaseIterable, Identifiable {
    case waves, grid, spiral, petals
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .waves:  return "Waves"
        case .grid:   return "Grid"
        case .spiral: return "Spiral"
        case .petals: return "Petals"
        }
    }
    var formula: String {
        switch self {
        case .waves:  return "sin(a(x²+y²)) − cos(b·xy)"
        case .grid:   return "sin(a·x) + sin(b·y)"
        case .spiral: return "sin(a·r − b·θ)"
        case .petals: return "r − 0.5 − sin(b·θ)"
        }
    }
}

private enum ImplicitPalette: Int, CaseIterable, Identifiable {
    case rainbow, warm, cool, mono
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .warm:    return "Warm"
        case .cool:    return "Cool"
        case .mono:    return "Mono"
        }
    }
    var colors: [Color] {
        switch self {
        case .rainbow:
            return stride(from: 0.0, to: 2.0, by: 1.0 / 7.0).map {
                Color(hue: $0.truncatingRemainder(dividingBy: 1), saturation: 0.25, brightness: 1)
            }
        case .warm:  return [.red, .orange, .yellow, .pink, .orange, .red]
        case .cool:  return [.teal, .blue, .indigo, .cyan, .mint, .blue]
        case .mono:  return [.white, Color(white: 0.6), .white, Color(white: 0.4), .white]
        }
    }
}

struct ImplicitEquationView: View {
    @State private var radialFreq: Double = 1.0   // a
    @State private var mixFreq:    Double = 1.0   // b
    @State private var isoLevel:   Double = 0.0
    @State private var zoom:       Double = 0.15
    @State private var levels:     Double = 1
    @State private var thickness:  Double = 0.02
    @State private var function: ImplicitFunction = .waves
    @State private var palette:  ImplicitPalette = .rainbow
    @State private var animate = false

    private let startDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TimelineView(.animation(paused: !animate)) { context in
                    let phase = animate ? Float(context.date.timeIntervalSince(startDate)) : 0
                    GeometryReader { geo in
                        Rectangle().fill(gradient(size: geo.size))
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .layerEffect(shader(phase: phase), maxSampleOffset: .zero)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                Text(verbatim: "f(x,y) = \(function.formula)")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)

                controls

                Text("A Metal `layerEffect` shading contours of an implicit equation. Pick a "
                     + "function family, draw one or several iso-levels, tune line thickness, "
                     + "recolour the field, and let it self-animate. From my-toybox.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .animation(.default, value: radialFreq + mixFreq + isoLevel + zoom + levels + thickness)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Implicit Equation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var controls: some View {
        VStack(spacing: 0) {
            pickerRow("Function") {
                Picker("Function", selection: $function) {
                    ForEach(ImplicitFunction.allCases) { Text($0.label).tag($0) }
                }.pickerStyle(.menu)
            }
            divider
            pickerRow("Palette") {
                Picker("Palette", selection: $palette) {
                    ForEach(ImplicitPalette.allCases) { Text($0.label).tag($0) }
                }.pickerStyle(.menu)
            }
            divider
            row("Radial Freq", $radialFreq, 0...10, fmt(radialFreq))
            divider
            row("Mix Freq",    $mixFreq,    0...10, fmt(mixFreq))
            divider
            row("Iso Level",   $isoLevel,  -1...1,  String(format: "%.2f", isoLevel))
            divider
            row("Levels",      $levels,     1...6,  "\(Int(levels.rounded()))", step: 1)
            divider
            row("Thickness",   $thickness,  0.005...0.06, String(format: "%.3f", thickness))
            divider
            row("Zoom",        $zoom,       0.01...1, String(format: "%.2f", zoom))
            divider
            HStack {
                Toggle("Animate", isOn: $animate)
                Spacer()
                Button(role: .destructive) {
                    radialFreq = 1; mixFreq = 1; isoLevel = 0; zoom = 0.15
                    levels = 1; thickness = 0.02; function = .waves; palette = .rainbow; animate = false
                } label: { Label("Reset", systemImage: "arrow.counterclockwise") }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func pickerRow<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
        HStack {
            Text(label).frame(width: 96, alignment: .leading)
            Spacer()
            content()
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }

    private func row(_ label: String, _ value: Binding<Double>,
                     _ range: ClosedRange<Double>, _ text: String, step: Double = 0) -> some View {
        HStack(spacing: 12) {
            Text(label).frame(width: 96, alignment: .leading)
            if step > 0 {
                Slider(value: value, in: range, step: step)
            } else {
                Slider(value: value, in: range)
            }
            Text(text).font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private var divider: some View { Divider().padding(.leading, 16) }

    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }

    private func shader(phase: Float) -> Shader {
        ShaderLibrary.implicitEquation(
            .float(Float(radialFreq)),
            .float(Float(mixFreq)),
            .float(Float(isoLevel)),
            .float(Float(zoom)),
            .float(Float(function.rawValue)),
            .float(Float(levels.rounded())),
            .float(Float(thickness)),
            .float(phase),
            .boundingRect
        )
    }

    private func gradient(size: CGSize) -> RadialGradient {
        RadialGradient(colors: palette.colors, center: .center,
                       startRadius: 0, endRadius: min(size.width, size.height) / sqrt(2))
    }
}

// MARK: - Preview

#Preview { NavigationStack { ImplicitEquationView().preferredColorScheme(.dark) } }
