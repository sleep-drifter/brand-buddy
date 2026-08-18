# Designer Buddy for Android — Implementation Plan

This is the plan for building a native Android version of Designer Buddy: a
searchable, bookmarkable catalog of platform-native components, patterns,
gestures, animations, shaders, haptics, and device capabilities — the same
product idea as the iOS app, expressed in Android's native language.

## 1. Product framing: a parallel native showcase, not a port

The iOS app's entire value is *"this is what native feels like on this
platform."* Every page demonstrates iOS-native behavior: SwiftUI components,
SF Symbols, Liquid Glass materials, Core Haptics, Metal shaders. A pixel
port of those pages to Android would be a contradiction of the product.

The Android version therefore keeps the **information architecture** —
Home → sections (Elements / Patterns & System / Shaders / Playgrounds) →
catalog → demo pages, plus fuzzy search and bookmarks — but every demo page
showcases the **Android-native equivalent**: Material 3 Expressive
components, Material Symbols, predictive back, dynamic color, AGSL shaders,
`VibrationEffect` haptics, and so on. Where iOS has a concept Android
doesn't (Writing Tools, Liquid Glass), the page is replaced by the nearest
Android-native concept, and Android-only concepts get new pages iOS doesn't
have (Predictive Back, Dynamic Color, Widgets).

## 2. Guiding principles

1. **100% Kotlin, 100% Jetpack Compose, single-activity.** No Fragments, no
   XML layouts, no AppCompat theming. Views appear only where a platform API
   requires interop (maps, camera preview), wrapped in Compose.
2. **Catalog-as-data, screens-as-code.** Same model as iOS's `AppEntry.all`,
   but the registry is generated rather than hand-maintained (see §4.3) —
   the Android version of `AppDestination.swift`'s 120-case switch should
   not exist.
3. **Latest stable Jetpack, alpha where the demo *is* the alpha.** The app is
   a showcase of cutting-edge platform UI, so demo pages may opt into
   experimental APIs (Material 3 Expressive components, new haptics APIs)
   behind capability checks. App infrastructure (navigation, persistence,
   build) stays on stable releases.
4. **Graceful degradation over lowest-common-denominator.** Pages that need
   newer APIs (Android 16 haptic envelopes, high-end vibrators) detect
   capability at runtime and explain what's missing — that explanation is
   itself useful reference content for designers.

## 3. Platform targets

| Decision | Value | Rationale |
|---|---|---|
| `minSdk` | **33** (Android 13) | AGSL `RuntimeShader` (the Metal-shader analog), native Photo Picker, `POST_NOTIFICATIONS` runtime permission, predictive back all need 33. Audience is designers on modern hardware; supporting 21–32 would gut a third of the catalog. |
| `targetSdk` / `compileSdk` | **36** (Android 16) | Required by Play from Aug 2026 anyway; unlocks haptic envelope APIs and the current insets/adaptive behavior the app should demonstrate. |
| Form factors | Phone first; adaptive layouts for tablets/foldables from day one via window size classes | Android 16 ignores orientation/resizability restrictions on large screens — a reference app must handle this correctly. |

## 4. Tech stack

### 4.1 Language, build, tooling

- **Kotlin 2.2+** (K2 compiler), JDK 21 toolchain, **KSP2**.
- **Gradle version catalog** (`libs.versions.toml`) + **convention plugins**
  in `build-logic/` — the Now-in-Android pattern — so per-module build files
  stay ~10 lines.
- Compose compiler metrics + strong-skipping enabled; R8 full mode.

### 4.2 Core libraries

| Concern | Choice | Notes |
|---|---|---|
| UI | Jetpack Compose (latest BOM) | Compose-only app |
| Design system | **Material 3 Expressive** — `material3` 1.4 stable (`MaterialExpressiveTheme`, expressive `MotionScheme`) + 1.5 alpha for the newest components (FAB menus, split buttons, button groups, loading indicators, toolbars) with `@OptIn(ExperimentalMaterial3ExpressiveApi)` | The expressive components are themselves catalog content — being on the alpha is the point |
| Navigation | **Navigation 3** (`androidx.navigation3`, stable 1.0) | Back stack as observable state you own — a natural fit for a catalog app; scenes enable list-detail on large screens |
| Async/state | Coroutines + `Flow`/`StateFlow`, UDF | ViewModels only where there's real state (search, studios, pins); most demo pages are self-contained composables |
| Persistence | **Preferences DataStore** | Bookmarks (`pinnedKeys` set), replacing iOS `@AppStorage` |
| Serialization | `kotlinx.serialization` | Nav 3 keys, pins encoding |
| DI | **None initially.** The object graph is one DataStore + a generated static catalog. Add Hilt (or Metro) only if the graph earns it | Cutting-edge ≠ maximal framework use; a reference app should stay legible |
| Images/icons | **Material Symbols** variable font (fill/weight/grade/optical-size axes) | SF Symbols analog; the variable axes animate, which powers the Symbol Effects/Playground pages |
| Splash | AndroidX SplashScreen API | Replaces the hand-rolled iOS `SplashView` |

