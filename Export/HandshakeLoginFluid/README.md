# Handshake Login Fluid — drop-in export

An ambient GPU fluid background (Metal + SwiftUI) extracted from DesignerBuddy's
"Stable Fluid" playground and made **fully self-contained** for the Handshake
iOS app's login / home screen.

It self-animates (slow orbiting currents keep the flow alive with no input),
reacts to drags on any exposed area, and the Handshake **"H"** sits in the
current as a subtle frosted inset the fluid flows around — the cool
blue/green/violet treatment from the reference screenshots.

## Files

| File | What it is |
|------|------------|
| `HandshakeFluidBackground.swift` | The SwiftUI view, config, and Metal driver. |
| `HandshakeFluidKernels.metal` | The compute + render shaders. |

**No assets, no packages, no other source files are required.**

## Install

1. Drag both files into the app target in Xcode (any group). Confirm
   *"Copy items if needed"* and that the app target is checked.
2. Xcode adds `HandshakeFluidKernels.metal` to **Build Phases → Compile
   Sources** automatically — it compiles into the app's default Metal library,
   which is how the Swift side loads it (`device.makeDefaultLibrary()`).
3. Build. No `Info.plist` changes needed.

Every shader name is prefixed `hsFluid*` so it won't collide with any Metal
functions already in the app.

## Use

Put it at the bottom of a `ZStack`, behind the login content:

```swift
ZStack {
    HandshakeFluidBackground()      // already calls .ignoresSafeArea()

    VStack {
        Spacer()
        // ... your logo, fields, "Log in" button ...
    }
    .padding()
}
```

Because it's a plain background view, touches on your login controls go to
those controls; only drags on exposed background stir the fluid.

## Requirements

- iOS 14+.
- A Metal-capable device (every shipping iPhone/iPad). If `MTLCreateSystemDefaultDevice()`
  returns `nil` (some older simulators), it falls back to a static gradient built
  from the same palette, so it never crashes or renders black.

## Tuning

Pass a `HandshakeFluidConfig` to retune without touching the shader:

```swift
var cfg = HandshakeFluidConfig()
cfg.glow = 0.15            // icy-white lift on fast flow (0…1)
cfg.soften = 1.0           // edge blur in points
cfg.showLogo = true        // frosted "H" mark
cfg.logoScale = 0.11       // "H" half-height in field space
cfg.logoSlant = 0.16       // italic lean
cfg.logoStrength = 0.55    // how visible the mark is (0…1)
cfg.deltaTime = 0.30       // flow speed (smaller = calmer)
cfg.ambientStrength = 0.60 // how hard the ambient currents stir
cfg.interactive = true     // drag-to-stir
cfg.frameRateCap = 30      // fps budget (see Performance)
cfg.solverIterations = 12  // pressure-solve quality vs. cost
cfg.gridSize = 256         // sim resolution (128 = ~4× cheaper)
// palette corners: cfg.anchorA / B / C / D

HandshakeFluidBackground(config: cfg)
```

You don't have to guess these numbers — use the **live debug panel** below to
dial them in on-device, then copy the exact config out.

Recolor by setting `anchorA…anchorD` — the flow direction bilinearly blends
those four colours. The defaults are the Handshake cool palette:

| Anchor | RGB |
|--------|-----|
| A | 0.204, 0.780, 0.349 (green) |
| B | 0.200, 0.830, 0.930 (cyan) |
| C | 0.000, 0.478, 1.000 (blue) |
| D | 0.720, 0.620, 0.980 (violet) |

### Notes on look

- The simulation runs on a **square 256×256 grid** and the fragment shader
  **aspect-fills** it to any screen shape (center-crop, no stretch), with a
  small `overscan` zoom that hides the solver's static border. On a tall phone
  you see the full height of the field, center-cropped horizontally.
- The "H" is drawn procedurally (an SDF of two strokes + crossbar, sheared for
  the italic lean) — there's no logo asset to ship. If you'd rather use the real
  brand mark, replace `sdHandshakeH` in the `.metal` file or swap the fragment
  mark for a composited PNG.

## Live debug panel (dial in the values)

`HandshakeFluidDebugPanel` is a self-contained SwiftUI tuner (also in
`HandshakeFluidBackground.swift`). Share one `HandshakeFluidStore` between the
background and the panel; every change applies to the live simulation
instantly. When it looks right, tap **Copy Swift config** — it puts a ready-to-
paste `HandshakeFluidConfig` on the clipboard for your production code.

Present it however you like; a bottom sheet reads well:

```swift
struct LoginScreen: View {
    @StateObject private var fluid = HandshakeFluidStore()
    @State private var showTuner = false

    var body: some View {
        ZStack {
            HandshakeFluidBackground(store: fluid)   // note: store:, not config:
            LoginContent()
        }
        #if DEBUG
        // Any trigger you like — a hidden long-press, a shake, a debug menu row.
        .onLongPressGesture { showTuner = true }
        .sheet(isPresented: $showTuner) {
            HandshakeFluidDebugPanel(store: fluid)
                .presentationDetents([.medium, .large])   // iOS 16+
        }
        #endif
    }
}
```

Workflow: ship production with a static `HandshakeFluidBackground(config:)`;
only wire up the store + panel behind `#if DEBUG`. Tune on a real device, copy
the config, paste the values into your production `HandshakeFluidConfig`, and
the panel never ships.

The panel exposes: the four palette anchors, glow / soften / overscan, the "H"
mark (show, size, slant, strength, position), motion (drag-to-stir, time step,
ambient strength + decay, viscosity, swirl), and the performance knobs below.

## Performance & battery

Each frame is cheap — a 256×256 grid (~65K cells), ~22 compute dispatches
(mostly the pressure solve) plus one fullscreen draw, all on-GPU with no CPU
readback. On an A14 or newer a frame is well under a millisecond. The cost that
matters is that it's an **always-on GPU workload**, so the defaults are tuned
to keep it light:

- **30 fps cap** (`frameRateCap`). Without a cap, `MTKView` runs at the display
  max — **120 fps on ProMotion phones**, doubling power for a background nobody
  studies. 30 looks smooth for slow ambient flow. (Lowering fps also slows
  real-time flow, since the sim uses a fixed per-frame `deltaTime` — raise
  `deltaTime` to compensate.)
- **Pauses when off-screen or backgrounded.** The view sets `isPaused` on
  `onDisappear` and when `scenePhase` leaves `.active`, so it stops the instant
  the user logs in or leaves the app — no GPU burn behind other screens.
- **12 pressure iterations** (`solverIterations`), down from 18. Visually
  indistinguishable for a background; drop further to 8–10 to save more.

If you're targeting older devices or see thermals/drain:

- Lower `gridSize` to 192 or 128 (roughly 1.8× / 4× cheaper).
- Drop `frameRateCap` to 24.
- Set `soften = 0` to skip the SwiftUI blur pass (it forces an offscreen
  composite each frame).

Measure with Instruments (**Metal System Trace**, **GPU counters**) and Xcode's
**Energy** gauge. At 30 fps + pause-off-screen + 12 iterations this behaves like
a well-mannered live wallpaper; left uncapped and always drawing it will warm a
ProMotion phone on a lingering login screen.

## Where this came from

Ported from `DesignerBuddy/More/Playgrounds/StableFluidView.swift` +
`StableFluidKernels.metal`. Underlying solver: Jos Stam, *Stable Fluids*
(SIGGRAPH 1999); Metal implementation inspired by TypeGPU (© 2025 Software
Mansion, MIT). Trimmed to the cool field-color path only, with ambient forcing
+ energy decay added so it animates and stays stable unattended.
