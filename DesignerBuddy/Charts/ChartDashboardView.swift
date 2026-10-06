import SwiftUI
import Charts

// MARK: - Chart Dashboards
//
// Composing charts into a Health-style overview: glanceable stat tiles with
// sparklines, a trend call-out, a featured chart with range switching, and
// tap-through to a full interactive detail — the HIG's progressive
// disclosure, end to end.

// MARK: - Metric model

struct DashboardMetric: Identifiable {
    let id: String
    let name: String
    let unit: String
    let color: Color
    let icon: String
    let usesBars: Bool
    let data: [DailyDatum]   // 28 days, oldest first

    var latest: Double { data.last?.value ?? 0 }

    /// Percent change: last 7 days vs. the 7 before.
    var weekDelta: Double {
        let values = data.map(\.value)
        guard values.count >= 14 else { return 0 }
        let current = values.suffix(7).reduce(0, +) / 7
        let previous = values.suffix(14).prefix(7).reduce(0, +) / 7
        guard previous != 0 else { return 0 }
        return (current - previous) / previous * 100
    }

    static let all: [DashboardMetric] = [
        make(id: "steps", name: "Steps", unit: "steps", color: .orange,
             icon: "figure.walk", usesBars: true, base: 8200, swing: 2800, seed: 31),
        make(id: "heart", name: "Heart Rate", unit: "bpm", color: .pink,
             icon: "heart.fill", usesBars: false, base: 68, swing: 9, seed: 32),
        make(id: "sleep", name: "Sleep", unit: "hrs", color: .indigo,
             icon: "moon.zzz.fill", usesBars: true, base: 7.1, swing: 1.4, seed: 33),
        make(id: "water", name: "Hydration", unit: "oz", color: .teal,
             icon: "drop.fill", usesBars: true, base: 58, swing: 22, seed: 34),
    ]

    private static func make(id: String, name: String, unit: String, color: Color,
                             icon: String, usesBars: Bool,
                             base: Double, swing: Double, seed: UInt64) -> DashboardMetric {
        var rng = SeededRandom(seed: seed)
        let start = Calendar.current.startOfDay(for: .now)
        let data = (0..<28).map { i -> DailyDatum in
            let date = Calendar.current.date(byAdding: .day, value: i - 27, to: start)!
            let drift = sin(Double(i) / 5.5) * swing * 0.4
            let noise = Double.random(in: -swing...swing, using: &rng) * 0.5
            return DailyDatum(date: date, series: name,
                              value: max(base + drift + noise, base * 0.2))
        }
        return DashboardMetric(id: id, name: name, unit: unit, color: color,
                               icon: icon, usesBars: usesBars, data: data)
    }
}

// MARK: - Dashboard page

struct ChartDashboardView: View {

    private enum FeaturedRange: String, CaseIterable {
        case week = "Week", month = "Month"
    }
    @State private var featuredRange: FeaturedRange = .week

    private var steps: DashboardMetric { DashboardMetric.all[0] }

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                ChartHIGNote("A dashboard answers \"how am I doing?\" at a glance, then earns taps into detail. Tiles stay minimal — value, trend, shape — and every chart for a metric uses that metric's one color, everywhere it appears.")
            }

            // ── Stat tiles ─────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Stat Tiles", tag: "Overview")) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)],
                          spacing: 12) {
                    ForEach(DashboardMetric.all) { metric in
                        NavigationLink {
                            MetricDetailView(metric: metric)
                        } label: {
                            MetricTile(metric: metric)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                ChartCaption("tile = value + delta + bare sparkline · tap → detail")
                ChartHIGNote("No axes, legends, or gridlines in a tile — just the data's shape. The full chart, with axes and scrubbing, lives one tap away.")
            }

            // ── Trend call-out ─────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Trend Call-out", tag: "Insight")) {
                TrendCard(metric: steps)
                ChartCaption("overlay this week on last week, say the delta in words")
                ChartHIGNote("The most useful chart on a dashboard is often a sentence with evidence: state the trend, then show the two weeks that prove it.")
            }

            // ── Featured chart ─────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Featured Chart", tag: "Range switch")) {
                Picker("Range", selection: $featuredRange) {
                    ForEach(FeaturedRange.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                Chart(featuredData) { datum in
                    BarMark(
                        x: .value("Day", datum.date, unit: .day),
                        y: .value("Steps", datum.value)
                    )
                    .foregroundStyle(steps.color.gradient)
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...13000)
                .animation(.snappy, value: featuredRange)
                .frame(height: 200)
                .padding(.vertical, 4)

                ChartCaption(".animation(.snappy, value: range) re-aggregates in place")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                ChartDoRow(good: true,  text: "One color per metric, consistent from tile to detail — color becomes navigation.")
                ChartDoRow(good: true,  text: "Keep the y-scale fixed when switching ranges on one chart, so bars stay comparable.")
                ChartDoRow(good: false, text: "Don't put more than a handful of charts on screen at once; past that, nothing is glanceable.")
                ChartDoRow(good: false, text: "Don't make tiles interactive beyond the tap-through — scrubbing belongs on the full-size chart.")
            }
        }
        .navigationTitle("Chart Dashboards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var featuredData: [DailyDatum] {
        switch featuredRange {
        case .week:  return Array(steps.data.suffix(7))
        case .month: return steps.data
        }
    }
}

