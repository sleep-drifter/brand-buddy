import SwiftUI
import UIKit

// MARK: - Battery State View

struct BatteryStateView: View {
    @StateObject private var batteryMonitor = BatteryMonitor()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                batteryGaugeCard
                stateCard
                lowPowerCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Battery State")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { batteryMonitor.startMonitoring() }
        .onDisappear { batteryMonitor.stopMonitoring() }
    }

    // MARK: Battery Gauge Card

    private var batteryGaugeCard: some View {
        VStack(spacing: 20) {
            HStack {
                Label("Battery Level", systemImage: "battery.100").font(.headline)
                Spacer()
            }

            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.1, to: 0.9)
                    .stroke(Color(.quaternarySystemFill), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(90))

                // Filled arc
                Circle()
                    .trim(from: 0.1, to: 0.1 + 0.8 * CGFloat(max(0, batteryMonitor.level)))
                    .stroke(batteryMonitor.gaugeColor,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .animation(.spring(response: 0.6), value: batteryMonitor.level)

                VStack(spacing: 4) {
                    Text(batteryMonitor.levelText)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(batteryMonitor.stateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: State Card

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Battery State", systemImage: "bolt.fill").font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(BatteryMonitor.StateDisplay.allCases, id: \.self) { state in
                    VStack(spacing: 6) {
                        Image(systemName: state.icon)
                            .font(.title3)
                            .foregroundStyle(batteryMonitor.currentStateDisplay == state ? state.color : .secondary)
                        Text(state.label)
                            .font(.caption2)
                            .foregroundStyle(batteryMonitor.currentStateDisplay == state ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        batteryMonitor.currentStateDisplay == state
                        ? state.color.opacity(0.12)
                        : Color(.tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(batteryMonitor.currentStateDisplay == state ? state.color.opacity(0.4) : .clear)
                    )
                }
            }
            .animation(.spring(response: 0.3), value: batteryMonitor.currentStateDisplay)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Low Power Card

    private var lowPowerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Low Power Mode", systemImage: "bolt.slash").font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: batteryMonitor.isLowPowerMode ? "bolt.slash.fill" : "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(batteryMonitor.isLowPowerMode ? .yellow : .green)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(batteryMonitor.isLowPowerMode ? "Low Power Mode is ON" : "Low Power Mode is OFF")
                        .font(.subheadline).fontWeight(.medium)
                    Text(batteryMonitor.isLowPowerMode
                         ? "Reduce background activity, animations, and network tasks."
                         : "Full performance available.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(batteryMonitor.isLowPowerMode ? Color.yellow.opacity(0.1) : Color(.tertiarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10))
            .animation(.spring(response: 0.3), value: batteryMonitor.isLowPowerMode)

            Text("Observe NSProcessInfoPowerStateDidChange to react when the user toggles Low Power Mode in Settings.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Reference Card

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("API Reference", systemImage: "doc.text").font(.headline)
                Spacer()
            }
            VStack(spacing: 8) {
                RefRow(api: "UIDevice.current.isBatteryMonitoringEnabled", detail: "Must set true to read battery info")
                Divider()
                RefRow(api: ".batteryLevel", detail: "Float 0–1, or -1 if unknown. Updates ~1%/step.")
                Divider()
                RefRow(api: ".batteryState", detail: ".unknown / .unplugged / .charging / .full")
                Divider()
                RefRow(api: "ProcessInfo.isLowPowerModeEnabled", detail: "Bool — read anytime, no activation needed")
                Divider()
                RefRow(api: ".NSProcessInfoPowerStateDidChange", detail: "Notification for low power mode changes")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RefRow: View {
    let api: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(api).font(.caption.monospaced()).foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Battery Monitor

@MainActor
class BatteryMonitor: ObservableObject {
    @Published var level: Float = -1
    @Published var state: UIDevice.BatteryState = .unknown
    @Published var isLowPowerMode: Bool = false

    private var tokens: [NSObjectProtocol] = []

    enum StateDisplay: CaseIterable {
        case unplugged, charging, full, unknown

        var label: String {
            switch self {
            case .unplugged: return "Unplugged"
            case .charging:  return "Charging"
            case .full:      return "Full"
            case .unknown:   return "Unknown"
            }
        }
        var icon: String {
            switch self {
            case .unplugged: return "battery.75percent"
            case .charging:  return "battery.100percent.bolt"
            case .full:      return "battery.100percent"
            case .unknown:   return "questionmark.circle"
            }
        }
        var color: Color {
            switch self {
            case .unplugged: return .primary
            case .charging:  return .green
            case .full:      return .blue
            case .unknown:   return .secondary
            }
        }
    }

    var currentStateDisplay: StateDisplay {
        switch state {
        case .unplugged: return .unplugged
        case .charging:  return .charging
        case .full:      return .full
        default:         return .unknown
        }
    }

    var levelText: String {
        level < 0 ? "--" : "\(Int(level * 100))%"
    }

    var stateText: String { currentStateDisplay.label }

    var gaugeColor: Color {
        guard level >= 0 else { return .secondary }
        if level < 0.2 { return .red }
        if level < 0.4 { return .orange }
        return .green
    }

    func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        level = UIDevice.current.batteryLevel
        state = UIDevice.current.batteryState
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        tokens.append(NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.level = UIDevice.current.batteryLevel }
        })
        tokens.append(NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.state = UIDevice.current.batteryState }
        })
        tokens.append(NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        })
    }

    func stopMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = false
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens.removeAll()
    }
}

#Preview {
    NavigationStack { BatteryStateView() }
}
