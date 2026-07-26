import SwiftUI

// Component-shaped scenes for the Glass Morph playground: the same liquid
// mechanics applied to controls people actually ship — a segmented thumb, a
// download button's state machine, and a notification badge. Each takes the
// shared blend/tint/spring parameters from the page.

// MARK: - Liquid Thumb

/// A glass thumb sliding between segments, stretching mid-flight and
/// squishing back on arrival. An `Animatable` stage drives width and squish
/// from the travel fraction, so the spring and the stretch share one path.
struct LiquidThumbScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var selected = 0
    @State private var from = 0
    @State private var travel: Double = 1

    private let labels = ["Day", "Week", "Month", "Year"]
    private let segWidth: CGFloat = 70

    private var trackWidth: CGFloat { segWidth * CGFloat(labels.count) + 12 }

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                Capsule()
                    .fill(.black.opacity(0.22))
                    .frame(width: trackWidth, height: 52)

                ThumbStage(
                    travel: travel,
                    from: from,
                    to: selected,
                    segWidth: segWidth,
                    count: labels.count,
                    glass: tinted ? .regular.tint(.indigo.opacity(0.7)) : .regular
                )

                HStack(spacing: 0) {
                    ForEach(labels.indices, id: \.self) { i in
                        Text(labels[i])
                            .font(.subheadline.weight(i == selected ? .semibold : .regular))
                            .foregroundStyle(.white.opacity(i == selected ? 1 : 0.7))
                            .frame(width: segWidth, height: 52)
                            .contentShape(Rectangle())
                            .onTapGesture { select(i) }
                    }
                }
                .animation(.smooth(duration: 0.25), value: selected)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func select(_ i: Int) {
        guard i != selected else { return }
        withTransaction(Transaction()) {
            from = selected
            travel = 0
        }
        selected = i
        glassMorphHaptic(.soft)
        withAnimation(spring) { travel = 1 }
    }
}

private struct ThumbStage: View, Animatable {
    var travel: Double
    let from: Int
    let to: Int
    let segWidth: CGFloat
    let count: Int
    let glass: Glass

    var animatableData: Double {
        get { travel }
        set { travel = newValue }
    }

    var body: some View {
        let x0 = center(from)
        let x1 = center(to)
        let x = x0 + (x1 - x0) * travel
        let dist = min(CGFloat(abs(to - from)), 2.5)
        let stretch = CGFloat(sin(travel * .pi)) * dist
        return Color.clear
            .frame(width: (segWidth - 8) + 18 * stretch,
                   height: 40 - 5 * stretch)
            .glassEffect(glass, in: .capsule)
            .offset(x: x)
    }

    private func center(_ i: Int) -> CGFloat {
        (CGFloat(i) - CGFloat(count - 1) / 2) * segWidth
    }
}

// MARK: - State Morph

/// One glass element walking Download → progress → done: morphs as semantic
/// state transitions, not decoration. The capsule shape rides the frame, so
/// pill, bar, and circle are all the same lens.
struct StateMorphScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    private enum Phase { case idle, working, done }

    @State private var phase: Phase = .idle
    @State private var progress: Double = 0

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            morphButton
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var size: CGSize {
        switch phase {
        case .idle:    CGSize(width: 156, height: 46)
        case .working: CGSize(width: 200, height: 40)
        case .done:    CGSize(width: 56, height: 56)
        }
    }

    private var morphButton: some View {
        ZStack {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                Text("Download").font(.subheadline.weight(.medium))
            }
            .opacity(phase == .idle ? 1 : 0)

            Capsule()
                .fill(.white.opacity(0.25))
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 18)
                .opacity(phase == .working ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .opacity(phase == .done ? 1 : 0)
        }
        .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .frame(width: size.width, height: size.height)
        .glassEffect(tinted ? .regular.tint(.indigo.opacity(0.7)) : .regular, in: .capsule)
        .contentShape(Capsule())
        .onTapGesture(perform: advance)
        .animation(spring, value: phase)
    }

    private func advance() {
        switch phase {
        case .idle:
            phase = .working
            progress = 0
            glassMorphHaptic(.soft)
            withAnimation(.linear(duration: 2.2), completionCriteria: .logicallyComplete) {
                progress = 1
            } completion: {
                if phase == .working {
                    glassMorphHaptic(.medium)
                    withAnimation(spring) { phase = .done }
                }
            }
        case .working:
            break
        case .done:
            progress = 0
            phase = .idle
        }
    }
}

// MARK: - Badge Bud

/// A notification badge that grows out of the bell's glass, necks off, and
/// settles at the corner — pure proximity blending, driven by one offset.
struct BadgeBudScene: View {
    let blend: Double
    let tinted: Bool
    let spring: Animation

    @State private var shown = false
    @State private var count = 3

    var body: some View {
        GlassEffectContainer(spacing: CGFloat(blend)) {
            ZStack {
                badge
                bell
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var bell: some View {
        Image(systemName: shown ? "bell.fill" : "bell")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(tinted ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .frame(width: 64, height: 64)
            .glassEffect(tinted ? .regular.tint(.indigo.opacity(0.6)) : .regular, in: .circle)
            .contentShape(Circle())
            .onTapGesture {
                withAnimation(spring) { shown.toggle() }
                if shown { glassMorphHaptic(.soft) }
            }
            .animation(spring, value: shown)
    }

    private var badge: some View {
        Text("\(count)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .opacity(shown ? 1 : 0)
            .frame(width: 26, height: 26)
            .glassEffect(.regular.tint(.red.opacity(0.85)), in: .circle)
            .offset(x: shown ? 26 : 0, y: shown ? -26 : 0)
            .contentShape(Circle())
            .onTapGesture {
                guard shown else { return }
                count += 1
                glassMorphHaptic(.light)
            }
            .animation(spring, value: shown)
    }
}

// MARK: - Preview

#Preview("Liquid Thumb") {
    ZStack {
        BlobBackground()
        LiquidThumbScene(blend: 24, tinted: true, spring: .spring(response: 0.45, dampingFraction: 0.8))
    }
    .frame(height: 240)
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .padding()
}
