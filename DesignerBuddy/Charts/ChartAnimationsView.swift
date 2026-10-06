import SwiftUI
import Charts

// MARK: - Chart Animations
//
// Motion in charts: entry reveals, value morphing on data changes, and a
// live streaming chart — plus when *not* to animate (Reduce Motion,
// scrubbing).

struct ChartAnimationsView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Entry reveal
    @State private var revealed = Array(repeating: false,
                                        count: ChartSamples.weeklySteps.count)
    @State private var staggered = true

    // Data morphing
    private enum MorphMark: String, CaseIterable { case bar = "Bars", line = "Line" }
    @State private var morphMark: MorphMark = .bar
    @State private var morphSeed: UInt64 = 1

    // Streaming
    private struct StreamPoint: Identifiable {
        let id: Int
        let value: Double
    }
    @State private var streamPoints: [StreamPoint] = []
    @State private var streamLevel = 50.0
    @State private var isStreaming = true
    private let streamTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    private let streamWindow = 60

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                ChartHIGNote("Animation in a chart should mean something: values changed, data arrived, a range switched. Decorative motion distracts from reading the data — and all of it should quiet down when Reduce Motion is on.")
            }

            // ── Entry reveal ───────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Entry Reveal", tag: "On appear")) {
                Chart(Array(ChartSamples.weeklySteps.enumerated()), id: \.element.id) { index, datum in
                    BarMark(
                        x: .value("Day", datum.category),
                        y: .value("Steps", revealed[index] ? datum.value : 0)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(5)
                }
                .chartYScale(domain: 0...13000)
                .frame(height: 200)
                .padding(.vertical, 4)
                .onAppear { playReveal() }

                Toggle("Staggered", isOn: $staggered)
                Button {
                    resetReveal()
                    playReveal()
                } label: {
                    Label("Replay", systemImage: "arrow.counterclockwise")
                }
                ChartCaption("animate y from 0 → value · per-bar delay for stagger")
                ChartHIGNote("A grow-in orients the eye on first appearance, and a slight stagger reads as data \"arriving.\" Keep the whole reveal under a second — it plays on every visit.")
            }

            // ── Data morphing ──────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Data Morphing", tag: "Identity")) {
                Chart(morphData) { datum in
                    if morphMark == .bar {
                        BarMark(
                            x: .value("Point", datum.label),
                            y: .value("Value", datum.value)
                        )
                        .foregroundStyle(.purple.gradient)
                        .cornerRadius(4)
                    } else {
                        LineMark(
                            x: .value("Point", datum.label),
                            y: .value("Value", datum.value)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .symbol(.circle)
                    }
                }
                .chartYScale(domain: 0...110)
                .frame(height: 200)
                .padding(.vertical, 4)

                Picker("Mark", selection: $morphMark) {
                    ForEach(MorphMark.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Button {
                    if reduceMotion {
                        morphSeed &+= 1
                    } else {
                        withAnimation(.spring(duration: 0.6)) { morphSeed &+= 1 }
                    }
                } label: {
                    Label("New values", systemImage: "dice")
                }
                ChartCaption("stable ids per mark → values interpolate in place")
                ChartHIGNote("Swift Charts animates a data change only when marks keep their identity. Give each datum a stable id across updates and bars stretch, lines bend — instead of the whole chart cross-fading.")
            }

            // ── Streaming ──────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Live Streaming", tag: "Realtime")) {
                Chart(streamPoints) { point in
                    LineMark(
                        x: .value("Tick", point.id),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.teal)
                    AreaMark(
                        x: .value("Tick", point.id),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(.teal.opacity(0.12))
                }
                .chartXScale(domain: streamDomain)
                .chartYScale(domain: 0...100)
                .chartXAxis(.hidden)
                .frame(height: 180)
                .padding(.vertical, 4)
                .onAppear { seedStream() }
                .onReceive(streamTimer) { _ in
                    if isStreaming { streamTick() }
                }

                Toggle(isOn: $isStreaming) {
                    Label(isStreaming ? "Streaming" : "Paused",
                          systemImage: isStreaming ? "pause.fill" : "play.fill")
                }
                ChartCaption("append + slide chartXScale domain each tick")
                ChartHIGNote("For live data, keep a fixed window and a fixed y domain so only the data moves — a chart that rescales on every tick is unreadable. Slide, don't jump.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                ChartDoRow(good: true,  text: "Honor **Reduce Motion**: skip entry reveals and tick animation; values may still change, just without the choreography.")
                ChartDoRow(good: true,  text: "Animate range switches (W → M) so people see the data re-aggregate rather than teleport.")
                ChartDoRow(good: false, text: "Don't animate values while someone is scrubbing — the readout must track the finger exactly.")
                ChartDoRow(good: false, text: "Don't loop ambient motion in a chart; it reads as data changing when nothing changed.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    // Marks animate when their data changes under
                    // withAnimation — as long as ids stay stable.
                    struct Datum: Identifiable {
                        let id: String   // stable across updates
                        var value: Double
                    }

                    Button("Update") {
                        withAnimation(.spring(duration: 0.6)) {
                            regenerateValues()   // same ids, new values
                        }
                    }
                    """)
            }
        }
        .navigationTitle("Chart Animations")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Entry reveal

    private func resetReveal() {
        revealed = Array(repeating: false, count: ChartSamples.weeklySteps.count)
    }

    private func playReveal() {
        guard !reduceMotion else {
            revealed = Array(repeating: true, count: revealed.count)
            return
        }
        for index in revealed.indices {
            let delay = staggered ? Double(index) * 0.07 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(duration: 0.5)) {
                    if index < revealed.count { revealed[index] = true }
                }
            }
        }
    }

    // MARK: - Data morphing

    private struct MorphDatum: Identifiable {
        let id: String
        let label: String
        let value: Double
    }

    private var morphData: [MorphDatum] {
        var rng = SeededRandom(seed: morphSeed)
        return (0..<8).map { i in
            MorphDatum(
                id: "m\(i)",
                label: "P\(i + 1)",
                value: Double.random(in: 15...100, using: &rng))
        }
    }

    // MARK: - Streaming

    private var streamDomain: ClosedRange<Int> {
        let hi = streamPoints.last?.id ?? streamWindow
        return (hi - streamWindow + 1)...hi
    }

    private func seedStream() {
        guard streamPoints.isEmpty else { return }
        var rng = SeededRandom(seed: 9)
        var level = 50.0
        streamPoints = (0..<streamWindow).map { i in
            level += Double.random(in: -7...7, using: &rng)
            level = min(max(level, 10), 90)
            return StreamPoint(id: i, value: level)
        }
        streamLevel = level
    }

    private func streamTick() {
        streamLevel += Double.random(in: -7...7)
        streamLevel = min(max(streamLevel, 10), 90)
        let next = StreamPoint(id: (streamPoints.last?.id ?? 0) + 1,
                               value: streamLevel)
        let apply = {
            streamPoints.append(next)
            if streamPoints.count > streamWindow + 20 {
                streamPoints.removeFirst(streamPoints.count - streamWindow - 20)
            }
        }
        if reduceMotion {
            apply()
        } else {
            withAnimation(.linear(duration: 0.35)) { apply() }
        }
    }
}

#Preview {
    NavigationStack { ChartAnimationsView() }
}
