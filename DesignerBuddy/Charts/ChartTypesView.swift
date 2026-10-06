import SwiftUI
import Charts

// MARK: - Chart Types
//
// A gallery of every core Swift Charts mark, each paired with the HIG's
// when-to-use guidance. Companion pages cover axes & styling, interaction,
// function plots, 3D, and accessibility.

struct ChartTypesView: View {

    // Bar knobs
    @State private var barHorizontal = false
    @State private var barRounded = true

    // Multi-series bar knobs
    private enum MultiBarLayout: String, CaseIterable { case grouped = "Grouped", stacked = "Stacked" }
    @State private var multiBarLayout: MultiBarLayout = .grouped

    // Line knobs
    @State private var interpolation: InterpolationChoice = .catmullRom
    @State private var showSymbols = true

    private enum InterpolationChoice: String, CaseIterable {
        case linear = "Linear", monotone = "Monotone", catmullRom = "Catmull-Rom", step = "Step"
        var method: InterpolationMethod {
            switch self {
            case .linear:     return .linear
            case .monotone:   return .monotone
            case .catmullRom: return .catmullRom
            case .step:       return .stepCenter
            }
        }
    }

    // Area knobs
    private enum AreaStyle: String, CaseIterable { case single = "Single", stacked = "Stacked", range = "Range" }
    @State private var areaStyle: AreaStyle = .single

    // Pie knobs
    @State private var innerRadius = 0.62
    @State private var angularInset = 1.5

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("Swift Charts builds charts from **marks** — bars, lines, areas, points, sectors, rectangles — plotted against x/y **values**. Pick the mark that matches the question your data answers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ChartHIGNote("Design a chart around a single, focused message. If a chart tries to answer several questions at once, split it into several charts.")
            }

