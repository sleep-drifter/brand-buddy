import SwiftUI

// MARK: - Constants

private let kKFMaxDuration: Double = 5.0
private let kKFRulerH: CGFloat     = 22
private let kKFLaneH: CGFloat      = 38

// MARK: - Property

private enum KFProperty: String, CaseIterable, Identifiable {
    case scale, offsetX, offsetY, opacity, rotation
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var range: ClosedRange<Double> {
        switch self {
        case .scale:              return 0.1...3.0
        case .offsetX, .offsetY: return -150...150
        case .opacity:            return 0...1
        case .rotation:           return -360...360
        }
    }
    var defaultValue: Double {
        switch self {
        case .scale, .opacity: return 1.0
        default:               return 0.0
        }
    }
    var color: Color {
        switch self {
        case .scale:    return .indigo
        case .offsetX:  return .orange
        case .offsetY:  return .teal
        case .opacity:  return .pink
        case .rotation: return .purple
        }
    }
    var icon: String {
        switch self {
        case .scale:    return "arrow.up.left.and.arrow.down.right"
        case .offsetX:  return "arrow.left.and.right"
        case .offsetY:  return "arrow.up.and.down"
        case .opacity:  return "circle.lefthalf.filled"
        case .rotation: return "rotate.right"
        }
    }
    // Pre-set "to" value used when adding from the quick-add grid
    var defaultAddValue: Double {
        switch self {
        case .scale:    return 1.3
        case .offsetX:  return 40
        case .offsetY:  return -40
        case .opacity:  return 0.0
        case .rotation: return 15
        }
    }
    func formatted(_ v: Double) -> String {
        switch self {
        case .scale:              return String(format: "%.2f×", v)
        case .offsetX, .offsetY: return String(format: "%.0fpt", v)
        case .opacity:            return String(format: "%.2f", v)
        case .rotation:           return String(format: "%.0f°", v)
        }
    }
}

// MARK: - Interpolation

private enum KFInterp: String, CaseIterable, Hashable {
    case linear = "Linear"
    case spring = "Spring"
    case cubic  = "Cubic"

    var springCurve: Spring {
        switch self {
        case .linear: return .init(response: 0.25, dampingRatio: 1.0)
        case .spring: return .bouncy
        case .cubic:  return .init(response: 0.5,  dampingRatio: 0.85)
        }
    }
}

// MARK: - Keyframe Model

private struct KFKeyframe: Identifiable {
    var id        = UUID()
    var property:  KFProperty
    var startTime: Double = 0
    var value:     Double
    var duration:  Double
    var interp:    KFInterp
}

// MARK: - Animation Values

private struct KFAnimValues {
    var scale:    CGFloat = 1.0
    var offsetX:  CGFloat = 0
    var offsetY:  CGFloat = 0
    var opacity:  Double  = 1.0
    var rotation: Double  = 0
}

// MARK: - Presets

private enum KFPreset: CaseIterable {
    case bounce, fadeIn, swing, popIn

    var label: String {
        switch self {
        case .bounce: return "Bounce"
        case .fadeIn: return "Fade In"
        case .swing:  return "Swing"
        case .popIn:  return "Pop In"
        }
    }
    var color: Color {
        switch self {
        case .bounce: return .green
        case .fadeIn: return .cyan
        case .swing:  return .indigo
        case .popIn:  return .pink
        }
    }
    // Converts sequential keyframes (startTime=0) into absolute startTimes per property lane
    private static func withStartTimes(_ kfs: [KFKeyframe]) -> [KFKeyframe] {
        var cursor: [KFProperty: Double] = [:]
        return kfs.map { kf in
            var k = kf
            k.startTime = cursor[kf.property, default: 0]
            cursor[kf.property] = k.startTime + k.duration
            return k
        }
    }

