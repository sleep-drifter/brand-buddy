import SwiftUI
import Charts

// MARK: - Chart 3D
//
// iOS 26's Chart3D: math surfaces via SurfacePlot and three-variable
// scatter plots, with an interactive camera pose. Drag either chart to
// orbit it.

struct Chart3DView: View {

    // Surface
    private enum SurfaceChoice: String, CaseIterable {
        case ripple = "Ripple", saddle = "Saddle", hill = "Hill"
    }
    @State private var surfaceChoice: SurfaceChoice = .ripple
    @State private var surfaceNormalStyle = false
    @State private var surfacePose: Chart3DPose = .default

    // Scatter
    @State private var scatterPose: Chart3DPose = .default

    private struct Point3D: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
        let z: Double
        let group: String
    }

    /// Three seeded clusters — a tiny stand-in for the classic penguin dataset.
    private static let clusters: [Point3D] = {
        var rng = SeededRandom(seed: 5)
        func cluster(_ n: Int, _ cx: Double, _ cy: Double, _ cz: Double,
                     spread: Double, group: String) -> [Point3D] {
            (0..<n).map { _ in
                Point3D(
                    x: cx + Double.random(in: -spread...spread, using: &rng),
                    y: cy + Double.random(in: -spread...spread, using: &rng),
                    z: cz + Double.random(in: -spread...spread, using: &rng),
                    group: group)
            }
        }
        return cluster(18, 190, 3700, 39, spread: 14, group: "Adelie")
             + cluster(18, 217, 5000, 47, spread: 14, group: "Gentoo")
             + cluster(18, 196, 3730, 49, spread: 12, group: "Chinstrap")
    }()

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("**Chart3D** plots three continuous variables at once — a surface for functions of two inputs, or a 3D point cloud for data. Both demos orbit with a drag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ChartHIGNote("Reach for 3D only when the third dimension *is* the message — a surface's shape, or clusters separating in space. Perspective makes individual values harder to compare, so keep 2D charts for precise reading.")
            }

            // ── Surface plot ───────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "Surface Plot", tag: "iOS 26")) {
                Chart3D {
                    SurfacePlot(x: "X", y: "Y", z: "Z") { x, z in
                        surface(x, z)
                    }
                    .foregroundStyle(surfaceNormalStyle ? .normalBased : .heightBased)
                }
                .chartXScale(domain: -1...1)
                .chartYScale(domain: -1...1)
                .chartZScale(domain: -1...1)
                .chart3DPose($surfacePose)
                .frame(height: 300)
                .padding(.vertical, 4)

                Picker("Surface", selection: $surfaceChoice) {
                    ForEach(SurfaceChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Toggle("Normal-based shading", isOn: $surfaceNormalStyle)
                HStack {
                    Button("Default pose") { withAnimation { surfacePose = .default } }
                        .buttonStyle(.bordered)
                    Button("Front") { withAnimation { surfacePose = .front } }
                        .buttonStyle(.bordered)
                }
                ChartCaption("SurfacePlot(x:y:z:) { x, z in … } in Chart3D")
                ChartHIGNote("Height-based shading maps color to the y value — good for reading magnitudes. Normal-based shading lights the surface by slope, which makes fine ripples and curvature pop.")
            }

            // ── 3D scatter ─────────────────────────────────────────────────
            Section(header: ChartSectionHeader(title: "3D Scatter", tag: "iOS 26")) {
                Chart3D(Self.clusters) { point in
                    PointMark(
                        x: .value("Flipper", point.x),
                        y: .value("Mass", point.y),
                        z: .value("Bill", point.z)
                    )
                    .foregroundStyle(by: .value("Species", point.group))
                }
                .chart3DPose($scatterPose)
                .frame(height: 300)
                .padding(.vertical, 4)

                HStack {
                    Button("Default pose") { withAnimation { scatterPose = .default } }
                        .buttonStyle(.bordered)
                    Button("Front") { withAnimation { scatterPose = .front } }
                        .buttonStyle(.bordered)
                }
                ChartCaption("Chart3D(data) { PointMark(x:y:z:) }")
                ChartHIGNote("Three clusters that overlap in any single 2D projection can separate cleanly in 3D — the rotation itself is information. Offer a reset so people can't get lost in an odd angle.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                ChartDoRow(good: true,  text: "Set an initial pose that already shows the structure — don't rely on the reader to find it by rotating.")
                ChartDoRow(good: true,  text: "Keep 3D charts large and interactive; a tiny static 3D chart is just a confusing picture.")
                ChartDoRow(good: false, text: "Don't use 3D for data a bar or line chart can show — depth adds occlusion and perspective distortion.")
                ChartDoRow(good: false, text: "Don't animate the camera continuously; motion should come from the person's own drag.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                ChartCodeRow(code: """
                    @State var pose: Chart3DPose = .default

                    Chart3D {
                        SurfacePlot(x: "X", y: "Y", z: "Z") { x, z in
                            (sin(5 * x) + sin(5 * z)) / 2
                        }
                        .foregroundStyle(.heightBased)
                    }
                    .chartXScale(domain: -1...1)
                    .chartZScale(domain: -1...1)
                    .chart3DPose($pose)   // drag to orbit
                    """)
            }
        }
        .navigationTitle("Chart 3D")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Surfaces

    private func surface(_ x: Double, _ z: Double) -> Double {
        switch surfaceChoice {
        case .ripple:
            return (sin(5 * x) + sin(5 * z)) / 2
        case .saddle:
            return x * x - z * z
        case .hill:
            return exp(-(x * x + z * z) * 2.2) * 1.6 - 0.4
        }
    }
}

#Preview {
    NavigationStack { Chart3DView() }
}
