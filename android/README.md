# Designer Buddy for Android

Native Android version of Designer Buddy — a catalog of Android-native
components, patterns, and playgrounds built with Jetpack Compose and
Material 3 Expressive. See `../ANDROID_PLAN.md` for the full plan and the
iOS→Android page mapping.

## Build

```bash
cd android
./gradlew assembleDebug        # debug APK
./gradlew build                # assemble + lint + unit tests (what CI runs)
```

Requires JDK 17+ and the Android SDK. No `local.properties` is checked in;
set `ANDROID_HOME` or run `scripts/setup-android-sdk.sh`. CI builds every
PR and uploads two artifacts: `designer-buddy-debug-apk` (installable) and
`catalog-screenshots` — every catalog page rendered via Roborazzi
(`./gradlew recordRoborazziDebug` locally), so UI changes are reviewable
without a device.

## Architecture

- **Single activity, Compose-only.** No Fragments, no XML layouts (only the
  window-level splash theme).
- **AGP built-in Kotlin.** No Kotlin Gradle plugin anywhere; the Compose
  compiler plugin is applied by the convention plugins
  (`designerbuddy.android.application` / `.library` in `build-logic/`).
- **Catalog-as-data.** Every demo page is an `AppEntry` (id, name, section,
  group, icon, keywords, composable). Feature modules export entry lists;
  `:app` aggregates them into the `CatalogRegistry` that drives Home,
  search, and navigation.
- **Navigation 3.** `NavDisplay` over an owned `mutableStateListOf` back
  stack in `:app`.

| Module | Purpose |
|---|---|
| `:app` | Activity, Nav 3 host, catalog aggregation |
| `:core:designsystem` | Theme (M3 Expressive, dynamic color), typography (Roboto Flex / Chivo Mono), demo-page layout helpers |
| `:core:catalog` | `AppEntry`, `CatalogRegistry`, fuzzy search |
| `:core:data` | DataStore-backed bookmarks (`PinsRepository`) |
| `:feature:home` | Home screen: section grids, full catalog, search |
| `:feature:elements` | Element reference pages |

## Adding a catalog page

1. Write a `@Composable fun FooScreen()` in the right feature module.
   Pages render below a host-provided top bar — use a `LazyColumn` with
   `demoSection(...)` blocks from `:core:designsystem`.
2. Register it in the module's catalog list (e.g. `ElementsCatalog.kt`)
   with a stable id like `"elements/foo"`.
3. New feature modules also get one `addAll(...)` line in
   `DesignerBuddyApp.kt`.

## Conventions

- minSdk 33 / target+compile 36 — set once in `build-logic`, not per module.
- Versions live in `gradle/libs.versions.toml`; Dependabot keeps them fresh.
- material3 is pinned to a 1.5 alpha (overriding the Compose BOM) for the
  Expressive APIs — deliberate; see plan §11.
- Fonts are OFL-licensed; licenses in `core/designsystem/fonts-licenses/`.
