// OscillaLabView.swift — Oscilla Lab v0
//
// The lab itself: assembly of the whole synth. Owns the live performance
// state (@State patch + OscillaPerformance), drives the per-frame loop with
// TimelineView(.animation), and wires the pieces together — the hero canvas
// (OscillaRenderer folding the patch's layer stack at params resolved by
// OscillaEval), the patch chips, the pose pads (tap = morph, hold = capture),
// the knob row (bindings that bake an in-flight morph on grab), and the gate
// pad (click-free retrigger + a transient haptic through HapticStudioEngine).
// ScrollView lab archetype, dark canvas house style; elapsed time always
// comes from a stored startDate so Float never sees reference-date magnitudes.

import SwiftUI

struct OscillaLabView: View {

    // MARK: - State

    @State private var patch: OscillaPatch = OscillaFactory.drift
    @State private var perf = OscillaPerformance(patch: OscillaFactory.drift)
    private let startDate = Date()        // Float-precision rule
    @State private var tapPoint: CGPoint?
    @StateObject private var haptics = HapticStudioEngine()

    // MARK: - Body

    var body: some View {
        ScrollView {
            TimelineView(.animation) { tl in
                labStack(date: tl.date)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Oscilla Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { haptics.start() }
        .onDisappear { haptics.stop() }
    }

    /// Everything time-driven lives inside the TimelineView closure so the
    /// hero, the knob arcs (which track morphs), and the gate glow all share
    /// one frame clock.
    private func labStack(date: Date) -> some View {
        let elapsed = date.timeIntervalSince(startDate)
        return VStack(alignment: .leading, spacing: 20) {
            hero(date: date, elapsed: elapsed)
            patchChips
            poseRow
            knobRow(date: date, elapsed: elapsed)
            gateRow(date: date)
            footer
        }
    }

    // MARK: - Hero

    /// Full-width shader canvas, height 420, rounded 28 with a hairline
    /// border (dark canvas house style). Tapping aims circleWave/starNest.
    private func hero(date: Date, elapsed: Double) -> some View {
        GeometryReader { geo in
            heroSurface(date: date, elapsed: elapsed, size: geo.size)
        }
        .frame(height: 420)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { location in
            tapPoint = location
        }
    }

    /// One resolved frame: eval the patch + performance at this instant and
    /// hand the layer params to the renderer. v0 renders at the laid-out
    /// size; patch.renderScale is reserved for thermal tuning.
    private func heroSurface(date: Date, elapsed: Double, size: CGSize) -> some View {
        let time = Float(elapsed)
        let params: [[Float]] = OscillaEval.layerParams(
            patch: patch, perf: perf, elapsed: elapsed, now: date)
        let rendered: AnyView = OscillaRenderer.render(
            patch: patch, params: params, time: time, size: size, tap: tapPoint)
        return rendered
            .frame(width: size.width, height: size.height)
    }

    // MARK: - Patch chips

    private var patchChips: some View {
        HStack(spacing: 8) {
            ForEach(OscillaFactory.all) { candidate in
                patchChip(candidate)
            }
        }
    }

    private func patchChip(_ candidate: OscillaPatch) -> some View {
        let isSelected = candidate.id == patch.id
        let tint = candidate.tint.color
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Button {
            selectPatch(candidate)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? tint : Color.primary)
                Text(candidate.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: shape)
            .overlay {
                shape.strokeBorder(isSelected ? tint.opacity(0.7) : Color.white.opacity(0.08))
            }
        }
        .buttonStyle(.plain)
    }

    private func selectPatch(_ newPatch: OscillaPatch) {
        guard newPatch.id != patch.id else { return }
        withAnimation(.spring) {
            patch = newPatch
            perf = OscillaPerformance(patch: newPatch)
            tapPoint = nil
        }
    }

    // MARK: - Pose row

    private var poseRow: some View {
        HStack(spacing: 12) {
            ForEach(patch.poses.indices, id: \.self) { i in
                posePad(index: i)
            }
            Spacer(minLength: 0)
        }
    }

    private func posePad(index i: Int) -> some View {
        let pose = patch.poses[i]
        return OscillaPosePad(
            index: i,
            name: pose.name,
            tint: patch.tint.color,
            isActive: perf.activePose == i,
            onTap: { morphToPose(i) },
            onHold: { capturePose(i) }
        )
    }

    /// Tap: morph from the live (possibly mid-morph) knob values to the pose.
    private func morphToPose(_ i: Int) {
        guard i < patch.poses.count else { return }
        perf.morph = OscillaPerformance.Morph(
            from: OscillaEval.knobValues(perf: perf, at: Date()),
            to: patch.poses[i].knobValues,
            start: Date())
        perf.activePose = i
    }

    /// Hold: capture the current eval'd knob values into this pose slot.
    /// `patch` is the view's @State copy of the factory patch, so the
    /// overwrite lives only in this session.
    private func capturePose(_ i: Int) {
        guard i < patch.poses.count else { return }
        patch.poses[i].knobValues = OscillaEval.knobValues(perf: perf, at: Date())
    }

    // MARK: - Knob row

    /// Rendered inside the TimelineView closure so the value arcs track an
    /// active morph frame by frame.
    private func knobRow(date: Date, elapsed: Double) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(patch.knobs.indices, id: \.self) { i in
                knobView(index: i, date: date, elapsed: elapsed)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func knobView(index i: Int, date: Date, elapsed: Double) -> some View {
        let spec = patch.knobs[i]
        let modulation = OscillaEval.modulationAmount(
            onKnob: i, patch: patch, perf: perf, elapsed: elapsed, now: date)
        let phase = modPhase(forKnob: i, elapsed: elapsed)
        return OscillaKnob(
            label: spec.label,
            value: knobBinding(index: i, date: date),
            tint: patch.tint.color,
            modulation: modulation,
            modPhase: phase
        )
    }

    /// Read: the live morphed value. Write (grab): bake the morph into
    /// perf.knobs, cancel it, then set the knob. No state mutation on the
    /// read path.
    private func knobBinding(index i: Int, date: Date) -> Binding<Float> {
        Binding(
            get: {
                let values = OscillaEval.knobValues(perf: perf, at: date)
                guard i < values.count else { return 0 }
                return values[i]
            },
            set: { newValue in
                perf.knobs = OscillaEval.knobValues(perf: perf, at: Date())
                perf.morph = nil
                perf.activePose = nil
                guard i < perf.knobs.count else { return }
                perf.knobs[i] = newValue
            }
        )
    }

    /// Moon angle driver: elapsed / period of the first LFO sharing a
    /// (layer, param) with this knob's targets; 0 when only a gate (or
    /// nothing) modulates it.
    private func modPhase(forKnob i: Int, elapsed: Double) -> Double {
        guard i < patch.knobs.count else { return 0 }
        let knobTargets = patch.knobs[i].targets
        for lfo in patch.lfos where lfo.period > 0 {
            if sharesAnyTarget(lfo.targets, knobTargets) {
                return elapsed / lfo.period
            }
        }
        return 0
    }

    /// True when any (layer, param) pair appears in both target lists.
    private func sharesAnyTarget(_ lhs: [ParamTarget], _ rhs: [ParamTarget]) -> Bool {
        for a in lhs {
            for b in rhs where a.layer == b.layer && a.param == b.param {
                return true
            }
        }
        return false
    }

    // MARK: - Gate row

    private func gateRow(date: Date) -> some View {
        HStack(spacing: 12) {
            ForEach(patch.gates.indices, id: \.self) { i in
                gateView(index: i, date: date)
            }
        }
    }

    private func gateView(index i: Int, date: Date) -> some View {
        let gate = patch.gates[i]
        let fire: (fired: Date, level: Float)
        if i < perf.gateFires.count {
            fire = perf.gateFires[i]
        } else {
            fire = (fired: .distantPast, level: 0)
        }
        let envelope = OscillaEval.gateEnvelope(
            gate, fired: fire.fired, level: fire.level, now: date)
        return OscillaGatePad(
            label: gate.label,
            tint: patch.tint.color,
            onFire: { fireGate(i) },
            envelope: envelope
        )
    }

    /// Click-free retrigger: carry the envelope's current value into the new
    /// fire so the rise starts from where the fall left off. Haptic only when
    /// the gate asks for one.
    private func fireGate(_ i: Int) {
        guard i < patch.gates.count, i < perf.gateFires.count else { return }
        let old = perf.gateFires[i]
        let carried = OscillaEval.gateEnvelope(
            patch.gates[i], fired: old.fired, level: old.level, now: Date())
        perf.gateFires[i] = (fired: Date(), level: carried)
        if patch.gates[i].hapticIntensity > 0 {
            var e = HapticStudioEvent.defaultTransient(at: 0)
            e.intensity = patch.gates[i].hapticIntensity
            haptics.preview(event: e)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("a patch is an instrument — OSCILLA.md")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { OscillaLabView() }
}
