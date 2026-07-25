import SwiftUI

// Liquid-glass identity morphs. Liquid Carousel merges by proximity and
// Liquid Wallet by union membership; this page is the third mechanic:
// `glassEffectID`. Three scenes — a button that pours out into satellites,
// one lens reshaped across four silhouettes, and chips whose glass is
// absorbed or materialized as they join and leave the container.

// MARK: - Palette

private let morphPalette: [(symbol: String, color: Color)] = [
    ("bolt.fill",       .orange),
    ("heart.fill",      .pink),
    ("star.fill",       .yellow),
    ("bell.fill",       .indigo),
    ("paperplane.fill", .teal),
    ("moon.fill",       .purple),
]

// MARK: - View

struct GlassMorphView: View {
    private enum MorphScene: String, CaseIterable, Identifiable {
        case expand = "Expand"
        case shape = "Shape Shift"
        case membership = "Add / Remove"
        var id: String { rawValue }
    }

    private enum ExpandLayout: String, CaseIterable, Identifiable {
        case row = "Row", fan = "Fan"
        var id: String { rawValue }
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
    @State private var expanded = false
    @State private var itemCount: Double = 3
    @State private var layout: ExpandLayout = .row
    @State private var stagger: Double = 0.04

    // Shape Shift
    @State private var shapePreset: ShapePreset = .pill
    @State private var shapeRadius: Double = 32

    // Add / Remove
    @State private var memberIDs: [Int] = [0, 1, 2]
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

    // MARK: - Scene 1: Expand

    private var expandStage: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                ForEach(0..<expandCount, id: \.self) { i in
                    expandItem(i)
                }
                fab
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var fab: some View {
        Image(systemName: "plus")
            .font(.system(size: 22, weight: .semibold))
            .rotationEffect(.degrees(expanded ? 45 : 0))
            .frame(width: 56, height: 56)
            .glassEffect(.regular, in: .circle)
            .glassEffectID("fab", in: glassNS)
            .offset(fabOffset)
            .contentShape(Circle())
            .onTapGesture { expanded.toggle() }
            .animation(morphAnimation, value: expanded)
            .animation(morphAnimation, value: layout)
            .animation(morphAnimation, value: expandCount)
    }

    private func expandItem(_ i: Int) -> some View {
        let entry = morphPalette[i]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        return Image(systemName: entry.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(expanded ? 1 : 0)
            .frame(width: 42, height: 42)
            .glassEffect(glass, in: .circle)
            .glassEffectID("item-\(i)", in: glassNS)
            .offset(expanded ? itemTarget(i) : collapsedAnchor)
            .animation(morphAnimation.delay(Double(i) * stagger * slowFactor), value: expanded)
            .animation(morphAnimation, value: layout)
            .animation(morphAnimation, value: expandCount)
    }

    /// Where the FAB sits. In Row it slides right as satellites fan out to its
    /// left, keeping the ensemble centered; in Fan it holds low so the arc has
    /// headroom above.
    private var fabOffset: CGSize {
        switch layout {
        case .row:
            let shift: CGFloat = expanded ? 50 * CGFloat(expandCount) / 2 : 0
            return CGSize(width: shift, height: 0)
        case .fan:
            return CGSize(width: 0, height: 34)
        }
    }

    /// Collapsed satellites hide exactly under the FAB so the container reads
    /// as a single lens.
    private var collapsedAnchor: CGSize {
        layout == .fan ? CGSize(width: 0, height: 34) : .zero
    }

    private func itemTarget(_ i: Int) -> CGSize {
        switch layout {
        case .row:
            let step: CGFloat = 50
            let fabX = step * CGFloat(expandCount) / 2
            return CGSize(width: fabX - step * CGFloat(i + 1), height: 0)
        case .fan:
            let radius: CGFloat = 100
            let degrees = 150 - 120 * Double(i) / Double(max(expandCount - 1, 1))
            let theta = degrees * .pi / 180
            return CGSize(width: radius * CGFloat(cos(theta)),
                          height: 34 - radius * CGFloat(sin(theta)))
        }
    }

    // MARK: - Scene 2: Shape Shift

    private var shapeStage: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            MorphShapeCard(
                width: shapePreset.size.width,
                height: shapePreset.size.height,
                radius: CGFloat(shapeRadius),
                style: shapePreset.style,
                tint: tinted ? .indigo : nil
            )
            .glassEffectID("shifter", in: glassNS)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture { shapePreset = shapePreset.next }
        .animation(morphAnimation, value: shapePreset)
    }

