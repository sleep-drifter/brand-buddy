// OscillaControls.swift — Oscilla Lab v0
//
// The performance surface of the Oscilla synth: the three custom-drawn
// controls the lab wires to OscillaEval. OscillaKnob is a vertical-drag ring
// knob whose orbiting "moon" visualizes modulation depth (LFOs + gates)
// pressing on the same params the knob owns. OscillaGatePad fires a gate
// envelope exactly once per press via a per-press latch, and glows with the
// live envelope value. OscillaPosePad taps to morph to a stored pose and
// holds to capture the current knobs into its slot, using one combined
// tap/long-press gesture so a completed hold never double-fires the tap.
// Everything is drawn with plain SwiftUI shapes — no SF Symbols — and styled
// for the dark canvas the hero sits on. No state of its own beyond gesture
// latches; all synth state lives in OscillaPerformance upstream.

import SwiftUI

// MARK: - Knob

/// Circular knob, vertical-drag to change, with the orbital modulation moon.
struct OscillaKnob: View {
    let label: String
    @Binding var value: Float          // 0–1
    var tint: Color
    var modulation: Float              // 0–1 → moon orbit radius/visibility (time-invariant; see OscillaEval.modulationAmount)
    var modPhase: Double               // drives moon angle: elapsed / period of the matching LFO; 0 when only a gate modulates

    /// Knob value at the moment the current drag began; nil when idle.
    @State private var dragStartValue: Float? = nil

    private static let diameter: CGFloat = 64
    private static let ringRadius: CGFloat = 32            // diameter / 2
    private static let sweep: CGFloat = 0.75               // 270° of the circle (135°…405°)
    private static let fullTravel: CGFloat = 160           // points of vertical drag for 0→1

    var body: some View {
        VStack(spacing: 8) {
            dial
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(Circle())
                // High priority so a vertical knob drag beats the enclosing
                // ScrollView's pan — an instrument's knobs must win over scroll.
                .highPriorityGesture(dragGesture)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dial: some View {
        ZStack {
            trackRing
            valueArc
            centerDot
            moon
        }
    }

    /// The full 270° travel, dim — always visible.
    private var trackRing: some View {
        Circle()
            .trim(from: 0, to: Self.sweep)
            .stroke(Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(135))
    }

    /// The lit arc from 135° up to 135° + 270°·value.
    private var valueArc: some View {
        let clamped = CGFloat(min(max(value, 0), 1))
        return Circle()
            .trim(from: 0, to: Self.sweep * clamped)
            .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(135))
    }

    private var centerDot: some View {
        Circle()
            .fill(tint.opacity(0.9))
            .frame(width: 6, height: 6)
    }

    /// 5pt moon orbiting at angle modPhase·2π; orbit radius lerps
    /// 0 → (ring radius + 7) with modulation. Hidden below 0.01.
    @ViewBuilder
    private var moon: some View {
        if modulation > 0.01 {
            let amount = CGFloat(min(max(modulation, 0), 1))
            let orbitRadius: CGFloat = amount * (Self.ringRadius + 7)
            let angle: Double = modPhase * 2 * Double.pi
            let offsetX: CGFloat = CGFloat(cos(angle)) * orbitRadius
            let offsetY: CGFloat = CGFloat(sin(angle)) * orbitRadius
            Circle()
                .fill(tint)
                .frame(width: 5, height: 5)
                .offset(x: offsetX, y: offsetY)
        }
    }

    /// Vertical drag, 160pt full travel. The drag's translation delta is
    /// tracked against a dragStartValue captured on the first onChanged, so
    /// the knob never jumps and repeated onChanged calls do not compound.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let start: Float
                if let captured = dragStartValue {
                    start = captured
                } else {
                    start = value
                    dragStartValue = start
                }
                let delta = Float(-drag.translation.height / Self.fullTravel)
                value = min(max(start + delta, 0), 1)
            }
            .onEnded { _ in
                dragStartValue = nil
            }
    }
}

// MARK: - Gate pad

/// Gate pad: large rounded square; press fires immediately — exactly once per
/// press, via a per-press latch. Visual glow/scale driven by the live
/// envelope value fed back from OscillaEval.gateEnvelope.
/// strike low = hard, high = soft — the pad is velocity-sensitive.
struct OscillaGatePad: View {
    let label: String
    var tint: Color
    var onFire: (Float) -> Void        // velocity 0–1 (1 = bottom/hard, 0 = top/soft)
    var envelope: Float                // live 0–1 from eval, drives glow

    /// Per-press latch: true from first touch until the finger lifts.
    @State private var pressed = false

    private static let cornerRadius: CGFloat = 20
    /// One constant for BOTH the frame and the velocity division — no drift.
    private static let height: CGFloat = 84

