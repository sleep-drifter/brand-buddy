// OscillaModel.swift — Oscilla Lab v0
//
// The data model and pure evaluation math for the Oscilla synth. A patch is
// an instrument: a stack of shader layers (engines) whose normalized params
// are played live by knobs (set), LFOs (add), and gates (envelope lerp).
// This file owns the vocabulary (patch / layer / target / knob / LFO / gate /
// pose) plus OscillaEval, the stateless per-frame resolver that turns a patch
// and its live performance state into final [layer][param] values for the
// renderer. No views, no shaders here — just Foundation math and a Codable
// color bridge for SwiftUI.

import SwiftUI

/// Engines are the shaders v0 uses, by stable id. Raw values are serialized.
enum OscillaEngine: String, Codable, CaseIterable {
    case chromaField      // chromaGradientArt (generative)
    case starNest         // shaderStarNest (generative)
    case domainWarp       // shaderDomainWarp (distortion)
    case water            // shaderWater (distortion)
    case circleWave       // shaderCircleWave (generative/additive)
    case metaballs        // randomMetaball2D (generative, composites over layers below)
    case grain            // shaderGrain (filter)
    case vignette         // shaderVignette (filter)

    /// Number of normalized 0–1 param slots this engine consumes.
    /// (Enums cannot have stored instance properties — this is computed.)
    var paramCount: Int {
        switch self {
        case .chromaField: 6
        case .starNest: 5
        case .domainWarp: 4
        case .water: 3
        case .circleWave: 5
        case .metaballs: 5
        case .grain: 2
        case .vignette: 2
        }
    }
}

struct OscillaLayer: Codable {
    var engine: OscillaEngine
    /// Normalized 0–1 base values, count == engine.paramCount. The renderer
    /// maps them to physical shader args.
    var base: [Float]
}

/// One (layer, param) destination with a normalized range.
/// Semantics differ by the source that owns the target:
///  - KNOB targets: from/to are the param values at knob = 0 / knob = 1.
///  - LFO targets: only the span (to - from) matters — it is the peak-to-peak
///    swing at depth 1, centered on the param's current post-knob value.
///  - GATE targets: only .to is read — the envelope lerps the param from its
///    CURRENT value toward .to (.from is unused for gates).
///
/// Data rule: no two knobs in one patch may target the same (layer, param) —
/// knob targets SET in knob order, so a shared destination is order-dependent
/// (last knob wins). LFOs and gates may share targets freely.
struct ParamTarget: Codable {
    var layer: Int
    var param: Int
    var from: Float
    var to: Float
}

enum KnobCurve: String, Codable { case linear, expo }   // expo: t*t, applied to the knob value before the from→to lerp (nowhere else)
extension KnobCurve: CaseIterable {}

struct OscillaKnobSpec: Codable {
    var label: String          // "Weather", "Depth" — the patch's language
    var curve: KnobCurve
    var targets: [ParamTarget]
    var defaultValue: Float    // 0–1
}

enum LFOShape: String, Codable { case sine, triangle }
extension LFOShape: CaseIterable {}

struct OscillaLFO: Codable {
    var shape: LFOShape
    var period: Double         // seconds per cycle
    var depth: Float           // 0–1, scales target spans
    var targets: [ParamTarget] // only (to - from) matters: peak-to-peak span at depth 1, swing centered on current post-knob value
}

struct OscillaGate: Codable {
    var label: String          // "Drop", "Pulse"
    var attack: Double         // seconds, linear rise
    var release: Double        // seconds, exponential fall
    var targets: [ParamTarget] // envelope lerps param from its CURRENT value toward .to; .from unused
    var hapticIntensity: Float // 0 disables haptic
}

/// A pose is stored in KNOB space (values per knob, same order as knobs) —
/// morphs therefore always stay inside the patch's fences.
struct OscillaPose: Codable {
    var name: String
    var knobValues: [Float]
}

struct OscillaPatch: Codable, Identifiable {
    var id: String             // "drift", stable
    var name: String
    var subtitle: String       // one poetic line for the chip
    var tint: ColorSpec        // accent for UI chrome
    var layers: [OscillaLayer]
    var knobs: [OscillaKnobSpec]
    var lfos: [OscillaLFO]
    var gates: [OscillaGate]
    var poses: [OscillaPose]   // exactly 4 in v0
    var renderScale: CGFloat   // stored but UNUSED in v0 (reserved for thermal tuning)
}