    // MARK: - Scene 3: Add / Remove

    private var membershipStage: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            HStack(spacing: 14) {
                ForEach(memberIDs, id: \.self) { id in
                    memberChip(id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func memberChip(_ id: Int) -> some View {
        let entry = morphPalette[id]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        return Image(systemName: entry.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: 46, height: 46)
            .glassEffect(glass, in: .circle)
            .glassEffectID("chip-\(id)", in: glassNS)
            .glassEffectTransition(transitionKind.transition)
            .onTapGesture {
                withAnimation(morphAnimation) {
                    memberIDs.removeAll { $0 == id }
                }
            }
    }

    private func addMember() {
        guard let next = (0..<morphPalette.count).first(where: { !memberIDs.contains($0) }) else { return }
        withAnimation(morphAnimation) {
            memberIDs.append(next)
            memberIDs.sort()
        }
    }

    private func removeMember() {
        guard !memberIDs.isEmpty else { return }
        withAnimation(morphAnimation) {
            memberIDs.removeLast()
        }
    }

    // MARK: - Shuffle

    private func shuffle() {
        withAnimation(morphAnimation) {
            background = StageBG.allCases.randomElement() ?? .blobs
            tinted = Bool.random()
            switch scene {
            case .expand:
                expanded.toggle()
            case .shape:
                shapePreset = ShapePreset.allCases.randomElement() ?? .pill
                shapeRadius = Double(Int.random(in: 8...48))
            case .membership:
                memberIDs = Array((0..<morphPalette.count).shuffled().prefix(Int.random(in: 2...5))).sorted()
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            row {
                Picker("Scene", selection: $scene) {
                    ForEach(MorphScene.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            divider
            sceneControls
            divider
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
            row { Toggle("Expanded", isOn: $expanded) }
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
            sliderRow("Stagger", $stagger, 0...0.12, text: "\(Int(stagger * 1000))ms")
        case .shape:
            row {
                HStack {
                    Text("Shape").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Shape", selection: $shapePreset) {
                        ForEach(ShapePreset.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 220)
                }
            }
            divider
            sliderRow("Radius", $shapeRadius, 4...64, text: "\(Int(shapeRadius))")
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
            row {
                HStack {
                    Text("Chips").frame(width: 96, alignment: .leading)
                    Spacer()
                    Button(action: removeMember) {
                        Image(systemName: "minus.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(memberIDs.isEmpty)
                    Text("\(memberIDs.count)")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 32)
                    Button(action: addMember) {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(memberIDs.count >= morphPalette.count)
                }
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
            intro = "One button and its satellites share a `GlassEffectContainer`, each shape "
                + "carrying its own `glassEffectID`. Collapsed, the satellites hide under the "
                + "button so the container reads as a single lens; tap + and they pour out, "
                + "necking apart as they clear the Blend distance. Stagger delays each satellite "
                + "so the blob tears one drop at a time instead of splitting all at once. "
        case .shape:
            intro = "A single glass element with one stable identity. Width, height, and corner "
                + "radius interpolate through `Animatable`, so the lens flows between dot, pill, "
                + "card, and bar instead of cross-fading — the system reshapes the same piece of "
                + "glass. Tap the stage to cycle shapes. "
        case .membership:
            intro = "Chips join and leave the container — tap one to remove it. With Morph "
                + "(`.matchedGeometry`), a removed chip's glass is absorbed by its neighbors and "
                + "new glass buds back out of them; Materialize dissolves it in place with the "
                + "system sheen; None just pops. Push Blend up until resting chips fuse and the "
                + "absorb reads clearly. "
        }
        return intro
            + "Liquid Carousel merges by proximity and Liquid Wallet by union membership; this "
            + "page is the third mechanic — identity. Flip on Slow Motion to study the necks."
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
