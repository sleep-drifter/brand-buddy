# Oscilla — decision log

A visual synthesizer for people who don't think of themselves as players.
The phone renders; physical knobs (later) play it. This file is the durable
memory of the ongoing design conversation — update it whenever a decision
lands. It is a log, not a pitch.

## The idea in one paragraph

The layered Metal shader stack from DesignerBuddy's Shaders playground,
rebuilt as an instrument: generative shaders are oscillators, filter shaders
are the filter section, and a modulation layer (LFOs, envelopes) makes
patches feel alive before anyone touches them. Played with on-screen
controls first, a BLE hardware control surface later. Audience is
non-musicians — handpan people, not DAW people.

**Name: Oscilla.** From *oscillum* — the small Roman votive masks hung from
trees to sway in the wind and catch the light; the origin of the word
"oscillate." A hanging object that moves on its own and plays with light.
(App Store search came back clean Oct 2026; trademark search still TODO.)
Hardware controller, when it exists: **Sway**.

## Glossary (the synth parallels)

| Synth term | Oscilla meaning |
|---|---|
| Oscillator | Generative shader layer (paints its own content) |
| Filter | Image-filter shader layer (transforms what's below) |
| Patch | A *designed instrument*: fenced param ranges, curves, renamed controls, macros, palette, poses. **Not a preset.** Pure data (JSON), never code. |
| Note | A **pose** — full-state snapshot on a pad; playing = traveling between poses; the morph is the interval |
| Key / scale | The patch's **palette**; color harmony = consonance; palette shift = key change |
| Gate / note-on | Pad press fires an envelope (bloom, flare, pulse); release decays. Velocity via pressure |
| Mod matrix | `{source → destination, depth, curve}` slots; sources = knobs AND internal LFOs/envelopes. The core data structure |
| Macro | One named knob driving several raw params with individual depths |
| Mod wheel | A springy/momentary control (spring fader, pressure pad, ribbon) — ephemeral expression vs. latched patch state |

## Settled decisions

- **Phone is the renderer**; hardware is pure input. Don't foreclose a
  future headless mode in the protocol, but v1 is phone-centric.
- **No pro-music integrations** (no Ableton Link/MIDI-ecosystem features as
  product goals). BLE-MIDI remains interesting purely as a *transport* for
  cheap hardware. Internal clock framed as "pulse," not BPM.
- **Handpan principle**: no wrong notes at entry. Patches ship with ranges
  fenced to the good zone and palettes pre-harmonized; a child mashing pads
  produces something lovely. Depth = unlocking fences, not surviving them.
- **The 15-second capture**: hold a button, the last 15s you played is saved
  as a loop. It's the retention loop (play → capture → share) and the
  mandatory cover art for publishing a patch — every patch ships with proof
  it can sing, performed by its maker.
- **Patches are data, never code.** Shaders ship in the app, referenced by
  id + engine version. Keeps patches tiny/safe, avoids App Store
  executable-code rules, and makes engine updates a content cadence
  ("the March update adds the Ember oscillator").
- **Two roles, two UIs**: Play mode (pads + named knobs, zero numbers) and
  the Bench (fencing, curves, macro wiring, pose capture). Most players
  never open the Bench; that's health.
- **Lineage is first-class**: patches record their parent; remix genealogy
  is a feature.
- **Skill = transitions, not frames**: morph routing (avoiding ugly
  in-between states) is the visible mastery. Supercell is designed around it.
- **Logomark is a Lissajous curve** — oscilloscope art is the original
  visual synthesis, and it's literally "oscilla." Boot screen draws one.
  Integer frequency ratios = visible consonance (future patch: *Scope*).
- **Modulation UI language is orbital**: an LFO on a knob renders as a tiny
  orbiting moon (radius = depth, speed = rate). Stolen from the
  Heliocentric/epicycles playground — an orrery, not a waveform icon.

## Factory eight (the lineup)

| # | Patch | Engine | Teaches | Notes |
|---|---|---|---|---|
| 1 | Drift | **Volumetric clouds** + gradient | Knobs are safe | First-launch patch; knobs: Weather, Warmth, Tide |
| 2 | Tidepool | Seascape + caustics | Gates = note-ons | Pad tap = droplet envelope |
| 3 | Night Garden | Star Nest + Domain Warp | Poses & morphs | 8 constellation poses; Depth is log zoom (octave easter egg) |
| 4 | Nova | **Shine shader** (B&W burst) | Velocity/expression | Soft strike = shiver of light, hard = supernova + decay. Replaced "Coals" |
| 5 | Inkwell | Stable fluid (Navier-Stokes), sumi-e mono | Gesture; restraint | Deliberately NOT mistake-proof — the practice instrument |
| 6 | Analog Sunday | Photo in → Kuwahara + halftone + grain | Filter patches, personal content | Macro knob: *Decade* |
| 7 | Swarm | Metaball/flocking | The machine plays itself; you conduct | Knobs: Cohesion, Scatter; pad = startle |
| 8 | Supercell | Domain warp + storm | Mastery; A/B morph crossfade | Fences wide on purpose; the performer's patch |

**Bench (second wave):** Coals (fire/thermal, pressure = blowing on
embers), Sunflower (phyllotaxis; ONE knob sweeping the golden angle
~137.5°), Scope (Lissajous; ratio knobs snapping to simple fractions),
Orrery (epicycles, pulse-synced). **Rejected:** Multi Helix (screensaver,
not instrument), Conway's Life as a patch (hands can't steer it — maybe
later as a chaotic internal mod source).

## Engine inventory

- **In brand-buddy** (`DesignerBuddy/More/Playgrounds/`, esp.
  `ShadertoyClassics.metal`, `ShadersPlayground.metal`, `SDFPlaygrounds`,
  `StableFluidKernels.metal`): star nest, seascape/ocean, clouds, domain
  warp, plasma, metaballs/SDF, stable fluid, Kuwahara, halftone, dither,
  thermal, grain, mesh/fluid gradients, and the layer-stack compositor +
  preset system itself.
- **Port from Matt's other playground** (NOT in brand-buddy — source project
  TBD): Shine shader (Nova's engine), Archimedes/phyllotaxis spiral, prime
  spiral, Heliocentric epicycles, Lissajous.

## Hardware (later phase, sketched)

ESP32/nRF52 + pots/encoders/pads over BLE. Ride BLE-MIDI first (any cheap
controller works day one), custom GATT later with a **control manifest**
(device self-describes: "3 sliders, 2 pads" → app auto-maps). Soft takeover
for pots on preset load; LED rings for encoder feedback; dream flagship =
motorized faders that glide on patch load. MIDI-learn UX: tap on-screen
control, wiggle knob, bound. Latency budget ~15–30ms BLE interval = feels
attached. Spring-return fader or ribbon (SoftPot) as the "mod wheel."

## Open questions

- Which project holds Shine/spirals/epicycles/Lissajous? (Needed for the port.)
- Build v1 inside DesignerBuddy as a hidden "Oscilla Lab" playground
  (reuses working TestFlight loop) vs. fresh repo + new app from day one.
- Trademark/legal check on "Oscilla"; reserve App Store name + domain.
- Thermal/battery budget: render-scale and 30fps ambient mode targets.
- Monetization shape (unsaid so far: likely paid app or patch packs — TBD).
