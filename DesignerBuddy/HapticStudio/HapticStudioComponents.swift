import SwiftUI

// MARK: - Layout constants

let kTimelineH: CGFloat    = 150
let kRulerH: CGFloat       = 22
let kMinChipH: CGFloat     = 8
let kMaxChipH: CGFloat     = 130  // kTimelineH - 20
let kTransientW: CGFloat   = 9

// MARK: - Timeline Event Chip

struct TimelineEventChip: View {
    @Binding var event: HapticStudioEvent
    let isSelected: Bool
    let timeScale: CGFloat

    @GestureState private var moveDelta: CGFloat = .zero
    @GestureState private var resizeDelta: CGFloat = .zero

    private var chipW: CGFloat {
        event.type == .continuous
            ? max(16, CGFloat(event.duration) * timeScale + resizeDelta)
            : kTransientW
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Canvas { ctx, size in
                chipShape(ctx: ctx, size: size)
            }
            .frame(width: chipW, height: kTimelineH)

            // Resize handle (continuous only)
            if event.type == .continuous {
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 3, height: 24)
                    .padding(.trailing, 5)
                    .contentShape(Rectangle().size(width: 28, height: kTimelineH))
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .updating($resizeDelta) { val, state, _ in
                                state = max(-CGFloat(event.duration) * timeScale + 16, val.translation.width)
                            }
                            .onEnded { val in
                                let dt = Double(val.translation.width / timeScale)
                                event.duration = max(0.05, event.duration + dt)
                            }
                    )
            }
        }
        .frame(height: kTimelineH)
        .offset(x: CGFloat(event.time) * timeScale + moveDelta)
        .gesture(
            DragGesture(minimumDistance: 4)
                .updating($moveDelta) { val, state, _ in state = val.translation.width }
                .onEnded { val in
                    let dt = Double(val.translation.width / timeScale)
                    event.time = max(0, event.time + dt)
                }
        )
        .animation(.interactiveSpring, value: isSelected)
    }

    private func chipShape(ctx: GraphicsContext, size: CGSize) {
        let col      = sharpnessColor(event.sharpness)
        let peakH    = kMinChipH + (kMaxChipH - kMinChipH) * CGFloat(event.intensity)
        // Tight hatching = high sharpness (crisp), wide = low sharpness (soft)
        let hSpacing: CGFloat = 3 + (1 - CGFloat(event.sharpness)) * 10

        // Build the envelope silhouette
        let path: Path
        if event.type == .continuous {
            let attackW  = min(size.width * 0.45, CGFloat(event.attackTime)  * timeScale)
            let releaseW = min(size.width * 0.45, CGFloat(event.releaseTime) * timeScale)
            let sustainW = max(0, size.width - attackW - releaseW)
            var p = Path()
            p.move(to:    CGPoint(x: 0,                        y: size.height))
            p.addLine(to: CGPoint(x: attackW,                  y: size.height - peakH))
            p.addLine(to: CGPoint(x: attackW + sustainW,       y: size.height - peakH))
            p.addLine(to: CGPoint(x: size.width,               y: size.height))
            p.closeSubpath()
            path = p
        } else {
            // Transient: narrow spike
            var p = Path()
            p.move(to:    CGPoint(x: 0,            y: size.height))
            p.addLine(to: CGPoint(x: size.width / 2, y: size.height - peakH))
            p.addLine(to: CGPoint(x: size.width,   y: size.height))
            p.closeSubpath()
            path = p
        }

        // 1. Subtle base fill so the shape reads against dark backgrounds
        ctx.fill(path, with: .color(col.opacity(0.18)))

        // 2. Diagonal hatch lines (clipped to shape) encode sharpness via density
        var hCtx = ctx
        hCtx.clip(to: path)
        var x: CGFloat = -size.height
        while x < size.width + size.height {
            var line = Path()
            line.move(to:    CGPoint(x: x,               y: 0))
            line.addLine(to: CGPoint(x: x + size.height, y: size.height))
            hCtx.stroke(line, with: .color(col.opacity(0.62)), lineWidth: 1)
            x += hSpacing
        }

        // 3. Outline — brighter when selected
        ctx.stroke(path, with: .color(col.opacity(isSelected ? 1.0 : 0.72)),
                   style: StrokeStyle(lineWidth: isSelected ? 2 : 1))
    }
}

// MARK: - Preset Mini Preview

struct PresetMiniWaveform: View {
    let preset: HapticPreset

