import SwiftUI

// Liquid-glass merge carousel. A horizontal rail of glass cards inside one
// GlassEffectContainer — no unions anywhere. Scrubbing compresses the gap
// between the current card and the next; when the gap falls under the
// container's blend distance the glass necks and fuses, and the merged slab
// trails off behind while the next card peeks in from the right. Because
// merging is driven purely by proximity, the morph is continuous under the
// finger — no membership flips.

// MARK: - Model

private struct RailCard: Identifiable {
    let id: Int
    let title: String
    let symbol: String
    let color: Color
}

private let railCards: [RailCard] = [
    .init(id: 0, title: "Aurora",   symbol: "moon.stars.fill", color: .red),
    .init(id: 1, title: "Pulse",    symbol: "waveform.path",   color: .pink),
    .init(id: 2, title: "Tide",     symbol: "water.waves",     color: .orange),
    .init(id: 3, title: "Ember",    symbol: "flame.fill",      color: .indigo),
    .init(id: 4, title: "Meadow",   symbol: "leaf.fill",       color: .teal),
    .init(id: 5, title: "Nocturne", symbol: "pianokeys",       color: .purple),
]

// MARK: - View

struct LiquidCarouselView: View {
    @State private var count: Double = 4
    @State private var widthFrac: Double = 0.62
    @State private var restGap: Double = 56
    @State private var blendSpacing: Double = 40
    @State private var cornerRadius: Double = 26
    @State private var behind: BehindMode = .merged
    @State private var tinted = true
    @State private var background: StageBG = .blobs

    /// Continuous scroll parameter: card index the "camera" sits on.
    @State private var t: Double = 0
    @State private var dragStartT: Double?

    private let cardHeight: CGFloat = 150
    private let mergedOverlap: CGFloat = 6

    private enum BehindMode: String, CaseIterable, Identifiable {
        case merged = "Stay Merged"
        case split = "Split"
        var id: String { rawValue }
    }

    private enum StageBG: String, CaseIterable, Identifiable {
        case blobs = "Blobs", gradient = "Gradient", mesh = "Mesh"
        var id: String { rawValue }
    }

    private var railCount: Int { max(2, Int(count)) }
    private var rail: [RailCard] { Array(railCards.prefix(railCount)) }
    private var maxT: Double { Double(railCount - 1) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Liquid Carousel") {
            stage
        }
        .navigationTitle("Liquid Carousel")
        .onChange(of: count) { t = 0 }
        .onChange(of: behind) { t = t.rounded() }
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack {
            stageBackground

            GeometryReader { geo in
                railView(viewport: geo.size.width)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(viewport: geo.size.width))
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(.snappy, value: widthFrac)
        .animation(.snappy, value: restGap)
        .animation(.snappy, value: cornerRadius)
        .animation(.snappy, value: count)
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

    private func railView(viewport: CGFloat) -> some View {
        let W = viewport * CGFloat(widthFrac)
        let xs = positions(cardWidth: W)
        let camera = cameraX(positions: xs)
        let leftMargin = (viewport - W) / 2

        return GlassEffectContainer(spacing: CGFloat(blendSpacing)) {
            ZStack(alignment: .leading) {
                ForEach(rail) { card in
                    let i = card.id
                    let glass: Glass = tinted ? .regular.tint(card.color.opacity(0.7)) : .regular
                    cardFace(card)
                        .frame(width: W, height: cardHeight)
                        .glassEffect(glass, in: .rect(cornerRadius: CGFloat(cornerRadius)))
                        .offset(x: leftMargin + xs[i] - camera)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func cardFace(_ card: RailCard) -> some View {
        VStack(spacing: 10) {
            Image(systemName: card.symbol).font(.system(size: 34, weight: .semibold))
            Text(card.title).font(.headline)
        }
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .opacity(1 - mergeAmount(t - Double(card.id)))
    }

    // MARK: - Geometry

    /// How compressed the boundary after card j is, 0 (rest gap) … 1 (merged).
    /// u is the scroll parameter relative to that boundary.
    private func mergeAmount(_ u: Double) -> Double {
        switch behind {
        case .merged:
            // Compresses as the boundary is crossed, and stays shut behind you.
            return min(max(u, 0), 1)
        case .split:
            // Kisses shut mid-transition, reopens at rest — cells dividing.
            return max(0, 1 - abs(2 * u - 1))
        }
    }

    private func gapAfter(_ j: Int) -> CGFloat {
        let m = CGFloat(mergeAmount(t - Double(j)))
        return CGFloat(restGap) + (-mergedOverlap - CGFloat(restGap)) * m
    }

    private func positions(cardWidth W: CGFloat) -> [CGFloat] {
        var xs: [CGFloat] = [0]
        for j in 1 ..< railCount {
            xs.append(xs[j - 1] + W + gapAfter(j - 1))
        }
        return xs
    }

    private func cameraX(positions xs: [CGFloat]) -> CGFloat {
        let c = min(railCount - 2, max(0, Int(floor(t))))
        let frac = CGFloat(t - Double(c))
        return xs[c] + (xs[c + 1] - xs[c]) * frac
    }

    // MARK: - Interaction

    private func dragGesture(viewport: CGFloat) -> some Gesture {
        let W = max(1, viewport * CGFloat(widthFrac))
        return DragGesture()
            .onChanged { value in
                if dragStartT == nil { dragStartT = t }
                let raw = (dragStartT ?? 0) - Double(value.translation.width / W)
                t = rubberBand(raw)
            }
            .onEnded { value in
                let predicted = (dragStartT ?? t) - Double(value.predictedEndTranslation.width / W)
                dragStartT = nil
                let target = min(max(predicted.rounded(), 0), maxT)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    t = target
                }
            }
    }

    private func rubberBand(_ raw: Double) -> Double {
        if raw < 0 { return raw * 0.25 }
        if raw > maxT { return maxT + (raw - maxT) * 0.25 }
        return raw
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Cards", $count, 2...6, step: 1, text: "\(railCount)")
            divider
            scrubRow
            divider
            sliderRow("Card Width", $widthFrac, 0.4...0.85, text: String(format: "%.0f%%", widthFrac * 100))
            divider
            sliderRow("Gap", $restGap, 16...96, text: "\(Int(restGap))")
            divider
            sliderRow("Blend", $blendSpacing, 0...80, text: "\(Int(blendSpacing))")
            divider
            sliderRow("Radius", $cornerRadius, 12...44, text: "\(Int(cornerRadius))")
            divider
            row {
                HStack {
                    Text("Behind").frame(width: 96, alignment: .leading)
                    Spacer()
                    Picker("Behind", selection: $behind) {
                        ForEach(BehindMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 210)
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
                Slider(value: $t, in: 0...maxT) { editing in
                    if !editing {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            t = t.rounded()
                        }
                    }
                }
                Text(String(format: "%.2f", t))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary).frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var caption: some View {
        Text("A merge carousel driven purely by proximity — every card is plain glass in "
             + "one `GlassEffectContainer`, no unions. Scrubbing compresses the gap to the "
             + "next card; once it drops under the container's Blend distance the shapes "
             + "neck and fuse, then the slab trails off behind while the next card peeks "
             + "in. Because nothing flips state, the morph tracks the finger continuously. "
             + "Behind picks whether passed cards stay merged into the slab or split apart "
             + "again after the handoff. Watch the neck form right at Gap ≈ Blend.")
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
    NavigationStack { LiquidCarouselView() }
        .environmentObject(PinsStore())
}
