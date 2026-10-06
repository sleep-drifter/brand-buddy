import SwiftUI
import Charts

// MARK: - Finance Charts
//
// Stocks-style patterns: a price line with scrub and change header,
// candlesticks built from RuleMark + RectangleMark, and a volume underlay
// sharing the price chart's domain.

struct FinanceChartsView: View {

    // MARK: Sample market data

    private struct Candle: Identifiable {
        let id = UUID()
        let date: Date
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Double
        var up: Bool { close >= open }
    }

    /// 90 days of a seeded random walk, oldest first.
    private static let candles: [Candle] = {
        var rng = SeededRandom(seed: 77)
        let start = Calendar.current.startOfDay(for: .now)
        var price = 184.0
        return (0..<90).map { i in
            let date = Calendar.current.date(byAdding: .day, value: i - 89, to: start)!
            let open = price
            let drift = Double.random(in: -4.2...4.6, using: &rng)
            let close = max(open + drift, 40)
            let high = max(open, close) + Double.random(in: 0.2...2.4, using: &rng)
            let low  = min(open, close) - Double.random(in: 0.2...2.4, using: &rng)
            let volume = Double.random(in: 18...70, using: &rng)
                       * (abs(drift) > 2.8 ? 1.7 : 1.0)   // busier on big moves
            price = close
            return Candle(date: date, open: open, high: high,
                          low: low, close: close, volume: volume)
        }
    }()