    var body: some View {
        let env = Double(min(max(envelope, 0), 1))
        return padFace(env: env)
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .scaleEffect(1 + 0.02 * CGFloat(env))
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .gesture(latchGesture)
    }

    private func padFace(env: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        let fillOpacity: Double = 0.08 + 0.3 * env
        let borderOpacity: Double = 0.22 + 0.6 * env
        let glowOpacity: Double = 0.65 * env
        let glowRadius: CGFloat = 4 + 16 * CGFloat(env)
        return shape
            .fill(tint.opacity(fillOpacity))
            .overlay(shape.strokeBorder(tint.opacity(borderOpacity), lineWidth: 1))
            .overlay(
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            )
            .shadow(color: tint.opacity(glowOpacity), radius: glowRadius)
    }

    /// Fires exactly once per press: the latch sets on the first onChanged
    /// and only clears when the finger lifts. Velocity is the vertical
    /// position of the first touch within the pad (the drag location is in
    /// the pad's own coordinate space), bottom = hard = 1.
    private var latchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if !pressed {
                    pressed = true
                    let v = min(max(Float(drag.location.y / Self.height), 0), 1)
                    onFire(v)
                }
            }
            .onEnded { _ in
                pressed = false
            }
    }
}

// MARK: - Pose pad

/// Pose pad: small rounded square, filled with tint when active. Tap morphs
/// to the pose; a 0.4s hold captures the current knobs into the slot. ONE
/// combined gesture — never separate .onTapGesture + .onLongPressGesture,
/// which double-fires the tap after a completed hold (the shipped
/// TapLongPressView pattern).
struct OscillaPosePad: View {
    let index: Int
    let name: String
    var tint: Color
    var isActive: Bool
    var onTap: () -> Void              // morph to this pose
    var onHold: () -> Void             // capture current knobs into this slot

    /// Brief scale pulse acknowledging a capture (hold).
    @State private var capturePulse = false

    private static let cornerRadius: CGFloat = 14

    var body: some View {
        padFace
            .frame(width: 72, height: 54)
            .scaleEffect(capturePulse ? 1.1 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .gesture(combinedGesture)
            .accessibilityLabel("Pose \(index + 1): \(name)")
    }

    private var padFace: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        let fill: Color = isActive ? tint.opacity(0.85) : Color.white.opacity(0.06)
        let border: Color = isActive ? tint : Color.white.opacity(0.15)
        let text: Color = isActive ? Color.white : Color.white.opacity(0.7)
        return shape
            .fill(fill)
            .overlay(shape.strokeBorder(border, lineWidth: 1))
            .overlay(
                Text(name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 6)
            )
    }

    private var combinedGesture: some Gesture {
        TapGesture()
            .simultaneously(with: LongPressGesture(minimumDuration: 0.4))
            .onEnded { value in
                if value.second == true {
                    onHold()
                    pulse()
                } else {
                    onTap()
                }
            }
    }

    private func pulse() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.55)) {
            capturePulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                capturePulse = false
            }
        }
    }
}

// MARK: - Previews

private struct OscillaKnobPreviewHost: View {
    @State private var weather: Float = 0.62
    @State private var warmth: Float = 0.35
    @State private var tide: Float = 0.2

    var body: some View {
        HStack(spacing: 32) {
            OscillaKnob(label: "Weather", value: $weather,
                        tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                        modulation: 0.4, modPhase: 0.35)
            OscillaKnob(label: "Warmth", value: $warmth,
                        tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                        modulation: 0, modPhase: 0)
            OscillaKnob(label: "Tide", value: $tide,
                        tint: Color(red: 0.35, green: 0.85, blue: 0.8),
                        modulation: 1, modPhase: 0.8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview("Knob") {
    OscillaKnobPreviewHost()
}

#Preview("Gate pad") {
    VStack(spacing: 24) {
        OscillaGatePad(label: "Bloom",
                       tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                       onFire: { _ in }, envelope: 0)
        OscillaGatePad(label: "Drop",
                       tint: Color(red: 0.35, green: 0.85, blue: 0.8),
                       onFire: { _ in }, envelope: 0.85)
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Pose pads") {
    HStack(spacing: 12) {
        OscillaPosePad(index: 0, name: "Dawn",
                       tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                       isActive: true, onTap: {}, onHold: {})
        OscillaPosePad(index: 1, name: "Noon",
                       tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                       isActive: false, onTap: {}, onHold: {})
        OscillaPosePad(index: 2, name: "Dusk",
                       tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                       isActive: false, onTap: {}, onHold: {})
        OscillaPosePad(index: 3, name: "Night",
                       tint: Color(red: 1.0, green: 0.72, blue: 0.35),
                       isActive: false, onTap: {}, onHold: {})
    }
    .padding(32)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
