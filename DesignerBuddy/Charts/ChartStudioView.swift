import SwiftUI
import UIKit
import Charts

// MARK: - Chart Studio
//
// A live playground: pick a chart family, shape the data, tune the styling,
// and take the generated Swift Charts code with you. The preview stays
// pinned while knobs scroll, like the other Studio pages.

struct ChartStudioView: View {

    // MARK: Config

    private enum Family: String, CaseIterable {
        case bar = "Bar", line = "Line", area = "Area", points = "Points", donut = "Donut"
    }
    private enum DataShape: String, CaseIterable {
        case trend = "Trend", seasonal = "Seasonal", random = "Random"
    }
    private enum BarLayout: String, CaseIterable {
        case stacked = "Stacked", grouped = "Grouped"
    }
    private enum Smoothing: String, CaseIterable {
        case linear = "Linear", monotone = "Monotone", catmullRom = "Catmull-Rom"
        var method: InterpolationMethod {
            switch self {
            case .linear:     return .linear
            case .monotone:   return .monotone
            case .catmullRom: return .catmullRom
            }
        }
        var code: String {
            switch self {
            case .linear:     return ".linear"
            case .monotone:   return ".monotone"
            case .catmullRom: return ".catmullRom"
            }
        }
    }

    @State private var family: Family = .bar
    @State private var dataShape: DataShape = .seasonal
    @State private var seriesCount = 2
    @State private var pointCount = 8.0
    @State private var seed: UInt64 = 42

    @State private var barLayout: BarLayout = .grouped
    @State private var cornerRadius = 4.0
    @State private var smoothing: Smoothing = .catmullRom
    @State private var showSymbols = false
    @State private var lineWidth = 2.0
    @State private var innerRadius = 0.6
    @State private var paletteIndex = 0

    @State private var showLegend = true
    @State private var showXAxis = true
    @State private var showYAxis = true
    @State private var yFromZero = true

    private let palettes: [(name: String, colors: [Color])] = [
        ("Default", [.blue, .orange, .green]),
        ("Calm",    [.teal, .indigo, .mint]),
        ("Warm",    [.orange, .pink, .red]),
    ]
    private let seriesNames = ["Alpha", "Beta", "Gamma"]

    // MARK: Data

    private struct StudioDatum: Identifiable {
        let id: String      // stable across regenerations so changes animate
        let index: Int
        let label: String
        let series: String
        let value: Double
    }

    private var data: [StudioDatum] {
        var rng = SeededRandom(seed: seed)
        let n = Int(pointCount)
        var out: [StudioDatum] = []
        for s in 0..<seriesCount {
            let phase = Double(s) * 1.3
            var level = Double.random(in: 35...65, using: &rng)
            for p in 0..<n {
                let value: Double
                switch dataShape {
                case .trend:
                    level += Double.random(in: -6...10, using: &rng)
                    level = min(max(level, 10), 100)
                    value = level
                case .seasonal:
                    let t = Double(p) / Double(max(n - 1, 1))
                    value = 55 + 32 * sin(t * 2 * .pi + phase)
                          + Double.random(in: -6...6, using: &rng)
                case .random:
                    value = Double.random(in: 15...95, using: &rng)
                }
                out.append(StudioDatum(
                    id: "s\(s)-p\(p)",
                    index: p,
                    label: "P\(p + 1)",
                    series: seriesNames[s],
                    value: max(value, 2)))
            }
        }
        return out
    }

    private var donutSlices: [StudioDatum] {
        Array(data.filter { $0.series == seriesNames[0] }.prefix(6))
    }

    private var activeSeries: [String] { Array(seriesNames.prefix(seriesCount)) }
    private var activeColors: [Color] { Array(palettes[paletteIndex].colors.prefix(seriesCount)) }

    // MARK: Body

