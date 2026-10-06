import SwiftUI
import Charts

// MARK: - Chart Axes & Style
//
// Everything around the marks: axes, domains, color scales, legends,
// annotations, and the plot area itself — with the HIG rules for each.

struct ChartAxesStyleView: View {

    // Axis knobs
    @State private var showGridLines = true
    @State private var showTicks = false
    @State private var showAxisLabels = true
    @State private var yAxisLeading = false
    @State private var yTickCount = 4.0

    // Domain knobs
    private enum DomainChoice: String, CaseIterable {
        case automatic = "Auto", zeroBased = "From zero", tight = "Tight"
    }
    @State private var domainChoice: DomainChoice = .automatic

    // Legend & color knobs
    private enum LegendChoice: String, CaseIterable {
        case hidden = "Hidden", top = "Top", bottom = "Bottom"
    }
    @State private var legendChoice: LegendChoice = .bottom
    @State private var paletteIndex = 0
    private let palettes: [(name: String, colors: [Color])] = [
        ("Default", [.blue, .orange]),
        ("Calm",    [.teal, .indigo]),
        ("Warm",    [.orange, .pink]),
    ]

    // Annotation knobs
    @State private var showThreshold = true
    @State private var showGoalBand = true
    @State private var showPeakLabel = true

    // Plot area knobs
    @State private var plotBackground = false
    @State private var plotBorder = false

    private var indoor: [DailyDatum] {
        ChartSamples.monthTrend.filter { $0.series == "Indoor" }
    }

