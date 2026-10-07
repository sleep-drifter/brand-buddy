// OscillaFactoryPatches.swift — Oscilla Lab v0
//
// The three factory patches: the instruments that ship with the synth.
// Each patch authors a layer stack (engines with normalized 0–1 base params),
// three macro knobs in the patch's own language, one LFO, one gate, and four
// poses (stored in knob space, so morphs always stay inside the fences).
// Pure static data — no views, no shaders, no state. OscillaLabView reads
// OscillaFactory.all; OscillaEval resolves these targets per frame.
//
// NOTE: Engines diverge from OSCILLA.md's factory table ON PURPOSE —
// Seascape/Protean Clouds are CC BY-NC-SA (non-commercial) and heavy
// raymarchers; chromaField + water are in-house/MIT and cheap. Do not
// substitute them back.
//
// Param index legend (mirrors the shipped ShadersPlaygroundView mappings):
//   chromaField: 0 speed, 1 grain, 2 zoom, 3 saturation, 4 softness, 5 warp
//   starNest:    0 speed, 1 zoom, 2 formula, 3 brightness, 4 saturation
//   domainWarp:  0 strength, 1 scale, 2 depth (octaves), 3 speed
//   water:       0 speed, 1 strength, 2 frequency
//   circleWave:  0 brightness, 1 speed, 2 strength, 3 density, 4 hue
//   grain:       0 intensity, 1 size
//   vignette:    0 radius, 1 softness

import SwiftUI

enum OscillaFactory {

