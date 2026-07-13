import SwiftUI

// Liquid-glass wallet carousel. The rear cards of the deck render as ONE
// merged glass shape (glassEffectUnion), so their peeking bottom edges fuse
// into a single scalloped blob. Swiping tears the next card out of the blob
// while the old front card is absorbed back in — GlassEffectContainer does
// the metaball morphing; we only animate offsets and union membership.

// MARK: - Model

private struct WalletCard: Identifiable, Equatable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
}

private let walletCards: [WalletCard] = [
    .init(id: 0, title: "Boarding Pass", subtitle: "SFO → HND",      symbol: "airplane",                color: .red),
    .init(id: 1, title: "Coffee Club",   subtitle: "Gold member",    symbol: "cup.and.saucer.fill",     color: .pink),
    .init(id: 2, title: "Transit",       subtitle: "Zones 1–3",      symbol: "tram.fill",               color: .orange),
    .init(id: 3, title: "Gym Pass",      subtitle: "All access",     symbol: "figure.run",              color: .indigo),
    .init(id: 4, title: "Library",       subtitle: "Central branch", symbol: "books.vertical.fill",     color: .teal),
    .init(id: 5, title: "Museum",        subtitle: "Annual pass",    symbol: "building.columns.fill",   color: .purple),
]

// MARK: - Placement

/// Whether a card participates in the merged rear blob or stands alone.
private enum GlassGroup { case stack, solo }

private struct CardPlacement {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var z: Double
    var contentOpacity: Double
    var group: GlassGroup
}

private struct PlacedCard: Identifiable {
    let card: WalletCard
    let placement: CardPlacement
    var id: Int { card.id }
}

// MARK: - View

struct LiquidWalletView: View {
    // Deck
    @State private var count: Double = 4
    @State private var topIndex = 0

    // Morph controls
    @State private var peek: Double = 16
    @State private var depthInset: Double = 0.05     // width shrink per depth
    @State private var blendSpacing: Double = 40
    @State private var cornerRadius: Double = 28
    @State private var mergeStack = true
    @State private var frontLayer: FrontLayer = .container
    @State private var tinted = true
    @State private var background: StageBG = .blobs

    // Transition: 0 = at rest, 1 = advanced one card
    @State private var progress: Double = 0
    @State private var direction: CGFloat = 1
    @State private var isSettling = false

    @Namespace private var glassNS

    private let cardHeight: CGFloat = 180

    private enum FrontLayer: String, CaseIterable, Identifiable {
        case container = "One Container"
        case layered = "Layered"
        var id: String { rawValue }
    }

    private enum StageBG: String, CaseIterable, Identifiable {
        case blobs = "Blobs", gradient = "Gradient", mesh = "Mesh"
        var id: String { rawValue }
    }

