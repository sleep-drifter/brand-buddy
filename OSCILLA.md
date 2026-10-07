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
(Name status, researched Oct 2026: YELLOW, not clean — "Oscilla – Local AI"
(id6759628356) is live on the App Store with the exact name, and the
open-source Oscilla graphic-score system (oscilla.cc, NIME 2026) owns the
niche's mindshare; no live US mark found on bare "Oscilla" in
software/music classes (advisory, not legal advice). Plan a qualified
listing name ("Oscilla — Visual Synth"); reserve domains/handles; counsel
before paid launch. **"Sway" is RED**: Audima Labs ships a motion MIDI
controller named Sway and NI has a Sway synth — internal codename only.)
Hardware controller, when it exists: **Sway**.

## Glossary (the synth parallels)

| Synth term | Oscilla meaning |
|---|---|
| Oscillator | Generative shader layer (paints its own content) |
| Filter | Image-filter shader layer (transforms what's below) |
| Patch | A *designed instrument*: fenced param ranges, curves, renamed controls, macros, palette, poses. **Not a preset.** Pure data (JSON), never code. |
| Note | A **pose** — knob-space snapshot on a pad; playing = traveling between poses; the morph is the interval. (On a stateful patch like Inkwell, poses pose the WATER, never the painting.) |
| Key / scale | The patch's **palette**; color harmony = consonance; palette shift = key change |
| Gate / note-on | Pad press fires an envelope (bloom, flare, pulse); release decays. Velocity = strike height on the pad (per-gate velocityFloor; Nova teaches it) |
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
  Prototype lives in DesignerBuddy: the **Oscilla Logomark** playground
  (`OscillaLogomarkView.swift`) — scope-beam draw-on, ratio steppers with
  interval names, phase drift, glow, solid/beam trace, lockup preview.
  Working candidate: **3:2 ("perfect fifth"), δ=π/2** — stable, legible at
  icon sizes, and the consonance story in one figure.
- **Modulation UI language is orbital**: an LFO on a knob renders as a tiny
  orbiting moon (radius = depth, speed = rate). Stolen from the
  Heliocentric/epicycles playground — an orrery, not a waveform icon.

## Factory eight (the lineup)

| # | Patch | Engine | Teaches | Notes |
|---|---|---|---|---|
| 1 | Drift | **Chroma field** + grain *(subst.)* | Knobs are safe | First-launch patch; knobs: Weather, Warmth, Tide |
| 2 | Tidepool | Chroma field + water + circle wave *(subst.)* | Gates = note-ons | Pad tap ("Drop") = droplet envelope |
| 3 | Night Garden | Star Nest + Domain Warp + vignette | Poses & morphs | v0 ships 4 poses; Depth is expo zoom (octave easter egg) |
| 4 | Nova | **Shine shader** (B&W burst) — SHIPPED v0.3 | Velocity/expression | Soft strike = shiver, hard = supernova flare + 1.4s decay; Drift knob hand-sweeps the tan singularity |
| 5 | Inkwell | Stable fluid (Navier-Stokes), sumi-e mono — SHIPPED v0.2 | Gesture; restraint | NOT mistake-proof; Fade 0 = permanent ink; Rinse is the only eraser |
| 6 | Analog Sunday | Photo in → Kuwahara + grade + halftone + grain — SHIPPED v0.2 | Filter patches, personal content | Macro knob: *Decade*; gate *Flash* |
| 7 | Swarm | Metaball/flocking | The machine plays itself; you conduct | Knobs: Cohesion, Scatter; pad = startle |
| 8 | Supercell | Domain warp + storm | Mastery; A/B morph crossfade | Fences wide on purpose; the performer's patch |

**Engine substitutions (v0, on purpose — do not revert):** the Shadertoy
Seascape and Protean Clouds ports are **CC BY-NC-SA (non-commercial)** and
heavy raymarchers, so Drift ships on chromaGradientArt and Tidepool on
chromaField + water + circleWave — all in-house/MIT and cheap. Revisit only
with a relicense or replacement engines.

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
- **my-toybox (CONFIRMED Oct 2026)**: the "other playground" is
  github.com/Koshimizu-Takehito/my-toybox (MIT © 2025 takehito). Shine
  (Nova's engine — PORTED v0.3), Archimedes + prime spiral screens live
  there too. Heliocentric/epicycles were NOT found in the clone — that
  source is still unconfirmed.

## Hardware (later phase, sketched)

ESP32/nRF52 + pots/encoders/pads over BLE. Ride BLE-MIDI first (any cheap
controller works day one), custom GATT later with a **control manifest**
(device self-describes: "3 sliders, 2 pads" → app auto-maps). Soft takeover
for pots on preset load; LED rings for encoder feedback; dream flagship =
motorized faders that glide on patch load. MIDI-learn UX: tap on-screen
control, wiggle knob, bound. Latency budget ~15–30ms BLE interval = feels
attached. Spring-return fader or ribbon (SoftPot) as the "mod wheel."

## Multiplayer (logged Oct 2026 — not building yet)

Two phones, one instrument ("local multiplayer"). Two shapes, both wanted:

- **Controller mode**: one phone renders, the other is a pure control
  surface. This is architecturally IDENTICAL to the Sway hardware plan —
  the second phone is a control manifest ("3 knobs, 2 pads") streaming
  events over the same transport hardware will use. Build multiplayer
  first and Sway inherits a proven protocol; the phone is the zero-solder
  test harness.
- **Mirror mode**: both phones render the same image, four hands on one
  patch. Cheap by accident: OscillaEval is a pure function of
  (patch, performance, time), so syncing = one tiny performance struct +
  a clock-offset estimate (shared epoch; gate fire times rebased). No
  frame streaming. Roles fall out naturally — one player on knobs
  (weather), one on gates/poses (notes); the 15s capture becomes proof
  of a duet; the handpan principle doubles (two strangers can't break it).

Transport v1: MultipeerConnectivity (same-room, serverless). Design note
for the mod matrix: sources eventually carry a player id. Deferred until
after migration — needs local-network permission prompts the catalog app
shouldn't carry.

## Migration to a dedicated repo/app (criteria, decided Oct 2026)

Oscilla will not scale inside DesignerBuddy. Rather than a date, migrate
when the FIRST of these hits (Matt has delegated the call on the moment):

1. The next feature needs app-level surface the catalog shouldn't carry:
   local-network/multiplayer permissions, own icon + branding, own
   StoreKit, App Intents. (Multiplayer is exactly this trigger.)
2. The patch factory outgrows playground navigation / starts to feel like
   an app inside an app.
3. A playtester beyond Matt needs a build (sharing DesignerBuddy exposes
   the whole catalog).

Sequence: finish the in-repo patch wave (Inkwell, Analog Sunday, Nova
once the Shine source project is found) + one on-device Bench-lite tuning
round → migrate → multiplayer becomes the new app's first native feature.

## v0: Oscilla Lab — SHIPPED (Oct 2026, PR #48)

Lives as the **Oscilla Lab** playground in DesignerBuddy
(`DesignerBuddy/Oscilla/`, five files), reusing the CI + TestFlight loop;
extract to a dedicated repo/app once the engine sings. What landed:

- **OscillaModel** — Codable patch model (layers, fenced knob targets with
  linear/expo curves, LFOs, gates, poses in knob space) + `OscillaEval`,
  the stateless per-frame resolver: knobs SET, LFOs ADD centered swings,
  gates lerp toward their target by a click-free retriggerable envelope
  (a re-fire carries the prior envelope level into its attack).
- **OscillaRenderer** — layer-stack compositor mirroring the shipped
  shader call sites argument-for-argument; switch dispatch + typed locals
  (type-checker-safety house rule).
- **OscillaControls** — ring knob with the orbital modulation moon
  (radius = summed source depth, angle = LFO phase), latched gate pad
  (one fire per press), tap/hold pose pads (combined gesture, no
  double-fire). No numbers anywhere; knob drags beat scroll.
- **OscillaFactoryPatches** — Drift, Tidepool, Night Garden, each 3 knobs /
  1 gate / 1 LFO (always sharing a param with a knob so the moon shows) /
  4 poses.
- **OscillaLabView** — hero + chips + pose row + knobs + gates; pose tap
  morphs (1.6s smoothstep), hold captures; grabbing a knob bakes the
  morph; gate fires trigger HapticStudioEngine transients.
- Process note: the spec survived an adversarial critique panel (15
  upheld findings, 2 compile blockers caught before implementation) and
  a staged implementation + cross-file audit; build green first try.

## v0.1 — SHIPPED (Oct 2026, PRs #50 + #51)

- **metaballs engine** (`randomMetaball2D`, MIT-safe): autonomous bodies on
  Lissajous paths — the logomark motif wandering inside a patch. Ball count
  fixed in data (int-cast pops), speed knob-only (phase term is unwrapped:
  gating it would teleport the swarm by session age — critique catch).
- **Supercell** (steel-blue, the performer's patch): full-span fences,
  domain warp's 1↔2-octave cliff at Shear's midpoint; Wall/Anvil author
  Pressure ≥ 0.75 so the morph pops the cliff at any LFO phase. Strike =
  tap-aimed circleWave lightning.
- **Swarm** (firefly green, the machine plays itself): Cohesion fuses,
  Scatter speeds/shrinks, Startle breaks the swarm into individuals that
  re-gather over 1.8s.
- **Bench-lite** (`OscillaBenchView`): dev tuning sheet over the live lab —
  fences, curves, LFO/gate numbers, layer bases — behind a half-height
  detent with the hero still playable; Copy JSON / ShareLink exports for
  baking tuned values back into the factory. Player Bench stays deferred.
- **The 15s capture loop** (`OscillaCaptureController` + lab wiring):
  ReplayKit clip buffering — `exportClip` is system-capped at exactly 15s,
  so the spec IS the API ceiling. Explicit-tap arm (consent alert),
  `.arming` state so a disarm during the alert is never lost, disarm on
  real backgrounding only, share-sheet export with temp-file cleanup.
  Records the whole app screen; chrome-free canvas capture stays on the
  roadmap for patch cover art.
- Deferred still: player Bench, Nova (needs Shine port), hardware input,
  patch sharing, patch JSON import (export-only today), render-scale
  thermal tuning, chrome-free capture.

## v0.2 — SHIPPED (Oct 2026, PR #53)

The factory grows to seven with the two architecture-extending patches:

- **Inkwell** — the practice instrument. The stable-fluid solver rehosted
  as Oscilla's first STATEFUL layer (`OscillaFluidView`, an MTKView clone
  of the playground; three Metal kernels appended — fluidDrop, fluidClear,
  fluidSumiFS — none of the shipped ones touched). Drag paints (paint
  beats scroll); Drop splashes at the aimed point; Rinse — the only
  eraser, a decision not a knob — clears the sim; Fade defaults to 0, so
  what you put down stays. Poses pose the WATER, never the painting; the
  15s capture is the only way to keep a painting. Modulation on a
  stateful engine INTEGRATES (it does not revert with the LFO) — depths
  fenced low.
- **Analog Sunday** — the personal-content patch. Layers fold over a
  chosen photo (PhotosPicker, thumbnail-downsampled) through Kuwahara →
  Warm Vintage grade → halftone → grain → vignette. Decade is the macro;
  Flash snaps the print *almost* to the present (the halftone shader has
  no bypass — the screen tightens to its 3px floor and decays back).
  renderScale is now LIVE for fold patches (Analog Sunday ships at 0.7;
  tune per device from the Bench).
- **THIRD_PARTY_LICENSES.md** at the repo root: the fluid chain is MIT
  end-to-end (Jos Stam algorithm → TypeGPU © Software Mansion → my-toybox
  © takehito), verified upstream; notices now ship in-repo as MIT
  requires, covering all the my-toybox ports plus Inferno and Star Nest.
- Licensing resolved: delete "my-toybox license unknown" from any future
  planning — it is MIT (© 2025 takehito).

## v0.3 — SHIPPED (Oct 2026, PR #55)

- **Nova** — the velocity patch, on the Shine shader found in my-toybox.
  Ported VERBATIM behind four hooks; tempo is BASE DATA ONLY (the unwrapped
  phase term crosses full-field 1/tan singularities — a tempo knob would
  let pose morphs strobe at session-age-scaled rates, the critique panel's
  photosensitivity catch). **Drift** hand-sweeps exactly one tan period;
  **Strike** is a pure velocity-scaled gain flare.
- **Pad velocity** — pads report strike height (low = hard);
  `OscillaGate.velocityFloor` scales the envelope peak per gate, clamped
  to the carried level (no retrigger pop). The seven older patches take
  floor 1.0: bitwise-identical feel. Haptics ride the same curve.
- Shine provenance: my-toybox MIT, original by Yohei Nishitsuji —
  attribution shipped; explicit permission flagged before commercial ship.

## Migration — GO (decided Oct 2026)

The patch wave is complete (eight instruments) and multiplayer — the next
feature — is migration trigger #1, so the call delegated to the session is
GO. Two tracks:

- **Session**: scaffold `sleep-drifter/oscilla` (private) — nine sources
  copy verbatim; surgery = OscillaShaders.metal (Star Nest lifted ALONE
  from the Shadertoy file; Seascape/Protean Clouds/Plasma Globe are
  CC BY-NC-SA and stay behind) + trimmed OscillaFluidKernels.metal (all 15
  kernels the fluid view force-unwraps — a miss crashes, not fails
  compile) + OscillaHaptics/ActivityViewController/glassMorphHaptic shims +
  adapted pbxproj (bundle `com.wujdesign.oscilla`) + the same macos-26 CI.
  First on-device Inkwell run is the mandatory smoke test.
- **Matt**: create the GitHub repo + grant the Claude app; the tuning
  evening (Bench → Copy JSON → bake back); the ~30-min Apple pass (ASC app
  record "Oscilla", Xcode Cloud workflow, TestFlight group); reserve
  domains/handles; counsel for trademark.

brand-buddy keeps its Oscilla Lab copy until the new app's first TestFlight
build is verified on device; deletion is a later, separate PR.

## Open questions

- Heliocentric/epicycles source (not in my-toybox) — needed for Orrery later.
- Trademark counsel for "Oscilla" (research says yellow — see the name-status
  note up top); reserve oscilla.app / getoscilla.com + handles; new hardware
  codename to replace "Sway" (RED — taken in-category).
- Verify Yohei Nishitsuji's permission for the Shine adaptation before any
  commercial ship (Nova-specific ship-blocker, not a migration blocker).
- Thermal/battery budget: render-scale and 30fps ambient mode targets.
- Monetization shape (unsaid so far: likely paid app or patch packs — TBD).
