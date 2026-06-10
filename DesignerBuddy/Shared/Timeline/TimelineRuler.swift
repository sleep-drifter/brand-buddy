import SwiftUI

// MARK: - TimelineRuler
//
// Adaptive Canvas-based ruler shared by KeyframeStudio and HapticStudio.
// The playhead is fixed at the horizontal centre; content scrolls via scrollOffset.
// Tick density and label granularity adapt to the current zoom level automatically.

struct TimelineRuler: View {
    let timeScale:    CGFloat  // pts per second
    let scrollOffset: CGFloat  // pts from t=0 to the playhead centre
    let maxDuration:  Double   // hard end marker (e.g. 5.0 for both studios)

    var body: some View {
        Canvas { ctx, size in
            guard timeScale > 0 else { return }

            let zeroX = size.width / 2 - scrollOffset
            let endX  = size.width / 2 + CGFloat(maxDuration) * timeScale - scrollOffset

            // Hatching outside the valid [0, maxDuration] window
            for (from, to) in [(CGFloat(0), min(zeroX, size.width)),
                               (max(endX, 0), size.width)] {
                guard to > from + 0.5 else { continue }
                let rect = CGRect(x: from, y: 0, width: to - from, height: size.height)
                ctx.fill(Path(rect), with: .color(.primary.opacity(0.07)))
                var clipped = ctx
                clipped.clip(to: Path(rect))
                let spacing: CGFloat = 9
                var k = from - size.height
                while k < to + size.height {
                    var ln = Path()
                    ln.move(to:    CGPoint(x: k,               y: 0))
                    ln.addLine(to: CGPoint(x: k + size.height, y: size.height))
                    clipped.stroke(ln, with: .color(.primary.opacity(0.1)), lineWidth: 1)
                    k += spacing
                }
            }

            // Adaptive tick step — only draw ticks that will be ≥ 3 pts apart
            let step: Double = timeScale * 0.05 >= 3 ? 0.05
                             : timeScale * 0.25 >= 3 ? 0.25
                             : 0.5

            // Adaptive label interval — show finer labels only when ≥ 40 pts apart
            let labelIntervalMs: Int = CGFloat(0.25) * timeScale >= 40 ? 250
                                     : CGFloat(0.5)  * timeScale >= 40 ? 500
                                     : 1000

            let tLeft: Double = Double((scrollOffset - size.width / 2) / timeScale)
            var t = max(0.0, floor(tLeft / step) * step)

            while t <= maxDuration + step * 0.01 {
                let x = size.width / 2 + CGFloat(t) * timeScale - scrollOffset
                guard x >= -1 && x <= size.width + 1 else { t += step; continue }

                let ms      = Int((t * 1000).rounded())
                let isWhole = ms % 1000 == 0
                let isLabel = ms % labelIntervalMs == 0

                var tick = Path()
                tick.move(to:    .init(x: x, y: 0))
                tick.addLine(to: .init(x: x, y: size.height))

                if isWhole {
                    ctx.stroke(tick, with: .color(.secondary.opacity(0.35)), lineWidth: 1.5)
                } else {
                    ctx.stroke(tick, with: .color(.secondary.opacity(0.18)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                if isLabel {
                    let lbl = isWhole ? (ms == 0 ? "0s" : "\(ms / 1000)s") : "\(ms)ms"
                    ctx.draw(
                        Text(lbl).font(.system(size: 9)).foregroundColor(.secondary),
                        at: .init(x: x + 3, y: 3), anchor: .topLeading
                    )
                }

                t += step
            }

            // Hard end marker
            if endX >= 0 && endX <= size.width {
                var ep = Path()
                ep.move(to:    .init(x: endX, y: 0))
                ep.addLine(to: .init(x: endX, y: size.height))
                ctx.stroke(ep, with: .color(.primary.opacity(0.5)), lineWidth: 2)
                let endLabel = maxDuration == Double(Int(maxDuration))
                    ? "\(Int(maxDuration))s"
                    : String(format: "%.1fs", maxDuration)
                ctx.draw(
                    Text(endLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.6)),
                    at: .init(x: endX + 3, y: 3), anchor: .topLeading
                )
            }
        }
    }
}
