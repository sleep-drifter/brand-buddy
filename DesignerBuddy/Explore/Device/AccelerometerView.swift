import SwiftUI
import CoreMotion
import Combine

// MARK: - Accelerometer & Gyroscope View

struct AccelerometerView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                #if targetEnvironment(simulator)
                simulatorBanner
                #endif
                liveValuesCard
                tiltBallCard
                gyroCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Accelerometer & Gyroscope")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { motionManager.start() }
        .onDisappear { motionManager.stop() }
    }

    // MARK: Simulator Banner

    private var simulatorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.slash").foregroundStyle(.orange)
            Text("Live motion data requires a physical device. Simulator shows static demo values.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Live Values Card

    private var liveValuesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Accelerometer", systemImage: "move.3d").font(.headline)
                Spacer()
                Circle()
                    .fill(motionManager.isActive ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
            }

            VStack(spacing: 10) {
                AxisRow(axis: "X", value: motionManager.acceleration.x, color: .red)
                AxisRow(axis: "Y", value: motionManager.acceleration.y, color: .green)
                AxisRow(axis: "Z", value: motionManager.acceleration.z, color: .blue)
            }

            HStack(spacing: 12) {
                Button(motionManager.isActive ? "Stop" : "Start") {
                    if motionManager.isActive { motionManager.stop() } else { motionManager.start() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Tilt Ball Card

    private var tiltBallCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Tilt to Move", systemImage: "circle.circle").font(.headline)
                Spacer()
            }

            GeometryReader { geo in
                let maxOffset = geo.size.width * 0.35
                let dx = CGFloat(motionManager.acceleration.x) * maxOffset
                let dy = CGFloat(-motionManager.acceleration.y) * maxOffset

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))

                    // Grid lines
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        let cy = size.height / 2
                        var h = Path(); h.move(to: .init(x: 0, y: cy)); h.addLine(to: .init(x: size.width, y: cy))
                        var v = Path(); v.move(to: .init(x: cx, y: 0)); v.addLine(to: .init(x: cx, y: size.height))
                        ctx.stroke(h, with: .color(.secondary.opacity(0.2)), lineWidth: 1)
                        ctx.stroke(v, with: .color(.secondary.opacity(0.2)), lineWidth: 1)
                    }

                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                        .shadow(color: .blue.opacity(0.4), radius: 8)
                        .offset(x: dx, y: dy)
                        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.7), value: motionManager.acceleration.x)
                }
            }
            .frame(height: 180)

            Text("Tilt your device to move the ball. Uses CMAcceleration X/Y axes.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Gyro Card

    private var gyroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Gyroscope (°/s)", systemImage: "gyroscope").font(.headline)
                Spacer()
            }

            VStack(spacing: 10) {
                AxisRow(axis: "Pitch", value: motionManager.rotation.x, color: .orange)
                AxisRow(axis: "Roll",  value: motionManager.rotation.y, color: .purple)
                AxisRow(axis: "Yaw",   value: motionManager.rotation.z, color: .teal)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Reference Card

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("API Notes", systemImage: "info.circle").font(.headline)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 6) {
                BulletRow("CMMotionManager is a shared resource — use one instance per app")
                BulletRow("Update intervals: 1/60s for smooth UI, 1/10s for light polling")
                BulletRow("Always stop updates in onDisappear to save battery")
                BulletRow("DeviceMotion (gravity-corrected) is better than raw accelerometer for UI")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

private struct AxisRow: View {
    let axis: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(axis)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .frame(width: 44, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.15)).frame(height: 8)
                    Capsule().fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat((value + 1) / 2)), height: 8)
                }
            }
            .frame(height: 8)
            Text(String(format: "%+.2f", value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52)
        }
    }
}

private struct BulletRow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(.secondary)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Motion Manager

@MainActor
class MotionManager: ObservableObject {
    private let manager = CMMotionManager()

    @Published var acceleration: CMAcceleration = .init(x: 0, y: 0, z: -1)
    @Published var rotation: CMRotationRate = .init(x: 0, y: 0, z: 0)
    @Published var isActive = false

    func start() {
        guard manager.isAccelerometerAvailable else {
            // Simulator: use static values
            acceleration = CMAcceleration(x: 0.12, y: -0.08, z: -0.99)
            return
        }
        manager.accelerometerUpdateInterval = 1.0 / 60
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            Task { @MainActor [weak self] in
                self?.acceleration = data.acceleration
            }
        }
        if manager.isGyroAvailable {
            manager.gyroUpdateInterval = 1.0 / 60
            manager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let data else { return }
                Task { @MainActor [weak self] in
                    self?.rotation = data.rotationRate
                }
            }
        }
        isActive = true
    }

    func stop() {
        manager.stopAccelerometerUpdates()
        manager.stopGyroUpdates()
        isActive = false
    }
}

#Preview {
    NavigationStack { AccelerometerView() }
}
