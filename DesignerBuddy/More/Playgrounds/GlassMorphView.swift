import SwiftUI

// Liquid-glass identity morphs. Liquid Carousel merges by proximity and
// Liquid Wallet by union membership; this page is the third mechanic —
// identity — plus a set of gesture toys where the finger drives the morph
// continuously (see GlassMorphGestureScenes.swift). Eight scenes share one
// stage: scrub a button pouring into satellites, stretch a lens between
// silhouettes, flick chips out of a container, and four pure-gesture scenes.

// MARK: - Palette

let glassMorphPalette: [(symbol: String, color: Color)] = [
    ("bolt.fill",       .orange),
    ("heart.fill",      .pink),
    ("star.fill",       .yellow),
    ("bell.fill",       .indigo),
    ("paperplane.fill", .teal),
    ("moon.fill",       .purple),
]

private enum ExpandLayout: String, CaseIterable, Identifiable {
    case row = "Row", fan = "Fan"
    var id: String { rawValue }
}

// MARK: - View

struct GlassMorphView: View {
    private enum MorphScene: String, CaseIterable, Identifiable {
        case expand = "Expand"
        case shape = "Shape Shift"
        case membership = "Add / Remove"
        case gooey = "Gooey Drag"
        case bloom = "Bloom"
        case magnetic = "Magnetic Row"
        case swipe = "Swipe Actions"
        case slingshot = "Slingshot"
        var id: String { rawValue }

        var chip: PresetChip {
            switch self {
            case .expand:
                PresetChip(name: rawValue,
                           detail: "A button pours out into satellites. Scrub the timeline below, or tap the + in the stage.",
                           code: "Animatable progress + glassEffect")
            case .shape:
                PresetChip(name: rawValue,
                           detail: "Drag the lens to stretch it, pinch to round the corners; release snaps to the nearest preset.",
                           code: ".glassEffect(in: .rect(cornerRadius:))")
            case .membership:
                PresetChip(name: rawValue,
                           detail: "Flick a chip off the row to remove it; tap the empty well to add one back.",
                           code: ".glassEffectTransition(...)")
            case .gooey:
                PresetChip(name: rawValue,
                           detail: "Drag the drop out of its socket — the neck tears past the blend distance and snaps back on release.",
                           code: "GlassEffectContainer(spacing:)")
            case .bloom:
                PresetChip(name: rawValue,
                           detail: "Press and hold anywhere; actions bloom around your finger. Slide onto one and let go.",
                           code: "DragGesture(minimumDistance: 0)")
            case .magnetic:
                PresetChip(name: rawValue,
                           detail: "Slide your finger along the row — the nearest lens swells and leans toward the touch.",
                           code: "gaussian falloff on distance")
            case .swipe:
                PresetChip(name: rawValue,
                           detail: "Pull the row left and actions pour out of its trailing edge; past halfway it snaps open.",
                           code: "reveal = -offset / span")
            case .slingshot:
                PresetChip(name: rawValue,
                           detail: "Pull the drop back and release — it flies into the target, fuses, and gets spat back out.",
                           code: "withAnimation(_:completion:)")
            }
        }
    }

    private enum ShapePreset: String, CaseIterable, Identifiable {
        case dot = "Dot", pill = "Pill", card = "Card", bar = "Bar"
        var id: String { rawValue }

        var size: CGSize {
            switch self {
            case .dot:  CGSize(width: 68, height: 68)
            case .pill: CGSize(width: 190, height: 56)
            case .card: CGSize(width: 230, height: 132)
            case .bar:  CGSize(width: 300, height: 48)
            }
        }

        var style: MorphShapeCard.ContentStyle {
            switch self {
            case .dot: .icon
            case .pill, .bar: .row
            case .card: .card
            }
        }

        var next: ShapePreset {
            let all = Self.allCases
            let i = all.firstIndex(of: self)!
            return all[(i + 1) % all.count]
        }
    }

    private enum TransitionKind: String, CaseIterable, Identifiable {
        case morph = "Morph", materialize = "Materialize", plain = "None"
        var id: String { rawValue }

        var transition: GlassEffectTransition {
            switch self {
            case .morph: .matchedGeometry
            case .materialize: .materialize
            case .plain: .identity
            }
        }
    }

    private enum StageBG: String, CaseIterable, Identifiable {
        case blobs = "Blobs", gradient = "Gradient", mesh = "Mesh", text = "Text"
        var id: String { rawValue }
    }