            // ── Bar ────────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Bar", tag: "Compare values")) {
                Chart(ChartSamples.weeklySteps) { datum in
                    if barHorizontal {
                        BarMark(
                            x: .value("Steps", datum.value),
                            y: .value("Day", datum.category)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(barRounded ? 5 : 0)
                    } else {
                        BarMark(
                            x: .value("Day", datum.category),
                            y: .value("Steps", datum.value)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(barRounded ? 5 : 0)
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 4)

                Toggle("Horizontal bars", isOn: $barHorizontal)
                Toggle("Rounded corners", isOn: $barRounded)
                ChartCaption("BarMark(x: .value(…), y: .value(…))")
                ChartHIGNote("Bars compare discrete categories. Go horizontal when category names are long or there are many of them — labels stay readable without rotating.")
            }

            // ── Grouped & stacked bars ─────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Multi-Series Bar", tag: "Compare series")) {
                Chart(ChartSamples.quarterlyRevenue) { datum in
                    if multiBarLayout == .grouped {
                        BarMark(
                            x: .value("Quarter", datum.category),
                            y: .value("Revenue", datum.value)
                        )
                        .foregroundStyle(by: .value("Line", datum.series))
                        .position(by: .value("Line", datum.series))
                        .cornerRadius(3)
                    } else {
                        BarMark(
                            x: .value("Quarter", datum.category),
                            y: .value("Revenue", datum.value)
                        )
                        .foregroundStyle(by: .value("Line", datum.series))
                        .cornerRadius(3)
                    }
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 220)
                .padding(.vertical, 4)

                Picker("Layout", selection: $multiBarLayout) {
                    ForEach(MultiBarLayout.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                ChartCaption(".position(by:) groups · omit it to stack")
                ChartHIGNote("Stack bars to show how parts build a total; group them to compare the parts themselves. Stacks get hard to read past three or four segments.")
            }

            // ── Line ───────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Line", tag: "Trends over time")) {
                Chart(ChartSamples.monthTrend) { datum in
                    LineMark(
                        x: .value("Date", datum.date),
                        y: .value("Air Quality", datum.value)
                    )
                    .foregroundStyle(by: .value("Place", datum.series))
                    .interpolationMethod(interpolation.method)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    if showSymbols {
                        PointMark(
                            x: .value("Date", datum.date),
                            y: .value("Air Quality", datum.value)
                        )
                        .foregroundStyle(by: .value("Place", datum.series))
                        .symbolSize(18)
                    }
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 220)
                .padding(.vertical, 4)

                Picker("Interpolation", selection: $interpolation) {
                    ForEach(InterpolationChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                Toggle("Point symbols", isOn: $showSymbols)
                ChartCaption("LineMark + .interpolationMethod(…)")
                ChartHIGNote("Lines show change over a continuous axis. Smoothing (Catmull-Rom, monotone) makes trends friendlier but invents values between points — avoid it when exact readings matter.")
            }

            // ── Area ───────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Area", tag: "Magnitude over time")) {
                Group {
                    switch areaStyle {
                    case .single:
                        Chart(ChartSamples.monthTrend.filter { $0.series == "Indoor" }) { datum in
                            AreaMark(
                                x: .value("Date", datum.date),
                                y: .value("Value", datum.value)
                            )
                            .foregroundStyle(.blue.opacity(0.25).gradient)
                            LineMark(
                                x: .value("Date", datum.date),
                                y: .value("Value", datum.value)
                            )
                            .foregroundStyle(.blue)
                        }
                    case .stacked:
                        Chart(ChartSamples.monthTrend) { datum in
                            AreaMark(
                                x: .value("Date", datum.date),
                                y: .value("Value", datum.value)
                            )
                            .foregroundStyle(by: .value("Place", datum.series))
                            .opacity(0.8)
                        }
                        .chartLegend(position: .bottom, spacing: 12)
                    case .range:
                        Chart(ChartSamples.tempRanges) { datum in
                            AreaMark(
                                x: .value("Month", datum.label),
                                yStart: .value("Low", datum.low),
                                yEnd: .value("High", datum.high)
                            )
                            .foregroundStyle(.teal.opacity(0.3))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 4)

                Picker("Style", selection: $areaStyle) {
                    ForEach(AreaStyle.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                ChartCaption("AreaMark · AreaMark(x:yStart:yEnd:) for ranges")
                ChartHIGNote("Filled areas emphasize how much, not just how values move. A range area (yStart/yEnd) shows a band — like daily temperature spans — rather than a single reading.")
            }

            // ── Scatter ────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Scatter", tag: "Correlation")) {
                Chart(ChartSamples.scatter) { datum in
                    PointMark(
                        x: .value("Duration", datum.x),
                        y: .value("Heart Rate", datum.y)
                    )
                    .foregroundStyle(by: .value("Session", datum.group))
                    .symbol(by: .value("Session", datum.group))
                    .symbolSize(60)
                    .opacity(0.8)
                }
                .chartXAxisLabel("Workout duration (min)")
                .chartYAxisLabel("Avg heart rate (bpm)")
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 240)
                .padding(.vertical, 4)

                ChartCaption("PointMark + .symbol(by:) + .foregroundStyle(by:)")
                ChartHIGNote("Scatter plots reveal relationships between two measures. Vary symbol shape as well as color per series, so groups stay distinguishable without color vision.")
            }

            // ── Pie & Donut ────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Pie & Donut", tag: "Parts of a whole")) {
                Chart(ChartSamples.marketShare) { datum in
                    SectorMark(
                        angle: .value("Share", datum.value),
                        innerRadius: .ratio(innerRadius),
                        angularInset: angularInset
                    )
                    .foregroundStyle(by: .value("Name", datum.name))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 240)
                .padding(.vertical, 4)
                .overlay {
                    if innerRadius > 0.35 {
                        VStack(spacing: 2) {
                            Text("38%").font(.title2.bold())
                            Text("Cirrus").font(.caption).foregroundStyle(.secondary)
                        }
                        .offset(y: -16)
                    }
                }

                LabeledContent("Inner radius") {
                    Slider(value: $innerRadius, in: 0...0.8)
                        .frame(width: 160)
                }
                LabeledContent("Angular inset") {
                    Slider(value: $angularInset, in: 0...6)
                        .frame(width: 160)
                }
                ChartCaption("SectorMark(angle:innerRadius:angularInset:)")
                ChartHIGNote("People judge bar lengths more accurately than angles, so prefer a bar chart when precise comparison matters. Keep pies to a handful of slices, and use the donut hole for a headline value.")
            }

            // ── Heatmap ────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Heatmap", tag: "Density grid")) {
                Chart(ChartSamples.heatmap) { cell in
                    RectangleMark(
                        x: .value("Hour", String(format: "%02d", cell.hour)),
                        y: .value("Day", ChartSamples.weekdays[cell.day])
                    )
                    .foregroundStyle(ChartPalette.heat(cell.level))
                }
                .chartXAxis {
                    AxisMarks(values: ["00", "06", "12", "18"]) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 4)

                ChartCaption("RectangleMark on two category axes")
                ChartHIGNote("Heatmaps show intensity across two dimensions at once — great for rhythms like activity by hour and weekday. Pair the color ramp with a legend or labels; color alone carries no exact value.")
            }

            // ── Range bars ─────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Range Bars", tag: "Spans")) {
                Chart(ChartSamples.tempRanges) { datum in
                    BarMark(
                        x: .value("Month", datum.label),
                        yStart: .value("Low", datum.low),
                        yEnd: .value("High", datum.high),
                        width: .fixed(8)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .padding(.vertical, 4)

                ChartCaption("BarMark(x:yStart:yEnd:width:)")
                ChartHIGNote("Floating bars show a span between two values — a low and a high — the way Weather presents daily temperature ranges.")
            }

            // ── Combo ──────────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Combined Marks", tag: "Overlay")) {
                comboChart
                    .frame(height: 220)
                    .padding(.vertical, 4)

                ChartCaption("BarMark + LineMark in one Chart { }")
                ChartHIGNote("Mixing marks works when they share a scale and reinforce one story — like daily totals with a running average. Don't overlay unrelated measures on one axis.")
            }

            // ── Choosing a chart ───────────────────────────────────────────
            Section("Choosing a chart") {
                ChartDoRow(good: true,  text: "**Compare categories** → bar. **Trend over time** → line. **Magnitude over time** → area. **Correlation** → scatter. **Part-to-whole** → stacked bar or pie. **Two-dimensional rhythm** → heatmap.")
                ChartDoRow(good: true,  text: "Keep a chart to one message, and say it in the title or description — \"Steps peaked on Saturday,\" not just \"Steps.\"")
                ChartDoRow(good: false, text: "Don't rely on a pie chart for more than ~5 slices, or when readers must compare similar values.")
                ChartDoRow(good: false, text: "Don't smooth lines when individual readings matter — interpolation invents data between points.")
            }
        }
        .navigationTitle("Chart Types")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Combo chart

    private var comboChart: some View {
        let steps = ChartSamples.weeklySteps
        let average = steps.map(\.value).reduce(0, +) / Double(steps.count)
        return Chart {
            ForEach(steps) { datum in
                BarMark(
                    x: .value("Day", datum.category),
                    y: .value("Steps", datum.value)
                )
                .foregroundStyle(.blue.opacity(0.5))
                .cornerRadius(4)
            }
            RuleMark(y: .value("Average", average))
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Avg \(Int(average))")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
        }
    }
}

#Preview {
    NavigationStack { ChartTypesView() }
}
