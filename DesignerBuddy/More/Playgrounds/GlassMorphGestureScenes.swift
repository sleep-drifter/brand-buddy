import SwiftUI
import UIKit

// Gesture-driven scenes for the Glass Morph playground. The finger drives the
// morph continuously — position, distance, velocity, or hold duration maps
// straight onto the glass — instead of triggering a spring and watching it
// play. Each scene owns its transient touch state and resets when the scene
// picker swaps it out.

@MainActor
func glassMorphHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
    min(max(v, lo), hi)
}

// MARK: - Gooey Drag

/// A drop rests in a socket; dragging stretches a neck between them that
/// tears past the blend distance and snaps home on release.
struct GooeyDragScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var drag: CGSize = .zero
    @State private var torn = false

    private var tearDistance: CGFloat { 58 + CGFloat(blend) }

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                // The empty socket — its dashed outline only shows once the
                // drop has torn away.
                Image(systemName: "circle.dashed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .opacity(torn ? 0.8 : 0)
                    .frame(width: 50, height: 50)
                    .glassEffect(.regular, in: .circle)

                Image(systemName: "drop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                    .frame(width: 60, height: 60)
                    .glassEffect(tinted ? .regular.tint(.cyan.opacity(0.7)) : .regular, in: .circle)
                    .offset(drag)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { v in
                    drag = CGSize(width: clamp(v.translation.width, -150, 150),
                                  height: clamp(v.translation.height, -95, 95))
                    let dist = hypot(drag.width, drag.height)
                    if (dist > tearDistance) != torn {
                        torn.toggle()
                        glassMorphHaptic(torn ? .light : .soft)
                    }
                }
                .onEnded { _ in
                    if torn { glassMorphHaptic(.soft) }
                    withAnimation(spring) { drag = .zero }
                    torn = false
                }
        )
    }
}

// MARK: - Bloom

