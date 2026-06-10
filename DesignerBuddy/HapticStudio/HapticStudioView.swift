import SwiftUI
import CoreHaptics

// MARK: - Add Menu State

private enum AddMenuState: Equatable {
    case idle
    case pressing
    case dragging(start: CGPoint, current: CGPoint)
}

// MARK: - Root

struct HapticStudioView: View {
    @StateObject private var engine = HapticStudioEngine()
    @State private var pattern   = HapticPattern()
    @State private var selectedEventID: UUID? = nil
    @State private var showingExport = false
    @State private var showingClearAlert = false

    // Add-event menu
    @GestureState private var addMenuState: AddMenuState = .idle
    @State private var timelineW: CGFloat = 390

    // Timeline transform
    @State private var timeScale: CGFloat = 0           // set on first layout to viewWidth/5
    @State private var scrollOffset: CGFloat = 0        // pts from t=0 to playhead center
    @GestureState private var dragDelta: CGFloat = 0    // live pts during finger drag
    @GestureState private var pinchDelta: CGFloat = 1.0 // live scale during pinch

    // Snap HUD
    @AppStorage("showSnapHUD_haptic") private var showSnapHUD = false
    @State private var hudVelocity: CGFloat    = 0
    @State private var hudVelocityMin: CGFloat = 0
    @State private var hudVelocityMax: CGFloat = 0
    @State private var hudIsSnapping: Bool     = false
    @State private var hudVisible: Bool        = false
    @State private var hudHideTask: Task<Void, Never>? = nil

    // Playback
    @State private var isPlaying = false
    @State private var playTimer: Timer? = nil

    // Derived — the scale and content-shift used for all rendering this frame
    private var liveScale: CGFloat  { timeScale == 0 ? 0 : min(300, max(20, timeScale * pinchDelta)) }
    private var liveOffset: CGFloat {
        let maxOffset = CGFloat(kPatternDuration) * liveScale
        return max(0, min(maxOffset, (scrollOffset - dragDelta) * pinchDelta))
    }

    // Current playhead time in seconds
    private var playheadTime: Double { Double(liveOffset / liveScale) }

    // MARK: – Snap helpers

    private var snapPoints: [Double] {
        var pts = Set<Double>()
        for e in pattern.events {
            pts.insert(e.time)
            if e.type == .continuous { pts.insert(e.time + e.duration) }
        }
        return pts.sorted()
    }

    private func isEventActive(_ event: HapticStudioEvent, at t: Double) -> Bool {
        if event.type == .transient { return abs(t - event.time) < 0.05 }
        return t >= event.time && t < event.time + event.duration
    }

    /// Instantaneous intensity of `event` at time `t`, respecting attack/release envelope.
    private func liveIntensity(_ event: HapticStudioEvent, at t: Double) -> Double {
        guard isEventActive(event, at: t) else { return 0 }
        if event.type == .transient { return Double(event.intensity) }
        let localT       = t - event.time
        let attackSec    = Double(event.attackTime)
        let releaseSec   = Double(event.releaseTime)
        let releaseStart = event.duration - releaseSec
        if localT < attackSec && attackSec > 0 {
            return Double(event.intensity) * (localT / attackSec)
        } else if localT >= releaseStart && releaseSec > 0 {
            return Double(event.intensity) * max(0, 1 - (localT - releaseStart) / releaseSec)
        }
        return Double(event.intensity)
    }

    /// The event with highest live intensity at `t`, used for the live-values pill.
    private func dominantEvent(at t: Double) -> HapticStudioEvent? {
        pattern.events
            .filter { isEventActive($0, at: t) }
            .max { liveIntensity($0, at: t) < liveIntensity($1, at: t) }
    }

    // MARK: – Selected event binding

    private var selectedEvent: Binding<HapticStudioEvent>? {
        guard let id = selectedEventID,
              let idx = pattern.events.firstIndex(where: { $0.id == id })
        else { return nil }
        return $pattern.events[idx]
    }

