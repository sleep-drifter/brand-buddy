import Combine
import SwiftUI

@MainActor
final class PinsStore: ObservableObject {
    @AppStorage("pinnedItemKeys") private var data: Data = Data()
    // One-time QA seed: force today's new/updated playgrounds into Saved.
    @AppStorage("didSeedQAPins_2026_07_07") private var didSeedQAPins = false
    // Second wave, seeded separately so installs that already ran wave 1 still get it.
    @AppStorage("didSeedQAPins_2026_07_07_wave2") private var didSeedQAPinsWave2 = false
    @AppStorage("didSeedQAPins_2026_07_07_wave3") private var didSeedQAPinsWave3 = false
    @AppStorage("didSeedQAPins_2026_07_25") private var didSeedQAPinsWave4 = false
    @AppStorage("didSeedQAPins_2026_07_25_wave2") private var didSeedQAPinsWave5 = false
    @AppStorage("didSeedQAPins_2026_07_26_lazy") private var didSeedQAPinsWave7 = false
    @AppStorage("didSeedQAPins_2026_07_26_anatomy") private var didSeedQAPinsWave8 = false
    @AppStorage("didSeedQAPins_2026_07_27_softbody") private var didSeedQAPinsWave9 = false

    /// Pages added or modified today — pinned once for QA. All live in the
    /// "Playgrounds" tab, so keys are "Playgrounds:<name>".
    private static let qaPinNames = [
        "Fluid Gradient", "Random Metaball 2D",
        "Circle SDF 1", "Circle SDF 2", "Smooth Min 2D",
        "Implicit Equation", "Flow Distortion", "Lissajous Curve",
        "Radial Layout", "Flow Layout", "Physics Tag", "Stable Fluid",
        "Shaders",
    ]

    private static let qaPinNamesWave2 = [
        "Liquid Wallet",
    ]

    private static let qaPinNamesWave3 = [
        "Liquid Carousel",
    ]

    private static let qaPinNamesWave4 = [
        "Glass Morph",
    ]

    private static let qaPinNamesWave5 = [
        "Sheet Detent Morph",
        "Tab Mini Player",
        "Toolbar Condense",
    ]

    init() {
        seedQAPinsIfNeeded()
    }

    var pinnedKeys: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? [] }
        set {
            objectWillChange.send()
            data = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Runs once (per install) to drop today's pages into Saved for QA. Guarded by
    /// a flag so it won't re-pin items the user later removes.
    private func seedQAPinsIfNeeded() {
        if !didSeedQAPins {
            var keys = pinnedKeys
            keys.formUnion(Self.qaPinNames.map { "Playgrounds:\($0)" })
            pinnedKeys = keys
            didSeedQAPins = true
        }
        if !didSeedQAPinsWave2 {
            var keys = pinnedKeys
            keys.formUnion(Self.qaPinNamesWave2.map { "Playgrounds:\($0)" })
            pinnedKeys = keys
            didSeedQAPinsWave2 = true
        }
        if !didSeedQAPinsWave3 {
            var keys = pinnedKeys
            keys.formUnion(Self.qaPinNamesWave3.map { "Playgrounds:\($0)" })
            pinnedKeys = keys
            didSeedQAPinsWave3 = true
        }
        if !didSeedQAPinsWave4 {
            var keys = pinnedKeys
            keys.formUnion(Self.qaPinNamesWave4.map { "Playgrounds:\($0)" })
            pinnedKeys = keys
            didSeedQAPinsWave4 = true
        }
        if !didSeedQAPinsWave5 {
            var keys = pinnedKeys
            keys.formUnion(Self.qaPinNamesWave5.map { "Playgrounds:\($0)" })
            pinnedKeys = keys
            didSeedQAPinsWave5 = true
        }
        // Lazy Stacks lives in the Elements tab, so its pin key uses that prefix.
        if !didSeedQAPinsWave7 {
            var keys = pinnedKeys
            keys.insert("Elements:Lazy Stacks")
            pinnedKeys = keys
            didSeedQAPinsWave7 = true
        }
        if !didSeedQAPinsWave8 {
            var keys = pinnedKeys
            keys.insert("Patterns & System:Live Activity Anatomy")
            pinnedKeys = keys
            didSeedQAPinsWave8 = true
        }
        if !didSeedQAPinsWave9 {
            var keys = pinnedKeys
            keys.insert("Playgrounds:Soft Body")
            pinnedKeys = keys
            didSeedQAPinsWave9 = true
        }
    }

    func isPinned(_ entry: AppEntry) -> Bool {
        pinnedKeys.contains(entry.pinKey)
    }

    func toggle(_ entry: AppEntry) {
        var keys = pinnedKeys
        if keys.contains(entry.pinKey) { keys.remove(entry.pinKey) }
        else { keys.insert(entry.pinKey) }
        pinnedKeys = keys
    }
}