/// Codable color (SwiftUI.Color isn't Codable).
struct ColorSpec: Codable {
    var r: Double; var g: Double; var b: Double
    var color: Color { Color(red: r, green: g, blue: b) }
}

// MARK: - Live performance state (not Codable; owned by the view as @State)

struct OscillaPerformance {
    var knobs: [Float]                    // current knob values 0–1
    var morph: Morph?                     // active pose morph
    /// Per gate: last fire time + the envelope value AT that instant
    /// (so retriggers are click-free). (.distantPast, 0) when never fired.
    var gateFires: [(fired: Date, level: Float)]
    var activePose: Int?                  // highlight only

    struct Morph {
        var from: [Float]
        var to: [Float]
        var start: Date
        var duration: Double = 1.6        // explicit default — the lab constructs without it
    }

    init(patch: OscillaPatch) {
        knobs = patch.knobs.map(\.defaultValue)
        morph = nil
        gateFires = Array(repeating: (fired: Date.distantPast, level: 0),
                          count: patch.gates.count)
        activePose = nil
    }
}

// MARK: - Pure evaluation (stateless; called per frame from TimelineView)

enum OscillaEval {
    /// Eased (smoothstep) pose morph applied over base knobs.
    /// Base is perf.knobs; an active morph interpolates morph.from → morph.to
    /// over morph.duration with smoothstep easing, clamped at both ends
    /// (at/past the end this returns morph.to exactly).
    static func knobValues(perf: OscillaPerformance, at now: Date) -> [Float] {
        guard let morph = perf.morph else { return perf.knobs }
        let t = now.timeIntervalSince(morph.start)
        if t <= 0 { return morph.from }
        if t >= morph.duration { return morph.to }
        let progress = Float(t / morph.duration)
        let eased = progress * progress * (3 - 2 * progress)
        var values = perf.knobs
        for i in values.indices {
            guard i < morph.from.count, i < morph.to.count else { continue }
            values[i] = morph.from[i] + (morph.to[i] - morph.from[i]) * eased
        }
        return values
    }

    /// Click-free retriggerable envelope. For t = now.timeIntervalSince(fired):
    ///   t < attack:  lerp(level, 1, Float(t / attack))          // rises from the level at fire time
    ///   else:        exp(-log(20) * Float((t - attack) / release))  // ≈0.05 at t = attack + release
    /// Values below 0.005 are treated as 0. env(0) = level (continuity on
    /// retrigger); both branches equal 1 at t = attack. Pure function of time.
    /// A never-fired gate (fired == .distantPast) is explicitly 0.
    static func gateEnvelope(_ gate: OscillaGate, fired: Date, level: Float, now: Date) -> Float {
        if fired == .distantPast { return 0 }
        let t = now.timeIntervalSince(fired)
        let value: Float
        if t < gate.attack {
            let riseProgress = Float(t / gate.attack)
            value = level + (1 - level) * riseProgress
        } else {
            let fallTime = Float((t - gate.attack) / gate.release)
            value = exp(-log(Float(20)) * fallTime)
        }
        return value < 0.005 ? 0 : value
    }

    /// LFO value in -1…1 for a given elapsed time.
    ///   sine:     sin(2π · elapsed / period)
    ///   triangle: 4·|frac(elapsed / period) - 0.5| - 1
    static func lfoValue(_ lfo: OscillaLFO, elapsed: Double) -> Float {
        guard lfo.period > 0 else { return 0 }
        switch lfo.shape {
        case .sine:
            let phase = 2 * Double.pi * elapsed / lfo.period
            return Float(sin(phase))
        case .triangle:
            let cycles = elapsed / lfo.period
            let frac = cycles - floor(cycles)
            return Float(4 * abs(frac - 0.5) - 1)
        }
    }

