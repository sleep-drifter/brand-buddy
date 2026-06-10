import SwiftUI

// MARK: - SnapHUDView
//
// Debug overlay that surfaces snap velocity statistics in real-time.
// Toggle visibility with a long-press on the timeline (each studio uses its own
// @AppStorage key: "showSnapHUD_keyframe" / "showSnapHUD_haptic").

struct SnapHUDView: View {
    let velocity:    CGFloat
    let velocityMin: CGFloat
    let velocityMax: CGFloat
    let threshold:   CGFloat
    let isSnapping:  Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isSnapping ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(isSnapping ? "SNAPPED" : "free")
                    .font(.caption2.monospaced())
            }
            Text("vel:    \(velocity,    specifier: "%.1f") pt/s").font(.caption2.monospaced())
            Text("min:    \(velocityMin, specifier: "%.1f") pt/s").font(.caption2.monospaced())
            Text("max:    \(velocityMax, specifier: "%.1f") pt/s").font(.caption2.monospaced())
            Text("thresh: \(threshold,   specifier: "%.1f") pt/s").font(.caption2.monospaced())
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