    var body: some View {
        Canvas { ctx, size in
            let events = preset.events
            let total  = events.map { $0.time + ($0.type == .continuous ? $0.duration : 0.08) }.max() ?? 0.3

            for e in events {
                let col      = sharpnessColor(e.sharpness)
                let startX   = CGFloat(e.time / total) * size.width
                let peakH    = 3 + (size.height - 4) * CGFloat(e.intensity)
                let hSpacing: CGFloat = 2 + (1 - CGFloat(e.sharpness)) * 5

                let path: Path
                if e.type == .transient {
                    let w: CGFloat = 5
                    var p = Path()
                    p.move(to:    CGPoint(x: startX - w / 2, y: size.height))
                    p.addLine(to: CGPoint(x: startX,         y: size.height - peakH))
                    p.addLine(to: CGPoint(x: startX + w / 2, y: size.height))
                    p.closeSubpath()
                    path = p
                } else {
                    let bw = max(6, CGFloat(e.duration / total) * size.width)
                    var p = Path()
                    p.move(to:    CGPoint(x: startX,      y: size.height))
                    p.addLine(to: CGPoint(x: startX,      y: size.height - peakH))
                    p.addLine(to: CGPoint(x: startX + bw, y: size.height - peakH))
                    p.addLine(to: CGPoint(x: startX + bw, y: size.height))
                    p.closeSubpath()
                    path = p
                }

                ctx.fill(path, with: .color(col.opacity(0.18)))

                var hCtx = ctx
                hCtx.clip(to: path)
                var hx = startX - size.height
                while hx < startX + size.width + size.height {
                    var line = Path()
                    line.move(to:    CGPoint(x: hx,               y: 0))
                    line.addLine(to: CGPoint(x: hx + size.height, y: size.height))
                    hCtx.stroke(line, with: .color(col.opacity(0.7)), lineWidth: 0.8)
                    hx += hSpacing
                }

                ctx.stroke(path, with: .color(col.opacity(0.85)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Inspector Panel

struct InspectorPanel: View {
    @Binding var event: HapticStudioEvent
    let engine: HapticStudioEngine
    let onClose: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle

            VStack(spacing: 10) {
                headerRow
                Divider()
                intensityRow
                sharpnessRow
                if event.type == .continuous {
                    durationRow
                    envelopeRows
                }
                deleteRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: Sub-rows

    private var handle: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private var headerRow: some View {
        HStack {
            Circle()
                .fill(sharpnessColor(event.sharpness))
                .frame(width: 10, height: 10)
            Label(event.type == .transient ? "Transient" : "Continuous",
                  systemImage: event.type == .transient ? "bolt" : "waveform")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button { engine.preview(event: event) } label: {
                Label("Preview", systemImage: "play.circle").font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button { onClose() } label: { Image(systemName: "xmark").font(.caption) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
        .padding(.top, 4)
    }

    private var intensityRow: some View {
        HStack(spacing: 10) {
            Text("Intensity")
                .font(.caption).foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Slider(value: Binding(get: { Double(event.intensity) }, set: { event.intensity = Float($0) }), in: 0...1)
                .tint(sharpnessColor(event.sharpness))
            // Mini height bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2).fill(Color(.tertiarySystemFill)).frame(width: 7, height: 22)
                RoundedRectangle(cornerRadius: 2).fill(sharpnessColor(event.sharpness))
                    .frame(width: 7, height: max(2, 22 * CGFloat(event.intensity)))
            }
            Text(String(format: "%.2f", event.intensity))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var sharpnessRow: some View {
        HStack(spacing: 10) {
            Text("Sharpness")
                .font(.caption).foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Slider(value: Binding(get: { Double(event.sharpness) }, set: { event.sharpness = Float($0) }), in: 0...1)
                .tint(sharpnessColor(event.sharpness))
            // Color swatch
            Circle()
                .fill(sharpnessColor(event.sharpness))
                .frame(width: 14, height: 14)
            Text(String(format: "%.2f", event.sharpness))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var durationRow: some View {
        HStack(spacing: 10) {
            Text("Duration")
                .font(.caption).foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Slider(value: $event.duration, in: 0.02...5)
                .tint(.secondary)
            Text(String(format: "%.2fs", event.duration))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .frame(width: 46, alignment: .trailing)
        }
    }

    private var envelopeRows: some View {
        Group {
            Text("ENVELOPE").font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            envelopeSlider("Attack",  value: Binding(get: { Double(event.attackTime) },  set: { event.attackTime  = Float($0) }))
            envelopeSlider("Decay",   value: Binding(get: { Double(event.decayTime) },   set: { event.decayTime   = Float($0) }))
            envelopeSlider("Release", value: Binding(get: { Double(event.releaseTime) }, set: { event.releaseTime = Float($0) }))
        }
    }

    private func envelopeSlider(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Slider(value: value, in: 0...1).tint(.secondary)
            Text(String(format: "%.2f", value.wrappedValue))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var deleteRow: some View {
        Button(role: .destructive, action: onDelete) {
            Text("Delete Event").frame(maxWidth: .infinity).font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.red)
        .padding(.top, 2)
    }
}