// MARK: - Tile

private struct MetricTile: View {
    let metric: DashboardMetric

    private var deltaUp: Bool { metric.weekDelta >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                    .foregroundStyle(metric.color)
                Text(metric.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatted(metric.latest))
                    .font(.title3.bold())
                Text(metric.unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 3) {
                Image(systemName: deltaUp ? "arrow.up.right" : "arrow.down.right")
                Text("\(abs(metric.weekDelta), specifier: "%.0f")% vs last week")
            }
            .font(.caption2)
            .foregroundStyle(deltaUp ? .green : .red)

            sparkline
                .frame(height: 34)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var sparkline: some View {
        let recent = Array(metric.data.suffix(14))
        Chart(recent) { datum in
            if metric.usesBars {
                BarMark(
                    x: .value("Date", datum.date, unit: .day),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(metric.color.gradient)
                .cornerRadius(1.5)
            } else {
                LineMark(
                    x: .value("Date", datum.date, unit: .day),
                    y: .value("Value", datum.value)
                )
                .foregroundStyle(metric.color)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }

    private func formatted(_ value: Double) -> String {
        value >= 100 ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

// MARK: - Trend card

private struct TrendCard: View {
    let metric: DashboardMetric

    private var thisWeek: [Double] { metric.data.suffix(7).map(\.value) }
    private var lastWeek: [Double] { Array(metric.data.suffix(14).prefix(7)).map(\.value) }
    private var deltaUp: Bool { metric.weekDelta >= 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: deltaUp ? "arrow.up.right" : "arrow.down.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(deltaUp ? .green : .red)
                Text("\(metric.name) \(deltaUp ? "up" : "down") \(abs(metric.weekDelta), specifier: "%.0f")% this week")
                    .font(.subheadline.bold())
            }
            Chart {
                ForEach(Array(lastWeek.enumerated()), id: \.offset) { day, value in
                    LineMark(
                        x: .value("Day", day),
                        y: .value("Value", value),
                        series: .value("Week", "Last week")
                    )
                    .foregroundStyle(.gray.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .interpolationMethod(.catmullRom)
                }
                ForEach(Array(thisWeek.enumerated()), id: \.offset) { day, value in
                    LineMark(
                        x: .value("Day", day),
                        y: .value("Value", value),
                        series: .value("Week", "This week")
                    )
                    .foregroundStyle(metric.color)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 70)
            HStack(spacing: 14) {
                legendDot(color: metric.color, label: "This week")
                legendDot(color: .gray.opacity(0.45), label: "Last week")
            }
        }
        .padding(.vertical, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Detail

private struct MetricDetailView: View {
    let metric: DashboardMetric
    @State private var scrubDate: Date?

    private var scrubbed: DailyDatum? {
        guard let scrubDate else { return nil }
        return metric.data.min {
            abs($0.date.timeIntervalSince(scrubDate)) < abs($1.date.timeIntervalSince(scrubDate))
        }
    }

    private var stats: (avg: Double, low: Double, high: Double) {
        let values = metric.data.map(\.value)
        let avg = values.reduce(0, +) / Double(max(values.count, 1))
        return (avg, values.min() ?? 0, values.max() ?? 0)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    let current = scrubbed ?? metric.data.last
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(current.map { String(format: $0.value >= 100 ? "%.0f" : "%.1f", $0.value) } ?? "—")
                            .font(.title.bold())
                            .contentTransition(.numericText())
                        Text(metric.unit)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(current.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                detailChart
                    .frame(height: 240)
                    .padding(.vertical, 4)
            }

            Section("Last 28 days") {
                LabeledContent("Average", value: String(format: "%.1f %@", stats.avg, metric.unit))
                LabeledContent("Lowest",  value: String(format: "%.1f %@", stats.low, metric.unit))
                LabeledContent("Highest", value: String(format: "%.1f %@", stats.high, metric.unit))
            }

            Section {
                ChartHIGNote("The detail view is where axes, scrubbing, and statistics belong. It repeats the tile's color and shape so the transition feels like zooming in, not switching apps.")
            }
        }
        .navigationTitle(metric.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailChart: some View {
        Chart {
            ForEach(metric.data) { datum in
                if metric.usesBars {
                    BarMark(
                        x: .value("Date", datum.date, unit: .day),
                        y: .value("Value", datum.value)
                    )
                    .foregroundStyle(metric.color.gradient)
                    .cornerRadius(2)
                    .opacity(scrubbed == nil || scrubbed?.id == datum.id ? 1 : 0.45)
                } else {
                    LineMark(
                        x: .value("Date", datum.date, unit: .day),
                        y: .value("Value", datum.value)
                    )
                    .foregroundStyle(metric.color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            if let scrubbed, !metric.usesBars {
                RuleMark(x: .value("Selected", scrubbed.date))
                    .foregroundStyle(.secondary.opacity(0.5))
                PointMark(
                    x: .value("Selected", scrubbed.date),
                    y: .value("Value", scrubbed.value)
                )
                .foregroundStyle(metric.color)
                .symbolSize(80)
            }
        }
        .chartXSelection(value: $scrubDate)
    }
}

#Preview {
    NavigationStack { ChartDashboardView() }
}
