import CoreHaptics
import Combine

@MainActor
class HapticStudioEngine: ObservableObject {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    @Published var isPlaying = false
    @Published var supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    func start() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = false
            engine?.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.isPlaying = false
                    // Restart immediately so the engine is always ready to fire
                    try? self?.engine?.start()
                }
            }
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {}
    }

    func stop() {
        player = nil
        engine?.stop()
        isPlaying = false
    }

    func play(pattern: HapticPattern) {
        guard let engine, supportsHaptics else { return }
        do {
            let events  = pattern.events.map { $0.toCHHapticEvent() }
            let curves  = pattern.curves
                .filter { !$0.controlPoints.isEmpty }
                .map    { $0.toCHParameterCurve() }

            let chPattern = try CHHapticPattern(events: events, parameterCurves: curves)
            player = try engine.makeAdvancedPlayer(with: chPattern)
            player?.completionHandler = { [weak self] _ in
                Task { @MainActor in self?.isPlaying = false }
            }
            try player?.start(atTime: CHHapticTimeImmediate)
            isPlaying = true
        } catch {}
    }

    func stopPlayback() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        isPlaying = false
    }

    // Send a single-shot preview for one event (for tap-to-preview in inspector)
    func preview(event: HapticStudioEvent) {
        guard let engine, supportsHaptics else { return }
        do {
            // Restart engine if it stopped — start() is a no-op when already running
            try engine.start()
            let chPattern = try CHHapticPattern(events: [event.toCHHapticEvent()], parameters: [])
            let p = try engine.makeAdvancedPlayer(with: chPattern)
            try p.start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