    /// THE resolver: final normalized params for every layer.
    /// Order of application: knob targets set values (lerp from→to by curved
    /// knob), then LFO targets ADD depth * lfoValue * (to - from) / 2 centered
    /// on the current post-knob value, then gate targets lerp current→.to by
    /// envelope (reading (fired, level) tuples from perf.gateFires). Clamped 0…1.
    /// Index-safe: any target whose (layer, param) is out of range is ignored.
    static func layerParams(
        patch: OscillaPatch,
        perf: OscillaPerformance,
        elapsed: Double,          // seconds since page start (Float-safe source)
        now: Date
    ) -> [[Float]]                // [layerIndex][paramIndex]
    {
        var params = patch.layers.map(\.base)
        let knobs = knobValues(perf: perf, at: now)

        // 1. Knob targets SET: lerp from→to by the curve-applied knob value.
        for (knobIndex, spec) in patch.knobs.enumerated() {
            guard knobIndex < knobs.count else { continue }
            let curved = curvedValue(spec.curve, knobs[knobIndex])
            for target in spec.targets {
                guard targetInRange(target, of: params) else { continue }
                params[target.layer][target.param] =
                    target.from + (target.to - target.from) * curved
            }
        }

        // 2. LFO targets ADD: depth · lfo · (to - from) / 2, centered on the
        //    current post-knob value.
        for lfo in patch.lfos {
            let value = lfoValue(lfo, elapsed: elapsed)
            for target in lfo.targets {
                guard targetInRange(target, of: params) else { continue }
                params[target.layer][target.param] +=
                    lfo.depth * value * (target.to - target.from) / 2
            }
        }

        // 3. Gate targets lerp current → .to by envelope.
        for (gateIndex, gate) in patch.gates.enumerated() {
            guard gateIndex < perf.gateFires.count else { continue }
            let fire = perf.gateFires[gateIndex]
            let envelope = gateEnvelope(gate, fired: fire.fired, level: fire.level, now: now)
            guard envelope > 0 else { continue }
            for target in gate.targets {
                guard targetInRange(target, of: params) else { continue }
                let current = params[target.layer][target.param]
                params[target.layer][target.param] =
                    current + (target.to - current) * envelope
            }
        }

        // 4. Clamp 0…1.
        for layerIndex in params.indices {
            for paramIndex in params[layerIndex].indices {
                params[layerIndex][paramIndex] =
                    min(max(params[layerIndex][paramIndex], 0), 1)
            }
        }
        return params
    }

    /// Modulation magnitude 0…1 on a knob, for the orbit UI. SOURCE space and
    /// time-invariant for LFOs (the moon's radius must not pulse):
    ///   clamp( Σ lfo.depth over LFOs sharing any (layer,param) with the
    ///          knob's targets
    ///        + Σ gateEnvelope(gate, fired:, level:, now:) over gates sharing
    ///          any (layer,param), 0, 1 )
    static func modulationAmount(onKnob knobIndex: Int, patch: OscillaPatch,
                                 perf: OscillaPerformance, elapsed: Double,
                                 now: Date) -> Float {
        guard knobIndex >= 0, knobIndex < patch.knobs.count else { return 0 }
        let knobTargets = patch.knobs[knobIndex].targets
        var total: Float = 0
        for lfo in patch.lfos where sharesAnyTarget(lfo.targets, knobTargets) {
            total += lfo.depth
        }
        for (gateIndex, gate) in patch.gates.enumerated() {
            guard gateIndex < perf.gateFires.count else { continue }
            guard sharesAnyTarget(gate.targets, knobTargets) else { continue }
            let fire = perf.gateFires[gateIndex]
            total += gateEnvelope(gate, fired: fire.fired, level: fire.level, now: now)
        }
        return min(max(total, 0), 1)
    }

    // MARK: Private helpers

    /// Knob response curve, applied to the raw knob value before the
    /// from→to lerp (nowhere else).
    private static func curvedValue(_ curve: KnobCurve, _ value: Float) -> Float {
        switch curve {
        case .linear:
            return value
        case .expo:
            return value * value
        }
    }

    /// Defensive bounds check: a target addressing a (layer, param) outside
    /// the resolved param grid is ignored rather than crashing.
    private static func targetInRange(_ target: ParamTarget, of params: [[Float]]) -> Bool {
        guard target.layer >= 0, target.layer < params.count else { return false }
        guard target.param >= 0, target.param < params[target.layer].count else { return false }
        return true
    }

    /// True when any (layer, param) pair appears in both target lists.
    private static func sharesAnyTarget(_ lhs: [ParamTarget], _ rhs: [ParamTarget]) -> Bool {
        for a in lhs {
            for b in rhs where a.layer == b.layer && a.param == b.param {
                return true
            }
        }
        return false
    }
}