    var body: some View {
        VStack(spacing: 0) {
            timelineLane.frame(height: kRulerH + kTimelineH)
            Divider()
            presetStrip
            Divider()

            if let binding = selectedEvent {
                InspectorPanel(event: binding, engine: engine) {
                    withAnimation(.spring(duration: 0.25)) { selectedEventID = nil }
                } onDelete: {
                    pattern.events.removeAll { $0.id == binding.id }
                    selectedEventID = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                Divider()
            }

            bottomBar
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: addMenuState) { _, newValue in
            if case .pressing = newValue {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .animation(.spring(duration: 0.25), value: selectedEventID != nil)
        .navigationTitle("Haptic Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingExport = true } label: { Image(systemName: "square.and.arrow.up") }
                    .disabled(pattern.events.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showingClearAlert = true } label: { Image(systemName: "trash") }
                    .disabled(pattern.events.isEmpty)
            }
        }
        .sheet(isPresented: $showingExport) { ExportSheet(ahapString: pattern.toAHAPString()) }
        .alert("Clear Timeline", isPresented: $showingClearAlert) {
            Button("Remove All", role: .destructive) {
                withAnimation {
                    pattern.events.removeAll()
                    for i in pattern.curves.indices { pattern.curves[i].controlPoints.removeAll() }
                    selectedEventID = nil
                    scrollOffset    = 0
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all events from the timeline. This action cannot be undone.")
        }
        .onAppear  { engine.start() }
        .onDisappear { engine.stop(); stopTimer() }
    }

    // MARK: – Preset Strip

    private var presetStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HapticPreset.allCases, id: \.self) { preset in
                    Button { insertPreset(preset) } label: {
                        VStack(spacing: 4) {
                            PresetMiniWaveform(preset: preset)
                                .frame(width: 54, height: 28)
                                .background(Color(.secondarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 7))
                            Text(preset.label).font(.system(size: 10, weight: .medium)).foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: – Timeline Lane
    //
    // The playhead is a fixed line at the horizontal center of the view.
    // Content is drawn offset so that time=0 appears at (center - scrollOffset).
    // Dragging pans the content; pinching scales around the playhead.
    // During playback, scrollOffset is driven by the timer at timeScale pts/sec.

    private var timelineLane: some View {
        GeometryReader { geo in
            let vw      = geo.size.width
            let scale   = liveScale > 0 ? liveScale : vw / 5
            let offset  = liveOffset
            let originX = vw / 2 - offset

            // Outer ZStack is NOT clipped — lets the add-event menu float above the lane
            ZStack(alignment: .topLeading) {

                // Inner ZStack is clipped — keeps event chips inside the lane
                ZStack(alignment: .topLeading) {
                    // Background — tap to play, long press to add
                    Color(.systemGroupedBackground)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPlaying ? stopPlayback() : playFromStart() }
                        .gesture(addEventGesture(vw: vw, scale: scale, offset: offset))

                    // Ruler
                    TimelineRuler(timeScale: scale, scrollOffset: offset, maxDuration: kPatternDuration)
                        .frame(height: kRulerH + kTimelineH)
                        .allowsHitTesting(false)

                    // Events
                    ZStack(alignment: .leading) {
                        ForEach($pattern.events) { $event in
                            TimelineEventChip(
                                event: $event,
                                isSelected: selectedEventID == event.id,
                                isActive:   isEventActive(event, at: playheadTime),
                                timeScale:  scale,
                                snapPoints: snapPoints,
                                onDragChanged: { vel, vMin, vMax, snapping in
                                    hudVelocity    = vel
                                    hudVelocityMin = vMin
                                    hudVelocityMax = vMax
                                    hudIsSnapping  = snapping
                                    hudVisible     = true
                                    hudHideTask?.cancel()
                                    hudHideTask = Task {
                                        try? await Task.sleep(for: .seconds(2))
                                        guard !Task.isCancelled else { return }
                                        await MainActor.run { hudVisible = false }
                                    }
                                }
                            )
                            .onTapGesture { selectedEventID = event.id }
                        }
                    }
                    .offset(x: originX, y: kRulerH)

                    // Fixed playhead
                    Rectangle()
                        .fill(Color.red.opacity(0.9))
                        .frame(width: 2, height: kRulerH + kTimelineH)
                        .offset(x: vw / 2 - 1)
                        .allowsHitTesting(false)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: 10, height: 6)
                        .offset(x: vw / 2 - 5, y: 0)
                        .allowsHitTesting(false)
                }
                .clipShape(Rectangle())

                // Add-event menu — outside the clip so it can float upward freely
                if case .dragging(let anchor, let current) = addMenuState {
                    AddEventMenu(anchor: anchor, hovered: menuHovered(anchor: anchor, current: current))
                        .allowsHitTesting(false)
                }

                // Snap debug HUD — top-trailing corner, toggled by long-press
                if showSnapHUD && hudVisible {
                    SnapHUDView(
                        velocity:    hudVelocity,
                        velocityMin: hudVelocityMin,
                        velocityMax: hudVelocityMax,
                        threshold:   kHapticSnapVelocityThreshold,
                        isSnapping:  hudIsSnapping
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                // Live values pill — shows dominant intensity + sharpness at playhead while scrubbing
                if !isPlaying, let dominant = dominantEvent(at: playheadTime) {
                    liveValuesPill(for: dominant, at: playheadTime)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.leading, 12)
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .animation(.easeInOut(duration: 0.15), value: dominantEvent(at: playheadTime) != nil)
                }
            }
            // Scroll — suppressed while the add-event gesture is active
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($dragDelta) { val, state, _ in
                        guard case .idle = addMenuState else { return }
                        state = val.translation.width
                    }
                    .onEnded { val in
                        guard case .idle = addMenuState else { return }
                        scrollOffset = max(0, min(CGFloat(kPatternDuration) * timeScale,
                                                  scrollOffset - val.translation.width))
                    }
            )
            // Pinch to zoom
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($pinchDelta) { val, state, _ in state = val }
                    .onEnded { val in
                        let newScale = min(300, max(20, timeScale * val))
                        scrollOffset = CGFloat(playheadTime) * newScale
                        timeScale    = newScale
                    }
            )
            // Long-press (0.5s) toggles the snap debug HUD
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.2)) { showSnapHUD.toggle() }
                    }
            )
        }
        .onAppear {
            if timeScale == 0 { timeScale = timelineW / 5 }
        }
    }

    // MARK: – Add Event Gesture

    private func addEventGesture(vw: CGFloat, scale: CGFloat, offset: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .updating($addMenuState) { value, state, _ in
                switch value {
                case .first(true):
                    state = .pressing
                case .second(true, let drag?):
                    state = .dragging(start: drag.startLocation, current: drag.location)
                default:
                    state = .idle
                }
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value else { return }
                guard let type = menuHovered(anchor: drag.startLocation, current: drag.location) else { return }
                // Convert screen x → time, accounting for centered-playhead offset
                let t = min(kPatternDuration, max(0, Double((drag.startLocation.x - vw / 2 + offset) / scale)))
                let event: HapticStudioEvent = type == .transient
                    ? .defaultTransient(at: t)
                    : .defaultContinuous(at: t)
                withAnimation { pattern.events.append(event) }
                selectedEventID = event.id
            }
    }

    private func menuHovered(anchor: CGPoint, current: CGPoint) -> HapticStudioEvent.EventType? {
        let dy = anchor.y - current.y   // positive = moved up
        if dy > 104 { return .continuous }
        if dy > 52  { return .transient }
        return nil
    }

    // MARK: – Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Label("Tap to play", systemImage: "play.circle")
                .font(.caption).foregroundStyle(.secondary)
            Label("Hold to add", systemImage: "hand.point.up.left")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: – Actions

    private func insertPreset(_ preset: HapticPreset) {
        let t = playheadTime
        for var e in preset.events {
            e.id    = UUID()
            e.time += t
            pattern.events.append(e)
        }
        let preview = HapticPattern(events: preset.events, curves: [
            HapticParameterCurve(parameterID: .intensity, controlPoints: []),
            HapticParameterCurve(parameterID: .sharpness,  controlPoints: []),
        ])
        engine.play(pattern: preview)
    }

    // MARK: – Live Values Pill

    @ViewBuilder
    private func liveValuesPill(for event: HapticStudioEvent, at t: Double) -> some View {
        let intensity = liveIntensity(event, at: t)
        HStack(spacing: 8) {
            // ◼ intensity
            Label(String(format: "%.2f", intensity), systemImage: "square.fill")
                .font(.caption2.monospaced())
            // ▲ sharpness
            Label(String(format: "%.2f", event.sharpness), systemImage: "triangle.fill")
                .font(.caption2.monospaced())
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }

    // MARK: – Playback

    private func playFromStart() {
        guard !pattern.events.isEmpty else { return }
        scrollOffset = 0
        isPlaying    = true
        engine.play(pattern: pattern)

        stopTimer()
        let start     = Date()
        let duration  = min(kPatternDuration, pattern.totalDuration)
        let startScale = timeScale          // capture so zoom mid-play doesn't distort timing

        playTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                let elapsed = Date().timeIntervalSince(start)
                if elapsed >= duration {
                    isPlaying    = false
                    scrollOffset = 0
                    stopTimer()
                } else {
                    // Drive scroll so elapsed time stays under the playhead
                    scrollOffset = CGFloat(elapsed) * startScale
                }
            }
        }
    }

    private func stopPlayback() {
        engine.stopPlayback()
        isPlaying = false
        stopTimer()
    }

    private func stopTimer() {
        playTimer?.invalidate()
        playTimer = nil
    }
}

