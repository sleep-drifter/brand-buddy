// OscillaFactoryPatches.swift — Oscilla Lab v0
//
// The seven factory patches: the instruments that ship with the synth.
// Each patch authors a layer stack (engines with normalized 0–1 base params),
// three macro knobs in the patch's own language, one LFO, one or two gates,
// and four poses (stored in knob space, so morphs always stay inside the
// fences). Pure static data — no views, no shaders, no state. OscillaLabView
// reads OscillaFactory.all; OscillaEval resolves these targets per frame.
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
//   metaballs:   0 count, 1 size, 2 speed, 3 fusion, 4 hue
//   inkFluid:    0 flow, 1 brush, 2 fade, 3 swirl
//   kuwahara:    0 radius
//   colorGrade:  0 look, 1 amount
//   halftone:    0 cell, 1 angle, 2 ink
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

    // MARK: - Supercell (chromaField + domainWarp + circleWave + grain + vignette)
    //
    // Steel-blue storm cell — the performer's patch, fences wide ON PURPOSE.
    // A hard-edged desaturated chroma bed (softness LOW, warp HIGH: the
    // anti-Drift) bent by a full-range domainWarp. Pressure (expo) drives
    // warp strength through its full 0→120px travel and pushes the bed's warp
    // with it; Shear slides warp scale and depth together — depth crosses the
    // shipped 1↔2 octave cliff at knob 0.5, the deliberate "ugly in-between"
    // that makes morph routing the mastery; Updraft quickens the bed and the
    // warp. The 17s LFO breathes warp strength (shared with Pressure, so its
    // knob grows a moon). "Strike" is silent lightning: the tap-aimed
    // circleWave flares to full brightness and falls away in under a second.
    static let supercell = OscillaPatch(
        id: "supercell",
        name: "Supercell",
        subtitle: "the sky before it breaks",
        tint: ColorSpec(r: 0.55, g: 0.62, b: 0.72),
        layers: [
            // chromaField: hard-edged desaturated storm bed — softness LOW,
            // warp HIGH (the anti-Drift). speed + warp are knob-owned.
            OscillaLayer(engine: .chromaField, base: [0.3, 0.15, 0.55, 0.3, 0.25, 0.7]),
            // domainWarp: every entry is knob-owned — the dead data still
            // documents the resting sound at knob defaults.
            OscillaLayer(engine: .domainWarp, base: [0.64, 0.35, 0.35, 0.42]),
            // circleWave: silent lightning — brightness 0 until "Strike" fires,
            // tap-aimed.
            OscillaLayer(engine: .circleWave, base: [0.0, 0.6, 0.3, 0.1, 0.58]),
            // grain: coarser film than Drift's.
            OscillaLayer(engine: .grain, base: [0.25, 0.4]),
            // vignette: tight storm framing.
            OscillaLayer(engine: .vignette, base: [0.35, 0.5]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Pressure",
                curve: .expo,
                targets: [
                    ParamTarget(layer: 1, param: 0, from: 0.0, to: 1.0),    // warp strength, full 0→120px
                    ParamTarget(layer: 0, param: 5, from: 0.2, to: 1.0),    // bed warp follows
                ],
                defaultValue: 0.8
            ),
            OscillaKnobSpec(
                label: "Shear",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 1, from: 0.0, to: 1.0),    // warp scale
                    ParamTarget(layer: 1, param: 2, from: 0.0, to: 1.0),    // warp depth — crosses the 1↔2 octave cliff at knob 0.5
                ],
                defaultValue: 0.35
            ),
            OscillaKnobSpec(
                label: "Updraft",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 0, from: 0.05, to: 0.9),   // bed speed
                    ParamTarget(layer: 1, param: 3, from: 0.1, to: 0.9),    // warp speed
                ],
                defaultValue: 0.4
            ),
        ],
        lfos: [
            // Shares domainWarp strength (1, 0) with Pressure → orbital moon.
            OscillaLFO(
                shape: .sine,
                period: 17,
                depth: 0.5,
                targets: [
                    ParamTarget(layer: 1, param: 0, from: 0.0, to: 1.0),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            OscillaGate(
                label: "Strike",
                attack: 0.01,
                release: 0.9,
                targets: [
                    ParamTarget(layer: 2, param: 0, from: 0.0, to: 1.0),    // circleWave brightness
                    ParamTarget(layer: 2, param: 2, from: 0.3, to: 0.8),    // circleWave strength
                ],
                hapticIntensity: 1.0
            ),
        ],
        poses: [
            // Knob space: [Pressure, Shear, Updraft]. Wall and Anvil straddle
            // Shear = 0.5 with Pressure ≥ 0.75 on BOTH sides, so the morph
            // visibly pops the octave cliff at any LFO phase (expo knob² ≥
            // 0.56 keeps the worst-case trough ≥ ~37px of warp).
            OscillaPose(name: "Wall", knobValues: [0.85, 0.3, 0.55]),      // towering, pre-cliff
            OscillaPose(name: "Anvil", knobValues: [0.8, 0.75, 0.3]),      // spread flat, post-cliff
            OscillaPose(name: "Downdraft", knobValues: [0.45, 0.2, 0.1]),  // collapsing, near-still
            OscillaPose(name: "Green Sky", knobValues: [0.6, 0.55, 0.8]),  // eerie, racing updraft
        ],
        renderScale: 1.0
    )

    // MARK: - Swarm (chromaField + metaballs + grain + vignette)
    //
    // Firefly green: ten metaballs drifting over a near-black dim bed — the
    // machine plays itself; you conduct. Ball count is FIXED in base data
    // (the shader int-casts it; a modulated count pops). Cohesion fuses the
    // swarm (fusion only); Scatter trades speed against size (faster =
    // smaller); Glow warms the hue inside the green key and lifts the bed's
    // saturation. The 13s LFO breathes fusion (shared with Cohesion, so its
    // knob grows a moon). "Startle" un-fuses and shrinks the balls into small
    // individuals, then lets the swarm slowly re-gather over the 1.8s
    // release. Speed (p2) is NEVER gated or LFO'd — t = time*speed is
    // unwrapped, so a speed step teleports every ball by elapsed·Δspeed, and
    // the jump grows with session age. Knob-paced moves only.
    static let swarm = OscillaPatch(
        id: "swarm",
        name: "Swarm",
        subtitle: "a thousand small decisions",
        tint: ColorSpec(r: 0.55, g: 0.9, b: 0.45),
        layers: [
            // chromaField: near-black dim bed. saturation is knob-owned.
            OscillaLayer(engine: .chromaField, base: [0.05, 0.1, 0.4, 0.33, 0.7, 0.2]),
            // metaballs: count FIXED ≈10 balls (p0 0.6 → 1 + 0.6·15 = 10).
            // size/speed/fusion/hue are knob-owned — resting knob-default
            // values, so the dead data still documents the resting sound.
            OscillaLayer(engine: .metaballs, base: [0.6, 0.48, 0.4, 0.55, 0.35]),
            // grain: faint film.
            OscillaLayer(engine: .grain, base: [0.12, 0.3]),
            // vignette: soft dark frame.
            OscillaLayer(engine: .vignette, base: [0.4, 0.5]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Cohesion",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 3, from: 0.15, to: 0.95),  // fusion only
                ],
                defaultValue: 0.5
            ),
            OscillaKnobSpec(
                label: "Scatter",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 2, from: 0.1, to: 0.85),   // speed — KNOB-paced only (see MARK note)
                    ParamTarget(layer: 1, param: 1, from: 0.6, to: 0.3),    // size inverse: faster = smaller
                ],
                defaultValue: 0.4
            ),
            OscillaKnobSpec(
                label: "Glow",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 4, from: 0.22, to: 0.48),  // hue within the green key
                    ParamTarget(layer: 0, param: 3, from: 0.15, to: 0.5),   // bed saturation
                ],
                defaultValue: 0.5
            ),
        ],
        lfos: [
            // Shares metaballs fusion (1, 3) with Cohesion → orbital moon.
            OscillaLFO(
                shape: .sine,
                period: 13,
                depth: 0.3,
                targets: [
                    ParamTarget(layer: 1, param: 3, from: 0.15, to: 0.95),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            // NEVER gate p2 (speed): the phase jump scales with session age.
            OscillaGate(
                label: "Startle",
                attack: 0.02,
                release: 1.8,
                targets: [
                    ParamTarget(layer: 1, param: 3, from: 0.55, to: 0.1),   // un-fuse
                    ParamTarget(layer: 1, param: 1, from: 0.48, to: 0.2),   // shrink apart
                ],
                hapticIntensity: 1.0
            ),
        ],
        poses: [
            // Knob space: [Cohesion, Scatter, Glow].
            OscillaPose(name: "Murmur", knobValues: [0.7, 0.45, 0.35]),    // one coordinated body
            OscillaPose(name: "Lanterns", knobValues: [0.3, 0.1, 0.9]),    // slow, large, radiant
            OscillaPose(name: "Mist", knobValues: [0.95, 0.25, 0.15]),     // fused into a dim haze
            OscillaPose(name: "Frenzy", knobValues: [0.1, 0.9, 0.55]),     // shattered, quick, small
        ],
        renderScale: 1.0
    )

    // MARK: - Inkwell (inkFluid — stateful)
    //
    // Deep ink-blue sumi-e well: the stable-fluid sim IS the instrument. The
    // only stateful patch — .inkFluid must be layer 0 AND the only layer (its
    // sumi-e look is baked in-fragment; the renderer returns the live MTKView
    // and never folds shader effects over it). Flow paces the sim's time
    // step; Brush sizes the finger's stamp; Fade (expo — the first half of
    // the travel barely forgives) dissolves ink and defaults to 0: INK IS
    // PERMANENT, the restraint teacher. Swirl (vorticity) rests gentle in
    // base data at 0.15.
    //
    // GATE ORDER IS A RENDERER CONTRACT. Both gates are EVENT gates with
    // empty targets — the envelope still glows the pad and fires haptics; the
    // fluid renderer binds the fires POSITIONALLY: gates[0] = "Drop" (splash
    // at tapPoint — a drop is a drop, constant full strength; the envelope
    // level drives pad glow only), gates[1] = "Rinse" (fluidClear wipes the
    // sim — the only eraser, deliberately a decision and not a knob).
    // Reordering or inserting gates here silently rewires Drop/Rinse.
    //
    // The 29s LFO breathes Flow at depth 0.12 — LFO/gate effects INTEGRATE
    // into a stateful sim (they do not revert when the modulator does), so
    // depths stay low. Poses pose the WATER, never the painting — the 15s
    // capture is the only way to keep a painting. (Supersedes OSCILLA.md's
    // generic "full-state snapshot" pose language for stateful patches.)
    static let inkwell = OscillaPatch(
        id: "inkwell",
        name: "Inkwell",
        subtitle: "what you put down, stays",
        tint: ColorSpec(r: 0.25, g: 0.3, b: 0.42),
        layers: [
            // inkFluid: flow, brush, fade, swirl. flow/brush/fade are
            // knob-owned; fade 0 = the ink is permanent; swirl rests at base.
            OscillaLayer(engine: .inkFluid, base: [0.62, 0.35, 0.0, 0.15]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Flow",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 0, from: 0.0, to: 1.0),    // sim time step
                ],
                defaultValue: 0.62
            ),
            OscillaKnobSpec(
                label: "Brush",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 1, from: 0.0, to: 1.0),    // stamp radius
                ],
                defaultValue: 0.35
            ),
            OscillaKnobSpec(
                label: "Fade",
                curve: .expo,          // the first half of the travel barely forgives
                targets: [
                    ParamTarget(layer: 0, param: 2, from: 0.0, to: 1.0),    // ink dissolve
                ],
                defaultValue: 0.0
            ),
        ],
        lfos: [
            // Shares inkFluid flow (0, 0) with Flow → orbital moon. Fenced at
            // depth 0.12: effects INTEGRATE on a stateful sim — keep it low.
            OscillaLFO(
                shape: .sine,
                period: 29,
                depth: 0.12,
                targets: [
                    ParamTarget(layer: 0, param: 0, from: 0.0, to: 1.0),
                ]
            ),
        ],
        gates: [
            // ORDER IS A RENDERER CONTRACT — the fluid renderer consumes
            // these fires positionally (see the MARK comment above). EVENT
            // gates: empty targets; the envelope drives pad glow/haptics only.
            OscillaGate(
                label: "Drop",
                attack: 0.01,
                release: 1.2,
                targets: [],           // gates[0]: renderer splashes at tapPoint, full strength always
                hapticIntensity: 0.7
            ),
            OscillaGate(
                label: "Rinse",
                attack: 0.01,
                release: 0.6,
                targets: [],           // gates[1]: renderer clears the sim (fluidClear) — the only eraser
                hapticIntensity: 0.3
            ),
        ],
        poses: [
            // Knob space: [Flow, Brush, Fade]. Poses pose the WATER, never
            // the painting — the 15s capture is the only way to keep one.
            // Squall caps Flow at 0.85: taste + stability fence with the
            // swirl base at 0.15.
            OscillaPose(name: "Still Water", knobValues: [0.3, 0.25, 0.0]),  // slow, fine, permanent
            OscillaPose(name: "Stream", knobValues: [0.62, 0.35, 0.1]),      // the resting sound, barely forgiving
            OscillaPose(name: "Squall", knobValues: [0.85, 0.6, 0.05]),      // fast, broad, near-permanent
            OscillaPose(name: "Dry Paper", knobValues: [0.15, 0.5, 0.65]),   // sketching — strokes sink away
        ],
        renderScale: 1.0
    )

    // MARK: - Analog Sunday (kuwahara + colorGrade + halftone + grain + vignette)
    //
    // Faded-amber photo lab — the first needsPhoto patch: the fold runs over
    // the user's photo (no photo loaded → the renderer early-outs to quiet
    // black and the lab's picker capsule invites). Decade is THE macro: one
    // knob slides the print back through time — grade amount, halftone cell,
    // halftone ink, and grain intensity travel together. Paint drives the
    // kuwahara radius (1→5): the INT-CAST steps are the discrete-brush feel
    // AND the perf fence at hero size — never widen the range past 0.8.
    // Paper ages the stock: grain size up while the vignette closes in.
    // renderScale 0.7 — the first live user of the field: kuwahara is up to
    // 144 layer samples/px at the Paint cap on a 420pt hero; tune per device
    // via the Bench slider.
    //
    // NEVER modulate (LFO/gate) kuwahara radius (L0.p0) or colorGrade look
    // (L1.p0) — both are int-cast in the renderer and pop. The halftone angle
    // (L2.p1) rotates about the ORIGIN — keep it fixed at base, never sweep.
    // "Flash" snaps the print ALMOST all the way back to the present: the
    // cell tightens to the renderer's 3px floor (the shipped shader has no
    // bypass, so a fine screen always remains; the dot screen crawls and
    // re-tessellates through the 0.8s release — filmic, intended; grain
    // freezing momentarily stops the LFO flicker — intended), then decays
    // back into its decade. Decade and Flash sharing (1,1)/(2,0)/(2,2)/(3,0)
    // is legal — gates lerp current → .to, and those params are continuous.
    static let analogSunday = OscillaPatch(
        id: "analogSunday",
        name: "Analog Sunday",
        subtitle: "every photo is already a memory",
        tint: ColorSpec(r: 0.85, g: 0.66, b: 0.44),
        layers: [
            // kuwahara: radius is knob-owned (Paint default resolved:
            // 0.0 + 0.8·0.4 = 0.32).
            OscillaLayer(engine: .kuwahara, base: [0.32]),
            // colorGrade: look FIXED at 0.34 → round(0.34·6) = 2 Warm Vintage
            // (0.34, not 0.333 — keeps the float arithmetic safely above
            // 1.5·⅙); amount is knob-owned (Decade default resolved).
            OscillaLayer(engine: .colorGrade, base: [0.34, 0.46]),
            // halftone: cell + ink are knob-owned (Decade default resolved);
            // angle 0.25 FIXED — rotates about the ORIGIN, never sweep.
            OscillaLayer(engine: .halftone, base: [0.336, 0.25, 0.3825]),
            // grain: intensity knob-owned (Decade), size knob-owned (Paper).
            OscillaLayer(engine: .grain, base: [0.3475, 0.45]),
            // vignette: radius knob-owned (Paper); softness rests at base.
            OscillaLayer(engine: .vignette, base: [0.425, 0.5]),
        ],
        knobs: [
            OscillaKnobSpec(
                label: "Decade",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 1, param: 1, from: 0.1, to: 0.9),    // grade amount
                    ParamTarget(layer: 2, param: 0, from: 0.12, to: 0.6),   // halftone cell 5.5→15.6px
                    ParamTarget(layer: 2, param: 2, from: 0.0, to: 0.85),   // ink → newsprint
                    ParamTarget(layer: 3, param: 0, from: 0.1, to: 0.65),   // grain intensity
                ],
                defaultValue: 0.45
            ),
            OscillaKnobSpec(
                label: "Paint",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 0, param: 0, from: 0.0, to: 0.8),    // kuwahara radius 1→5 — int steps + perf fence; never past 0.8
                ],
                defaultValue: 0.4
            ),
            OscillaKnobSpec(
                label: "Paper",
                curve: .linear,
                targets: [
                    ParamTarget(layer: 3, param: 1, from: 0.2, to: 0.7),    // grain size
                    ParamTarget(layer: 4, param: 0, from: 0.55, to: 0.3),   // vignette closes as the paper ages
                ],
                defaultValue: 0.5
            ),
        ],
        lfos: [
            // Shares grain intensity (3, 0) with Decade → the moon rides the
            // macro. Grain self-animates, so this flickers exposure, not motion.
            OscillaLFO(
                shape: .sine,
                period: 19,
                depth: 0.15,
                targets: [
                    ParamTarget(layer: 3, param: 0, from: 0.1, to: 0.65),
                ]
            ),
        ],
        gates: [
            // Gates read only .to; .from documents the resting base value.
            OscillaGate(
                label: "Flash",
                attack: 0.02,
                release: 0.8,
                targets: [
                    ParamTarget(layer: 1, param: 1, from: 0.46, to: 0.05),   // grade almost off
                    ParamTarget(layer: 2, param: 2, from: 0.3825, to: 0.0),  // ink back to color
                    ParamTarget(layer: 2, param: 0, from: 0.336, to: 0.0),   // cell to the 3px floor — no shader bypass, a fine screen remains
                    ParamTarget(layer: 3, param: 0, from: 0.3475, to: 0.05), // grain nearly freezes
                    ParamTarget(layer: 4, param: 0, from: 0.425, to: 0.9),   // vignette opens wide
                ],
                hapticIntensity: 0.6
            ),
        ],
        poses: [
            // Knob space: [Decade, Paint, Paper].
            OscillaPose(name: "Seventies", knobValues: [0.65, 0.5, 0.55]),   // warm drugstore print
            OscillaPose(name: "Fifties", knobValues: [0.85, 0.3, 0.7]),      // newsprint on heavy stock
            OscillaPose(name: "Yesterday", knobValues: [0.3, 0.45, 0.35]),   // barely aged
            OscillaPose(name: "Today", knobValues: [0.05, 0.35, 0.2]),       // keeps a faint ~5.5px screen — every photo is already a memory
        ],
        renderScale: 0.7,
        needsPhoto: true
    )

    // MARK: - Catalog

    static let all: [OscillaPatch] = [
        drift, tidepool, nightGarden, supercell, swarm, inkwell, analogSunday,
    ]
}
