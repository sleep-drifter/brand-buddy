import SwiftUI
import CoreHaptics
import Combine

// MARK: - Custom Haptics View

struct CustomHapticsView: View {
    @StateObject private var hapticsEngine = HapticsEngine()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                #if targetEnvironment(simulator)
                simulatorBanner
                #endif
                transientCard
                continuousCard
                patternCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Custom Haptics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { hapticsEngine.start() }
        .onDisappear { hapticsEngine.stop() }
    }

    // MARK: Simulator Banner

    private var simulatorBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "iphone.slash").foregroundStyle(.orange)
            Text("Haptics require a physical device. The UI below shows the API — patterns won't play in Simulator.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Transient Card

    private var transientCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Transient", systemImage: "bolt").font(.headline)
                Spacer()
                Text("Point-in-time")
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                HapticsSliderRow(label: "Intensity", value: $hapticsEngine.transientIntensity)
                HapticsSliderRow(label: "Sharpness", value: $hapticsEngine.transientSharpness)
            }

            Button {
                hapticsEngine.playTransient()
            } label: {
                Label("Play Transient", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text("Transients feel like taps. High sharpness = crisp click. Low sharpness = thud.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Continuous Card

    private var continuousCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Continuous", systemImage: "waveform").font(.headline)
                Spacer()
                Text("Duration-based")
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                HapticsSliderRow(label: "Intensity", value: $hapticsEngine.continuousIntensity)
                HapticsSliderRow(label: "Sharpness", value: $hapticsEngine.continuousSharpness)
                HapticsSliderRow(label: "Duration (s)", value: $hapticsEngine.continuousDuration, range: 0.1...2.0)
            }

            Button {
                hapticsEngine.playContinuous()
            } label: {
                Label("Play Continuous", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Text("Continuous events sustain over time. Useful for loading states, drag feedback, or rumble effects.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Pattern Card

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Named Patterns", systemImage: "list.bullet.rectangle").font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(HapticsEngine.NamedPattern.allCases, id: \.self) { pattern in
                    Button {
                        hapticsEngine.playPattern(pattern)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pattern.title).font(.subheadline).fontWeight(.medium)
                                Text(pattern.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle").foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    if pattern != HapticsEngine.NamedPattern.allCases.last {
                        Divider()
                    }
                }
            }
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
                RefRow(type: "CHHapticEngine", detail: "The engine itself — create once, reuse")
                Divider()
                RefRow(type: "CHHapticEvent", detail: "Transient or continuous, with parameters")
                Divider()
                RefRow(type: "CHHapticPattern", detail: "Sequence of events at relative times")
                Divider()
                RefRow(type: "CHHapticPatternPlayer", detail: "Plays a pattern, can be paused/stopped")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

private struct HapticsSliderRow: View {
    let label: String
    @Binding var value: Float
    var range: ClosedRange<Float> = 0...1

    var body: some View {
        HStack {
            Text(label).font(.subheadline).frame(width: 110, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: "%.2f", value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36)
        }
    }
}

private struct RefRow: View {
    let type: String
    let detail: String
    var body: some View {
        HStack(alignment: .top) {
            Text(type).font(.caption.monospaced()).foregroundStyle(.blue).frame(width: 170, alignment: .leading)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Haptics Engine

@MainActor
class HapticsEngine: ObservableObject {
    private var engine: CHHapticEngine?

    @Published var transientIntensity: Float = 0.8
    @Published var transientSharpness: Float = 0.5
    @Published var continuousIntensity: Float = 0.6
    @Published var continuousSharpness: Float = 0.3
    @Published var continuousDuration: Float = 0.5

    enum NamedPattern: CaseIterable {
        case selection, impact, warning, success

        var title: String {
            switch self {
            case .selection: return "Selection"
            case .impact:    return "Impact"
            case .warning:   return "Warning"
            case .success:   return "Success"
            }
        }
        var description: String {
            switch self {
            case .selection: return "Light tap — for picker scrolls or list selection"
            case .impact:    return "Medium tap — for button presses"
            case .warning:   return "Two sharp taps — for destructive actions"
            case .success:   return "Soft rise + gentle end — for completion"
            }
        }
    }

    func start() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch { }
    }

    func stop() {
        engine?.stop()
    }

    func playTransient() {
        guard let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: transientIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: transientSharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        play(events: [event], in: engine)
    }

    func playContinuous() {
        guard let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: continuousIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: continuousSharpness)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness],
                                  relativeTime: 0, duration: TimeInterval(continuousDuration))
        play(events: [event], in: engine)
    }

    func playPattern(_ pattern: NamedPattern) {
        guard let engine else { return }
        var events: [CHHapticEvent] = []
        switch pattern {
        case .selection:
            events = [makeTransient(t: 0, i: 0.4, s: 0.8)]
        case .impact:
            events = [makeTransient(t: 0, i: 0.8, s: 0.5)]
        case .warning:
            events = [makeTransient(t: 0, i: 0.9, s: 0.9), makeTransient(t: 0.15, i: 0.7, s: 0.9)]
        case .success:
            events = [
                makeContinuous(t: 0, d: 0.1, i: 0.3, s: 0.1),
                makeTransient(t: 0.12, i: 0.5, s: 0.3),
            ]
        }
        play(events: events, in: engine)
    }

    private func makeTransient(t: TimeInterval, i: Float, s: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: s),
        ], relativeTime: t)
    }

    private func makeContinuous(t: TimeInterval, d: TimeInterval, i: Float, s: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: i),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: s),
        ], relativeTime: t, duration: d)
    }

    private func play(events: [CHHapticEvent], in engine: CHHapticEngine) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch { }
    }
}

#Preview {
    NavigationStack { CustomHapticsView() }
}