    @Namespace private var glassNS

    // Scene
    @State private var scene: MorphScene = .expand

    // Expand
    @State private var expandProgress: Double = 0
    @State private var itemCount: Double = 3
    @State private var layout: ExpandLayout = .row
    @State private var stagger: Double = 0.12

    // Shape Shift
    @State private var shapePreset: ShapePreset = .pill
    @State private var shapeSize = CGSize(width: 190, height: 56)
    @State private var shapeRadius: Double = 32
    @State private var shapeDragBase: CGSize?
    @State private var shapePinchBase: Double?

    // Add / Remove
    @State private var memberIDs: [Int] = [0, 1, 2]
    @State private var memberDrag: [Int: CGSize] = [:]
    @State private var transitionKind: TransitionKind = .morph

    // Shared
    @State private var blend: Double = 28
    @State private var springResponse: Double = 0.45
    @State private var springDamping: Double = 0.8
    @State private var slowMotion = false
    @State private var tinted = true
    @State private var background: StageBG = .blobs

    private var expandCount: Int { min(5, max(2, Int(itemCount))) }
    private var slowFactor: Double { slowMotion ? 4 : 1 }
    private var morphAnimation: Animation {
        .spring(response: springResponse * slowFactor, dampingFraction: springDamping)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sceneChips
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Glass Morph", shuffle: shuffle) {
            stage
        }
        .navigationTitle("Glass Morph")
    }

    // MARK: - Scene chips

    private var sceneChips: some View {
        PresetChipRow(chips: MorphScene.allCases.map(\.chip), selectedID: sceneSelection)
    }

    private var sceneSelection: Binding<String?> {
        Binding(
            get: { scene.rawValue },
            set: { raw in
                if let raw, let s = MorphScene(rawValue: raw) { scene = s }
            }
        )
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack {
            stageBackground
            stageScene
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private var stageScene: some View {
        switch scene {
        case .expand: expandStage
        case .shape: shapeStage
        case .membership: membershipStage
        case .gooey: GooeyDragScene(blend: blend, tinted: tinted, spring: morphAnimation)
        case .bloom: BloomScene(blend: blend, tinted: tinted, spring: morphAnimation)
        case .magnetic: MagneticRowScene(blend: blend, tinted: tinted, spring: morphAnimation)
        case .swipe: SwipeActionsScene(blend: blend, tinted: tinted, spring: morphAnimation)
        case .slingshot: SlingshotScene(blend: blend, tinted: tinted, spring: morphAnimation)
        }
    }

    @ViewBuilder
    private var stageBackground: some View {
        switch background {
        case .blobs:
            BlobBackground()
        case .gradient:
            LinearGradient(colors: [.indigo, .cyan],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mesh:
            Rectangle().fill(MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ], colors: [.red, .orange, .yellow, .purple, .pink, .orange, .blue, .cyan, .green]))
        case .text:
            LegibilityBackground()
        }
    }

    // MARK: - Scene 1: Expand (scrubbable)

    private var expandStage: some View {
        ExpandMorphStage(
            progress: expandProgress,
            count: expandCount,
            layout: layout,
            stagger: stagger,
            blend: blend,
            tinted: tinted,
            onTap: {
                withAnimation(morphAnimation) {
                    expandProgress = expandProgress < 0.5 ? 1 : 0
                }
            }
        )
        .animation(morphAnimation, value: layout)
        .animation(morphAnimation, value: expandCount)
    }

    // MARK: - Scene 2: Shape Shift (direct manipulation)

    private var shapeStage: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            MorphShapeCard(
                width: shapeSize.width,
                height: shapeSize.height,
                radius: CGFloat(shapeRadius),
                style: shapePreset.style,
                tint: tinted ? .indigo : nil
            )
            .contentShape(Rectangle())
            .gesture(shapeResizeDrag)
            .simultaneousGesture(shapeRadiusPinch)
            .onTapGesture { applyPreset(shapePreset.next) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var shapeResizeDrag: some Gesture {
        DragGesture()
            .onChanged { v in
                if shapeDragBase == nil { shapeDragBase = shapeSize }
                let base = shapeDragBase ?? shapeSize
                shapeSize = CGSize(
                    width: min(max(base.width + v.translation.width, 48), 310),
                    height: min(max(base.height + v.translation.height, 40), 176)
                )
            }
            .onEnded { _ in
                shapeDragBase = nil
                snapShapeToNearestPreset()
            }
    }

    private var shapeRadiusPinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                if shapePinchBase == nil { shapePinchBase = shapeRadius }
                shapeRadius = min(max((shapePinchBase ?? shapeRadius) * v.magnification, 4), 66)
            }
            .onEnded { _ in shapePinchBase = nil }
    }

    private func snapShapeToNearestPreset() {
        let nearest = ShapePreset.allCases.min {
            shapeDistance($0) < shapeDistance($1)
        } ?? shapePreset
        applyPreset(nearest)
    }

    private func shapeDistance(_ p: ShapePreset) -> CGFloat {
        abs(p.size.width - shapeSize.width) + abs(p.size.height - shapeSize.height)
    }

    private func applyPreset(_ p: ShapePreset) {
        withAnimation(morphAnimation) {
            shapePreset = p
            shapeSize = p.size
        }
    }

    private var shapePresetBinding: Binding<ShapePreset> {
        Binding(get: { shapePreset }, set: { applyPreset($0) })
    }

    // MARK: - Scene 3: Add / Remove (flick to dismiss)

    private var membershipStage: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            HStack(spacing: 14) {
                ForEach(memberIDs, id: \.self) { id in
                    memberChip(id)
                }
                addWell
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func memberChip(_ id: Int) -> some View {
        let entry = glassMorphPalette[id]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        return Image(systemName: entry.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: 46, height: 46)
            .glassEffect(glass, in: .circle)
            .glassEffectID("chip-\(id)", in: glassNS)
            .glassEffectTransition(transitionKind.transition)
            .offset(memberDrag[id] ?? .zero)
            .gesture(memberFlick(id))
    }

    private func memberFlick(_ id: Int) -> some Gesture {
        DragGesture()
            .onChanged { v in memberDrag[id] = v.translation }
            .onEnded { v in
                let travel = hypot(v.translation.width, v.translation.height)
                let thrown = hypot(v.predictedEndTranslation.width, v.predictedEndTranslation.height)
                if travel > 70 || thrown > 170 {
                    glassMorphHaptic(.light)
                    withAnimation(morphAnimation) {
                        memberIDs.removeAll { $0 == id }
                    }
                } else {
                    withAnimation(morphAnimation) { memberDrag[id] = .zero }
                }
            }
    }

    private var addWell: some View {
        Image(systemName: "plus")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 46, height: 46)
            .glassEffect(.regular, in: .circle)
            .opacity(memberIDs.count >= glassMorphPalette.count ? 0.35 : 1)
            .contentShape(Circle())
            .onTapGesture(perform: addMember)
    }

    private func addMember() {
        guard let next = (0..<glassMorphPalette.count).first(where: { !memberIDs.contains($0) }) else { return }
        memberDrag[next] = nil
        withAnimation(morphAnimation) {
            memberIDs.append(next)
            memberIDs.sort()
        }
    }

    // MARK: - Shuffle

    private func shuffle() {
        withAnimation(morphAnimation) {
            background = StageBG.allCases.randomElement() ?? .blobs
            tinted = Bool.random()
            switch scene {
            case .expand:
                expandProgress = expandProgress < 0.5 ? 1 : 0
            case .shape:
                shapePreset = ShapePreset.allCases.randomElement() ?? .pill
                shapeSize = shapePreset.size
                shapeRadius = Double(Int.random(in: 8...48))
            case .membership:
                memberIDs = Array((0..<glassMorphPalette.count).shuffled().prefix(Int.random(in: 2...5))).sorted()
            default:
                break
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sceneControls
            sliderRow("Blend", $blend, 0...64, text: "\(Int(blend))")
            divider
            sliderRow("Response", $springResponse, 0.2...0.9, text: String(format: "%.2f", springResponse))
            divider
            sliderRow("Damping", $springDamping, 0.5...1.0, text: String(format: "%.2f", springDamping))
            divider
            row { Toggle("Slow Motion (¼×)", isOn: $slowMotion) }
            divider
            row { Toggle("Tint Glass", isOn: $tinted) }
            divider
            row {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background")
                    Picker("Background", selection: $background) {
                        ForEach(StageBG.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var sceneControls: some View {
        switch scene {
        case .expand:
            scrubRow
            divider
            sliderRow("Items", $itemCount, 2...5, step: 1, text: "\(expandCount)")
            divider
            row {
                HStack {
                    Text("Layout").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Layout", selection: $layout) {
                        ForEach(ExpandLayout.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 160)
                }
            }
            divider
            sliderRow("Stagger", $stagger, 0...0.35, text: String(format: "%.2f", stagger))
            divider
        case .shape:
            row {
                HStack {
                    Text("Shape").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Shape", selection: shapePresetBinding) {
                        ForEach(ShapePreset.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 220)
                }
            }
            divider
            sliderRow("Radius", $shapeRadius, 4...66, text: "\(Int(shapeRadius))")
            divider
        case .membership:
            row {
                HStack {
                    Text("Transition").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Transition", selection: $transitionKind) {
                        ForEach(TransitionKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 230)
                }
            }
            divider
        default:
            EmptyView()
        }
    }

    private var scrubRow: some View {
        row {
            HStack(spacing: 12) {
                Text("Scrub").frame(width: 96, alignment: .leading)
                Slider(value: $expandProgress, in: 0...1) { editing in
                    if !editing {
                        withAnimation(morphAnimation) { expandProgress = expandProgress.rounded() }
                    }
                }
                Text(String(format: "%.2f", expandProgress))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    // MARK: - Caption

    private var caption: some View {
        Text(captionText)
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    private var captionText: String {
        let intro: String
        switch scene {
        case .expand:
            intro = "Satellites and button share a `GlassEffectContainer`; an `Animatable` "
                + "progress drives their positions, so you can scrub the tear and freeze it "
                + "mid-neck. Stagger offsets each satellite along the timeline so the blob "
                + "sheds one drop at a time — tap the + or drag the Scrub slider."
        case .shape:
            intro = "One glass element, one identity. Drag stretches width and height, pinch "
                + "rounds the corners, and releasing snaps to the nearest preset — width, "
                + "height, and radius all interpolate through `Animatable`, so the lens flows "
                + "instead of cross-fading."
        case .membership:
            intro = "Chips join and leave the container. Flick one away — past the velocity "
                + "threshold its glass exits with the selected `glassEffectTransition` "
                + "(Morph is absorbed by neighbors, Materialize dissolves with the system "
                + "sheen, None pops). Tap the empty well to add glass back."
        case .gooey:
            intro = "Two lenses in one container: a fixed socket and a drop under your "
                + "finger. The neck between them holds until their gap beats the Blend "
                + "distance, then tears with a haptic tick — release and the spring snaps "
                + "the drop home."
        case .bloom:
            intro = "Press and hold: actions bud out of a lens that follows your finger, "
                + "necking against it while they spread. Slide onto one and release to "
                + "commit; let go anywhere else and the bloom retracts into the touch point."
        case .swipe:
            intro = "Drag the row left and its actions pour out of the trailing edge, "
                + "scaling and separating as the gap beats the Blend distance. Past halfway "
                + "the row snaps open; tap an action to slurp everything back."
        case .magnetic:
            intro = "A gaussian falloff maps finger distance to swell and lean, so the "
                + "nearest lens rises toward the touch and hands off smoothly to its "
                + "neighbor — dock magnification, but liquid. Push Blend up until swollen "
                + "neighbors kiss."
        case .slingshot:
            intro = "Pull the drop back against a rubber-band clamp and release: past the "
                + "threshold it flies into the target, fuses into one lens, then gets spat "
                + "back to the socket — chained spring animations with completion handlers."
        }
        return intro
            + " Carousel merges by proximity, Wallet by unions; this page is identity and "
            + "gesture. Slow Motion runs every spring at quarter speed."
    }

    // MARK: - Row helpers

    private func sliderRow(_ label: String, _ value: Binding<Double>,
                           _ range: ClosedRange<Double>, step: Double = 0, text: String) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(text).font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 48, alignment: .trailing)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

// MARK: - Expand stage (Animatable)

/// The Expand scene. Conforms to `Animatable` over its progress so both the
/// scrub slider and the tap-to-toggle spring travel the same nonlinear,
/// staggered path — attribute interpolation alone would collapse the stagger.
private struct ExpandMorphStage: View, Animatable {
    var progress: Double
    let count: Int
    let layout: ExpandLayout
    let stagger: Double
    let blend: Double
    let tinted: Bool
    let onTap: () -> Void

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    item(i)
                }
                fab
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var fab: some View {
        Image(systemName: "plus")
            .font(.system(size: 22, weight: .semibold))
            .rotationEffect(.degrees(45 * progress))
            .frame(width: 56, height: 56)
            .glassEffect(.regular, in: .circle)
            .offset(fabOffset)
            .contentShape(Circle())
            .onTapGesture(perform: onTap)
    }

    private func item(_ i: Int) -> some View {
        let entry = glassMorphPalette[i]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        let p = itemProgress(i)
        let anchor = collapsedAnchor
        let target = itemTarget(i)
        return Image(systemName: entry.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(p)
            .frame(width: 42, height: 42)
            .glassEffect(glass, in: .circle)
            .offset(x: anchor.width + (target.width - anchor.width) * p,
                    y: anchor.height + (target.height - anchor.height) * p)
    }

    /// Per-item progress: each satellite starts `stagger` later on the shared
    /// timeline, so the blob sheds drops one at a time.
    private func itemProgress(_ i: Int) -> Double {
        guard stagger > 0.001 else { return progress }
        let total = 1 + stagger * Double(count - 1)
        return min(1, max(0, progress * total - stagger * Double(i)))
    }

    /// In Row the FAB slides right as satellites fan out to its left, keeping
    /// the ensemble centered; in Fan it holds low so the arc has headroom.
    private var fabOffset: CGSize {
        switch layout {
        case .row:
            CGSize(width: 50 * CGFloat(count) / 2 * progress, height: 0)
        case .fan:
            CGSize(width: 0, height: 34)
        }
    }

    private var collapsedAnchor: CGSize {
        layout == .fan ? CGSize(width: 0, height: 34) : .zero
    }

    private func itemTarget(_ i: Int) -> CGSize {
        switch layout {
        case .row:
            let step: CGFloat = 50
            let fabX = step * CGFloat(count) / 2
            return CGSize(width: fabX - step * CGFloat(i + 1), height: 0)
        case .fan:
            let radius: CGFloat = 100
            let degrees = 150 - 120 * Double(i) / Double(max(count - 1, 1))
            let theta = degrees * .pi / 180
            return CGSize(width: radius * CGFloat(cos(theta)),
                          height: 34 - radius * CGFloat(sin(theta)))
        }
    }
}

// MARK: - Morphing shape card

/// The Shape Shift lens. Conforms to `Animatable` so width, height, and corner
/// radius interpolate per frame — the glass shape itself flows between
/// silhouettes rather than snapping while only the frame animates.
struct MorphShapeCard: View, Animatable {
    enum ContentStyle { case icon, row, card }

    var width: CGFloat
    var height: CGFloat
    var radius: CGFloat
    var style: ContentStyle
    var tint: Color?

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(width, AnimatablePair(height, radius)) }
        set {
            width = newValue.first
            height = newValue.second.first
            radius = newValue.second.second
        }
    }

    var body: some View {
        let glass: Glass = tint.map { Glass.regular.tint($0.opacity(0.7)) } ?? .regular
        let clamped = min(radius, min(width, height) / 2)
        return content
            .animation(.smooth(duration: 0.3), value: style)
            .foregroundStyle(tint != nil ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: width, height: height)
            .glassEffect(glass, in: .rect(cornerRadius: clamped))
    }

    private var content: some View {
        ZStack {
            Image(systemName: "bubbles.and.sparkles")
                .font(.system(size: 26, weight: .semibold))
                .opacity(style == .icon ? 1 : 0)

            HStack(spacing: 8) {
                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 17, weight: .semibold))
                Text("Liquid Glass").font(.subheadline.weight(.medium))
            }
            .opacity(style == .row ? 1 : 0)

            VStack(spacing: 8) {
                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 28, weight: .semibold))
                Text("Liquid Glass").font(.headline)
                Text("One identity, many shapes")
                    .font(.caption).opacity(0.8)
            }
            .opacity(style == .card ? 1 : 0)
        }
    }
}

// MARK: - Legibility background

/// Dense UI-ish text — the torture test. Blobs flatter glass; body copy is
/// what actually breaks it.
private struct LegibilityBackground: View {
    private static let lines = [
        "Boarding 9:40 · Gate C22 · Seat 14A",
        "Order #4821 — shipped Tuesday, arrives Fri",
        "Meeting notes · Q3 design review · 11:30",
        "Transfer complete: $482.19 to Savings",
        "3 new messages · Reply-all thread muted",
        "Sunny, 72° — light breeze from the west",
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<14, id: \.self) { i in
                    Text(Self.lines[i % Self.lines.count])
                        .font(.caption2)
                        .foregroundStyle(i.isMultiple(of: 3) ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { GlassMorphView() }
        .environmentObject(PinsStore())
}
