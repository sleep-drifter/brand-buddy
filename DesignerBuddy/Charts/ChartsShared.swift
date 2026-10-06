import SwiftUI
import Charts

// MARK: - Shared data models
//
// Every charts page draws from the same small vocabulary of sample types so
// demos stay comparable across pages. All sample data is deterministic
// (seeded) so previews and screenshots never shift between launches.

struct CategoryDatum: Identifiable {
    let id = UUID()
    let category: String
    let series: String
    let value: Double
}

struct DailyDatum: Identifiable {
    let id = UUID()
    let date: Date
    let series: String
    let value: Double
}

struct ScatterDatum: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let group: String
}

struct HeatCell: Identifiable {
    let id = UUID()
    let day: Int    // 0 = Mon … 6 = Sun
    let hour: Int   // 0…23
    let level: Double
}

struct RangeDatum: Identifiable {
    let id = UUID()
    let label: String
    let low: Double
    let high: Double
}

struct PieDatum: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
}

// MARK: - Seeded random

/// SplitMix64 — tiny deterministic generator so sample data is stable.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Sample datasets

enum ChartSamples {

    static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    static let months   = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// Steps per weekday — the canonical single-series bar dataset.
    static let weeklySteps: [CategoryDatum] = {
        let values: [Double] = [8450, 7230, 9100, 6875, 10340, 12680, 5420]
        return zip(weekdays, values).map {
            CategoryDatum(category: $0.0, series: "Steps", value: $0.1)
        }
    }()

    /// Quarterly revenue for three product lines — grouped / stacked bars.
    static let quarterlyRevenue: [CategoryDatum] = {
        let lines: [(String, [Double])] = [
            ("Hardware", [42, 48, 45, 61]),
            ("Software", [28, 31, 38, 44]),
            ("Services", [18, 22, 26, 30]),
        ]
        return lines.flatMap { series, values in
            zip(["Q1", "Q2", "Q3", "Q4"], values).map {
                CategoryDatum(category: $0.0, series: series, value: $0.1)
            }
        }
    }()

    /// 30 days × 2 series of smooth trend data — lines and areas.
    static let monthTrend: [DailyDatum] = {
        var rng = SeededRandom(seed: 7)
        let start = Calendar.current.startOfDay(for: .now)
        return (0..<30).flatMap { i -> [DailyDatum] in
            let date = Calendar.current.date(byAdding: .day, value: i - 29, to: start)!
            let base = Double(i)
            let a = 62 + 14 * sin(base / 4.6) + Double.random(in: -4...4, using: &rng)
            let b = 48 + 10 * sin(base / 3.4 + 1.8) + Double.random(in: -4...4, using: &rng)
            return [
                DailyDatum(date: date, series: "Indoor",  value: a),
                DailyDatum(date: date, series: "Outdoor", value: b),
            ]
        }
    }()

    /// 120 days of a single metric — the scrolling-chart dataset.
    static let longHistory: [DailyDatum] = {
        var rng = SeededRandom(seed: 21)
        let start = Calendar.current.startOfDay(for: .now)
        var level = 72.0
        return (0..<120).map { i in
            let date = Calendar.current.date(byAdding: .day, value: i - 119, to: start)!
            level += Double.random(in: -5...5, using: &rng)
            level = min(max(level, 45), 110)
            return DailyDatum(date: date, series: "Resting HR", value: level)
        }
    }()

    /// Two clusters of points — scatter demos.
    static let scatter: [ScatterDatum] = {
        var rng = SeededRandom(seed: 3)
        var out: [ScatterDatum] = []
        for _ in 0..<24 {
            out.append(ScatterDatum(
                x: Double.random(in: 18...42, using: &rng),
                y: Double.random(in: 120...190, using: &rng),
                group: "Morning"))
        }
        for _ in 0..<24 {
            out.append(ScatterDatum(
                x: Double.random(in: 30...58, using: &rng),
                y: Double.random(in: 90...160, using: &rng),
                group: "Evening"))
        }
        return out
    }()

    /// 7 × 24 activity grid — heatmap demos.
    static let heatmap: [HeatCell] = {
        var rng = SeededRandom(seed: 11)
        var out: [HeatCell] = []
        for day in 0..<7 {
            for hour in 0..<24 {
                // A plausible daily rhythm: quiet nights, busy afternoons,
                // lighter weekends.
                let rhythm = max(0, sin((Double(hour) - 6) / 24 * .pi * 2) + 0.45)
                let weekend = day >= 5 ? 0.6 : 1.0
                let noise = Double.random(in: 0...0.35, using: &rng)
                out.append(HeatCell(day: day, hour: hour,
                                    level: min(1, rhythm * weekend + noise)))
            }
        }
        return out
    }()

    /// Monthly temperature ranges — range-bar demos.
    static let tempRanges: [RangeDatum] = {
        let lows:  [Double] = [-3, -1, 3, 8, 13, 17, 20, 19, 15, 9, 4, -1]
        let highs: [Double] = [ 4,  6, 11, 17, 22, 27, 30, 29, 24, 17, 10, 5]
        return (0..<12).map {
            RangeDatum(label: months[$0], low: lows[$0], high: highs[$0])
        }
    }()

    /// Market share — pie / donut demos.
    static let marketShare: [PieDatum] = [
        PieDatum(name: "Cirrus",  value: 38),
        PieDatum(name: "Nimbus",  value: 27),
        PieDatum(name: "Stratus", value: 19),
        PieDatum(name: "Cumulus", value: 11),
        PieDatum(name: "Other",   value: 5),
    ]
}

// MARK: - Palette

enum ChartPalette {
    /// Distinct hues that hold up in dark mode and under color filters.
    static let standard: [Color] = [.blue, .orange, .green, .purple, .pink, .teal]

    /// Heat ramp used by heatmap demos. Interpolating manually keeps the
    /// mapping explicit and independent of scale inference.
    static func heat(_ t: Double) -> Color {
        let clamped = min(max(t, 0), 1)
        return Color(hue: 0.62 - 0.62 * clamped,
                     saturation: 0.55 + 0.35 * clamped,
                     brightness: 0.95 - 0.15 * clamped)
    }
}

// MARK: - Shared rows & headers

/// Section header with a small capsule tag, matching the Menus page style.
struct ChartSectionHeader: View {
    let title: String
    var tag: String? = nil
    var tagColor: Color = .blue

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            if let tag {
                Text(tag)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tagColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(tagColor.opacity(0.12)))
            }
        }
    }
}

/// Monospaced caption under a demo — names the API that produced it.
struct ChartCaption: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.mono(.caption2))
            .foregroundStyle(.secondary)
    }
}

/// A Human Interface Guidelines call-out row.
struct ChartHIGNote: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "book.closed")
                .font(.footnote)
                .foregroundStyle(.blue)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Do / Don't row for HIG guidance lists.
struct ChartDoRow: View {
    let good: Bool
    let text: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: good ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(good ? .green : .red)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Inline code snippet block.
struct ChartCodeRow: View {
    let code: String
    var body: some View {
        Text(code)
            .font(.mono(.caption))
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
