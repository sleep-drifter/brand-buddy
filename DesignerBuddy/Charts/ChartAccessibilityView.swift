import SwiftUI
import Charts
import Accessibility

// MARK: - Chart Accessibility
//
// Making charts work for everyone: VoiceOver labels on marks, Audio Graphs
// via AXChartDescriptor, series that survive without color, and the system
// settings charts should respect.

struct ChartAccessibilityView: View {

    @State private var customLabels = true
    @State private var differentiateWithoutColor = false
    @Environment(\.accessibilityDifferentiateWithoutColor) private var systemDifferentiate

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                ChartHIGNote("A chart that only works visually excludes part of your audience. Swift Charts exposes marks to VoiceOver automatically — your job is to make what it speaks meaningful, provide an Audio Graph for the overall shape, and never encode information in color alone.")
            }

            // ── VoiceOver labels ───────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "VoiceOver Labels", tag: "Per mark")) {
                Chart(ChartSamples.weeklySteps) { datum in
                    BarMark(
                        x: .value("Day", datum.category),
                        y: .value("Steps", datum.value)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(5)
                    .accessibilityLabel(customLabels ? fullDayName(datum.category) : datum.category)
                    .accessibilityValue(customLabels
                        ? "\(Int(datum.value)) steps"
                        : "\(datum.value)")
                }
                .frame(height: 200)
                .padding(.vertical, 4)

                Toggle("Curated labels", isOn: $customLabels)
                ChartCaption(".accessibilityLabel(…) / .accessibilityValue(…) on marks")
                ChartHIGNote("Each mark is a VoiceOver element by default, but the default reads raw values. Spell out abbreviations and add units — \"Saturday, 12,680 steps\" beats \"Sat, 12680\".")
            }

            // ── Audio graph ────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Audio Graphs", tag: "Sonification")) {
                Chart(ChartSamples.weeklySteps) { datum in
                    BarMark(
                        x: .value("Day", datum.category),
                        y: .value("Steps", datum.value)
                    )
                    .foregroundStyle(.indigo.gradient)
                    .cornerRadius(5)
                }
                .frame(height: 200)
                .padding(.vertical, 4)
                .accessibilityChartDescriptor(WeeklyStepsDescriptor())

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "speaker.wave.2")
                        .font(.footnote)
                        .foregroundStyle(.indigo)
                        .padding(.top, 2)
                    Text("With VoiceOver on, select this chart and choose **Audio Graph** in the rotor — the data plays as a rising and falling tone, with the summary spoken first.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ChartCaption(".accessibilityChartDescriptor(AXChartDescriptorRepresentable)")
                ChartHIGNote("An Audio Graph conveys the shape of the whole series at once — the thing per-mark reading can't do. Write the summary line yourself; it's the chart's one-sentence message.")
            }

            // ── Beyond color ───────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Beyond Color", tag: "Differentiate")) {
                twoSeriesChart
                    .frame(height: 200)
                    .padding(.vertical, 4)

                Toggle("Differentiate without color", isOn: $differentiateWithoutColor)
                ChartCaption("symbol shapes + dash patterns per series")
                ChartHIGNote("About 1 in 12 men can't reliably separate red from green. Give every series a second channel — symbol shape, dash pattern, or direct labels — and honor the system's **Differentiate Without Color** setting via its environment value.")
                if systemDifferentiate {
                    Text("System Differentiate Without Color is ON — this device already requests non-color coding.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // ── System settings ────────────────────────────────────────────
            Section("Respect system settings") {
                ChartDoRow(good: true,  text: "**Dynamic Type** — axis and annotation labels should use text styles so they scale; verify the chart still fits at accessibility sizes.")
                ChartDoRow(good: true,  text: "**Reduce Motion** — skip chart entry animations when `accessibilityReduceMotion` is set.")
                ChartDoRow(good: true,  text: "**Increase Contrast** — test fills like `.opacity(0.2)` bands; they can vanish or turn muddy in high contrast.")
                ChartDoRow(good: false, text: "Don't hide the only path to the data inside the chart — offer the numbers as text or a table somewhere too.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    struct StepsDescriptor: AXChartDescriptorRepresentable {
                        func makeChartDescriptor() -> AXChartDescriptor {
                            AXChartDescriptor(
                                title: "Steps this week",
                                summary: "Steps peaked Saturday at 12,680.",
                                xAxis: AXCategoricalDataAxisDescriptor(
                                    title: "Day",
                                    categoryOrder: days),
                                yAxis: AXNumericDataAxisDescriptor(
                                    title: "Steps",
                                    range: 0...13000,
                                    gridlinePositions: []) {
                                        "\\(Int($0)) steps"
                                    },
                                series: [AXDataSeriesDescriptor(
                                    name: "Steps",
                                    isContinuous: false,
                                    dataPoints: points)])
                        }
                    }

                    chart.accessibilityChartDescriptor(StepsDescriptor())
                    """)
            }
        }
        .navigationTitle("Chart Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private func fullDayName(_ short: String) -> String {
        switch short {
        case "Mon": return "Monday"
        case "Tue": return "Tuesday"
        case "Wed": return "Wednesday"
        case "Thu": return "Thursday"
        case "Fri": return "Friday"
        case "Sat": return "Saturday"
        default:    return "Sunday"
        }
    }

    private var twoSeriesChart: some View {
        Chart(ChartSamples.monthTrend) { datum in
            LineMark(
                x: .value("Date", datum.date),
                y: .value("Value", datum.value)
            )
            .foregroundStyle(by: .value("Place", datum.series))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(
                lineWidth: 2,
                dash: differentiateWithoutColor && datum.series == "Outdoor" ? [5, 4] : []
            ))
            if differentiateWithoutColor {
                PointMark(
                    x: .value("Date", datum.date),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(by: .value("Place", datum.series))
                .symbol(by: .value("Place", datum.series))
                .symbolSize(20)
            }
        }
        .chartLegend(position: .bottom, spacing: 12)
    }
}

// MARK: - Audio graph descriptor

private struct WeeklyStepsDescriptor: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let data = ChartSamples.weeklySteps

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: "Day of week",
            categoryOrder: data.map(\.category)
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Steps",
            range: 0...13000,
            gridlinePositions: []
        ) { value in
            "\(Int(value)) steps"
        }
        let series = AXDataSeriesDescriptor(
            name: "Steps",
            isContinuous: false,
            dataPoints: data.map { AXDataPoint(x: $0.category, y: $0.value) }
        )
        return AXChartDescriptor(
            title: "Steps this week",
            summary: "Steps ranged from 5,420 on Sunday to a peak of 12,680 on Saturday.",
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

#Preview {
    NavigationStack { ChartAccessibilityView() }
}
