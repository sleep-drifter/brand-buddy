import SwiftUI

// MARK: - Constants

private let kKFMaxDuration: Double = 5.0
private let kKFRulerH: CGFloat     = 22
private let kKFLaneH: CGFloat      = 38
private let kSnapVelocityThreshold: CGFloat = 10   // pts/sec — below this, snapping activates
private let kSnapRadiusPt: CGFloat          = 12   // screen pts converted to time units per zoom

// MARK: - Property

private enum KFProperty: String, CaseIterable, Identifiable {
    case scale, offsetX, offsetY, opacity, rotation, scaleX, scaleY, blur
    var id: String { rawValue }
    var label: String {
        switch self {
        case .scale:    return "Scale"
        case .offsetX:  return "Offset X"
        case .offsetY:  return "Offset Y"
        case .opacity:  return "Opacity"
        case .rotation: return "Rotation"
        case .scaleX:   return "Scale X"
        case .scaleY:   return "Scale Y"
        case .blur:     return "Blur"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .scale, .scaleX, .scaleY: return 0.1...3.0
        case .offsetX, .offsetY:       return -150...150
        case .opacity:                  return 0...1
        case .rotation:                 return -360...360
        case .blur:                     return 0...30
        }
    }
    var defaultValue: Double {
        switch self {
        case .scale, .scaleX, .scaleY, .opacity: return 1.0
        default:                                  return 0.0
        }
    }
    var color: Color {
        switch self {
        case .scale:    return .indigo
        case .offsetX:  return .orange
        case .offsetY:  return .teal
        case .opacity:  return .pink
        case .rotation: return .purple
        case .scaleX:   return .cyan
        case .scaleY:   return .green
        case .blur:     return .secondary
        }
    }
    var icon: String {
        switch self {
        case .scale:    return "arrow.up.left.and.arrow.down.right"
        case .offsetX:  return "arrow.left.and.right"
        case .offsetY:  return "arrow.up.and.down"
        case .opacity:  return "circle.lefthalf.filled"
        case .rotation: return "rotate.right"
        case .scaleX:   return "arrow.left.and.right.square"
        case .scaleY:   return "arrow.up.and.down.square"
        case .blur:     return "aqi.medium"
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
        case .scaleX:   return 1.5
        case .scaleY:   return 0.7
        case .blur:     return 8.0
        }
    }
    func formatted(_ v: Double) -> String {
        switch self {
        case .scale, .scaleX, .scaleY: return String(format: "%.2f×", v)
        case .offsetX, .offsetY:       return String(format: "%.0fpt", v)
        case .opacity:                  return String(format: "%.2f", v)
        case .rotation:                 return String(format: "%.0f°", v)
        case .blur:                     return String(format: "%.1fpt", v)
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
    var fromValue: Double
    var toValue:   Double
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
    var scaleX:   CGFloat = 1.0
    var scaleY:   CGFloat = 1.0
    var blur:     CGFloat = 0
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
    // and auto-chains fromValue from the preceding segment's toValue.
    private static func withStartTimes(_ kfs: [KFKeyframe]) -> [KFKeyframe] {
        var timeCursor:  [KFProperty: Double] = [:]
        var valueCursor: [KFProperty: Double] = [:]
        return kfs.map { kf in
            var k = kf
            k.startTime  = timeCursor[kf.property, default: 0]
            k.fromValue  = valueCursor[kf.property, default: kf.property.defaultValue]
            timeCursor[kf.property]  = k.startTime + k.duration
            valueCursor[kf.property] = k.toValue
            return k
        }
    }

    var keyframes: [KFKeyframe] {
        switch self {
        case .bounce:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.0,  duration: 0.1,  interp: .linear),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.4,  duration: 0.25, interp: .spring),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.0,  duration: 0.35, interp: .spring),
                KFKeyframe(property: .offsetY, fromValue: 0, toValue: 0,    duration: 0.1,  interp: .linear),
                KFKeyframe(property: .offsetY, fromValue: 0, toValue: -60,  duration: 0.25, interp: .spring),
                KFKeyframe(property: .offsetY, fromValue: 0, toValue: 0,    duration: 0.35, interp: .spring),
            ])
        case .fadeIn:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .opacity, fromValue: 0, toValue: 0.0, duration: 0.05, interp: .linear),
                KFKeyframe(property: .opacity, fromValue: 0, toValue: 1.0, duration: 0.5,  interp: .cubic),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 0.8, duration: 0.05, interp: .linear),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.0, duration: 0.5,  interp: .spring),
            ])
        case .swing:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .rotation, fromValue: 0, toValue: 0,   duration: 0.05, interp: .linear),
                KFKeyframe(property: .rotation, fromValue: 0, toValue: -25, duration: 0.2,  interp: .spring),
                KFKeyframe(property: .rotation, fromValue: 0, toValue: 25,  duration: 0.2,  interp: .spring),
                KFKeyframe(property: .rotation, fromValue: 0, toValue: -15, duration: 0.15, interp: .spring),
                KFKeyframe(property: .rotation, fromValue: 0, toValue: 0,   duration: 0.15, interp: .spring),
            ])
        case .popIn:
            return KFPreset.withStartTimes([
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 0.0, duration: 0.01, interp: .linear),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.2, duration: 0.3,  interp: .spring),
                KFKeyframe(property: .scale,   fromValue: 0, toValue: 1.0, duration: 0.2,  interp: .spring),
                KFKeyframe(property: .opacity, fromValue: 0, toValue: 0.0, duration: 0.01, interp: .linear),
                KFKeyframe(property: .opacity, fromValue: 0, toValue: 1.0, duration: 0.25, interp: .cubic),
            ])
        }
    }
}