    private var deckCount: Int { max(1, Int(count)) }
    private var deck: [WalletCard] { Array(walletCards.prefix(deckCount)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview {
            stage
        }
        .navigationTitle("Liquid Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: count) {
            topIndex = 0
            progress = 0
        }
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack {
            stageBackground

            GeometryReader { geo in
                let cardWidth = geo.size.width - 72
                deckView(cardWidth: cardWidth)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .padding(.top, 0)
            }
            .padding(.top, 24)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture { advance() }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(.snappy, value: peek)
        .animation(.snappy, value: depthInset)
        .animation(.snappy, value: cornerRadius)
        .animation(.snappy, value: count)
        .animation(.snappy, value: mergeStack)
        .animation(.snappy, value: tinted)
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
        }
    }

    // MARK: - Deck rendering

    /// Three render plumbings for the same geometry:
    /// merge off  → every card is its own plain glass shape (the "reference" look)
    /// container  → everything in one GlassEffectContainer, grouped by union ids
    /// layered    → only the stack blob lives in the container; solo cards sit above it
    @ViewBuilder
    private func deckView(cardWidth: CGFloat) -> some View {
        let items = placedCards(cardWidth: cardWidth)
        if !mergeStack {
            ZStack(alignment: .top) {
                ForEach(items) { item in
                    glassCard(item, unioned: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        } else if frontLayer == .container {
            GlassEffectContainer(spacing: CGFloat(blendSpacing)) {
                ZStack(alignment: .top) {
                    ForEach(items) { item in
                        glassCard(item, unioned: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            ZStack(alignment: .top) {
                GlassEffectContainer(spacing: CGFloat(blendSpacing)) {
                    ZStack(alignment: .top) {
                        ForEach(items.filter { $0.placement.group == .stack }) { item in
                            glassCard(item, unioned: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                ForEach(items.filter { $0.placement.group == .solo }) { item in
                    glassCard(item, unioned: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func glassCard(_ item: PlacedCard, unioned: Bool) -> some View {
        let p = item.placement
        let glass: Glass = tinted ? .regular.tint(item.card.color.opacity(0.7)) : .regular
        let base = cardFace(item.card, contentOpacity: p.contentOpacity)
            .frame(width: p.width, height: cardHeight)
            .glassEffect(glass, in: .rect(cornerRadius: CGFloat(cornerRadius)))

        Group {
            if unioned {
                base
                    .glassEffectID("card-\(item.card.id)", in: glassNS)
                    .glassEffectUnion(id: p.group == .stack ? "stack" : "solo-\(item.card.id)",
                                      namespace: glassNS)
            } else {
                base
            }
        }
        .offset(x: p.x, y: p.y)
        .zIndex(p.z)
    }

    private func cardFace(_ card: WalletCard, contentOpacity: Double) -> some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(.headline)
                    Text(card.subtitle).font(.caption).opacity(0.8)
                }
                Spacer()
                Image(systemName: card.symbol).font(.title3)
            }
            Spacer()
            HStack {
                Circle().fill(.white.opacity(0.35)).frame(width: 24, height: 24)
                Spacer()
                Text("•••• \(2748 + card.id * 731)")
                    .font(.mono(.caption2)).opacity(0.85)
            }
        }
        .padding(16)
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .opacity(contentOpacity)
    }

    // MARK: - Geometry

    private func placedCards(cardWidth: CGFloat) -> [PlacedCard] {
        let n = deckCount
        return (0 ..< n).map { d in
            let card = deck[(topIndex + d) % n]
            return PlacedCard(card: card,
                              placement: placement(depth: d, n: n, W: cardWidth))
        }
    }

    private func slotY(_ d: Int) -> CGFloat { CGFloat(d) * CGFloat(peek) }
    private func slotW(_ d: Int, W: CGFloat) -> CGFloat { W * (1 - CGFloat(depthInset) * CGFloat(d)) }

    /// Interpolates a card's frame between its resting slot and its destination
    /// one advance later. depth 0 = front (exits and is absorbed at the back),
    /// depth 1 = next up (tears out of the blob), the rest shuffle up a slot.
    private func placement(depth d: Int, n: Int, W: CGFloat) -> CardPlacement {
        let p = CGFloat(min(max(progress, 0), 1))

        if p <= 0 || n == 1 || d > 1 && n == 2 {
            return CardPlacement(x: 0, y: slotY(d), width: slotW(d, W: W),
                                 z: Double(n - d),
                                 contentOpacity: d == 0 ? 1 : 0,
                                 group: d == 0 ? .solo : .stack)
        }

        switch d {
        case 0:
            // Slides out with the finger, arcs back, and melts into the last slot.
            let easeIn = p * p
            let x = direction * W * 0.55 * sin(p * .pi)
            let y = slotY(n - 1) * easeIn
            let w = W + (slotW(n - 1, W: W) - W) * easeIn
            let fade = 1 - max(0, (Double(p) - 0.6) / 0.4)
            return CardPlacement(x: x, y: y, width: w,
                                 z: p < 0.85 ? 999 : 1,
                                 contentOpacity: fade,
                                 group: p < 0.85 ? .solo : .stack)
        case 1:
            // Lifts out of the blob on the opposite side and lands up front.
            let x = -direction * W * 0.16 * sin(p * .pi)
            let y = slotY(1) * (1 - p)
            let w = slotW(1, W: W) + (W - slotW(1, W: W)) * p
            return CardPlacement(x: x, y: y, width: w,
                                 z: 998,
                                 contentOpacity: Double(p),
                                 group: p < 0.08 ? .stack : .solo)
        default:
            let y = slotY(d) + (slotY(d - 1) - slotY(d)) * p
            let w = slotW(d, W: W) + (slotW(d - 1, W: W) - slotW(d, W: W)) * p
            return CardPlacement(x: 0, y: y, width: w,
                                 z: Double(n - d),
                                 contentOpacity: 0,
                                 group: .stack)
        }
    }

    // MARK: - Interaction

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isSettling, deckCount > 1 else { return }
                if progress == 0 {
                    direction = value.translation.width >= 0 ? 1 : -1
                }
                progress = min(1, abs(value.translation.width) / 150)
            }
            .onEnded { value in
                guard deckCount > 1 else { return }
                let flick = abs(value.predictedEndTranslation.width) > 150
                settle(complete: progress > 0.4 || flick)
            }
    }

    /// Tap anywhere on the deck to run a full advance under animation —
    /// the union flips happen inside withAnimation, so any liquid morphing
    /// the system gives us shows at its best here.
    private func advance() {
        guard !isSettling, deckCount > 1, progress == 0 else { return }
        direction = 1
        settle(complete: true)
    }

    private func settle(complete: Bool) {
        guard progress > 0 || complete else { return }
        isSettling = true
        if complete {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                progress = 1
            } completion: {
                commitAdvance()
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                progress = 0
            } completion: {
                isSettling = false
            }
        }
    }

    /// At progress == 1 every card sits exactly on the slot it will occupy
    /// after the reorder, so rotating the deck and zeroing progress without
    /// animation is invisible.
    private func commitAdvance() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            topIndex = (topIndex + 1) % deckCount
            progress = 0
        }
        isSettling = false
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Cards", $count, 2...6, step: 1, text: "\(deckCount)")
            divider
            sliderRow("Peek", $peek, 8...28, text: "\(Int(peek))pt")
            divider
            sliderRow("Depth Inset", $depthInset, 0...0.1, text: String(format: "%.0f%%", depthInset * 100))
            divider
            sliderRow("Blend", $blendSpacing, 0...80, text: "\(Int(blendSpacing))")
            divider
            sliderRow("Radius", $cornerRadius, 12...44, text: "\(Int(cornerRadius))")
            divider
            scrubRow
            divider
            row { Toggle("Merge Stack", isOn: $mergeStack) }
            if mergeStack {
                divider
                row {
                    HStack {
                        Text("Front Card").frame(width: 96, alignment: .leading)
                        Spacer()
                        Picker("Front Card", selection: $frontLayer) {
                            ForEach(FrontLayer.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented).frame(width: 210)
                    }
                }
            }
            divider
            row { Toggle("Tint Cards", isOn: $tinted) }
            divider
            row {
                HStack {
                    Text("Background").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Background", selection: $background) {
                        ForEach(StageBG.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 210)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scrubRow: some View {
        row {
            HStack(spacing: 12) {
                Text("Scrub").frame(width: 96, alignment: .leading)
                Slider(value: $progress, in: 0...1) { editing in
                    if editing {
                        direction = 1
                        isSettling = false
                    } else {
                        settle(complete: progress > 0.5)
                    }
                }
                .disabled(deckCount < 2)
                Text(String(format: "%.2f", progress))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var caption: some View {
        Text("A wallet-stack carousel where the rear cards fuse into one scalloped glass "
             + "blob via `glassEffectUnion`, inside a `GlassEffectContainer` whose spacing "
             + "sets the blend distance. Swipe (or Scrub) to tear the next card out of the "
             + "blob while the front card is absorbed at the back; tap to advance under "
             + "animation. Merge Stack off shows the unmerged reference. Front Card picks "
             + "the experiment: One Container keeps every card in the same container and "
             + "relies on union ids to keep the front card crisp; Layered renders solo "
             + "cards outside the container so they can never accidentally merge.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
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
                    .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

// MARK: - Preview

#Preview {
    NavigationStack { LiquidWalletView() }
}