    var keyframes: [KFKeyframe] {
        switch self {
        case .bounce:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .scale,   value: 1.0,  duration: 0.1,  interp: .linear),
                KFKeyframe(property: .scale,   value: 1.4,  duration: 0.25, interp: .spring),
                KFKeyframe(property: .scale,   value: 1.0,  duration: 0.35, interp: .spring),
                KFKeyframe(property: .offsetY, value: 0,    duration: 0.1,  interp: .linear),
                KFKeyframe(property: .offsetY, value: -60,  duration: 0.25, interp: .spring),
                KFKeyframe(property: .offsetY, value: 0,    duration: 0.35, interp: .spring),
            ])
        case .fadeIn:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .opacity, value: 0.0, duration: 0.05, interp: .linear),
                KFKeyframe(property: .opacity, value: 1.0, duration: 0.5,  interp: .cubic),
                KFKeyframe(property: .scale,   value: 0.8, duration: 0.05, interp: .linear),
                KFKeyframe(property: .scale,   value: 1.0, duration: 0.5,  interp: .spring),
            ])
        case .swing:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .rotation, value: 0,   duration: 0.05, interp: .linear),
                KFKeyframe(property: .rotation, value: -25, duration: 0.2,  interp: .spring),
                KFKeyframe(property: .rotation, value: 25,  duration: 0.2,  interp: .spring),
                KFKeyframe(property: .rotation, value: -15, duration: 0.15, interp: .spring),
                KFKeyframe(property: .rotation, value: 0,   duration: 0.15, interp: .spring),
            ])
        case .popIn:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .scale,   value: 0.0, duration: 0.01, interp: .linear),
                KFKeyframe(property: .scale,   value: 1.2, duration: 0.3,  interp: .spring),
                KFKeyframe(property: .scale,   value: 1.0, duration: 0.2,  interp: .spring),
                KFKeyframe(property: .opacity, value: 0.0, duration: 0.01, interp: .linear),
                KFKeyframe(property: .opacity, value: 1.0, duration: 0.25, interp: .cubic),
            ])
        }
    }
}

// MARK: - Main View

struct KeyframeStudioView: View {
    @State private var keyframes: [KFKeyframe] = KFPreset.bounce.keyframes
    @State private var selectedID: UUID? = nil

    // Timeline pan/zoom
    @State private var timeScale: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragDelta: CGFloat = 0
    @GestureState private var pinchDelta: CGFloat = 1.0

    // Playback
    @State private var triggerAnimation: Int = 0
    @State private var isPlaying            = false
    @State private var playTimer: Timer?    = nil
    @State private var loopEnabled          = false
    @State private var pingPongEnabled      = false
    @State private var playbackRevolutions  = 0
    @State private var isReversePhase       = false
    @State private var storedAnimDur: Double = 0

    // MARK: Derived

    private var liveScale: CGFloat {
        timeScale == 0 ? 0 : min(500, max(30, timeScale * pinchDelta))
    }
    private var liveOffset: CGFloat {
        let maxOff = CGFloat(kKFMaxDuration) * liveScale
        return max(0, min(maxOff, (scrollOffset - dragDelta) * pinchDelta))
    }
    private var totalDuration: Double {
        keyframes.map { $0.startTime + $0.duration }.max() ?? 0
    }

    // The end-state of the animation — used as initialValue during the reverse ping-pong phase
    private var finalAnimValues: KFAnimValues {
        var v = KFAnimValues()
        for prop in KFProperty.allCases {
            let last = keyframes
                .filter { $0.property == prop }
                .sorted { $0.startTime < $1.startTime }
                .last
            guard let last else { continue }
            switch prop {
            case .scale:    v.scale    = CGFloat(last.value)
            case .offsetX:  v.offsetX  = CGFloat(last.value)
            case .offsetY:  v.offsetY  = CGFloat(last.value)
            case .opacity:  v.opacity  = last.value
            case .rotation: v.rotation = last.value
            }
        }
        return v
    }
    private var selectedKeyframe: Binding<KFKeyframe>? {
        guard let id = selectedID,
              let idx = keyframes.firstIndex(where: { $0.id == id })
        else { return nil }
        return $keyframes[idx]
    }

