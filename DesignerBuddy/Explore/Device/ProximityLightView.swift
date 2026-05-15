import SwiftUI
import UIKit

// MARK: - Proximity & Ambient Light View

struct ProximityLightView: View {
    @StateObject private var proximityMonitor = ProximityMonitor()
    @State private var screenBrightness: Double = Double(UIScreen.main.brightness)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                proximityCard
                brightnessCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Proximity & Ambient Light")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { proximityMonitor.start() }
        .onDisappear { proximityMonitor.stop() }
    }

    // MARK: Proximity Card

    private var proximityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Proximity Sensor", systemImage: "sensor.tag.radiowaves.forward").font(.headline)
                Spacer()
            }

            // Visual indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(proximityMonitor.isNear ? Color.black : Color(.secondarySystemBackground))
                    .animation(.easeInOut(duration: 0.2), value: proximityMonitor.isNear)

                VStack(spacing: 8) {
                    Image(systemName: proximityMonitor.isNear ? "iphone.homebutton.radiowaves.left.and.right" : "iphone")
                        .font(.system(size: 40))
                        .foregroundStyle(proximityMonitor.isNear ? .white : .secondary)
                    Text(proximityMonitor.isNear ? "Near" : "Far")
                        .font(.headline)
                        .foregroundStyle(proximityMonitor.isNear ? .white : .secondary)
                }
            }
            .frame(height: 120)

            Toggle("Enable Proximity Monitoring", isOn: $proximityMonitor.monitoringEnabled)
                .onChange(of: proximityMonitor.monitoringEnabled) { _, enabled in
                    if enabled { proximityMonitor.start() } else { proximityMonitor.stop() }
                }

            HStack {
                Image(systemName: "info.circle").foregroundStyle(.secondary).font(.caption)
                Text("Cover the top front sensor to trigger. Device-only — sensor isn't simulated.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Brightness Card

    private var brightnessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Screen Brightness", systemImage: "sun.max").font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", screenBrightness * 100))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "sun.min").foregroundStyle(.secondary)
                Slider(value: $screenBrightness, in: 0.01...1.0) { _ in
                    UIScreen.main.brightness = screenBrightness
                }
                Image(systemName: "sun.max").foregroundStyle(.secondary)
            }

            Button("Reset to System Default") {
                // Can't read system's preferred brightness, but 0.5 is a safe reset
                screenBrightness = 0.5
                UIScreen.main.brightness = 0.5
            }
            .font(.subheadline)
            .foregroundStyle(.blue)

            Text("UIScreen.main.brightness accepts 0.0–1.0. Changes persist until the user adjusts Control Center. Use sparingly.")
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
                RefRow(api: "UIDevice.current.isProximityMonitoringEnabled", detail: "Must set true to enable the sensor")
                Divider()
                RefRow(api: ".proximityStateDidChangeNotification", detail: "Posted when near/far state changes")
                Divider()
                RefRow(api: "UIDevice.current.proximityState", detail: "Bool — true when object is near")
                Divider()
                RefRow(api: "UIScreen.main.brightness", detail: "Read or write current display brightness")
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

// MARK: - Proximity Monitor

@MainActor
class ProximityMonitor: ObservableObject {
    @Published var isNear = false
    @Published var monitoringEnabled = false

    private var notificationToken: NSObjectProtocol?

    func start() {
        UIDevice.current.isProximityMonitoringEnabled = true
        monitoringEnabled = true
        notificationToken = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isNear = UIDevice.current.proximityState
            }
        }
    }

    func stop() {
        UIDevice.current.isProximityMonitoringEnabled = false
        monitoringEnabled = false
        if let token = notificationToken {
            NotificationCenter.default.removeObserver(token)
            notificationToken = nil
        }
    }
}

#Preview {
    NavigationStack { ProximityLightView() }
}