### 4.3 Catalog registry (the key architectural move)

iOS maintains the catalog in two hand-synced places: `AppEntry.all` literals
and a 120-case `switch` in `AppDestination.swift`. On Android, each demo
screen self-registers via annotation, and **KSP generates the registry**:

```kotlin
@CatalogEntry(
    name = "Buttons",
    section = "Actions",
    group = Group.ELEMENTS,
    icon = "buttons",           // Material Symbol name
    keywords = ["cta", "filled", "tonal", "elevated"],
)
@Composable
fun ButtonsScreen() { ... }
```

KSP emits `CatalogRegistry.all: List<AppEntry>` (name, section, group,
icon, keywords, and a composable reference) consumed by Home, search,
section lists, and the Nav 3 entry provider. Adding a page = writing one
annotated composable in the right feature module. This also keeps the
per-section catalogs modular: each feature module contributes entries,
aggregated at compile time.

Search ports the iOS in-order fuzzy `fuzzyMatch` over precomputed lowercase
fields — trivially portable Kotlin, warmed at startup exactly as iOS warms
`AppEntry.all`.

### 4.4 Module layout

```
android/
  build-logic/            // convention plugins
  app/                    // single Activity, Nav 3 host, theme wiring
  core/
    designsystem/         // theme, typography, MotionScheme, shared chrome
    catalog/              // @CatalogEntry annotation + KSP processor + registry API
    data/                 // PinsRepository (DataStore)
    ui/                   // shared demo scaffolding (PinnedPreview, PresetChips, timeline ruler)
  feature/
    home/                 // Home, search, section lists, Saved, Profile
    elements/             // M3 component reference pages
    patterns/             // navigation/modal/form patterns, states, permissions, media, maps, sensors, a11y
    playgrounds/          // motion & layout playgrounds
    shaders/              // AGSL pages
    studios/              // Haptic Studio, Keyframe Studio
  baselineprofile/        // baseline + startup profile generation
  benchmark/              // Macrobenchmark (startup, scroll jank)
```

Feature-level modularization (not per-screen) keeps incremental builds fast
without exploding into 120 modules.

## 5. Catalog mapping — iOS page → Android page

### Elements (≈35 pages) — mostly 1:1 onto Material 3 / M3 Expressive