    private enum PriceRange: String, CaseIterable {
        case week = "1W", month = "1M", quarter = "3M"
        var days: Int {
            switch self {
            case .week:    return 7
            case .month:   return 30
            case .quarter: return 90
            }
        }
    }
    @State private var priceRange: PriceRange = .month
    @State private var scrubDate: Date?

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                ChartHIGNote("Finance charts lead with the latest value and the period's change — the chart is evidence. Direction color (green up, red down) is a convention worth keeping, but pair it with signs and arrows so color never carries the message alone.")
            }

            // ── Price line ─────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Price Line", tag: "Stocks style")) {
                priceHeader
                priceChart
                    .frame(height: 220)
                    .padding(.vertical, 4)
                Picker("Range", selection: $priceRange) {
                    ForEach(PriceRange.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                ChartCaption("LineMark + gradient AreaMark + dashed open RuleMark")
                ChartHIGNote("The dashed baseline at the period's opening price turns the whole chart into a change readout: everything above is gain, below is loss. Tint line and fill by the period's direction, not the day's.")
            }

            // ── Candlesticks ───────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Candlesticks", tag: "OHLC")) {
                candleChart
                    .frame(height: 240)
                    .padding(.vertical, 4)
                ChartCaption("RuleMark wick (low→high) + RectangleMark body (open→close)")
                ChartHIGNote("A candle packs four values into one mark: the thin wick spans the day's low to high, the body spans open to close, and fill color gives direction. Past ~40 candles the bodies blur — switch to a line.")
            }

            // ── Volume underlay ────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Volume Underlay", tag: "Shared domain")) {
                VStack(spacing: 2) {
                    closeLineChart
                        .frame(height: 160)
                    volumeChart
                        .frame(height: 64)
                }
                .padding(.vertical, 4)
                ChartCaption("two Charts, one chartXScale(domain:) — axes align")
                ChartHIGNote("Price and volume use incompatible y scales, so give each its own plot and pin both to the same x domain. Keep the volume strip short — it's context, not the headline.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                ChartDoRow(good: true,  text: "A zoomed (non-zero) y domain is standard for price charts — change is the message, not absolute level.")
                ChartDoRow(good: true,  text: "Show the period change as a signed number and arrow next to the price, styled in the direction color.")
                ChartDoRow(good: false, text: "Don't mix per-day coloring into a period line chart — one period, one direction, one color.")
                ChartDoRow(good: false, text: "Don't animate live price ticks with springs; financial data should settle instantly.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    Chart(candles) { candle in
                        RuleMark(x: .value("Day", candle.date, unit: .day),
                                 yStart: .value("Low", candle.low),
                                 yEnd: .value("High", candle.high))
                            .foregroundStyle(candle.up ? .green : .red)

                        RectangleMark(x: .value("Day", candle.date, unit: .day),
                                      yStart: .value("Open", candle.open),
                                      yEnd: .value("Close", candle.close),
                                      width: .fixed(5))
                            .foregroundStyle(candle.up ? .green : .red)
                    }
                    """)
            }
        }
        .navigationTitle("Finance Charts")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Price line

    private var rangeCandles: [Candle] {
        Array(Self.candles.suffix(priceRange.days))
    }

    private var scrubbedCandle: Candle? {
        guard let scrubDate else { return nil }
        return rangeCandles.min {
            abs($0.date.timeIntervalSince(scrubDate)) < abs($1.date.timeIntervalSince(scrubDate))
        }
    }

    private var periodOpen: Double { rangeCandles.first?.open ?? 0 }
    private var periodUp: Bool { (rangeCandles.last?.close ?? 0) >= periodOpen }
    private var directionColor: Color { periodUp ? .green : .red }

    private var priceHeader: some View {
        let shown = scrubbedCandle ?? rangeCandles.last
        let price = shown?.close ?? 0
        let change = price - periodOpen
        let percent = periodOpen != 0 ? change / periodOpen * 100 : 0
        return VStack(alignment: .leading, spacing: 4) {
            Text("$\(price, specifier: "%.2f")")
                .font(.title2.bold())
                .contentTransition(.numericText())
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text("\(change >= 0 ? "+" : "")\(change, specifier: "%.2f") (\(percent, specifier: "%.1f")%)")
                Text(shown.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? "")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
            .foregroundStyle(change >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var priceDomain: ClosedRange<Double> {
        let lows = rangeCandles.map(\.low)
        let highs = rangeCandles.map(\.high)
        let lo = (lows.min() ?? 0) - 2
        let hi = (highs.max() ?? 1) + 2
        return lo...hi
    }

    private var priceChart: some View {
        Chart {
            ForEach(rangeCandles) { candle in
                AreaMark(
                    x: .value("Date", candle.date, unit: .day),
                    yStart: .value("Open", periodOpen),
                    yEnd: .value("Close", candle.close)
                )
                .foregroundStyle(
                    LinearGradient(colors: [directionColor.opacity(0.22), .clear],
                                   startPoint: .top, endPoint: .bottom)
                )
                LineMark(
                    x: .value("Date", candle.date, unit: .day),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(directionColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            RuleMark(y: .value("Open", periodOpen))
                .foregroundStyle(.secondary.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
            if let candle = scrubbedCandle {
                RuleMark(x: .value("Selected", candle.date, unit: .day))
                    .foregroundStyle(.secondary.opacity(0.5))
                PointMark(
                    x: .value("Selected", candle.date, unit: .day),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(directionColor)
                .symbolSize(70)
            }
        }
        .chartYScale(domain: priceDomain)
        .chartXSelection(value: $scrubDate)
    }

    // MARK: - Candlesticks

    private var candleChart: some View {
        let shown = Array(Self.candles.suffix(30))
        return Chart(shown) { candle in
            RuleMark(
                x: .value("Day", candle.date, unit: .day),
                yStart: .value("Low", candle.low),
                yEnd: .value("High", candle.high)
            )
            .foregroundStyle(candle.up ? Color.green : .red)
            .lineStyle(StrokeStyle(lineWidth: 1))
            RectangleMark(
                x: .value("Day", candle.date, unit: .day),
                yStart: .value("Open", candle.open),
                yEnd: .value("Close", candle.close),
                width: .fixed(5)
            )
            .foregroundStyle(candle.up ? Color.green : .red)
            .cornerRadius(1)
        }
        .chartYScale(domain: domain(of: shown))
    }

    // MARK: - Volume underlay

    private var underlayCandles: [Candle] {
        Array(Self.candles.suffix(60))
    }

    private var underlayDomain: ClosedRange<Date> {
        let dates = underlayCandles.map(\.date)
        return (dates.first ?? .now)...(dates.last ?? .now)
    }

    private var closeLineChart: some View {
        Chart(underlayCandles) { candle in
            LineMark(
                x: .value("Date", candle.date, unit: .day),
                y: .value("Close", candle.close)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXScale(domain: underlayDomain)
        .chartYScale(domain: domain(of: underlayCandles))
        .chartXAxis(.hidden)
    }

    private var volumeChart: some View {
        Chart(underlayCandles) { candle in
            BarMark(
                x: .value("Date", candle.date, unit: .day),
                y: .value("Volume", candle.volume)
            )
            .foregroundStyle((candle.up ? Color.green : .red).opacity(0.45))
        }
        .chartXScale(domain: underlayDomain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }

    private func domain(of candles: [Candle]) -> ClosedRange<Double> {
        let lo = (candles.map(\.low).min() ?? 0) - 2
        let hi = (candles.map(\.high).max() ?? 1) + 2
        return lo...hi
    }
}

#Preview {
    NavigationStack { FinanceChartsView() }
}
