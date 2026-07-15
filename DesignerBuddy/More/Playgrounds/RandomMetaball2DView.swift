import Combine
import SwiftUI

// MARK: - Model

private struct MetaParticle {
    var x: CGFloat        // position ratio, 0...1
    var y: CGFloat        // position ratio, 0...1
    var sizeSeed: CGFloat // 0...1; scaled live by the Size control
}

// MARK: - View

/// Random 2D metaballs built with SwiftUI's `Canvas` + `alphaThreshold`/`blur`
/// filters — no Metal. Randomly placed, randomly sized circles fade in and out on a
/// staggered timer; blurring their alpha and thresholding it fuses overlapping
/// circles into smooth liquid blobs with crisp edges.
///
/// Technique adapted from Koshimizu-Takehito/my-toybox (RandomMetaball2D).
struct RandomMetaball2DView: View {
    @State private var count:      Double = 50
    @State private var sizeFactor: Double = 0.4
    @State private var blur:       Double = 0.025
    @State private var threshold:  Double = 0.3
    @State private var hue:        Double = 0.83   // magenta, matching the concept art

    @State private var particles: [MetaParticle] = []
    @State private var scales: [Double] = []

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    private var color: Color { Color(hue: hue, saturation: 0.9, brightness: 1.0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                controls
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Random Metaball 2D") {
            preview
        }
        .navigationTitle("Random Metaball 2D")
        .onAppear {
            if particles.count != Int(count) { rebuild() } else { toggle() }
        }
        .onReceive(timer) { _ in toggle() }
    }

    // MARK: - Preview

    private var preview: some View {
        MetaballCanvas(particles: particles,
                       scales: scales,
                       color: color,
                       sizeFactor: sizeFactor,
                       blur: blur,
                       threshold: threshold)
            .frame(height: 240)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 0) {
            sliderRow("Particles", $count, range: 5...80, step: 1, value: "\(Int(count))")
            divider
            sliderRow("Size",      $sizeFactor, range: 0.1...0.6)
            divider
            sliderRow("Merge",     $blur, range: 0.005...0.06)
            divider
            sliderRow("Threshold", $threshold, range: 0.05...0.6)
            divider
            row {
                HStack(spacing: 12) {
                    Text("Hue").frame(width: 96, alignment: .leading)
                    Slider(value: $hue).tint(color)
                    Circle().fill(color).frame(width: 22, height: 22)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: count) { _, _ in rebuild() }
    }

    private var caption: some View {
        Text("No Metal here: randomly placed circles are drawn into a Canvas, their alpha "
             + "blurred so neighbours overlap, then \u{201C}alphaThreshold\u{201D} snaps "
             + "everything above the cutoff to solid colour — fusing them into liquid blobs. "
             + "A timer toggles each circle\u{2019}s scale with random delays. \u{201C}Merge\u{201D} "
             + "is the blur radius; \u{201C}Threshold\u{201D} is the alpha cutoff. Technique from "
             + "Koshimizu-Takehito\u{2019}s my-toybox.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Animation

    private func rebuild() {
        let n = Int(count)
        particles = (0..<n).map { _ in
            MetaParticle(x: .random(in: 0...1),
                         y: .random(in: 0...1),
                         sizeSeed: .random(in: 0...1))
        }
        scales = Array(repeating: 0, count: n)
        // Commit the zeroed scales first, then animate them in.
        DispatchQueue.main.async { toggle() }
    }

    private func toggle() {
        guard !scales.isEmpty else { return }
        for i in scales.indices {
            withAnimation(.easeInOut(duration: .random(in: 1...4)).delay(.random(in: 0...2))) {
                scales[i] = scales[i] == 0 ? 1 : 0
            }
        }
    }

    // MARK: - Helpers

    private func sliderRow(_ label: String,
                           _ value: Binding<Double>,
                           range: ClosedRange<Double> = 0...1,
                           step: Double = 0,
                           value valueText: String? = nil) -> some View {
        row {
            HStack(spacing: 12) {
                Text(label).frame(width: 96, alignment: .leading)
                if step > 0 {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                if let valueText {
                    Text(valueText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }
}

// MARK: - Canvas

/// The metaball renderer: draws circle symbols with a blur + alpha-threshold filter
/// stack so overlapping circles fuse. All symbols are drawn at centre and positioned
/// via `.position` inside the symbol (matching the reference implementation).
private struct MetaballCanvas: View {
    var particles: [MetaParticle]
    var scales: [Double]
    var color: Color
    var sizeFactor: Double
    var blur: Double
    var threshold: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let minDim = min(size.width, size.height)
            Canvas { context, canvasSize in
                context.addFilter(.alphaThreshold(min: threshold, color: color))
                context.addFilter(.blur(radius: blur * min(canvasSize.width, canvasSize.height)))
                context.drawLayer { layer in
                    let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    for i in particles.indices {
                        if let symbol = layer.resolveSymbol(id: i) {
                            layer.draw(symbol, at: center)
                        }
                    }
                }
            } symbols: {
                ForEach(particles.indices, id: \.self) { i in
                    let diameter = minDim * (0.04 + particles[i].sizeSeed * sizeFactor)
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .position(x: particles[i].x * size.width,
                                  y: particles[i].y * size.height)
                        .scaleEffect(scales.indices.contains(i) ? scales[i] : 0)
                        .tag(i)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RandomMetaball2DView()
    }
    .environmentObject(PinsStore())
}