// MARK: - Main View

struct KeyframeStudioView: View {
    @State private var keyframes: [KFKeyframe] = KFPreset.bounce.keyframes
    @State private var selectedID: UUID? = nil
    @State private var previewAssetIndex: Int = 0

    // Timeline pan/zoom
    @State private var timeScale: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragDelta: CGFloat = 0
    @GestureState private var pinchDelta: CGFloat = 1.0

    // Snap HUD
    @AppStorage("showSnapHUD_keyframe") private var showSnapHUD = false
    @State private var hudVelocity: CGFloat    = 0
    @State private var hudVelocityMin: CGFloat = 0
    @State private var hudVelocityMax: CGFloat = 0
    @State private var hudIsSnapping: Bool     = false
    @State private var hudVisible: Bool        = false
    @State private var hudHideTask: Task<Void, Never>? = nil

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

    private var snapPoints: [Double] {
        Array(Set(keyframes.flatMap { [$0.startTime, $0.startTime + $0.duration] })).sorted()
    }

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
            case .scale:    v.scale    = CGFloat(last.toValue)
            case .offsetX:  v.offsetX  = CGFloat(last.toValue)
            case .offsetY:  v.offsetY  = CGFloat(last.toValue)
            case .opacity:  v.opacity  = last.toValue
            case .rotation: v.rotation = last.toValue
            case .scaleX:   v.scaleX   = CGFloat(last.toValue)
            case .scaleY:   v.scaleY   = CGFloat(last.toValue)
            case .blur:     v.blur     = CGFloat(last.toValue)
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

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            previewSection
            Divider()
            timelineSection
            Divider()
            if let kfBinding = selectedKeyframe {
                inspectorSection(kfBinding)
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

    // MARK: – Scrub Evaluation

    // Computes the exact animated state at time t by evaluating each property's
    // built track using Spring.value for spring/cubic curves, linear lerp otherwise.
    private func evaluateAt(time t: Double) -> KFAnimValues {
        var result = KFAnimValues()
        let clamped = max(0, t)
        for prop in KFProperty.allCases {
            let track = buildTrack(for: prop)
            let value: Double
            if let active = track.last(where: { $0.startTime <= clamped }) {
                let elapsed = clamped - active.startTime
                if elapsed >= active.duration {
                    value = active.toValue
                } else {
                    switch active.interp {
                    case .linear:
                        value = active.fromValue + (active.toValue - active.fromValue) * (elapsed / active.duration)
                    case .spring, .cubic:
                        // Spring.value(target:time:) computes displacement from 0 toward target,
                        // starting at rest. Shift so the spring travels from fromValue to toValue.
                        let delta = active.toValue - active.fromValue
                        value = active.fromValue + active.interp.springCurve.value(
                            target: delta,
                            time: elapsed
                        )
                    }
                }
            } else {
                value = track.first?.fromValue ?? prop.defaultValue
            }
            switch prop {
            case .scale:    result.scale    = CGFloat(value)
            case .offsetX:  result.offsetX  = CGFloat(value)
            case .offsetY:  result.offsetY  = CGFloat(value)
            case .opacity:  result.opacity  = value
            case .rotation: result.rotation = value
            case .scaleX:   result.scaleX   = CGFloat(value)
            case .scaleY:   result.scaleY   = CGFloat(value)
            case .blur:     result.blur     = CGFloat(value)
            }
        }
        return result
    }

    // MARK: – Preview

    // The 5 cycling preview assets. Second item is explicitly the bookmark symbol per spec;
    // others are common interactive elements that appear throughout the app.
    @ViewBuilder
    private var previewAsset: some View {
        switch previewAssetIndex {
        case 1:
            Image(systemName: "bookmark.fill")
                .font(.system(size: 40))
                .foregroundStyle(.indigo)
        case 2:
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(.pink)
        case 3:
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
        case 4:
            Image(systemName: "bell.fill")
                .font(.system(size: 40))
                .foregroundStyle(.teal)
        default:
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
        }
    }

    @ViewBuilder
    private func previewShape(_ v: KFAnimValues) -> some View {
        previewAsset
            .blur(radius: v.blur)
            .scaleEffect(x: v.scaleX, y: v.scaleY)
            .scaleEffect(v.scale)
            .opacity(v.opacity)
            .offset(x: v.offsetX, y: v.offsetY)
            .rotationEffect(.degrees(v.rotation))
    }

    private var previewSection: some View {
        ZStack {
            Color(.systemGroupedBackground)

            if keyframes.isEmpty {
                // Tap to cycle through preview assets; dots show current position.
                // Cycling is only available while the timeline is empty.
                ZStack {
                    previewAsset
                        .id(previewAssetIndex)
                        .transition(.scale(scale: 0.72).combined(with: .opacity))

                    VStack {
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(i == previewAssetIndex
                                          ? Color.primary.opacity(0.5)
                                          : Color.secondary.opacity(0.18))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3, bounce: 0.35)) {
                        previewAssetIndex = (previewAssetIndex + 1) % 5
                    }
                }
            } else {
                ZStack {
                    // KeyframeAnimator stays in the hierarchy at all times so trigger changes
                    // always land on an existing view (not a freshly created one).
                    // Opacity hides it while the user scrubs; the scrub preview sits on top.
                    //
                    // Reverse phase uses a ternary to select a single-frame hold array rather
                    // than if/else between track groups — @KeyframesBuilder doesn't support
                    // top-level conditionals between KeyframeTrack sets.
                    let revDur = storedAnimDur > 0 ? storedAnimDur : 0.1
                    let hold: (KFProperty, Double) -> [KFKeyframe] = { prop, val in
                        [KFKeyframe(property: prop, fromValue: val, toValue: val,
                                    duration: revDur, interp: .linear)]
                    }
                    KeyframeAnimator(
                        initialValue: isReversePhase ? finalAnimValues : KFAnimValues(),
                        trigger: triggerAnimation
                    ) { v in
                        previewShape(v)
                    } keyframes: { _ in
                        KeyframeTrack(\.scale) {
                            for kf in (isReversePhase ? hold(.scale, 1.0) : buildTrack(for: .scale)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.offsetX) {
                            for kf in (isReversePhase ? hold(.offsetX, 0) : buildTrack(for: .offsetX)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.offsetY) {
                            for kf in (isReversePhase ? hold(.offsetY, 0) : buildTrack(for: .offsetY)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.opacity) {
                            for kf in (isReversePhase ? hold(.opacity, 1.0) : buildTrack(for: .opacity)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(kf.toValue, duration: kf.duration)
                                } else {
                                    SpringKeyframe(kf.toValue, duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.rotation) {
                            for kf in (isReversePhase ? hold(.rotation, 0) : buildTrack(for: .rotation)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(kf.toValue, duration: kf.duration)
                                } else {
                                    SpringKeyframe(kf.toValue, duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.scaleX) {
                            for kf in (isReversePhase ? hold(.scaleX, 1.0) : buildTrack(for: .scaleX)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.scaleY) {
                            for kf in (isReversePhase ? hold(.scaleY, 1.0) : buildTrack(for: .scaleY)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                        KeyframeTrack(\.blur) {
                            for kf in (isReversePhase ? hold(.blur, 0) : buildTrack(for: .blur)) {
                                if kf.interp == .linear {
                                    LinearKeyframe(CGFloat(kf.toValue), duration: kf.duration)
                                } else {
                                    SpringKeyframe(CGFloat(kf.toValue), duration: kf.duration, spring: kf.interp.springCurve)
                                }
                            }
                        }
                    }
                    .opacity(isPlaying ? 1 : 0)

                    // Scrub preview — exact evaluated state at current playhead position
                    if !isPlaying {
                        let t = liveScale > 0 ? Double(liveOffset / liveScale) : 0
                        previewShape(evaluateAt(time: t))
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
                    TimelineRuler(timeScale: scale, scrollOffset: offset, maxDuration: kKFMaxDuration)
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
                                        snapPoints: snapPoints,
                                        currentStartTime: kf.startTime,
                                        currentDuration: kf.duration,
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
                                        },
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

                // Snap debug HUD — top-trailing, visible when enabled and a drag is active
                if showSnapHUD && hudVisible {
                    SnapHUDView(
                        velocity:    hudVelocity,
                        velocityMin: hudVelocityMin,
                        velocityMax: hudVelocityMax,
                        threshold:   kSnapVelocityThreshold,
                        isSnapping:  hudIsSnapping
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
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
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.2)) { showSnapHUD.toggle() }
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
    private func inspectorSection(_ binding: Binding<KFKeyframe>) -> some View {
        let kf = binding.wrappedValue

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
                    Text("\(kf.property.formatted(kf.fromValue)) → \(kf.property.formatted(kf.toValue))")
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

                // From value — always editable, bound directly to this keyframe
                HStack(spacing: 10) {
                    Text("From")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Slider(value: binding.fromValue, in: kf.property.range)
                        .tint(kf.property.color.opacity(0.55))
                    Text(kf.property.formatted(kf.fromValue))
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }

                // To value — always editable
                HStack(spacing: 10) {
                    Text("To")
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Slider(value: binding.toValue, in: kf.property.range)
                        .tint(kf.property.color)
                    Text(kf.property.formatted(kf.toValue))
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .trailing)
                }

                // Interpolation
                Picker("Type", selection: binding.interp) {
                    ForEach(KFInterp.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.segmented)

                // Duration — read-only, shown in ms to match ruler
                HStack {
                    Text("Duration").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(kf.duration * 1000, specifier: "%.0f")ms")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

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
                            let prevKF = keyframes
                                .filter { $0.property == prop && $0.startTime + $0.duration <= startTime + 0.001 }
                                .max { ($0.startTime + $0.duration) < ($1.startTime + $1.duration) }
                            let fromVal = prevKF?.toValue ?? prop.defaultValue
                            let kf = KFKeyframe(property: prop, startTime: startTime,
                                                fromValue: fromVal, toValue: prop.defaultAddValue,
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
                               fromValue: prop.defaultValue, toValue: prop.defaultValue,
                               duration: total, interp: .linear)]
        }

        var result: [KFKeyframe] = []
        var cursor = 0.0

        for kf in sorted {
            if kf.startTime > cursor + 0.001 {
                // Gap before this segment: hold at its fromValue so the animator starts there
                result.append(KFKeyframe(property: prop, startTime: cursor,
                                         fromValue: kf.fromValue, toValue: kf.fromValue,
                                         duration: kf.startTime - cursor, interp: .linear))
            }
            result.append(kf)
            cursor = kf.startTime + kf.duration
        }

        if cursor < total - 0.001 {
            let lastVal = sorted.last!.toValue
            result.append(KFKeyframe(property: prop, startTime: cursor,
                                     fromValue: lastVal, toValue: lastVal,
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
    let property:         KFProperty
    let chipWidth:        CGFloat
    let chipHeight:       CGFloat
    let isSelected:       Bool
    let timeScale:        CGFloat
    let minLeftDelta:     CGFloat
    let snapPoints:       [Double]
    let currentStartTime: Double
    let currentDuration:  Double
    let onTap:            () -> Void
    let onRightDragEnd:   (CGFloat) -> Void
    let onLeftDragEnd:    (CGFloat) -> Void
    let onDragChanged:    (CGFloat, CGFloat, CGFloat, Bool) -> Void  // vel, vMin, vMax, isSnapping

    // Live drag deltas (replace @GestureState so snap can be applied before committing)
    @State private var leftDelta:  CGFloat = 0
    @State private var rightDelta: CGFloat = 0

    // Which handle is active — used to detect drag-session start for velocity reset
    private enum ActiveHandle { case none, left, right }
    @State private var activeHandle: ActiveHandle = .none

    // Velocity tracking
    @State private var velocityTracker = VelocityTracker()

    // Snap state
    @State private var wasSnapped: Bool = false
    @State private var isSnapping: Bool = false

    private var liveWidth: CGFloat {
        guard isSelected else { return max(8, chipWidth) }
        return max(8, chipWidth + rightDelta - leftDelta)
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
        .offset(x: isSelected ? leftDelta : 0)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        // One gesture on the whole chip; startLocation.x determines which handle is active.
        // including: .none when not selected lets the parent timeline pan receive these drags.
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    guard showHandles else { return }
                    let x = value.startLocation.x
                    let isLeft  = x <= kHandleW + 4
                    let isRight = x >= chipWidth - kHandleW - 4
                    guard isLeft || isRight else { return }

                    // Reset velocity stats at the start of each drag session
                    if activeHandle == .none {
                        velocityTracker.reset()
                        wasSnapped   = false
                        isSnapping   = false
                        activeHandle = isLeft ? .left : .right
                    }

                    let raw          = value.translation.width
                    let dragVelocity = velocityTracker.update(rawDelta: raw)

                    // Clamped raw delta (same bounds as before)
                    let rawDelta: CGFloat = isLeft
                        ? min(max(raw, -minLeftDelta), chipWidth - 8)
                        : max(raw, -(chipWidth - 8))

                    // Snap via shared engine — re-apply bounds clamping after snapping
                    let baseTime = isLeft ? currentStartTime : (currentStartTime + currentDuration)
                    let (engineDelta, snapping) = TimelineSnapEngine.snappedDelta(
                        rawDelta:     rawDelta,
                        baseTime:     baseTime,
                        snapPoints:   snapPoints,
                        timeScale:    timeScale,
                        snapRadiusPt: kSnapRadiusPt,
                        velocity:     dragVelocity,
                        threshold:    kSnapVelocityThreshold
                    )
                    let finalDelta: CGFloat = isLeft
                        ? min(max(engineDelta, -minLeftDelta), chipWidth - 8)
                        : max(engineDelta, -(chipWidth - 8))

                    isSnapping = snapping
                    if snapping && !wasSnapped {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        wasSnapped = true
                    } else if !snapping {
                        wasSnapped = false
                    }

                    if isLeft { leftDelta  = finalDelta }
                    else      { rightDelta = finalDelta }

                    onDragChanged(dragVelocity, velocityTracker.velocityMin, velocityTracker.velocityMax, isSnapping)
                }
                .onEnded { value in
                    guard showHandles else { return }
                    let x = value.startLocation.x
                    if x <= kHandleW + 4 {
                        onLeftDragEnd(leftDelta)
                    } else if x >= chipWidth - kHandleW - 4 {
                        onRightDragEnd(rightDelta)
                    }
                    leftDelta    = 0
                    rightDelta   = 0
                    activeHandle = .none
                    wasSnapped   = false
                    isSnapping   = false
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


#Preview {
    NavigationStack { KeyframeStudioView() }
}