/// Press and hold anywhere: action satellites bud out of a lens that follows
/// the finger. Slide onto one and release to commit; release elsewhere and
/// the bloom retracts into the touch point.
struct BloomScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var origin: CGPoint?
    @State private var finger: CGPoint = .zero
    @State private var bloom: Double = 0
    @State private var selection: Int?

    private let radius: CGFloat = 74
    private let actions = Array(glassMorphPalette.prefix(4))

    var body: some View {
        GeometryReader { geo in
            GlassEffectContainer(spacing: CGFloat(blend)) {
                ZStack {
                    if let origin {
                        ForEach(0..<actions.count, id: \.self) { i in
                            satellite(i, origin: origin)
                        }
                        puck(in: geo.size)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .contentShape(Rectangle())
            .gesture(bloomGesture(in: geo.size))
            .overlay {
                if origin == nil {
                    Label("Press and hold", systemImage: "hand.draw.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func satellite(_ i: Int, origin: CGPoint) -> some View {
        let entry = actions[i]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        return Image(systemName: entry.symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .opacity(bloom)
            .frame(width: 44, height: 44)
            .glassEffect(glass, in: .circle)
            .scaleEffect(selection == i ? 1.22 : 1)
            .position(satellitePoint(i, origin: origin, bloom: bloom))
            .animation(.snappy(duration: 0.18), value: selection)
    }

    private func puck(in size: CGSize) -> some View {
        Circle()
            .fill(.clear)
            .frame(width: 40, height: 40)
            .glassEffect(.regular, in: .circle)
            .opacity(bloom)
            .position(CGPoint(x: clamp(finger.x, 20, size.width - 20),
                              y: clamp(finger.y, 20, size.height - 20)))
    }

    private func satellitePoint(_ i: Int, origin: CGPoint, bloom: Double) -> CGPoint {
        let degrees = 160 - 140 * Double(i) / Double(max(actions.count - 1, 1))
        let theta = degrees * .pi / 180
        return CGPoint(x: origin.x + radius * CGFloat(cos(theta)) * bloom,
                       y: origin.y - radius * CGFloat(sin(theta)) * bloom)
    }

    private func bloomGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in
                if origin == nil {
                    origin = CGPoint(x: clamp(v.startLocation.x, 84, size.width - 84),
                                     y: clamp(v.startLocation.y, 100, size.height - 36))
                    glassMorphHaptic(.soft)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { bloom = 1 }
                }
                finger = v.location
                selection = nearestSatellite(to: v.location)
            }
            .onEnded { _ in
                if selection != nil { glassMorphHaptic(.medium) }
                withAnimation(spring, completionCriteria: .logicallyComplete) {
                    bloom = 0
                } completion: {
                    origin = nil
                    selection = nil
                }
            }
    }

    private func nearestSatellite(to point: CGPoint) -> Int? {
        guard let origin else { return nil }
        for i in 0..<actions.count {
            let p = satellitePoint(i, origin: origin, bloom: 1)
            if hypot(p.x - point.x, p.y - point.y) < 32 { return i }
        }
        return nil
    }
}

// MARK: - Magnetic Row

/// Slide a finger along a row of lenses; a gaussian falloff maps distance to
/// swell and lean, so the nearest lens rises toward the touch and hands off
/// smoothly to its neighbor.
struct MagneticRowScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var fingerX: CGFloat?

    private let cells = Array(glassMorphPalette.prefix(5))

    var body: some View {
        GeometryReader { geo in
            GlassEffectContainer(spacing: CGFloat(blend)) {
                HStack(spacing: 18) {
                    ForEach(0..<cells.count, id: \.self) { i in
                        cell(i, midX: geo.size.width / 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { fingerX = $0.location.x }
                    .onEnded { _ in withAnimation(spring) { fingerX = nil } }
            )
        }
    }

    private func cell(_ i: Int, midX: CGFloat) -> some View {
        let entry = cells[i]
        let glass: Glass = tinted ? .regular.tint(entry.color.opacity(0.7)) : .regular
        let baseX = midX + (CGFloat(i) - CGFloat(cells.count - 1) / 2) * 62
        let w = influence(baseX)
        return Image(systemName: entry.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: 44, height: 44)
            .glassEffect(glass, in: .circle)
            .scaleEffect(1 + 0.5 * w)
            .offset(x: pull(baseX, weight: w), y: -22 * w)
    }

    private func influence(_ x: CGFloat) -> CGFloat {
        guard let fingerX else { return 0 }
        let d = (fingerX - x) / 64
        return exp(-d * d)
    }

    private func pull(_ x: CGFloat, weight: CGFloat) -> CGFloat {
        guard let fingerX else { return 0 }
        return clamp(fingerX - x, -26, 26) * 0.3 * weight
    }
}

// MARK: - Swipe Actions

/// Drag a glass row left and its actions pour out of the trailing edge,
/// scaling and separating as they clear the blend distance. Past halfway the
/// row snaps open; tapping an action slurps everything back.
struct SwipeActionsScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var open = false
    @State private var dragX: CGFloat?

    private let span: CGFloat = 116
    private let actions: [(symbol: String, color: Color)] = [
        ("flag.fill", .orange),
        ("trash.fill", .red),
    ]

    private var rowOffset: CGFloat { dragX ?? (open ? -span : 0) }
    private var revealed: CGFloat { clamp(-rowOffset / span, 0, 1) }

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                ForEach(0..<actions.count, id: \.self) { i in
                    actionButton(i)
                }
                rowCard
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(rowDrag)
    }

    private var rowCard: some View {
        HStack(spacing: 12) {
            Circle().fill(.secondary.opacity(0.35)).frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text("Swipe me").font(.subheadline.weight(.medium))
                Text("Actions pour out of the edge")
                    .font(.caption2).opacity(0.75)
            }
            Spacer()
        }
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .padding(.horizontal, 14)
        .frame(width: 300, height: 58)
        .glassEffect(tinted ? .regular.tint(.indigo.opacity(0.55)) : .regular,
                     in: .rect(cornerRadius: 18))
        .offset(x: rowOffset)
    }

    private func actionButton(_ i: Int) -> some View {
        let entry = actions[i]
        return Image(systemName: entry.symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .opacity(revealed)
            .frame(width: 44, height: 44)
            .glassEffect(.regular.tint(entry.color.opacity(0.75)), in: .circle)
            .scaleEffect(0.55 + 0.45 * revealed)
            .offset(x: 128 - CGFloat(i) * 54)
            .contentShape(Circle())
            .onTapGesture {
                glassMorphHaptic(.medium)
                withAnimation(spring) { open = false }
            }
    }

    private var rowDrag: some Gesture {
        DragGesture()
            .onChanged { v in
                let base: CGFloat = open ? -span : 0
                dragX = clamp(base + v.translation.width, -span - 28, 26)
            }
            .onEnded { v in
                let base: CGFloat = open ? -span : 0
                let predicted = base + v.predictedEndTranslation.width
                let willOpen = predicted < -span / 2
                if willOpen != open { glassMorphHaptic(.light) }
                open = willOpen
                withAnimation(spring) { dragX = nil }
            }
    }
}

// MARK: - Slingshot

/// Pull the drop back against a rubber-band clamp and release: past the
/// threshold it flies into the target, fuses into one lens, then gets spat
/// back to its socket — chained springs with completion handlers.
struct SlingshotScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var pos: CGSize = SlingshotScene.anchor
    @State private var flying = false

    private static let anchor = CGSize(width: -95, height: 28)
    private static let target = CGSize(width: 96, height: -18)

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                pad(at: Self.anchor, symbol: "circle.dashed", size: 50)
                pad(at: Self.target, symbol: "scope", size: 64)

                Image(systemName: "drop.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                    .frame(width: 46, height: 46)
                    .glassEffect(tinted ? .regular.tint(.cyan.opacity(0.7)) : .regular, in: .circle)
                    .offset(pos)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(slingDrag)
    }

    private func pad(at offset: CGSize, symbol: String, size: CGFloat) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .glassEffect(.regular, in: .circle)
            .offset(offset)
    }

    private var slingDrag: some Gesture {
        DragGesture()
            .onChanged { v in
                guard !flying else { return }
                pos = CGSize(width: clamp(Self.anchor.width + v.translation.width * 0.9, -160, 40),
                             height: clamp(Self.anchor.height + v.translation.height * 0.9, -80, 95))
            }
            .onEnded { v in
                guard !flying else { return }
                if hypot(v.translation.width, v.translation.height) > 45 {
                    fling()
                } else {
                    withAnimation(spring) { pos = Self.anchor }
                }
            }
    }

    private func fling() {
        flying = true
        glassMorphHaptic(.light)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75),
                      completionCriteria: .logicallyComplete) {
            pos = Self.target
        } completion: {
            glassMorphHaptic(.medium)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.45),
                          completionCriteria: .logicallyComplete) {
                pos = Self.anchor
            } completion: {
                flying = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Gooey Drag") {
    ZStack {
        BlobBackground()
        GooeyDragScene(blend: 28, tinted: true, spring: .spring(response: 0.45, dampingFraction: 0.8))
    }
    .frame(height: 240)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .padding()
}