private let kPatternDuration: Double = 5.0

// MARK: - Add Event Menu

private struct AddEventMenu: View {
    let anchor: CGPoint
    let hovered: HapticStudioEvent.EventType?

    // Cards sit above the anchor:
    //   Transient  center: anchor.y - 78
    //   Continuous center: anchor.y - 142  (78 + 12 gap + 52 item height)
    private let itemH: CGFloat = 52
    private let gap:   CGFloat = 12
    private let lift:  CGFloat = 26   // space between anchor and bottom of first card

    var body: some View {
        ZStack {
            // Anchor dot
            Circle()
                .fill(Color.primary.opacity(0.25))
                .frame(width: 10, height: 10)
                .position(anchor)

            // Transient (closer)
            menuCard("Transient", icon: "bolt", active: hovered == .transient)
                .position(x: anchor.x, y: anchor.y - lift - itemH / 2)

            // Continuous (further)
            menuCard("Continuous", icon: "waveform", active: hovered == .continuous)
                .position(x: anchor.x, y: anchor.y - lift - itemH - gap - itemH / 2)
        }
    }

    private func menuCard(_ label: String, icon: String, active: Bool) -> some View {
        Label(label, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(active ? Color.white : Color.primary)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(active
                          ? AnyShapeStyle(Color.accentColor)
                          : AnyShapeStyle(.regularMaterial))
                    .shadow(color: .black.opacity(active ? 0.25 : 0.12), radius: active ? 12 : 6, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(active ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
            }
            .scaleEffect(active ? 1.07 : 1.0)
            .animation(.spring(duration: 0.18, bounce: 0.4), value: active)
    }
}

// MARK: - Export Sheet

private struct ExportSheet: View {
    let ahapString: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(ahapString)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("AHAP Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: ahapString, preview: SharePreview("pattern.ahap"))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { HapticStudioView() }
}
