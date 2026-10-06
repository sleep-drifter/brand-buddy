import SwiftUI
import Charts

// MARK: - Function Plots
//
// iOS 18's second generation of Swift Charts: plot math functions directly
// with LinePlot/AreaPlot closures, and render large datasets with the
// vectorized plot initializers.

struct FunctionPlotsView: View {

    // Function graphing
    private enum FunctionChoice: String, CaseIterable {
        case sine = "Sine", damped = "Damped", cubic = "Cubic"
    }
    @State private var functionChoice: FunctionChoice = .sine
    @State private var amplitude = 1.5
    @State private var frequency = 1.0

    // Distribution
    @State private var mean = 0.0
    @State private var sigma = 1.0

    // Vectorized
    @State private var sampleCount = 1000.0

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("iOS 18 added two plot families: **function plots** that graph a closure over a continuous domain, and **vectorized plots** that take whole collections at once for large datasets.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Function graphing ──────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "LinePlot", tag: "iOS 18")) {
                functionChart
                    .frame(height: 220)
                    .padding(.vertical, 4)

                Picker("Function", selection: $functionChoice) {
                    ForEach(FunctionChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                LabeledContent("Amplitude \(amplitude, specifier: "%.1f")") {
                    Slider(value: $amplitude, in: 0.2...3)
                        .frame(width: 150)
                }
                LabeledContent("Frequency \(frequency, specifier: "%.1f")") {
                    Slider(value: $frequency, in: 0.2...4)
                        .frame(width: 150)
                }
                ChartCaption("LinePlot(x: \"x\", y: \"y\") { x in … }")
                ChartHIGNote("A function plot has no data points — Swift Charts samples the closure across the visible domain. Pin the domain explicitly with chartXScale/chartYScale so the shape doesn't jump as parameters change.")
            }

            // ── Area under a curve ─────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "AreaPlot", tag: "iOS 18")) {
                Chart {
                    AreaPlot(x: "x", y: "density") { x in
                        gaussian(x, mean: mean, sigma: sigma)
                    }
                    .foregroundStyle(.purple.opacity(0.25))
                    LinePlot(x: "x", y: "density") { x in
                        gaussian(x, mean: mean, sigma: sigma)
                    }
                    .foregroundStyle(.purple)
                    RuleMark(x: .value("Mean", mean))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartXScale(domain: -5...5)
                .chartYScale(domain: 0...0.9)
                .frame(height: 220)
                .padding(.vertical, 4)

                LabeledContent("Mean \(mean, specifier: "%.1f")") {
                    Slider(value: $mean, in: -2...2)
                        .frame(width: 150)
                }
                LabeledContent("Sigma \(sigma, specifier: "%.1f")") {
                    Slider(value: $sigma, in: 0.5...2)
                        .frame(width: 150)
                }
                ChartCaption("AreaPlot(x: \"x\", y: \"y\") { x in … }")
                ChartHIGNote("AreaPlot fills between the curve and zero — made for distributions and \"area under the curve\" explanations. Pair the fill with a line so the curve's edge stays crisp.")
            }

            // ── Vectorized plots ───────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Vectorized Plots", tag: "Performance")) {
                Chart {
                    LinePlot(
                        vectorSamples,
                        x: .value("x", \.x),
                        y: .value("y", \.y)
                    )
                    .foregroundStyle(.teal)
                }
                .chartYScale(domain: -2...2)
                .frame(height: 200)
                .padding(.vertical, 4)

                LabeledContent("Samples: \(Int(sampleCount))") {
                    Slider(value: $sampleCount, in: 100...5000, step: 100)
                        .frame(width: 150)
                }
                ChartCaption("LinePlot(data, x: .value(…, \\.x), y: .value(…, \\.y))")
                ChartHIGNote("Vectorized initializers take the whole collection and keypaths instead of building a mark per element — markedly faster for thousands of points. All points share one style; use the per-element API when styling varies.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    Chart {
                        // Graph a function directly
                        LinePlot(x: "x", y: "y") { x in
                            amplitude * sin(frequency * x)
                        }

                        // Or plot a big dataset in one call
                        LinePlot(samples,
                                 x: .value("x", \\.x),
                                 y: .value("y", \\.y))
                    }
                    .chartXScale(domain: -10...10)
                    """)
            }
        }
        .navigationTitle("Function Plots")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private var functionChart: some View {
        Chart {
            LinePlot(x: "x", y: "y") { x in
                evaluate(x)
            }
            .foregroundStyle(.blue)
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1))
        }
        .chartXScale(domain: -10...10)
        .chartYScale(domain: -4...4)
    }

    private func evaluate(_ x: Double) -> Double {
        switch functionChoice {
        case .sine:
            return amplitude * sin(frequency * x)
        case .damped:
            return amplitude * sin(frequency * x) * exp(-abs(x) / 4)
        case .cubic:
            return amplitude * 0.02 * frequency * x * x * x
        }
    }

    private func gaussian(_ x: Double, mean: Double, sigma: Double) -> Double {
        let z = (x - mean) / sigma
        return exp(-z * z / 2) / (sigma * (2 * Double.pi).squareRoot())
    }

    private struct VectorSample {
        let x: Double
        let y: Double
    }

    private var vectorSamples: [VectorSample] {
        let count = Int(sampleCount)
        return (0..<count).map { i in
            let x = Double(i) / Double(count - 1) * 20 - 10
            // A noisy signal that only reads as a shape with enough samples.
            let y = sin(x) + 0.4 * sin(7.3 * x) + 0.2 * sin(23.7 * x)
            return VectorSample(x: x, y: y)
        }
    }
}

#Preview {
    NavigationStack { FunctionPlotsView() }
}