    // The keyframe in the same property lane whose end point is closest before selectedKeyframe.startTime
    private var selectedKeyframePrev: Binding<KFKeyframe>? {
        guard let id = selectedID,
              let kf = keyframes.first(where: { $0.id == id })
        else { return nil }
        let prev = keyframes
            .filter { $0.property == kf.property && $0.id != kf.id }
            .filter { $0.startTime + $0.duration <= kf.startTime + 0.001 }
            .max { ($0.startTime + $0.duration) < ($1.startTime + $1.duration) }
        guard let prev,
              let prevIdx = keyframes.firstIndex(where: { $0.id == prev.id })
        else { return nil }
        return $keyframes[prevIdx]
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            previewSection
            Divider()
            timelineSection
            Divider()
            if let kfBinding = selectedKeyframe {
                inspectorSection(kfBinding, prev: selectedKeyframePrev)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                Divider()
            }
            controlsScroll
        }
        .animation(.spring(duration: 0.25), value: selectedID != nil)
        .navigationTitle("Keyframe Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    withAnimation { keyframes.removeAll(); selectedID = nil }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(keyframes.isEmpty)
            }
        }
        .onDisappear { stopPlayback() }
    }

    // MARK: – Preview

    private var previewSection: some View {
        ZStack {
            Color(.systemGroupedBackground)

            if keyframes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.sparkles")
                        .font(.system(size: 32)).foregroundStyle(.secondary)
                    Text("Add keyframes to preview")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            } else {
                KeyframeAnimator(
                    initialValue: isReversePhase ? finalAnimValues : KFAnimValues(),
                    trigger: triggerAnimation
                ) { v in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "wand.and.sparkles")
                                .font(.title2).foregroundStyle(.white)
                        )
                        .scaleEffect(v.scale)
                        .opacity(v.opacity)
                        .offset(x: v.offsetX, y: v.offsetY)
                        .rotationEffect(.degrees(v.rotation))
                } keyframes: { _ in
                    if isReversePhase {
                        // Reverse phase: animate from final state back to defaults
                        let d = storedAnimDur
                        KeyframeTrack(\.scale)    { LinearKeyframe(1.0, duration: d) }
                        KeyframeTrack(\.offsetX)  { LinearKeyframe(0,   duration: d) }
                        KeyframeTrack(\.offsetY)  { LinearKeyframe(0,   duration: d) }
                        KeyframeTrack(\.opacity)  { LinearKeyframe(1.0, duration: d) }
                        KeyframeTrack(\.rotation) { LinearKeyframe(0,   duration: d) }
                    } else {
                        // Forward phase: normal keyframe tracks
                        KeyframeTrack(\.scale) {
                            for kf in buildTrack(for: .scale) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.value), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.offsetX) {
                            for kf in buildTrack(for: .offsetX) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.value), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.offsetY) {
                            for kf in buildTrack(for: .offsetY) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.value), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.value), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.opacity) {
                            for kf in buildTrack(for: .opacity) {
                                if kf.interp == .linear {
                                    LinearKeyframe(kf.value, duration: kf.duration)
                                } else {
                                    SpringKeyframe(kf.value, duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.rotation) {
                            for kf in buildTrack(for: .rotation) {
                                if kf.interp == .linear {
                                    LinearKeyframe(kf.value, duration: kf.duration)
                                } else {
                                    SpringKeyframe(kf.value, duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                    }
                }
            }

            // Play/stop button — bottom trailing
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        playFromTimeline()
                    } label: {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(keyframes.isEmpty ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(Color.indigo))
                    }
                    .disabled(keyframes.isEmpty)
                    .padding(12)
                }
            }
        }
        .frame(height: 140)
        .clipped()
    }

    // MARK: – Timeline

    private var timelineSection: some View {
        let activeProps = KFProperty.allCases.filter { p in keyframes.contains { $0.property == p } }
        let laneCount   = activeProps.count
        let totalH      = max(60, kKFRulerH + CGFloat(laneCount) * kKFLaneH + CGFloat(max(0, laneCount - 1)))

        return GeometryReader { geo in
            let vw      = geo.size.width
            let scale   = liveScale > 0 ? liveScale : max(1, vw / CGFloat(kKFMaxDuration))
            let offset  = liveOffset
            let originX = vw / 2 - offset

            ZStack(alignment: .topLeading) {
                Color(.systemGroupedBackground)

                // Clipped region: ruler + lane chips
                ZStack(alignment: .topLeading) {
                    KFRuler(viewWidth: vw, timeScale: scale, scrollOffset: offset)
                        .frame(height: totalH)

                    VStack(spacing: 0) {
                        ForEach(Array(activeProps.enumerated()), id: \.offset) { laneIdx, prop in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(laneIdx % 2 == 0 ? Color.primary.opacity(0.025) : Color.clear)

                                let propKFs = keyframes.filter { $0.property == prop }
                                ForEach(propKFs, id: \.id) { kf in
                                    let x   = originX + CGFloat(kf.startTime) * scale
                                    let w   = max(8, CGFloat(kf.duration) * scale)
                                    let sel = selectedID == kf.id

                                    KFChipView(
                                        property: prop,
                                        chipWidth: w,
                                        chipHeight: kKFLaneH - 8,
                                        isSelected: sel,
                                        timeScale: scale,
                                        minLeftDelta: CGFloat(kf.startTime) * scale,
                                        onTap: {
                                            withAnimation(.spring(duration: 0.22)) {
                                                selectedID = selectedID == kf.id ? nil : kf.id
                                            }
                                        },
                                        onRightDragEnd: { translation in
                                            guard let i = keyframes.firstIndex(where: { $0.id == kf.id }) else { return }
                                            keyframes[i].duration = max(0.05, kf.duration + Double(translation / scale))
                                        },
                                        onLeftDragEnd: { translation in
                                            guard let i = keyframes.firstIndex(where: { $0.id == kf.id }) else { return }
                                            let deltaT    = Double(translation / scale)
                                            let newStart  = max(0, kf.startTime + deltaT)
                                            let clampedDT = newStart - kf.startTime
                                            keyframes[i].startTime = newStart
                                            keyframes[i].duration  = max(0.05, kf.duration - clampedDT)
                                        }
                                    )
                                    .offset(x: x, y: 4)
                                }
                            }
                            .frame(height: kKFLaneH)

                            if laneIdx < activeProps.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .offset(y: kKFRulerH)
                }
                .clipShape(Rectangle())

                // Property labels — float above clips
                VStack(spacing: 0) {
                    Color.clear.frame(height: kKFRulerH)
                    ForEach(Array(activeProps.enumerated()), id: \.offset) { laneIdx, prop in
                        HStack(spacing: 0) {
                            Text(prop.rawValue)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(prop.color)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(prop.color.opacity(0.12), in: Capsule())
                                .padding(.leading, 6)
                            Spacer()
                        }
                        .frame(height: kKFLaneH)

                        if laneIdx < activeProps.count - 1 { Divider() }
                    }
                }

                // Playhead line + cap
                Rectangle()
                    .fill(Color.red.opacity(0.85))
                    .frame(width: 2, height: totalH)
                    .offset(x: vw / 2 - 1)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red)
                    .frame(width: 10, height: 6)
                    .offset(x: vw / 2 - 5, y: 0)
                    .allowsHitTesting(false)

                // Playhead time label — centered on playhead in ruler area
                let playheadT   = liveScale > 0 ? Double(liveOffset / liveScale) : 0
                let playheadMs  = Int((playheadT * 1000).rounded())
                let playheadLbl = playheadMs % 1000 == 0
                    ? (playheadMs == 0 ? "0s" : "\(playheadMs / 1000)s")
                    : "\(playheadMs)ms"
                Text(playheadLbl)
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.red.opacity(0.15), in: Capsule())
                    .position(x: vw / 2, y: kKFRulerH / 2 + 4)
                    .allowsHitTesting(false)
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($dragDelta) { v, state, _ in state = v.translation.width }
                    .onEnded { v in
                        scrollOffset = max(0, min(
                            CGFloat(kKFMaxDuration) * timeScale,
                            scrollOffset - v.translation.width
                        ))
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($pinchDelta) { v, state, _ in state = v }
                    .onEnded { v in
                        let t = liveScale > 0 ? Double(liveOffset / liveScale) : 0
                        let newScale = min(500, max(30, timeScale * v))
                        scrollOffset = CGFloat(t) * newScale
                        timeScale    = newScale
                    }
            )
        }
        .frame(height: totalH)
        .onAppear {
            if timeScale == 0 {
                // ~3s fills the screen width so shorter animations sit comfortably
                timeScale = 390 / CGFloat(kKFMaxDuration) * 0.65
            }
        }
    }

    // MARK: – Inspector

    @ViewBuilder
    private func inspectorSection(_ binding: Binding<KFKeyframe>, prev: Binding<KFKeyframe>?) -> some View {
        let kf        = binding.wrappedValue
        let fromValue = prev?.wrappedValue.value ?? kf.property.defaultValue

        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8).padding(.bottom, 6)

            VStack(spacing: 10) {
                // Header — shows full transition at a glance
                HStack {
                    Text(kf.property.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(kf.property.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(kf.property.color)
                    Text("\(kf.property.formatted(fromValue)) → \(kf.property.formatted(kf.value))")
                        .font(.caption.monospacedDigit())
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.22)) { selectedID = nil }
                    } label: {
                        Image(systemName: "xmark").font(.caption)
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                }

                Divider()

                // From value — editable only when a previous keyframe exists
                HStack(spacing: 10) {
                    Text("From")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    if let prevBinding = prev {
                        Slider(value: prevBinding.value, in: kf.property.range)
                            .tint(kf.property.color.opacity(0.55))
                        Text(kf.property.formatted(fromValue))
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    } else {
                        Text("initial state")
                            .font(.caption).foregroundStyle(.tertiary)
                        Spacer()
                        Text(kf.property.formatted(fromValue))
                            .font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }

                // To value — always editable
                HStack(spacing: 10) {
                    Text("To")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Slider(value: binding.value, in: kf.property.range)
                        .tint(kf.property.color)
                    Text(kf.property.formatted(kf.value))
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }

                // Interpolation
                Picker("Type", selection: binding.interp) {
                    ForEach(KFInterp.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.segmented)

                // Delete
                Button(role: .destructive) {
                    withAnimation(.spring(duration: 0.22)) {
                        keyframes.removeAll { $0.id == selectedID }
                        selectedID = nil
                    }
                } label: {
                    Text("Remove Keyframe").font(.caption).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).controlSize(.small).tint(.red)
            }
            .padding(.horizontal, 16).padding(.bottom, 14)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: – Scrollable Controls

    private var controlsScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if keyframes.isEmpty { presetsCard }
                addKeyframeCard
                playbackCard
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Presets

    private var presetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Presets")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(KFPreset.allCases, id: \.label) { preset in
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                keyframes        = preset.keyframes
                                selectedID       = nil
                                triggerAnimation += 1
                            }
                        } label: {
                            Text(preset.label.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(preset.color, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Add Keyframe

    private var addKeyframeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Add to timeline")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(KFProperty.allCases) { prop in
                        Button {
                            let startTime = timeScale > 0 ? Double(scrollOffset / timeScale) : 0
                            let kf = KFKeyframe(property: prop, startTime: startTime,
                                                value: prop.defaultAddValue,
                                                duration: 0.25, interp: .spring)
                            withAnimation(.spring(duration: 0.25)) { keyframes.append(kf) }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: prop.icon)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(prop.color)
                                    .frame(width: 64, height: 52)
                                    .background(Color(.secondarySystemGroupedBackground),
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Text(prop.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Playback Info

    private var playbackCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Playback")
            VStack(spacing: 0) {
                cardRow {
                    HStack {
                        Text("Animation Duration").foregroundStyle(.secondary)
                        Spacer()
                        Text(keyframes.isEmpty ? "—" : String(format: "%.2fs", totalDuration))
                            .font(.subheadline.monospacedDigit())
                    }
                }
                cardDivider
                cardRow {
                    HStack {
                        Text("Timeline Max").foregroundStyle(.secondary)
                        Spacer()
                        Text("5.0s").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                cardDivider
                cardRow {
                    HStack {
                        Text("Loop").foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: $loopEnabled).labelsHidden()
                    }
                }
                cardDivider
                cardRow {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Ping-pong").foregroundStyle(.secondary)
                            if pingPongEnabled && !loopEnabled {
                                Text("Plays once unless Loop is on")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $pingPongEnabled).labelsHidden()
                    }
                }
                cardDivider
                cardRow {
                    Button {
                        playFromTimeline()
                    } label: {
                        Label(
                            isPlaying ? "Playing…" : "Play Animation",
                            systemImage: isPlaying ? "stop.circle" : "play.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isPlaying ? .red : .indigo)
                    .disabled(keyframes.isEmpty)
                }
            }
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: – Layout Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote).foregroundStyle(.secondary).textCase(.uppercase)
            .padding(.horizontal, 4)
    }

    private func cardRow<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardDivider: some View {
        Divider().padding(.leading, 16)
    }

    // MARK: – Keyframe Helpers

    // Builds a gapless track for KeyframeAnimator: inserts LinearKeyframe hold segments
    // wherever there is space before the first keyframe or between keyframes.
    private func buildTrack(for prop: KFProperty) -> [KFKeyframe] {
        let sorted = keyframes.filter { $0.property == prop }
                              .sorted { $0.startTime < $1.startTime }
        let total = max(totalDuration, 0.1)

        guard !sorted.isEmpty else {
            return [KFKeyframe(property: prop, startTime: 0,
                               value: prop.defaultValue, duration: total, interp: .linear)]
        }

        var result: [KFKeyframe] = []
        var cursor = 0.0

        for (i, kf) in sorted.enumerated() {
            if kf.startTime > cursor + 0.001 {
                let holdVal = i > 0 ? sorted[i - 1].value : prop.defaultValue
                result.append(KFKeyframe(property: prop, startTime: cursor, value: holdVal,
                                         duration: kf.startTime - cursor, interp: .linear))
            }
            result.append(kf)
            cursor = kf.startTime + kf.duration
        }

        if cursor < total - 0.001 {
            result.append(KFKeyframe(property: prop, startTime: cursor,
                                     value: sorted.last!.value,
                                     duration: total - cursor, interp: .linear))
        }

        return result
    }

    // MARK: – Playback

    private func playFromTimeline() {
        guard !isPlaying else { stopPlayback(); return }
        guard !keyframes.isEmpty else { return }

        let dur        = min(kKFMaxDuration, max(totalDuration, 0.1))
        storedAnimDur  = dur
        isPlaying           = true
        isReversePhase      = false
        scrollOffset        = 0
        playbackRevolutions = 0
        stopTimer()
        triggerAnimation   += 1

        let start      = Date()
        let startScale = timeScale

        playTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in
            Task { @MainActor in
                guard isPlaying else { return }
                let elapsed = Date().timeIntervalSince(start)

                if pingPongEnabled && loopEnabled {
                    let fullCycle    = dur * 2
                    let cycleT       = elapsed.truncatingRemainder(dividingBy: fullCycle)
                    let newIsReverse = cycleT >= dur
                    // Phase flip triggers a new KeyframeAnimator run with updated initialValue
                    if newIsReverse != isReversePhase {
                        isReversePhase   = newIsReverse
                        triggerAnimation += 1
                    }
                    scrollOffset = CGFloat(cycleT < dur ? cycleT : fullCycle - cycleT) * startScale

                } else if pingPongEnabled {
                    let fullCycle = dur * 2
                    if elapsed >= fullCycle {
                        isPlaying      = false
                        isReversePhase = false
                        scrollOffset   = 0          // ping-pong ends back at start
                        stopTimer()
                    } else {
                        let newIsReverse = elapsed >= dur
                        if newIsReverse != isReversePhase {
                            isReversePhase   = newIsReverse
                            triggerAnimation += 1
                        }
                        scrollOffset = CGFloat(elapsed < dur ? elapsed : fullCycle - elapsed) * startScale
                    }

                } else if loopEnabled {
                    let rev = Int(elapsed / dur)
                    if rev > playbackRevolutions {
                        playbackRevolutions = rev
                        triggerAnimation += 1
                    }
                    scrollOffset = CGFloat(elapsed.truncatingRemainder(dividingBy: dur)) * startScale

                } else {
                    if elapsed >= dur {
                        isPlaying    = false
                        scrollOffset = CGFloat(dur) * startScale   // rest at final frame
                        stopTimer()
                    } else {
                        scrollOffset = CGFloat(elapsed) * startScale
                    }
                }
            }
        }
    }

    private func stopPlayback() {
        isPlaying      = false
        isReversePhase = false
        stopTimer()
    }

    private func stopTimer() {
        playTimer?.invalidate()
        playTimer = nil
    }
}

// MARK: - Keyframe Chip

private let kHandleW: CGFloat = 16

private struct KFChipView: View {
    let property:     KFProperty
    let chipWidth:    CGFloat
    let chipHeight:   CGFloat
    let isSelected:   Bool
    let timeScale:    CGFloat
    let minLeftDelta: CGFloat
    let onTap:           () -> Void
    let onRightDragEnd:  (CGFloat) -> Void
    let onLeftDragEnd:   (CGFloat) -> Void

    // Single gesture state covering both handles — eliminates gesture conflicts with parent timeline
    private enum HandleDrag {
        case none, left(CGFloat), right(CGFloat)
        var leftDelta:  CGFloat { if case .left(let d)  = self { return d } else { return 0 } }
        var rightDelta: CGFloat { if case .right(let d) = self { return d } else { return 0 } }
    }
    @GestureState private var handleDrag: HandleDrag = .none

    private var liveWidth: CGFloat {
        guard isSelected else { return max(8, chipWidth) }
        return max(8, chipWidth + handleDrag.rightDelta - handleDrag.leftDelta)
    }

    private var showHandles: Bool {
        isSelected && liveWidth >= kHandleW * 2 + 6
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(property.color.opacity(isSelected ? 0.42 : 0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(property.color.opacity(isSelected ? 0.9 : 0.55),
                                      lineWidth: isSelected ? 1.5 : 1)
                )

            if showHandles {
                HStack(spacing: 0) {
                    grip(color: property.color)
                    Spacer(minLength: 0)
                    grip(color: property.color)
                }
            }
        }
        .frame(width: liveWidth, height: chipHeight)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .offset(x: isSelected ? handleDrag.leftDelta : 0)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        // One gesture on the whole chip; startLocation.x determines which handle is active.
        // including: .none when not selected lets the parent timeline pan receive these drags.
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .updating($handleDrag) { value, state, transaction in
                    transaction.animation = nil
                    guard showHandles else { return }
                    let x = value.startLocation.x
                    if x <= kHandleW + 4 {
                        state = .left(min(max(value.translation.width, -minLeftDelta), chipWidth - 8))
                    } else if x >= chipWidth - kHandleW - 4 {
                        state = .right(max(value.translation.width, -(chipWidth - 8)))
                    }
                }
                .onEnded { value in
                    guard showHandles else { return }
                    let x = value.startLocation.x
                    if x <= kHandleW + 4 {
                        onLeftDragEnd(value.translation.width)
                    } else if x >= chipWidth - kHandleW - 4 {
                        onRightDragEnd(value.translation.width)
                    }
                },
            including: isSelected ? .all : .none
        )
        .animation(.spring(duration: 0.22), value: isSelected)
    }

    // Visual only — hit testing handled by parent gesture
    private func grip(color: Color) -> some View {
        ZStack {
            color.opacity(0.9)
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 2, height: 7)
                }
            }
        }
        .frame(width: kHandleW, height: chipHeight)
        .allowsHitTesting(false)
    }
}