    var body: some View {
        List {

            // ── Family ─────────────────────────────────────────────────────
            Section("Chart") {
                Picker("Family", selection: $family) {
                    ForEach(Family.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            // ── Data ───────────────────────────────────────────────────────
            Section("Data") {
                Picker("Shape", selection: $dataShape) {
                    ForEach(DataShape.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                if family != .donut {
                    Stepper("Series: \(seriesCount)", value: $seriesCount, in: 1...3)
                }
                LabeledContent("Points: \(Int(pointCount))") {
                    Slider(value: $pointCount, in: 4...24, step: 1)
                        .frame(width: 150)
                }
                Button {
                    withAnimation(.spring(duration: 0.5)) {
                        seed = UInt64.random(in: 0..<UInt64.max)
                    }
                } label: {
                    Label("Regenerate data", systemImage: "dice")
                }
            }

            // ── Style ──────────────────────────────────────────────────────
            Section("Style") {
                Picker("Palette", selection: $paletteIndex) {
                    ForEach(palettes.indices, id: \.self) { Text(palettes[$0].name) }
                }
                .pickerStyle(.segmented)

                switch family {
                case .bar:
                    if seriesCount > 1 {
                        Picker("Layout", selection: $barLayout) {
                            ForEach(BarLayout.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    }
                    LabeledContent("Corner radius: \(Int(cornerRadius))") {
                        Slider(value: $cornerRadius, in: 0...12, step: 1)
                            .frame(width: 150)
                    }
                case .line:
                    Picker("Smoothing", selection: $smoothing) {
                        ForEach(Smoothing.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    LabeledContent("Line width: \(lineWidth, specifier: "%.0f")") {
                        Slider(value: $lineWidth, in: 1...6, step: 1)
                            .frame(width: 150)
                    }
                    Toggle("Point symbols", isOn: $showSymbols)
                case .area:
                    Picker("Smoothing", selection: $smoothing) {
                        ForEach(Smoothing.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                case .points:
                    EmptyView()
                case .donut:
                    LabeledContent("Inner radius") {
                        Slider(value: $innerRadius, in: 0...0.8)
                            .frame(width: 150)
                    }
                }
            }

            // ── Chrome ─────────────────────────────────────────────────────
            Section("Chrome") {
                Toggle("Legend", isOn: $showLegend)
                if family != .donut {
                    Toggle("X axis", isOn: $showXAxis)
                    Toggle("Y axis", isOn: $showYAxis)
                    Toggle("Y starts at zero", isOn: $yFromZero)
                }
            }

            // ── Generated code ─────────────────────────────────────────────
            Section("Generated code") {
                ChartCodeRow(code: generatedCode)
                Button {
                    UIPasteboard.general.string = generatedCode
                } label: {
                    Label("Copy code", systemImage: "doc.on.clipboard")
                }
            }
        }
        .pinnedPreview(entry: "Chart Studio", shuffle: {
            withAnimation(.spring(duration: 0.5)) {
                seed = UInt64.random(in: 0..<UInt64.max)
            }
        }) {
            studioCanvas
        }
        .navigationTitle("Chart Studio")
    }

    // MARK: Canvas

    @ViewBuilder
    private var studioCanvas: some View {
        if family == .donut {
            donutChart.frame(height: 220)
        } else {
            xyChart.frame(height: 220)
        }
    }

    @ViewBuilder
    private var xyChart: some View {
        let base = Chart(data) { datum in
            xyMarks(for: datum)
        }
        .chartForegroundStyleScale(domain: activeSeries, range: activeColors)
        .chartLegend(showLegend && seriesCount > 1 ? .automatic : .hidden)
        .chartXAxis(showXAxis ? .automatic : .hidden)
        .chartYAxis(showYAxis ? .automatic : .hidden)

        if yFromZero {
            base.chartYScale(domain: 0...(family == .bar && barLayout == .stacked && seriesCount > 1 ? 110 * Double(seriesCount) : 110))
        } else {
            base
        }
    }

    @ChartContentBuilder
    private func xyMarks(for datum: StudioDatum) -> some ChartContent {
        switch family {
        case .bar:
            if barLayout == .grouped && seriesCount > 1 {
                BarMark(
                    x: .value("Point", datum.label),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(by: .value("Series", datum.series))
                .position(by: .value("Series", datum.series))
                .cornerRadius(cornerRadius)
            } else {
                BarMark(
                    x: .value("Point", datum.label),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(by: .value("Series", datum.series))
                .cornerRadius(cornerRadius)
            }
        case .line:
            LineMark(
                x: .value("Point", datum.index),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(by: .value("Series", datum.series))
            .interpolationMethod(smoothing.method)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            if showSymbols {
                PointMark(
                    x: .value("Point", datum.index),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(by: .value("Series", datum.series))
                .symbolSize(30)
            }
        case .area:
            AreaMark(
                x: .value("Point", datum.index),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(by: .value("Series", datum.series))
            .interpolationMethod(smoothing.method)
            .opacity(0.75)
        case .points:
            PointMark(
                x: .value("Point", datum.index),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(by: .value("Series", datum.series))
            .symbol(by: .value("Series", datum.series))
            .symbolSize(70)
        case .donut:
            // Never reached — the donut family renders through donutChart.
            BarMark(
                x: .value("Point", datum.label),
                y: .value("Value", datum.value)
            )
            .opacity(0)
        }
    }

    private var donutChart: some View {
        Chart(donutSlices) { datum in
            SectorMark(
                angle: .value("Value", datum.value),
                innerRadius: .ratio(innerRadius),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Slice", datum.label))
            .cornerRadius(4)
        }
        .chartLegend(showLegend ? .automatic : .hidden)
    }

    // MARK: Code generation

    private var generatedCode: String {
        switch family {
        case .bar:
            let position = (barLayout == .grouped && seriesCount > 1)
                ? "\n        .position(by: .value(\"Series\", point.series))" : ""
            return """
                Chart(data) { point in
                    BarMark(x: .value("Point", point.label),
                            y: .value("Value", point.value))
                        .foregroundStyle(by: .value("Series", point.series))\(position)
                        .cornerRadius(\(Int(cornerRadius)))
                }\(chromeCode)
                """
        case .line:
            let symbols = showSymbols
                ? "\n        .symbol(by: .value(\"Series\", point.series))" : ""
            return """
                Chart(data) { point in
                    LineMark(x: .value("Point", point.index),
                             y: .value("Value", point.value))
                        .foregroundStyle(by: .value("Series", point.series))
                        .interpolationMethod(\(smoothing.code))
                        .lineStyle(StrokeStyle(lineWidth: \(Int(lineWidth))))\(symbols)
                }\(chromeCode)
                """
        case .area:
            return """
                Chart(data) { point in
                    AreaMark(x: .value("Point", point.index),
                             y: .value("Value", point.value))
                        .foregroundStyle(by: .value("Series", point.series))
                        .interpolationMethod(\(smoothing.code))
                }\(chromeCode)
                """
        case .points:
            return """
                Chart(data) { point in
                    PointMark(x: .value("Point", point.index),
                              y: .value("Value", point.value))
                        .foregroundStyle(by: .value("Series", point.series))
                        .symbol(by: .value("Series", point.series))
                }\(chromeCode)
                """
        case .donut:
            return """
                Chart(slices) { slice in
                    SectorMark(angle: .value("Value", slice.value),
                               innerRadius: .ratio(\(String(format: "%.2f", innerRadius))),
                               angularInset: 1.5)
                        .foregroundStyle(by: .value("Slice", slice.label))
                        .cornerRadius(4)
                }\(showLegend ? "" : "\n.chartLegend(.hidden)")
                """
        }
    }

    private var chromeCode: String {
        var lines: [String] = []
        if !showLegend || seriesCount == 1 { lines.append(".chartLegend(.hidden)") }
        if !showXAxis { lines.append(".chartXAxis(.hidden)") }
        if !showYAxis { lines.append(".chartYAxis(.hidden)") }
        if yFromZero { lines.append(".chartYScale(domain: 0...110)") }
        guard !lines.isEmpty else { return "" }
        return "\n" + lines.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack { ChartStudioView() }
        .environmentObject(PinsStore())
}
