import SwiftUI

// MARK: - Text Effects
//
// SwiftUI's TextRenderer (iOS 18) hands you the resolved Text.Layout —
// lines, runs, and run slices — to draw yourself, one GraphicsContext
// copy per glyph. One-shot effects animate a progress value through
// Animatable; ambient effects derive phase from TimelineView.

struct TextEffectsView: View {
    private enum Effect: String, CaseIterable, Identifiable {
        case none = "None"
        case blurIn = "Blur In"
        case rise = "Rise"
        case wave = "Wave"
        case shimmer = "Shimmer"
        var id: Self { self }

        var isOneShot: Bool { self == .blurIn || self == .rise }
    }

    @State private var effect: Effect = .blurIn
    @State private var progress: Double = 0
    @State private var speed: Double = 1.0
    @State private var intensity: Double = 6
    @State private var sampleText = "Glyphs that move"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                stageCard
                controlsCard
                anatomyCard
            }
            .padding(16)
        }
        .navigationTitle("Text Effects")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { replay() }
    }

    // MARK: Stage Card

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Stage", systemImage: "wand.and.sparkles").font(.headline)
                Spacer()
                if effect.isOneShot {
                    Button {
                        replay()
                    } label: {
                        Label("Replay", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                    }
                }
            }

            ZStack {
                stagedText
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Picker("Effect", selection: $effect) {
                ForEach(Effect.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: effect) {
                replay()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var baseText: Text {
        Text(sampleText.isEmpty ? "Glyphs that move" : sampleText)
            .font(.system(size: 34, weight: .semibold, design: .rounded))
    }

    @ViewBuilder
    private var stagedText: some View {
        switch effect {
        case .none:
            baseText
                .multilineTextAlignment(.center)
                .padding(20)
        case .blurIn:
            baseText
                .multilineTextAlignment(.center)
                .padding(20)
                .textRenderer(RevealRenderer(progress: progress, blurred: true, lift: intensity))
        case .rise:
            baseText
                .multilineTextAlignment(.center)
                .padding(20)
                .textRenderer(RevealRenderer(progress: progress, blurred: false, lift: intensity))
        case .wave:
            TimelineView(.animation) { timeline in
                baseText
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .textRenderer(WaveRenderer(
                        time: timeline.date.timeIntervalSinceReferenceDate * speed,
                        amplitude: intensity
                    ))
            }
        case .shimmer:
            TimelineView(.animation) { timeline in
                baseText
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .textRenderer(ShimmerRenderer(
                        phase: shimmerPhase(at: timeline.date.timeIntervalSinceReferenceDate)
                    ))
            }
        }
    }

    private func shimmerPhase(at time: TimeInterval) -> Double {
        let cycle = 2.2 / max(speed, 0.1)
        let t = time.truncatingRemainder(dividingBy: cycle) / cycle
        // Overshoot both ends so the highlight fully exits before looping.
        return t * 1.5 - 0.25
    }

    private func replay() {
        guard effect.isOneShot else { return }
        progress = 0
        withAnimation(.easeOut(duration: 1.8 / max(speed, 0.1))) {
            progress = 1
        }
    }

    // MARK: Controls Card

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Controls", systemImage: "slider.horizontal.3").font(.headline)

            TextField("Sample text", text: $sampleText)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Speed").font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f×", speed)).font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                Slider(value: $speed, in: 0.3...2.5)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Intensity").font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f", intensity)).font(.mono(.caption2)).foregroundStyle(.secondary)
                }
                Slider(value: $intensity, in: 2...14)
            }

            Text("Intensity drives blur radius and lift for the reveals, and wave amplitude for the ambient effects.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Anatomy Card

    private var anatomyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How TextRenderer Works", systemImage: "list.bullet.rectangle").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                apiRow("Text.Layout", "Lines → runs → run slices; a slice is roughly one glyph")
                apiRow("context.draw(slice)", "Draw each slice through its own copied GraphicsContext — offset, blur, and fade compose per glyph")
                apiRow("Animatable", "A renderer with animatableData interpolates inside withAnimation — that's the whole replay button")
                apiRow("TimelineView(.animation)", "Ambient effects skip Animatable and derive phase from the frame clock")
            }

            Text("UIKit's equivalent trick is rendering each TextKit 2 NSTextLayoutFragment into its own CALayer and animating the layers — same idea, more plumbing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func apiRow(_ api: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(api).font(.caption.monospaced()).foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Layout helpers

private extension Text.Layout {
    var allSlices: [Text.Layout.RunSlice] {
        flatMap { line in
            line.flatMap { run in
                run.map { $0 }
            }
        }
    }
}

// MARK: - Renderers

/// One-shot staggered reveal: each glyph fades in with an optional blur
/// and a vertical lift, delayed by its position in the string.
private struct RevealRenderer: TextRenderer, Animatable {
    var progress: Double
    var blurred: Bool
    var lift: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.allSlices
        let count = max(slices.count, 1)
        for (index, slice) in slices.enumerated() {
            let delay = Double(index) / Double(count) * 0.65
            let t = min(max((progress - delay) / 0.35, 0), 1)
            var copy = context
            copy.opacity = t
            if blurred {
                copy.addFilter(.blur(radius: (1 - t) * lift * 0.8))
            } else {
                copy.translateBy(x: 0, y: (1 - t) * lift)
            }
            copy.draw(slice)
        }
    }
}

/// Ambient sine wave: every glyph bobs, phase-shifted by its index.
private struct WaveRenderer: TextRenderer {
    var time: Double
    var amplitude: Double

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for (index, slice) in layout.allSlices.enumerated() {
            let phase = time * 2.4 - Double(index) * 0.45
            var copy = context
            copy.translateBy(x: 0, y: sin(phase) * amplitude * 0.5)
            copy.draw(slice)
        }
    }
}

/// A brightness highlight sweeping left to right across the glyphs.
private struct ShimmerRenderer: TextRenderer {
    var phase: Double

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let slices = layout.allSlices
        guard !slices.isEmpty else { return }
        let minX = slices.map { $0.typographicBounds.rect.minX }.min() ?? 0
        let maxX = slices.map { $0.typographicBounds.rect.maxX }.max() ?? 1
        let sweepX = minX + (maxX - minX) * phase

        for slice in slices {
            let distance = abs(slice.typographicBounds.rect.midX - sweepX)
            let boost = max(0, 1 - distance / 70)
            var copy = context
            copy.opacity = 0.5 + 0.5 * boost
            copy.addFilter(.brightness(0.45 * boost))
            copy.draw(slice)
        }
    }
}

#Preview {
    NavigationStack { TextEffectsView() }
}
