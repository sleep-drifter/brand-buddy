import SwiftUI
import CoreMotion
import Combine

// MARK: - Barometer View

struct BarometerView: View {
    @StateObject private var altimeter = AltimeterManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                #if targetEnvironment(simulator)
                simulatorBanner
                #endif
                altitudeCard
                pressureCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Barometer")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { altimeter.stop() }
    }

    private var simulatorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.slash").foregroundStyle(.orange)
            Text("Barometer requires a physical device. Showing simulated data.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Altitude Card

    private var altitudeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Relative Altitude", systemImage: "mountain.2").font(.headline)
                Spacer()
                Circle()
                    .fill(altimeter.isRunning ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
            }

            // Big altitude number
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(altimeter.formattedAltitude)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                Text("m")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)

            // Trend arrow
            HStack(spacing: 6) {
                Image(systemName: altimeter.trendIcon)
                    .foregroundStyle(altimeter.trendColor)
                Text(altimeter.trendLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 12) {
                Button(altimeter.isRunning ? "Stop" : "Start") {
                    if altimeter.isRunning { altimeter.stop() } else { altimeter.start() }
                }
                .buttonStyle(.borderedProminent)
                .tint(altimeter.isRunning ? .red : .blue)

                if altimeter.isRunning {
                    Button("Reset Baseline") { altimeter.reset() }
                        .buttonStyle(.bordered)
                }
            }
            .animation(.spring(response: 0.3), value: altimeter.isRunning)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Pressure Card

    private var pressureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pressure", systemImage: "gauge").font(.headline)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Absolute").font(.caption).foregroundStyle(.tertiary)
                    Text(altimeter.formattedPressure)
                        .font(.title3.monospacedDigit())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Unit").font(.caption).foregroundStyle(.tertiary)
                    Text("kPa").font(.title3)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
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
                BulletRow("CMAltimeter measures relative change from start, not absolute elevation")
                BulletRow("Check CMAltimeter.isRelativeAltitudeAvailable() before starting")
                BulletRow("Data arrives on a background queue — dispatch to main for UI updates")
                BulletRow("Altitude precision: ~0.1–0.5 m indoors, better outdoors")
                BulletRow("Available on iPhone 6 and later with a barometric pressure sensor")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

// MARK: - Altimeter Manager

@MainActor
class AltimeterManager: ObservableObject {
    private let altimeter = CMAltimeter()
    @Published var relativeAltitude: Double = 0
    @Published var pressure: Double = 101.3
    @Published var isRunning = false

    var formattedAltitude: String {
        String(format: "%+.1f", relativeAltitude)
    }

    var formattedPressure: String {
        String(format: "%.2f", pressure)
    }

    var trendIcon: String {
        if relativeAltitude > 0.5 { return "arrow.up" }
        if relativeAltitude < -0.5 { return "arrow.down" }
        return "minus"
    }

    var trendColor: Color {
        if relativeAltitude > 0.5 { return .blue }
        if relativeAltitude < -0.5 { return .orange }
        return .secondary
    }

    var trendLabel: String {
        if relativeAltitude > 0.5 { return "Moving up" }
        if relativeAltitude < -0.5 { return "Moving down" }
        return "Stable"
    }

    func start() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            // Simulator: simulate slowly rising altitude
            isRunning = true
            simulateAltitude()
            return
        }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            Task { @MainActor [weak self] in
                self?.relativeAltitude = data.relativeAltitude.doubleValue
                self?.pressure = data.pressure.doubleValue
            }
        }
        isRunning = true
    }

    func stop() {
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
    }

    func reset() {
        stop()
        relativeAltitude = 0
        start()
    }

    private func simulateAltitude() {
        Task {
            var t: Double = 0
            while isRunning {
                try? await Task.sleep(nanoseconds: 500_000_000)
                t += 0.5
                relativeAltitude = sin(t * 0.3) * 3.0
                pressure = 101.3 - relativeAltitude * 0.012
            }
        }
    }
}

#Preview {
    NavigationStack { BarometerView() }
}