Buttons, menus, text fields, switches, sliders, steppers, pickers, segmented
controls (→ button groups / `SegmentedButton`), date-time pickers, color
picker (custom; no platform picker — that's a teachable difference), badges,
chips (tags), lists, swipeable rows (`SwipeToDismissBox`), scroll behaviors,
**M3 Carousel**, grids (`LazyVerticalGrid`/`LazyVerticalStaggeredGrid`),
cards, top app bars & toolbars, navigation bar / rail / drawer (tab bars),
search (`SearchBar`), **bottom sheets** (`ModalBottomSheet`, standard
sheets), dialogs (`AlertDialog`, full-screen dialogs), menus/popups
(popovers), snackbars (toasts/banners), progress + **expressive loading
indicators**, gauges (custom draw + `progress` semantics), images & icons.

### Patterns & System (≈45 pages)

| iOS page | Android page |
|---|---|
| Navigation patterns | Nav 3 patterns: owned back stacks, nested flows, list-detail scenes |
| Tab bar patterns | Navigation bar/rail patterns + adaptive `NavigationSuiteScaffold` |
| Modal patterns | Sheets vs dialogs vs full-screen dialogs; when Android uses which |
| Onboarding, settings, empty/loading/error states, reorderable list | Same patterns, M3 idiom (`LazyColumn` drag-reorder) |
| Permission request / denied-recovery / push | Runtime permissions via Activity Result API, rationale flows, `POST_NOTIFICATIONS`, Settings deep-link recovery |
| Camera (config, viewfinder, capture UI, crop) | **CameraX + camera-compose viewfinder**, capture patterns, crop UIs |
| Document scanner (VisionKit) | **ML Kit Document Scanner** (Play services, full-screen contract) |
| Photo picker / library patterns | **Android Photo Picker** (`PickVisualMedia`) — permissionless, worth a page on exactly that |
| Audio record / waveform / playback | `AudioRecord` + amplitude waveform (Compose Canvas); **Media3** playback UI patterns |
| Maps (basics, annotations, overlays) | **Maps Compose** (markers, polygons/polylines, custom info windows) |
| Share sheet / clipboard / document picker / Quick Look | Android Sharesheet, `ClipboardManager`, Storage Access Framework, `ACTION_VIEW` / PDF renderer |
| Face ID | **BiometricPrompt** (class 2/3 biometrics, credential fallback) |
| Gestures (tap/long-press, swipe/drag, pinch, rotate) | `pointerInput` + `detectTransformGestures`, `AnchoredDraggable` |
| Transitions / keyframes / phase / matched geometry / content transition | `AnimatedContent`, `keyframes()`, `Animatable` sequences, **shared element transitions** (`SharedTransitionLayout`), `AnimatedVisibility`, `LookaheadScope` |
| Symbol effects / playground | **Material Symbols variable-axis animation** (animate fill/weight/grade) |
| Streaming text / prompt input / image generation UI | Same UI patterns; optionally wired to **Gemini Nano via ML Kit GenAI APIs** for a real on-device demo |
| Writing Tools | Dropped (no analog) → replaced by on-device GenAI patterns page |
| Sensors (accelerometer, barometer, proximity/light, battery) | `SensorManager` equivalents + `BatteryManager` |
| Custom haptics | `VibrationEffect.startComposition()` primitives + capability matrix |
| A11y: VoiceOver / Dynamic Type / Reduce Motion / High Contrast | TalkBack semantics, **non-linear font scaling** (Android 14+), animator-scale/remove-animations detection, contrast themes |
| Safe areas | **Edge-to-edge & WindowInsets** (enforced at targetSdk 35+) |

**New Android-only pages** (no iOS counterpart — the reason this app should
exist on Android): Predictive Back (in-app + cross-activity animations),
Dynamic Color / Material You (wallpaper-derived schemes, contrast levels),
Themed & adaptive icons, Haptic primitives capability explorer, Widgets
(**Glance**), App shortcuts, Per-app language. First release includes
Predictive Back, Dynamic Color, and Edge-to-Edge; the rest are backlog.

### Materials (glass/vibrancy pages)

Liquid Glass has no system analog. These become **Surfaces & Blur on
Android**: tonal elevation vs shadow, `Modifier.blur`/`RenderEffect`,
backdrop-blur glassmorphism via **Haze** (the community-standard library)
or a custom `RuntimeShader`, plus an honest "why Android doesn't do
system-wide translucency" reference note.

### Shaders (≈20 pages) — Metal → AGSL

- SwiftUI `colorEffect`/`layerEffect` pages port to **AGSL
  `RuntimeShader`** via `Modifier.graphicsLayer { renderEffect }` and
  `ShaderBrush`. AGSL is GLSL-flavored and single-pass fragment — the SDF,
  metaball, gradient, Lissajous, implicit-equation, and Shadertoy-classic
  ports translate directly.
- **Stable Fluid** (Metal compute + ping-pong textures) has no AGSL compute
  path. Plan: CPU simulation on a coroutine (the grid is small) rendered
  through a shader, or ping-pong `RenderNode`/`Bitmap` passes. Scheduled
  last in the shader phase; acceptable to ship at reduced resolution first.

### Playgrounds & Studios

- Spring physics, corner radius, shadow explorer, mesh/fluid gradient,
  physics tag, radial/flow layouts → Compose `Animatable`, `spring()`
  visualization, custom `Layout` composables, Canvas drawing. Mesh gradient
  has no Compose primitive → AGSL shader implementation.
- **Keyframe Studio** (timeline editor): port the timeline UI (ruler, snap
  engine, HUD are plain geometry/state code) driving Compose `keyframes()`
  and `Animatable` playback.
- **Haptic Studio**: the flagship divergence. Core Haptics' continuous
  intensity/sharpness curves map to `VibrationEffect` **composition
  primitives** (API 30+) and **waveform envelope APIs** (Android 16 /
  API 36). Device support varies wildly → the studio includes a capability
  readout (`arePrimitivesSupported`, amplitude control) and degrades
  from envelopes → primitives → one-shot waveforms. This page doubles as
  the best haptics-fragmentation reference designers will have.

## 6. Design system & motion

- **Theme:** `MaterialExpressiveTheme` with brand color scheme + optional
  dynamic color toggle (dynamic color is itself a demo page). Light/dark +
  contrast levels.
- **Typography:** iOS uses NoiGrotesk (commercial) + Chivo Mono. Chivo Mono
  is OFL (bundle it). **Verify the NoiGrotesk license covers Android
  distribution**; otherwise pick a fallback (e.g. Inter/Roboto Flex — Roboto
  Flex's variable axes are also demo material). Non-linear font scaling
  respected throughout.
- **Motion:** expressive `MotionScheme` (spatial/effects springs) as the
  default animation vocabulary; shared element transitions between catalog
  and detail where it aids spatial continuity.
- **Haptics:** `Modifier`-level haptic feedback on the same interactions the
  iOS app decorates (long-press bookmark, etc.) via `HapticFeedbackConstants`.

## 7. App shell behavior (parity with iOS shell)

- Home: section rows with 2-column preview grids, full catalog list,
  long-press-to-bookmark with haptic, context menus, bookmark badges.
- Search: fuzzy match with `SearchBar`; registry precomputed at startup.
- Saved & Profile as sheets/destinations; pins in DataStore keyed
  `"group:name"` exactly like iOS `pinKey`.
- Splash: SplashScreen API with icon-scale exit animation. The iOS keyboard
  prewarm hack is unnecessary on Android; the `AppEntry.all` warm-up is
  replaced by baseline profiles + eager registry init in `Application`.
- Predictive back fully supported (`android:enableOnBackInvokedCallback`),
  including Nav 3 in-app animations.

## 8. Performance, testing, CI

- **Baseline + startup profiles** (`baselineprofile` module) and
  **Macrobenchmark** (cold start, Home scroll jank, search latency) with CI
  regression thresholds.
- **Screenshot tests** (Roborazzi or Compose Preview Screenshot Testing) for
  every catalog page in light/dark/dynamic-color — this is a visual
  reference app; screenshots are the highest-value tests.
- Unit tests for registry generation, fuzzy search, PinsRepository
  (Turbine for Flows); Compose UI tests for shell flows (search → open →
  bookmark → saved).
- **GitHub Actions** (iOS uses Xcode Cloud; Android CI lives here): build +
  lint + unit/screenshot tests on PR; release workflow assembles a signed
  bundle to Play internal track (Play App Signing) — Android's TestFlight
  equivalent.

## 9. Repository layout

Plan assumes the Android app lives in this repo under `android/` (structure
in §4.4), keeping the shared catalog taxonomy, naming, and issue tracking in
one place. The directory is fully self-contained (own Gradle root), so
extracting it to a separate repo later is a `git mv` away if ever wanted.

## 10. Phased roadmap

**Phase 0 — Foundation (~2 weeks).** Gradle scaffold, convention plugins,
CI, theme + typography, Nav 3 shell, KSP catalog registry, Home + search +
sections + DataStore bookmarks, splash, edge-to-edge, predictive back.
*Exit: app shell fully working with a handful of stub pages; screenshot
harness running in CI.*

**Phase 1 — Elements (~3–4 weeks).** All Material 3 / Expressive component
reference pages. *Exit: Elements section at parity; screenshot coverage
complete.*

**Phase 2 — Patterns & System (~4–5 weeks).** Navigation/modal/form/state
patterns; permissions; camera/photos/audio/maps; system integration
(share, clipboard, biometrics, documents); gestures; animations incl.
shared elements; accessibility pages; sensors. *Exit: Patterns & System at
parity with the mapping table above.*

**Phase 3 — Playgrounds, Shaders, Studios (~4–5 weeks).** AGSL shader pages;
motion/layout playgrounds; Keyframe Studio; Haptic Studio with capability
matrix; Stable Fluid last. *Exit: full catalog parity minus explicitly
dropped pages.*

**Phase 4 — Polish & release (~2 weeks).** Android-only showcase pages
(Dynamic Color, Predictive Back deep-dive), adaptive layout pass
(tablet/foldable), baseline-profile tuning, a11y audit (TalkBack sweep,
font-scale extremes), Play listing + internal testing rollout.

Phases 1–3 are parallelizable across contributors because pages are
self-contained annotated composables in separate feature modules.

## 11. Risks & open questions

1. **NoiGrotesk licensing** for Android distribution — needs confirmation
   before Phase 0 theming (fallback identified in §6).
2. **Haptics fragmentation:** primitive/envelope support varies by vendor;
   Haptic Studio UX must treat capability detection as a feature. Test on
   Pixel + Samsung + one budget device.
3. **Stable Fluid on AGSL:** no compute shaders; CPU-sim fallback accepted.
4. **M3 Expressive alpha churn:** expressive components sit behind
   experimental APIs in 1.5 alphas; pin BOM per release train and batch
   upgrades.
5. **Maps API key / billing** setup needed for Maps Compose pages.
6. **Naming:** repo is `brand-buddy`, app is Designer Buddy — pick the
   Android `applicationId` (e.g. `com.designerbuddy.android`) early; it's
   immutable on Play.