    // MARK: - Drift (chromaField + grain)
    //
    // Warm amber weather system: a slow chroma field under a film of grain.
    // Weather drives warp up while pulling softness down (sharper storms);
    // Warmth drives saturation; Tide drives speed. The LFO breathes the warp
    // (sharing chromaField warp with Weather, so its knob grows a moon).
    // "Bloom" swells saturation and zoom, then falls away over 2.2s.
    static let drift = OscillaPatch(
        id: "drift",
        name: "Drift",
        subtitle: "slow weather over warm glass",
        tint: ColorSpec(r: 1.0, g: 0.72, b: 0.35),
        layers: [
            // chromaField: speed, grain, zoom, saturation, softness, warp.
            // speed/saturation/softness/warp are knob-owned; zoom + grain rest at base.
            OscillaLayer(engine: .chromaField, base: [0.2, 0.12, 0.45, 0.55, 0.5, 0.4]),
            // grain: a quiet film — intensity low, size smallish.
            OscillaLayer(engine: .grain, base: [0.18, 0.3]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Weather",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 5, from: 0.15, to: 0.75),  // warp up
                    ParamTarget(layer: 0, param: 4, from: 0.7, to: 0.3),    // softness inverse
                ],
                defaultValue: 0.4
            ),
            OscillaKnobSpec(
                label: "Warmth",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.35, to: 0.8),   // saturation
                ],
                defaultValue: 0.5
            ),
            OscillaKnobSpec(
                label: "Tide",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 0, from: 0.05, to: 0.35),  // speed
                ],
                defaultValue: 0.45
            ),
        ],
        lfos: [
            // Shares chromaField warp (0, 5) with Weather → orbital moon.
            OscillaLFO(
                shape: .sine,
                period: 23,
                depth: 0.4,
                targets: [
                    ParamTarget(layer: 0, param: 5, from: 0.15, to: 0.75),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            OscillaGate(
                label: "Bloom",
                attack: 0.08,
                release: 2.2,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.55, to: 0.95),  // saturation swell
                    ParamTarget(layer: 0, param: 2, from: 0.45, to: 0.75),  // zoom push
                ],
                hapticIntensity: 0.5
            ),
        ],
        poses: [
            // Knob space: [Weather, Warmth, Tide].
            OscillaPose(name: "Dawn", knobValues: [0.25, 0.4, 0.2]),      // calm, pale, slow
            OscillaPose(name: "Noon", knobValues: [0.7, 0.9, 0.65]),      // churning, hot, quick
            OscillaPose(name: "Dusk", knobValues: [0.5, 0.65, 0.35]),     // mid-storm ember
            OscillaPose(name: "Night", knobValues: [0.1, 0.2, 0.08]),     // nearly still, cool
        ],
        renderScale: 1.0
    )

    // MARK: - Tidepool (chromaField + water + circleWave + grain)
    //
    // Deep teal pool: a slow indigo chroma bed refracted through water, with
    // a silent circleWave layer (base brightness 0, strength 0.2) that only
    // speaks when "Drop" is gated — a stone into the pool. Swell drives water
    // strength (shared with the 11s LFO, so Swell grows a moon); Current
    // drives both water speed and the chroma bed's drift; Depth desaturates
    // and softens the bed as you sink.
    static let tidepool = OscillaPatch(
        id: "tidepool",
        name: "Tidepool",
        subtitle: "a stone dropped into still water",
        tint: ColorSpec(r: 0.25, g: 0.78, b: 0.72),
        layers: [
            // chromaField fenced to deep teal/indigo: slow, low saturation, soft.
            OscillaLayer(engine: .chromaField, base: [0.1, 0.08, 0.4, 0.35, 0.65, 0.3]),
            // water: speed, strength, frequency.
            OscillaLayer(engine: .water, base: [0.3, 0.45, 0.4]),
            // circleWave: silent until gated — brightness 0 AND strength 0.2.
            OscillaLayer(engine: .circleWave, base: [0.0, 0.5, 0.2, 0.3, 0.5]),
            // grain: subtle.
            OscillaLayer(engine: .grain, base: [0.14, 0.3]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Swell",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 1, from: 0.2, to: 0.8),    // water strength
                ],
                defaultValue: 0.45
            ),
            OscillaKnobSpec(
                label: "Current",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 0, from: 0.1, to: 0.6),    // water speed
                    ParamTarget(layer: 0, param: 0, from: 0.05, to: 0.3),   // chroma speed
                ],
                defaultValue: 0.4
            ),
            OscillaKnobSpec(
                label: "Depth",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.5, to: 0.2),    // saturation fades down
                    ParamTarget(layer: 0, param: 4, from: 0.45, to: 0.8),   // softness blooms
                ],
                defaultValue: 0.35
            ),
        ],
        lfos: [
            // Shares water strength (1, 1) with Swell → orbital moon.
            OscillaLFO(
                shape: .sine,
                period: 11,
                depth: 0.3,
                targets: [
                    ParamTarget(layer: 1, param: 1, from: 0.2, to: 0.8),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            OscillaGate(
                label: "Drop",
                attack: 0.02,
                release: 1.6,
                targets: [
                    ParamTarget(layer: 2, param: 0, from: 0.0, to: 0.9),    // circleWave brightness
                    ParamTarget(layer: 2, param: 2, from: 0.2, to: 0.7),    // circleWave strength
                ],
                hapticIntensity: 0.8
            ),
        ],
        poses: [
            // Knob space: [Swell, Current, Depth].
            OscillaPose(name: "Shallows", knobValues: [0.3, 0.6, 0.08]),   // bright, busy, surface
            OscillaPose(name: "Ebb", knobValues: [0.15, 0.2, 0.4]),        // drained, slow, mid
            OscillaPose(name: "Surge", knobValues: [0.9, 0.8, 0.25]),      // heaving, fast
            OscillaPose(name: "Abyss", knobValues: [0.45, 0.1, 0.95]),     // slow swell, lightless
        ],
        renderScale: 1.0
    )

    // MARK: - Night Garden (starNest + domainWarp + vignette)
    //
    // Violet star field warped by wind, framed by a vignette. Depth dives
    // into the nest (expo curve — the first half of the travel is gentle);
    // Turbulence bends the field with domainWarp; Shimmer lifts brightness
    // and saturation together. The 31s triangle LFO breathes brightness
    // (shared with Shimmer, so its knob grows a moon). "Pulse" flares the
    // whole nest to full brightness and lets it fall over 1.2s.
    static let nightGarden = OscillaPatch(
        id: "nightGarden",
        name: "Night Garden",
        subtitle: "stars bending in a dark wind",
        tint: ColorSpec(r: 0.62, g: 0.48, b: 0.95),
        layers: [
            // starNest: speed, zoom, formula, brightness, saturation.
            // zoom/brightness/saturation are knob-owned; speed + formula rest at base.
            OscillaLayer(engine: .starNest, base: [0.25, 0.5, 0.5, 0.45, 0.6]),
            // domainWarp: strength + scale knob-owned; depth 0.3 → 1 octave (cheap),
            // speed mild.
            OscillaLayer(engine: .domainWarp, base: [0.2, 0.35, 0.3, 0.35]),
            // vignette: p0 0.4 → radius 1.0 (shipped default; scales ×2.5).
            OscillaLayer(engine: .vignette, base: [0.4, 0.45]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Depth",
                curve: .expo,
                targets: [
                    ParamTarget(layer: 0, param: 1, from: 0.15, to: 0.85),  // starNest zoom
                ],
                defaultValue: 0.5
            ),
            OscillaKnobSpec(
                label: "Turbulence",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 0, from: 0.0, to: 0.55),   // warp strength
                    ParamTarget(layer: 1, param: 1, from: 0.2, to: 0.6),    // warp scale
                ],
                defaultValue: 0.35
            ),
            OscillaKnobSpec(
                label: "Shimmer",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.25, to: 0.75),  // brightness
                    ParamTarget(layer: 0, param: 4, from: 0.3, to: 0.9),    // saturation
                ],
                defaultValue: 0.5
            ),
        ],
        lfos: [
            // Shares starNest brightness (0, 3) with Shimmer → orbital moon.
            OscillaLFO(
                shape: .triangle,
                period: 31,
                depth: 0.35,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.25, to: 0.75),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            OscillaGate(
                label: "Pulse",
                attack: 0.05,
                release: 1.2,
                targets: [
                    ParamTarget(layer: 0, param: 3, from: 0.45, to: 1.0),   // full flare
                ],
                hapticIntensity: 1.0
            ),
        ],
        poses: [
            // Knob space: [Depth, Turbulence, Shimmer].
            OscillaPose(name: "Meadow", knobValues: [0.3, 0.12, 0.6]),     // shallow, calm, bright
            OscillaPose(name: "Canopy", knobValues: [0.6, 0.6, 0.3]),      // deep, windblown, dim
            OscillaPose(name: "Clearing", knobValues: [0.45, 0.05, 0.85]), // still and radiant
            OscillaPose(name: "Deep Sky", knobValues: [0.95, 0.3, 0.45]),  // all the way down
        ],
        renderScale: 1.0
    )

    // MARK: - Catalog

    static let all: [OscillaPatch] = [drift, tidepool, nightGarden]
}
