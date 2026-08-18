import SwiftUI
import CoreMotion
import simd

// Soft-body playground: the matter.js Composites.softBody idea implemented
// the fast way — a hand-rolled particle/constraint solver (SoftBodyEngine)
// drawn with Canvas at display rate. The HUD shows real solver cost so the
// performance story is measurable, not claimed: crank the grid and watch
// sim milliseconds, then flip Verlet ↔ XPBD or trade substeps against
// iterations and see what it buys.

struct SoftBodyView: View {
    @State private var world = SoftBodyWorld()

    @State private var scene: SoftBodyScene = .blobs
    @State private var solver: SoftBodySolver = .verlet
    @State private var stiffness: Double = 0.65
    @State private var iterations: Double = 4
    @State private var substeps: Double = 4
    @State private var gravity: Double = 1500
    @State private var damping: Double = 0.996
    @State private var blobGrid: Double = 6
    @State private var wireframe = true
    @State private var tilt = false
    @State private var tearing = true
    @State private var resetToken = 0

    @State private var motion: CMMotionManager?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Soft Body", shuffle: { resetToken += 1 }) {
            stage
        }
        .navigationTitle("Soft Body")
        .onDisappear { stopTilt() }
        .onChange(of: tilt) {
            if tilt { startTilt() } else { stopTilt() }
        }
    }

    // MARK: - Stage

    private var stage: some View {
        TimelineView(.animation) { tl in
            ZStack(alignment: .topLeading) {
                Canvas { ctx, size in
                    world.config = currentConfig()
                    world.advance(now: tl.date, size: size,
                                  scene: scene, blobGrid: Int(blobGrid),
                                  resetToken: resetToken)
                    world.draw(in: &ctx, wireframe: wireframe)
                }
                hud
                    .padding(8)
            }
        }
        .frame(height: 280)
        .background(Color(red: 0.075, green: 0.085, blue: 0.12),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { world.drag(to: $0.location) }
                .onEnded { v in
                    let fling = CGSize(
                        width: (v.predictedEndTranslation.width - v.translation.width) * 4,
                        height: (v.predictedEndTranslation.height - v.translation.height) * 4
                    )
                    world.endDrag(flingPointsPerSecond: fling)
                }
        )
    }

    private var hud: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: "sim %.2f ms · frame %.1f ms", world.simMs, world.frameMs))
                Text("\(world.particleCount) pts · \(world.constraintCount) constraints")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.65))

            sparkline
                .frame(width: 64, height: 20)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .allowsHitTesting(false)
    }

    /// Rolling solver-cost sparkline, scaled to the 120 Hz step budget.
    private var sparkline: some View {
        Canvas { ctx, size in
            let history = world.history
            let n = history.count
            let budget = 1000.0 / 120.0
            var path = Path()
            for k in 0..<n {
                let sample = history[(world.historyIdx + 1 + k) % n]
                let x = size.width * CGFloat(k) / CGFloat(n - 1)
                let y = size.height * (1 - CGFloat(min(sample / budget, 1)))
                if k == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(.cyan.opacity(0.9)), lineWidth: 1)
        }
    }

    private func currentConfig() -> SoftBodyConfig {
        var c = SoftBodyConfig()
        c.solver = solver
        c.stiffness = Float(stiffness)
        c.iterations = Int(iterations)
        c.substeps = Int(substeps)
        c.damping = Float(damping)
        c.tearing = tearing
        c.gravity = gravityVector() * Float(gravity)
        return c
    }

    private func gravityVector() -> SIMD2<Float> {
        if tilt, let a = motion?.accelerometerData?.acceleration {
            let v = SIMD2<Float>(Float(a.x), Float(-a.y))
            let len = simd_length(v)
            if len > 0.05 { return v / len }
        }
        return SIMD2<Float>(0, 1)
    }

    private func startTilt() {
        let m = CMMotionManager()
        guard m.isAccelerometerAvailable else { return }
        m.accelerometerUpdateInterval = 1.0 / 60.0
        m.startAccelerometerUpdates()
        motion = m
    }

    private func stopTilt() {
        motion?.stopAccelerometerUpdates()
        motion = nil
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            row {
                Picker("Scene", selection: $scene) {
                    ForEach(SoftBodyScene.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            divider
            row {
                HStack {
                    Text("Solver").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Solver", selection: $solver) {
                        ForEach(SoftBodySolver.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 170)
                }
            }
            divider
            sliderRow("Stiffness", $stiffness, 0.05...1, text: String(format: "%.2f", stiffness))
            divider
            sliderRow("Iterations", $iterations, 1...10, step: 1, text: "\(Int(iterations))")
            divider
            sliderRow("Substeps", $substeps, 1...8, step: 1, text: "\(Int(substeps))")
            divider
            sliderRow("Gravity", $gravity, 0...3000, text: "\(Int(gravity))")
            divider
            sliderRow("Damping", $damping, 0.9...1.0, text: String(format: "%.3f", damping))
            if scene == .blobs {
                divider
                sliderRow("Grid", $blobGrid, 4...9, step: 1, text: "\(Int(blobGrid))×\(Int(blobGrid))")
            }
            divider
            row { Toggle("Wireframe (matter.js debug look)", isOn: $wireframe) }
            divider
            row { Toggle("Tilt Gravity", isOn: $tilt) }
            if scene == .cloth {
                divider
                row { Toggle("Tearing", isOn: $tearing) }
            }
            divider
            row {
                HStack(spacing: 12) {
                    Button {
                        resetToken += 1
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    if scene == .blobs {
                        Button {
                            world.spawnBlob()
                        } label: {
                            Label("Add Blob", systemImage: "plus.circle.fill")
                        }
                    }
                    Spacer()
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Caption

    private var caption: some View {
        Text(captionText)
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    private var captionText: String {
        let sceneNote: String
        switch scene {
        case .blobs:
            sceneNote = "Each blob is a grid of circle particles cross-braced with distance "
                + "constraints — the matter.js `Composites.softBody` recipe. Drag to grab, "
                + "flick to throw, Add Blob to stress the solver. "
        case .balloons:
            sceneNote = "Balloons are a ring of particles held round by gas pressure: each "
                + "substep compares the polygon's area to its rest area and pushes vertices "
                + "along their normals. Squash one and it reinflates. "
        case .cloth:
            sceneNote = "Same solver, different topology: a pinned sheet (no diagonals, so it "
                + "shears like fabric) and a rope with a welded weight. Drag hard and "
                + "constraints past 2.6× rest length tear. "
        }
        return sceneNote
            + "Everything runs on a hand-rolled particle solver — SoA SIMD storage, a fixed "
            + "120 Hz accumulator, and a flat spatial hash for collisions — because soft-body "
            + "squish is just particles + constraints; an engine adds overhead, not softness. "
            + "The HUD's sim number is per-step solver cost against the 8.3 ms budget "
            + "(sparkline scale). Verlet folds stiffness into iteration count; XPBD's "
            + "compliance keeps stiffness stable when you change substeps or iterations — "
            + "flip the toggle and compare both feel and cost."
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 52, alignment: .trailing)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

#Preview {
    NavigationStack { SoftBodyView() }
        .environmentObject(PinsStore())
}
