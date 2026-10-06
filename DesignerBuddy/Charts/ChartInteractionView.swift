import SwiftUI
import Charts

// MARK: - Chart Interaction
//
// The patterns behind Health- and Stocks-style charts: scrubbing with a
// lollipop, drag-to-select ranges, horizontally scrolling history with
// snapping, and tap-to-select donut sectors.

struct ChartInteractionView: View {

    // Scrubbing
    @State private var scrubDate: Date?

    // Range selection
    @State private var selectedRange: ClosedRange<Date>?

    // Scrolling
    @State private var scrollDate = Calendar.current.date(
        byAdding: .day, value: -30, to: Calendar.current.startOfDay(for: .now))!

    // Donut selection
    @State private var selectedAngle: Double?

    private var indoor: [DailyDatum] {
        ChartSamples.monthTrend.filter { $0.series == "Indoor" }
    }

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                ChartHIGNote("Make interactive charts big — typically full-width — so touch targets are comfortable and detail is visible. Smaller charts work better as static previews that navigate to an interactive version.")
            }

            // ── Scrubbing ──────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Scrubbing", tag: "chartXSelection")) {
                VStack(alignment: .leading, spacing: 4) {
                    // Fixed-height readout so the chart doesn't jump while scrubbing.
                    let current = scrubbedDatum ?? indoor.last
                    Text(current.map { "\(Int($0.value)) AQI" } ?? "—")
                        .font(.title3.bold())
                        .contentTransition(.numericText())
                    Text(current.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                scrubChart
                    .frame(height: 220)
                    .padding(.vertical, 4)

                ChartCaption(".chartXSelection(value: $date) + RuleMark lollipop")
                ChartHIGNote("Touching a chart should reveal exact values without hiding the data — Health pins the readout above the plot and drops a thin rule at the touched x position.")
            }

            // ── Range selection ────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Range Selection", tag: "Drag")) {
                VStack(alignment: .leading, spacing: 4) {
                    if let selectedRange, let avg = average(in: selectedRange) {
                        Text("Avg \(Int(avg)) AQI")
                            .font(.title3.bold())
                        Text("\(selectedRange.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(selectedRange.upperBound.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Drag across the chart")
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                        Text("Select a window to see its average")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                rangeChart
                    .frame(height: 220)
                    .padding(.vertical, 4)

                ChartCaption(".chartXSelection(range: $range) + RectangleMark")
                ChartHIGNote("Range selection answers questions about windows of time — \"how was last week vs. this week?\" Highlight the band and summarize it; don't make readers do the math.")
            }

            // ── Scrolling history ──────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Scrolling History", tag: "Scrollable")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resting heart rate")
                        .font(.title3.bold())
                    Text("Showing 30 days from \(scrollDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Chart(ChartSamples.longHistory) { datum in
                    BarMark(
                        x: .value("Day", datum.date, unit: .day),
                        y: .value("BPM", datum.value)
                    )
                    .foregroundStyle(.pink.gradient)
                    .cornerRadius(2)
                }
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: 3600 * 24 * 30)
                .chartScrollPosition(x: $scrollDate)
                .chartScrollTargetBehavior(
                    .valueAligned(matching: DateComponents(hour: 0))
                )
                .chartYScale(domain: 0...120)
                .frame(height: 220)
                .padding(.vertical, 4)

                ChartCaption(".chartScrollableAxes(.horizontal) + .chartXVisibleDomain")
                ChartHIGNote("For long histories, show a fixed window and let people scroll — don't compress months into an unreadable strip. Snap scrolling to day boundaries so the window always starts somewhere meaningful.")
            }

            // ── Donut selection ────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Sector Selection", tag: "chartAngleSelection")) {
                donutChart
                    .frame(height: 260)
                    .padding(.vertical, 4)

                ChartCaption(".chartAngleSelection(value: $angle)")
                ChartHIGNote("On touch, emphasize the chosen sector and surface its exact value — fading the rest keeps the selection obvious while preserving context.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                ChartDoRow(good: true,  text: "Keep the readout in a fixed position while scrubbing, so eyes stay on the data.")
                ChartDoRow(good: true,  text: "Interaction should add precision, not carry the message — the chart must make its point even if nobody touches it.")
                ChartDoRow(good: false, text: "Don't attach interaction to a small chart; give it room or link to a full-size version first.")
                ChartDoRow(good: false, text: "Don't animate values under the finger — immediate response makes scrubbing feel attached to the touch.")
            }
        }
        .navigationTitle("Chart Interaction")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Scrubbing

    private var scrubbedDatum: DailyDatum? {
        guard let scrubDate else { return nil }
        return indoor.min {
            abs($0.date.timeIntervalSince(scrubDate)) < abs($1.date.timeIntervalSince(scrubDate))
        }
    }

    private var scrubChart: some View {
        Chart {
            ForEach(indoor) { datum in
                LineMark(
                    x: .value("Date", datum.date),
                    y: .value("AQI", datum.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Date", datum.date),
                    y: .value("AQI", datum.value)
                )
                .foregroundStyle(.blue.opacity(0.1))
                .interpolationMethod(.catmullRom)
            }
            if let selected = scrubbedDatum {
                RuleMark(x: .value("Selected", selected.date))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(
                    x: .value("Selected", selected.date),
                    y: .value("AQI", selected.value)
                )
                .foregroundStyle(.blue)
                .symbolSize(80)
            }
        }
        .chartXSelection(value: $scrubDate)
    }

    // MARK: - Range selection

    private func average(in range: ClosedRange<Date>) -> Double? {
        let window = indoor.filter { range.contains($0.date) }
        guard !window.isEmpty else { return nil }
        return window.map(\.value).reduce(0, +) / Double(window.count)
    }

    private var rangeChart: some View {
        Chart {
            if let selectedRange {
                RectangleMark(
                    xStart: .value("Start", selectedRange.lowerBound),
                    xEnd: .value("End", selectedRange.upperBound)
                )
                .foregroundStyle(.blue.opacity(0.12))
            }
            ForEach(indoor) { datum in
                LineMark(
                    x: .value("Date", datum.date),
                    y: .value("AQI", datum.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }
            if let selectedRange {
                RuleMark(x: .value("Start", selectedRange.lowerBound))
                    .foregroundStyle(.blue.opacity(0.5))
                RuleMark(x: .value("End", selectedRange.upperBound))
                    .foregroundStyle(.blue.opacity(0.5))
            }
        }
        .chartXSelection(range: $selectedRange)
    }

    // MARK: - Donut selection

    private var selectedSlice: PieDatum? {
        guard let selectedAngle else { return nil }
        var running = 0.0
        for slice in ChartSamples.marketShare {
            running += slice.value
            if selectedAngle <= running { return slice }
        }
        return ChartSamples.marketShare.last
    }

    private var donutChart: some View {
        Chart(ChartSamples.marketShare) { datum in
            SectorMark(
                angle: .value("Share", datum.value),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Name", datum.name))
            .cornerRadius(4)
            .opacity(selectedSlice == nil || selectedSlice?.name == datum.name ? 1 : 0.35)
        }
        .chartAngleSelection(value: $selectedAngle)
        .chartLegend(position: .bottom, spacing: 12)
        .overlay {
            VStack(spacing: 2) {
                if let slice = selectedSlice {
                    Text("\(Int(slice.value))%").font(.title2.bold())
                    Text(slice.name).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("100%").font(.title2.bold())
                    Text("Tap a sector").font(.caption).foregroundStyle(.secondary)
                }
            }
            .offset(y: -16)
        }
    }
}

#Preview {
    NavigationStack { ChartInteractionView() }
}