    var body: some View {
        List {

            // ── Anatomy ────────────────────────────────────────────────────
            Section {
                ChartHIGNote("A chart is more than its marks: axes orient the reader, gridlines support value lookup, labels name the units, annotations call out what matters, and a legend decodes the series. Include each element only when it earns its space.")
            }

            // ── Axes ───────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Axis Marks", tag: "AxisMarks")) {
                Chart(indoor) { datum in
                    LineMark(
                        x: .value("Date", datum.date),
                        y: .value("Value", datum.value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(
                        position: yAxisLeading ? .leading : .trailing,
                        values: .automatic(desiredCount: Int(yTickCount))
                    ) { _ in
                        if showGridLines { AxisGridLine() }
                        if showTicks { AxisTick() }
                        if showAxisLabels { AxisValueLabel() }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        if showGridLines { AxisGridLine() }
                        if showAxisLabels {
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 4)

                Toggle("Grid lines", isOn: $showGridLines)
                Toggle("Ticks", isOn: $showTicks)
                Toggle("Value labels", isOn: $showAxisLabels)
                Toggle("Y axis on leading edge", isOn: $yAxisLeading)
                LabeledContent("Y label count ≈ \(Int(yTickCount))") {
                    Slider(value: $yTickCount, in: 2...8, step: 1)
                        .frame(width: 150)
                }
                ChartCaption("chartYAxis { AxisMarks(position:values:) { … } }")
                ChartHIGNote("Trailing is the conventional y-axis edge on iOS — the newest data sits next to its labels. Use just enough gridlines to support reading values; too many become texture.")
            }

            // ── Domain & scale ─────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Domain & Scale", tag: "chartYScale")) {
                Group {
                    switch domainChoice {
                    case .automatic:
                        domainChart
                    case .zeroBased:
                        domainChart.chartYScale(domain: 0...100)
                    case .tight:
                        domainChart.chartYScale(domain: 40...80)
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 4)

                Picker("Domain", selection: $domainChoice) {
                    ForEach(DomainChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                ChartCaption(".chartYScale(domain: 0...100)")
                ChartHIGNote("A truncated baseline magnifies small differences — sometimes that's the point, often it misleads. Bar charts should virtually always start at zero; line charts may zoom, but tell the reader.")
            }

            // ── Color & legend ─────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Color & Legend", tag: "Scales")) {
                colorLegendChart
                    .frame(height: 200)
                    .padding(.vertical, 4)

                Picker("Palette", selection: $paletteIndex) {
                    ForEach(palettes.indices, id: \.self) { Text(palettes[$0].name) }
                }
                .pickerStyle(.segmented)
                Picker("Legend", selection: $legendChoice) {
                    ForEach(LegendChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                ChartCaption(".chartForegroundStyleScale([\"A\": .blue, …])")
                ChartHIGNote("Give color a job: one hue per series, applied consistently across every chart in the app. Check both appearances and the color-blind simulators — and never let color be the only difference between series.")
            }

            // ── Annotations & thresholds ───────────────────────────────────
            Section(header: ChartSectionHeader(title: "Annotations", tag: "Call-outs")) {
                annotatedChart
                    .frame(height: 220)
                    .padding(.vertical, 4)

                Toggle("Threshold rule", isOn: $showThreshold)
                Toggle("Goal band", isOn: $showGoalBand)
                Toggle("Peak label", isOn: $showPeakLabel)
                ChartCaption("RuleMark · RectangleMark band · .annotation { }")
                ChartHIGNote("Annotations answer \"so what?\" directly on the chart — a limit line, a goal zone, the peak. Use a few, keep them short, and make sure they don't collide with the data they describe.")
            }

            // ── Plot area ──────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Plot Area", tag: "chartPlotStyle")) {
                Chart(ChartSamples.weeklySteps) { datum in
                    BarMark(
                        x: .value("Day", datum.category),
                        y: .value("Steps", datum.value)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(plotBackground ? AnyShapeStyle(.quaternary.opacity(0.5)) : AnyShapeStyle(.clear))
                        .border(plotBorder ? Color.secondary.opacity(0.4) : .clear)
                }
                .frame(height: 200)
                .padding(.vertical, 4)

                Toggle("Background fill", isOn: $plotBackground)
                Toggle("Border", isOn: $plotBorder)
                ChartCaption(".chartPlotStyle { $0.background(…) }")
            }

            // ── Sparkline / minimal ────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Minimal Charts", tag: "Sparklines")) {
                HStack(spacing: 12) {
                    sparkTile(title: "Resting HR", value: "72", unit: "bpm", color: .pink,
                              data: Array(ChartSamples.longHistory.suffix(14)))
                    sparkTile(title: "Air Quality", value: "64", unit: "AQI", color: .teal,
                              data: Array(indoor.suffix(14)))
                }
                .padding(.vertical, 4)

                ChartCaption(".chartXAxis(.hidden) + .chartYAxis(.hidden)")
                ChartHIGNote("Small static charts work as previews: strip axes and legends, show only the shape of the data, and route taps to a full interactive chart. Health and Stocks both use this progressive disclosure.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    Chart(data) { point in
                        LineMark(x: .value("Date", point.date),
                                 y: .value("Value", point.value))
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(position: .leading,
                                  values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartLegend(position: .bottom)
                    """)
            }
        }
        .navigationTitle("Chart Axes & Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var colorLegendChart: some View {
        let chart = Chart(ChartSamples.monthTrend) { datum in
            LineMark(
                x: .value("Date", datum.date),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(by: .value("Place", datum.series))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartForegroundStyleScale([
            "Indoor":  palettes[paletteIndex].colors[0],
            "Outdoor": palettes[paletteIndex].colors[1],
        ])

        switch legendChoice {
        case .hidden: chart.chartLegend(.hidden)
        case .top:    chart.chartLegend(position: .top, spacing: 12)
        case .bottom: chart.chartLegend(position: .bottom, spacing: 12)
        }
    }

    private var domainChart: some View {
        Chart(indoor) { datum in
            LineMark(
                x: .value("Date", datum.date),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(.blue)
            AreaMark(
                x: .value("Date", datum.date),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(.blue.opacity(0.12))
        }
    }

    private var annotatedChart: some View {
        let peak = indoor.max { $0.value < $1.value }
        return Chart {
            if showGoalBand {
                RectangleMark(
                    yStart: .value("Goal low", 55),
                    yEnd: .value("Goal high", 70)
                )
                .foregroundStyle(.green.opacity(0.08))
            }
            ForEach(indoor) { datum in
                LineMark(
                    x: .value("Date", datum.date),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
            if showThreshold {
                RuleMark(y: .value("Limit", 80))
                    .foregroundStyle(.red.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Limit 80")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
            }
            if showPeakLabel, let peak {
                PointMark(
                    x: .value("Date", peak.date),
                    y: .value("Value", peak.value)
                )
                .foregroundStyle(.blue)
                .symbolSize(70)
                .annotation(position: .top) {
                    Text("Peak \(Int(peak.value))")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }

    private func sparkTile(title: String, value: String, unit: String,
                           color: Color, data: [DailyDatum]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.title3.bold())
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
            Chart(data) { datum in
                LineMark(
                    x: .value("Date", datum.date),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 36)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { ChartAxesStyleView() }
}
