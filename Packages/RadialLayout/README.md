# RadialLayout

The "Radial Layout" playground from DesignerBuddy, exported as a self-contained
Swift package so it can be dropped into any other iOS app. Pure SwiftUI — no
UIKit subclassing, no Metal, no third-party dependencies.

## What's inside

| Type | Min OS | What it is |
| --- | --- | --- |
| `RadialRingLayout` | iOS 16 | The custom `Layout`: places subviews evenly around a ring, optionally pulling one into the middle. |
| `RadialRing` | iOS 16 | Convenience container that manages subview ordering for the centre item. |
| `RadialLayoutDemoView` | iOS 17 | The full playground screen (sliders, centre toggle, shape picker, tap-to-focus, photo fills). |

## Adding it to another app

Pick whichever fits your setup:

1. **Local Swift package (recommended).** Copy the `Packages/RadialLayout`
   folder into the other app's repo (or anywhere on disk). In Xcode:
   *File ▸ Add Package Dependencies… ▸ Add Local…*, select the folder, and add
   the `RadialLayout` product to your app target. Then `import RadialLayout`.
2. **Drop in the sources.** Copy
   `Sources/RadialLayout/RadialRingLayout.swift` into your project — that one
   file is the whole layout. Add `RadialLayoutDemoView.swift` too if you want
   the demo screen. No `import RadialLayout` needed in this case.
3. **Its own repo, versioned.** The folder is fully self-contained: push its
   contents to a new GitHub repo (with `Package.swift` at the repo root) and
   add it by URL like any other SwiftPM dependency.

> SwiftPM can't resolve a package that lives in a subfolder of a remote repo,
> so option 3 is the route if you want to add it by URL rather than by path.

## Usage

The arrangement from the screenshot — 7 items, item size 100%, start angle 0°,
centre item on, centre gap 15%:

```swift
import RadialLayout

RadialRing(itemScale: 1.0, centerScale: 1.165) {
    ForEach(1..<7, id: \.self) { i in
        Circle().fill(Color(hue: Double(i) / 7, saturation: 0.55, brightness: 1))
    }
} center: {
    Circle().fill(Color(hue: 0, saturation: 0.55, brightness: 1))
}
.aspectRatio(1, contentMode: .fit)
.padding(20)
.background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
```

Ring only, no centre item:

```swift
RadialRing(itemScale: 0.9, startAngle: .degrees(30)) {
    ForEach(contacts) { AvatarBubble($0) }
}
```

Pass ring items directly (a `ForEach` or a list of views) — wrapping them in a
stack would make the whole stack a single ring item.

Or use the raw `Layout` yourself. When `centerItem` is true, the **last**
subview becomes the centre — it has to be last so it draws on top, because
`zIndex` isn't honoured inside a custom `Layout`:

```swift
RadialRingLayout(itemScale: 0.95, startAngle: .degrees(15), centerItem: true) {
    ForEach(satellites) { SatelliteView($0) }   // ring
    PlanetView()                                // centre, emitted last
}
```

The full playground screen, exactly as in DesignerBuddy:

```swift
NavigationStack { RadialLayoutDemoView() }
```

## Parameters ↔ playground controls

| Playground control | API parameter |
| --- | --- |
| Items | number of subviews you pass in |
| Item Size | `itemScale` (1 = adjacent items touch, smaller opens gaps) |
| Start Angle | `startAngle` (an `Angle`; 0 puts the first item at 12 o'clock) |
| Center Item | `centerItem` / using the `center:` builder of `RadialRing` |
| Center Gap | `centerScale` (demo maps gap g to `1.3 − 0.9·g`) |
| Ring/Center Shape | whatever shapes you render as items |

Ring geometry: for n ring items in a square of side `s`, items of radius
`r = R·sin(π/n)` sit on a ring of radius `R = (s/2)/(1 + sin(π/n))`, which is
exactly the size where neighbours touch and the ring fills the frame.

## Credits

Layout math adapted from Koshimizu-Takehito's
[my-toybox](https://github.com/Koshimizu-Takehito/my-toybox), via the
DesignerBuddy playground port.