// MARK: - Timeline Ruler

private struct KFRuler: View {
    let viewWidth: CGFloat
    let timeScale: CGFloat
    let scrollOffset: CGFloat

    var body: some View {
        Canvas { ctx, size in
            guard timeScale > 0 else { return }

            let zeroX = size.width / 2 - scrollOffset
            let endX  = size.width / 2 + CGFloat(kKFMaxDuration) * timeScale - scrollOffset

            // Hatching outside the valid [0, 5s] window
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

            // Adaptive tick step — only draw ticks that will be >= 3pt apart
            let step: Double = timeScale * 0.05 >= 3 ? 0.05
                             : timeScale * 0.25 >= 3 ? 0.25
                             : 0.5

            // Adaptive label interval — show finer labels only when they're >= 40pt apart
            // Priority: 1s → 500ms → 250ms
            let labelIntervalMs: Int = CGFloat(0.25) * timeScale >= 40 ? 250
                                     : CGFloat(0.5)  * timeScale >= 40 ? 500
                                     : 1000

            let tLeft: Double = Double((scrollOffset - size.width / 2) / timeScale)
            var t = max(0.0, floor(tLeft / step) * step)

            while t <= kKFMaxDuration + step * 0.01 {
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

            // Hard end marker at 5s
            if endX >= 0 && endX <= size.width {
                var ep = Path()
                ep.move(to:    .init(x: endX, y: 0))
                ep.addLine(to: .init(x: endX, y: size.height))
                ctx.stroke(ep, with: .color(.primary.opacity(0.5)), lineWidth: 2)
                ctx.draw(
                    Text("5s").font(.system(size: 9, weight: .semibold)).foregroundColor(.primary.opacity(0.6)),
                    at: .init(x: endX + 3, y: 3), anchor: .topLeading
                )
            }
        }
    }
}

#Preview {
    NavigationStack { KeyframeStudioView() }
}
