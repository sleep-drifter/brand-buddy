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

import PhotosUI
import SwiftUI

struct OscillaLabView: View {

    // MARK: - State

    @State private var patch: OscillaPatch = OscillaFactory.drift
    @State private var perf = OscillaPerformance(patch: OscillaFactory.drift)
    private let startDate = Date()        // Float-precision rule
    @State private var tapPoint: CGPoint?
    /// The user's photo for needsPhoto patches. KEPT across patch switches —
    /// only needsPhoto patches read it, everything else ignores it.
    @State private var photo: UIImage?
    @State private var photoItem: PhotosPickerItem?
    /// The latest paint sample for the stateful (fluid) hero; reset on patch
    /// switch so a stroke never leaks across instruments.
    @State private var fluidBrush = OscillaFluidBrush(location: .zero, last: nil, isDown: false)
    @State private var showBench = false
    @StateObject private var haptics = HapticStudioEngine()
    @StateObject private var capture = OscillaCaptureController()
    @Environment(\.scenePhase) private var scenePhase
    /// The last exported clip URL, stashed so the share sheet's onDismiss can
    /// delete the file even after .sheet(item:) has already nilled exportedClip.
    @State private var lastClipURL: URL?

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showBench = true } label: { Image(systemName: "slider.horizontal.3") }
            }
        }
        .sheet(isPresented: $showBench) {
            OscillaBenchView(patch: $patch)
                .presentationDetents([.fraction(0.45), .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $capture.exportedClip, onDismiss: cleanUpSharedClip) { clip in
            ActivityViewController(activityItems: [clip.url], applicationActivities: nil)
                .ignoresSafeArea()
        }
        .onChange(of: capture.exportedClip?.url) { _, newURL in
            if let newURL { lastClipURL = newURL }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Only on real backgrounding: .inactive also fires for system
            // alerts OVER the scene — including ReplayKit's own consent alert
            // on the first arm and the photo-add alert from "Save Video" —
            // and disarming there would kill the very capture being set up.
            // Every background transition still passes through .background.
            if newPhase == .background { capture.disarm() }
        }
        // Photo load (needsPhoto patches, house pattern): decode downsampled
        // via byPreparingThumbnail — size is in PIXELS, aspect-preserving,
        // and never materializes the full bitmap. (NOT UIGraphicsImageRenderer
        // with its default format: that inherits the 3x screen scale and
        // would upscale memory 9x.)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    photo = await ui.byPreparingThumbnail(
                        ofSize: CGSize(width: 2048, height: 2048)) ?? ui
                }
            }
        }
        .onAppear { haptics.start() }
        .onDisappear {
            haptics.stop()
            capture.disarm()
        }
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
            captureCaption
            footer
        }
    }

    // MARK: - Hero

    /// Full-width shader canvas, height 420, rounded 28 with a hairline
    /// border (dark canvas house style). Tapping aims circleWave/starNest;
    /// on a stateful patch the surface's own high-priority drag paints (and
    /// a sub-8pt drag aims Drop instead — see paintGesture). needsPhoto
    /// patches grow the photo picker overlays here: the capsule centered
    /// over the quiet black, the swap button top-LEADING (capture controls
    /// own top-trailing).
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
        .overlay(alignment: .topTrailing) {
            captureControls(elapsed: elapsed)
        }
        .overlay {
            if patch.needsPhoto && photo == nil {
                photoPickerCapsule
            }
        }
        .overlay(alignment: .topLeading) {
            if patch.needsPhoto && photo != nil {
                photoSwapButton
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { location in
            tapPoint = location
        }
    }

    /// One resolved frame: eval the patch + performance at this instant and
    /// hand the layer params to the renderer. A stateful (fluid) patch gets
    /// the live surface plus the painting drag; a fold patch renders at
    /// patch.renderScale (clamped 0.25–1) and is scaled back up to the hero.
    private func heroSurface(date: Date, elapsed: Double, size: CGSize) -> some View {
        let time = Float(elapsed)
        let params: [[Float]] = OscillaEval.layerParams(
            patch: patch, perf: perf, elapsed: elapsed, now: date)
        let surface: AnyView
        if patch.layers.first?.engine.isStateful == true {
            surface = statefulSurface(params: params, time: time, size: size)
        } else {
            surface = foldSurface(params: params, time: time, size: size)
        }
        return surface
            .frame(width: size.width, height: size.height)
    }

    /// The stateful (fluid) hero: rendered at the laid-out size (the MTKView
    /// owns its own resolution — renderScale is ignored) with the painting
    /// drag attached HERE, on the rendered surface INSIDE the GeometryReader,
    /// before the hero's overlays are applied — a high-priority drag on the
    /// outer hero would swallow the capture/share buttons' taps.
    private func statefulSurface(params: [[Float]], time: Float, size: CGSize) -> AnyView {
        let rendered: AnyView = OscillaRenderer.render(
            patch: patch, params: params, time: time, size: size,
            tap: tapPoint, baseImage: photo, fluid: fluidInput())
        return AnyView(rendered.highPriorityGesture(paintGesture()))
    }

    /// The fold (non-stateful) hero. renderScale < 1 renders a smaller copy
    /// and scales it back up: scaleEffect does not change layout bounds, so
    /// the hero's clipShape/contentShape/gestures stay in full-size space —
    /// only the size/tap passed into render() scale. Center anchor is
    /// required: .topLeading under the default centered outer frame would
    /// offset the raster and clip.
    private func foldSurface(params: [[Float]], time: Float, size: CGSize) -> AnyView {
        guard patch.renderScale < 1 else {
            return OscillaRenderer.render(
                patch: patch, params: params, time: time, size: size,
                tap: tapPoint, baseImage: photo)
        }
        let scale = min(max(patch.renderScale, 0.25), 1)
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let scaledTap = tapPoint.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
        let rendered: AnyView = OscillaRenderer.render(
            patch: patch, params: params, time: time, size: scaledSize,
            tap: scaledTap, baseImage: photo)
        return AnyView(rendered
            .frame(width: scaledSize.width, height: scaledSize.height)
            .scaleEffect(1 / scale, anchor: .center)   // center anchor + default
            .frame(width: size.width, height: size.height))  // centered frame maps exactly onto size
    }

    /// The fluid engine's live input. Drop/Rinse bind POSITIONALLY per the
    /// factory ordering contract — Drop = gates[0]/gateFires[0], Rinse =
    /// gates[1]/gateFires[1]. A stateful patch without both gates is a data
    /// bug: degrade to a fully inert input (`.distantPast` edge sentinels the
    /// coordinator ignores) instead of guessing at the wiring.
    private func fluidInput() -> OscillaFluidInput {
        guard patch.gates.count >= 2, perf.gateFires.count >= 2 else {
            return OscillaFluidInput(
                brush: OscillaFluidBrush(location: .zero, last: nil, isDown: false),
                drop: OscillaFluidDrop(fired: .distantPast, level: 0, point: nil),
                rinse: .distantPast)
        }
        let dropFire = perf.gateFires[0]
        let drop = OscillaFluidDrop(
            fired: dropFire.fired, level: dropFire.level, point: tapPoint)
        return OscillaFluidInput(
            brush: fluidBrush, drop: drop, rinse: perf.gateFires[1].fired)
    }

    /// The painting drag, stateful patches only: minimumDistance 0, HIGH
    /// priority — paint beats the lab ScrollView's pan, the same mechanism
    /// and rationale as OscillaKnob. The nil `last` on a stroke's first
    /// sample prevents a corner-to-finger ink jet (the coordinator maps a
    /// nil last to delta ZERO). onEnded drops the brush, and a gesture whose
    /// total travel stayed under ~8pt also aims Drop via tapPoint — the
    /// high-priority drag suppresses the hero's .onTapGesture on stateful
    /// patches, so tap aiming folds into the drag (the first onChanged
    /// sample remains the "dab"). Tradeoff, stated: on a stateful patch the
    /// hero owns its touches — scrolling the lab must start outside the hero
    /// (chips/knobs/gates below). NEVER .simultaneousGesture (vertical
    /// strokes would scroll + shear the stroke on the permanent-ink patch)
    /// and NEVER .scrollDisabled (the gate row falls below the fold on
    /// standard-height phones).
    private func paintGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                fluidBrush = OscillaFluidBrush(
                    location: value.location,
                    last: fluidBrush.isDown ? fluidBrush.location : nil,
                    isDown: true)
            }
            .onEnded { value in
                fluidBrush.isDown = false
                let travel = hypot(value.translation.width, value.translation.height)
                if travel < 8 {
                    tapPoint = value.location
                }
            }
    }

    // MARK: - Photo (needsPhoto patches)

    /// Centered glass invitation over the quiet black hero while a
    /// needsPhoto patch has no photo yet (the renderer early-outs to
    /// Color.black behind this).
    private var photoPickerCapsule: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Label("choose a photo", systemImage: "photo.on.rectangle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Small glass swap control once a photo is loaded — top-LEADING; the
    /// capture controls own the top-trailing corner.
    private var photoSwapButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Image(systemName: "photo.on.rectangle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
    }

    // MARK: - Patch chips

    private var patchChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OscillaFactory.all) { candidate in
                    patchChip(candidate)
                }
            }
            .padding(.horizontal, 2)
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
            // A stroke never leaks across instruments; `photo` is KEPT —
            // only needsPhoto patches read it.
            fluidBrush = OscillaFluidBrush(location: .zero, last: nil, isDown: false)
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
        let fire: (fired: Date, level: Float, velocity: Float)
        if i < perf.gateFires.count {
            fire = perf.gateFires[i]
        } else {
            fire = (fired: .distantPast, level: 0, velocity: 1)
        }
        let envelope = OscillaEval.gateEnvelope(
            gate, fired: fire.fired, level: fire.level,
            velocity: fire.velocity, now: date)
        return OscillaGatePad(
            label: gate.label,
            tint: patch.tint.color,
            onFire: { v in fireGate(i, velocity: v) },
            envelope: envelope
        )
    }

    /// Click-free retrigger: carry the envelope's current value into the new
    /// fire so the rise starts from where the fall left off (the carried
    /// level evaluates with the OLD fire's velocity). `velocity` is the new
    /// strike's force 0…1 (1 = bottom/hard, 0 = top/soft). Haptic only when
    /// the gate asks for one, scaled through the gate's velocityFloor the
    /// same way the envelope peak is — legacy gates (floor 1.0) keep
    /// full-strength haptics.
    private func fireGate(_ i: Int, velocity: Float) {
        guard i < patch.gates.count, i < perf.gateFires.count else { return }
        let old = perf.gateFires[i]
        let carried = OscillaEval.gateEnvelope(
            patch.gates[i], fired: old.fired, level: old.level,
            velocity: old.velocity, now: Date())
        perf.gateFires[i] = (fired: Date(), level: carried, velocity: velocity)
        let gate = patch.gates[i]
        if gate.hapticIntensity > 0 {
            var e = HapticStudioEvent.defaultTransient(at: 0)
            e.intensity = gate.hapticIntensity
                * (gate.velocityFloor + (1 - gate.velocityFloor) * velocity)
            haptics.preview(event: e)
        }
    }

    // MARK: - Capture

    /// Capture controls in the hero's top-trailing corner — deliberately
    /// small, the hero is the instrument. Hidden entirely (with the whole
    /// feature) while ReplayKit reports unavailable: simulator, or another
    /// recording already in flight.
    @ViewBuilder
    private func captureControls(elapsed: Double) -> some View {
        switch capture.phase {
        case .unavailable:
            EmptyView()
        case .idle:
            captureGlassButton(systemName: "record.circle") { capture.arm() }
                .padding(10)
        case .buffering:
            HStack(spacing: 8) {
                bufferingDot(elapsed: elapsed)
                captureGlassButton(systemName: "square.and.arrow.up") {
                    // Close the Bench first: with backgroundInteraction the
                    // save button is tappable at the small detent, and SwiftUI
                    // can't present the share sheet over a sibling sheet.
                    showBench = false
                    capture.saveClip()
                }
            }
            .padding(10)
        case .arming, .exporting:
            ProgressView()
                .controlSize(.small)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .padding(10)
        }
    }

    /// One small glass circle: ultra-thin material over the shader, plain
    /// button style so no system chrome fights the canvas.
    private func captureGlassButton(
        systemName: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    /// A subtle tint dot that breathes while the rolling buffer is live. The
    /// pulse is computed from elapsed — everything here re-renders every
    /// frame inside TimelineView anyway, so no repeatForever animation has
    /// to fight the frame clock.
    private func bufferingDot(elapsed: Double) -> some View {
        Circle()
            .fill(patch.tint.color)
            .frame(width: 7, height: 7)
            .opacity(0.45 + 0.3 * sin(elapsed * 2.4))
    }

    /// One line on the capture loop, next to the footer; hidden (with the
    /// whole feature) when ReplayKit is unavailable.
    @ViewBuilder
    private var captureCaption: some View {
        if capture.phase != .unavailable {
            Text("tap ◉ to arm · play · share the last 15s")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    /// Best-effort cleanup once the share sheet goes away. The URL comes from
    /// the stash, not capture.exportedClip — .sheet(item:) nils the item as
    /// part of dismissal, so reading it here would race.
    private func cleanUpSharedClip() {
        if let url = lastClipURL {
            capture.deleteClip(url)
            lastClipURL = nil
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
