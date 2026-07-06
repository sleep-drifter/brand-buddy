import SwiftUI

// MARK: - ParamAnimation

struct ParamAnimation {
    var enabled:  Bool  = false
    var drift:    Float = 0.4   // 0–1 shown as 0–100% of param range
    var duration: Float = 0.16  // 0–1 → 1–20s (default ≈ 4s)
}

// MARK: - Effect Enum

enum ShaderEffect: String, CaseIterable, Identifiable {
    case ripple          = "Ripple"
    case pixelate        = "Pixelate"
    case chromatic       = "Chromatic"
    case wave            = "Wave"
    case grain           = "Grain"
    case vignette        = "Vignette"
    case swirl           = "Swirl"
    case emboss          = "Emboss"
    case hueRotate       = "Hue Rotate"
    case kaleidoscope    = "Kaleidoscope"
    case glitch          = "Glitch"
    case crt             = "CRT"
    case edgeDetect      = "Edge Detect"
    case fisheye         = "Fisheye"
    case progressiveBlur = "Progressive Blur"
    case dissolve        = "Dissolve"
    case zoomBlur        = "Zoom Blur"
    case holographic     = "Holographic"
    case duotone         = "Duotone"
    case halftone        = "Halftone"
    case solarize        = "Solarize"
    case frosted         = "Frosted"
    case refractLens     = "Refract Lens"

    var id: String { rawValue }
    var isTapBased:     Bool { self == .ripple || self == .zoomBlur || self == .refractLens }
    var alwaysAnimates: Bool {
        self == .wave || self == .grain || self == .glitch || self == .hueRotate || self == .holographic
    }

    var icon: String {
        switch self {
        case .ripple:          return "drop.circle"
        case .pixelate:        return "square.grid.2x2"
        case .chromatic:       return "camera.filters"
        case .wave:            return "waveform"
        case .grain:           return "film.stack"
        case .vignette:        return "circle.dashed"
        case .swirl:           return "hurricane"
        case .emboss:          return "square.on.square.dashed"
        case .hueRotate:       return "paintpalette"
        case .kaleidoscope:    return "star.6.fill"
        case .glitch:          return "bolt.horizontal"
        case .crt:             return "tv"
        case .edgeDetect:      return "squareshape.dotted.squareshape"
        case .fisheye:         return "circle.inset.filled"
        case .progressiveBlur: return "aqi.medium"
        case .dissolve:        return "flame"
        case .zoomBlur:        return "arrow.up.left.and.arrow.down.right.circle"
        case .holographic:     return "rainbow"
        case .duotone:         return "circle.lefthalf.filled"
        case .halftone:        return "circle.grid.3x3.fill"
        case .solarize:        return "sun.max.fill"
        case .frosted:         return "snowflake"
        case .refractLens:     return "magnifyingglass"
        }
    }
}

// MARK: - Preview Subject

enum PreviewSubject: String, CaseIterable {
    case wallpaper = "Wallpaper"
    case palette   = "Palette"

    var assetName: String {
        switch self {
        case .wallpaper: return "PreviewBackground"
        case .palette:   return "PreviewPalette"
        }
    }
}

// MARK: - Blur Direction

enum BlurDirection: String, CaseIterable {
    case top      = "Top"
    case bottom   = "Bottom"
    case leading  = "Leading"
    case trailing = "Trailing"

    var startPoint: UnitPoint {
        switch self {
        case .top:      return .bottom
        case .bottom:   return .top
        case .leading:  return .trailing
        case .trailing: return .leading
        }
    }
    var endPoint: UnitPoint {
        switch self {
        case .top:      return .top
        case .bottom:   return .bottom
        case .leading:  return .leading
        case .trailing: return .trailing
        }
    }
}

// MARK: - View

struct ShadersPlaygroundView: View {
    @EnvironmentObject private var pinsStore: PinsStore

    @State private var effect:  ShaderEffect   = .ripple
    @State private var subject: PreviewSubject = .wallpaper

    @State private var params:     [Float]          = Array(repeating: 0.5, count: 5)
    @State private var animParams: [ParamAnimation] = Array(repeating: ParamAnimation(), count: 5)

    @State private var blurDirection: BlurDirection = .bottom

    @State private var tapOrigin:    CGPoint = .init(x: 60, y: 60)
    @State private var rippleTapTime: Date   = .distantPast

    private let previewPt: CGFloat = 120

    private var timeSinceTap: Float {
        Float(max(0, -rippleTapTime.timeIntervalSinceNow))
    }

    private var shadersEntry: AppEntry? {
        AppEntry.all.first { $0.name == "Shaders" }
    }

    private var isBookmarked: Bool {
        shadersEntry.map { pinsStore.isPinned($0) } ?? false
    }

    private var anyParamAnimated: Bool {
        animParams.contains { $0.enabled }
    }

    private var previewAreaHeight: CGFloat {
        previewPt + 20 + (effect.isTapBased ? 28 : 0)
    }

    // MARK: - Animation helpers

    private func animatedValue(_ base: Float, anim: ParamAnimation, time: Float) -> Float {
        guard anim.enabled else { return base }
        let period = 1 + anim.duration * 19
        return min(1, max(0, base + anim.drift * sin(time * 2 * .pi / period)))
    }

    private func ep(_ i: Int, time: Float) -> Float {
        animatedValue(params[i], anim: animParams[i], time: time)
    }

    // MARK: - Subject fallback

    @ViewBuilder
    private var subjectFallback: some View {
        switch subject {
        case .wallpaper:
            AngularGradient(
                colors: [
                    Color(hue: 0.62, saturation: 0.9,  brightness: 0.95),
                    Color(hue: 0.55, saturation: 0.85, brightness: 0.75),
                    Color(hue: 0.50, saturation: 0.95, brightness: 0.85),
                    Color(hue: 0.58, saturation: 0.7,  brightness: 0.5),
                    Color(hue: 0.62, saturation: 0.9,  brightness: 0.95)
                ],
                center: .bottomLeading
            )
        case .palette:
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.45),                         location: 0.0),
                    .init(color: Color(white: 0.18),                         location: 0.2),
                    .init(color: .black,                                      location: 0.32),
                    .init(color: Color(red: 0.0,  green: 0.10, blue: 0.58), location: 0.45),
                    .init(color: Color(red: 0.09, green: 0.46, blue: 0.78), location: 0.65),
                    .init(color: Color(red: 0.13, green: 0.60, blue: 0.37), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Space for the floating preview
                    Color.clear.frame(height: previewAreaHeight + 8)

                    controlsSection
                        .padding(.top, 8)
                        .padding(.horizontal, 16)

                    if !effect.isTapBased {
                        animationSection
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 40)
                }
            }

            // Preview floats above scroll content — clear background lets content show through
            previewArea
        }
        .navigationTitle("Shaders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let entry = shadersEntry {
                        pinsStore.toggle(entry)
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: shuffle) {
                    Image(systemName: "shuffle")
                }
            }
        }
        .onChange(of: effect) { _, newEffect in
            params         = defaultParams(for: newEffect)
            animParams     = Array(repeating: ParamAnimation(), count: 5)
            blurDirection  = .bottom
        }
    }

    // MARK: - Preview Area (no card — clear bg so scroll content shows through)

    private var previewArea: some View {
        VStack(spacing: 8) {
            // Full-width card — image is centered at its natural size so shader
            // parameters (center, radius, etc.) remain correct.
            ZStack {
                Group {
                    if effect.isTapBased {
                        TimelineView(.animation) { _ in
                            shaderView(time: timeSinceTap)
                        }
                    } else if effect.alwaysAnimates || anyParamAnimated {
                        TimelineView(.animation) { tl in
                            shaderView(time: Float(tl.date.timeIntervalSinceReferenceDate))
                        }
                    } else {
                        shaderView(time: 0)
                    }
                }
                .frame(width: previewPt, height: previewPt)
                // Gesture stays on the 120 pt image so .local coordinates
                // match what the shaders expect.
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onEnded { val in
                            guard effect.isTapBased else { return }
                            tapOrigin = val.location
                            if effect == .ripple { rippleTapTime = Date() }
                        }
                )
            }
            .frame(maxWidth: .infinity)          // card fills margin-to-margin
            .previewCanvas(clipped: effect != .progressiveBlur)
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

            if effect.isTapBased {
                Text("Tap the preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Shader View

    @ViewBuilder
    private func shaderView(time: Float) -> some View {
        let img = ZStack {
            subjectFallback
            Image(subject.assetName)
                .resizable()
                .scaledToFill()
        }
        .frame(width: previewPt, height: previewPt)
        .clipped()  // contain scaledToFill inside the square frame before shader runs

        switch effect {
        case .ripple:
            img.distortionEffect(
                ShaderLibrary.shaderRipple(
                    .float(time),
                    .float2(tapOrigin),
                    .float(ep(0, time: time) * 80),
                    .float(1 + ep(1, time: time) * 59),
                    .float(0.001 + ep(3, time: time) * 0.049),
                    .float(ep(2, time: time) * 80),
                    .float(1 + ep(4, time: time) * 24)
                ),
                maxSampleOffset: CGSize(width: 80, height: 80)
            )

        case .pixelate:
            img.layerEffect(
                ShaderLibrary.shaderPixelate(.float(1 + ep(0, time: time) * 199)),
                maxSampleOffset: .zero
            )

        case .chromatic:
            img.layerEffect(
                ShaderLibrary.shaderChromatic(
                    .float(ep(0, time: time) * 80),
                    .float(ep(1, time: time) * 40)
                ),
                maxSampleOffset: CGSize(width: 80, height: 40)
            )

        case .wave:
            // Speed has a floor of 0.3 so wave never freezes
            img.distortionEffect(
                ShaderLibrary.shaderWave(
                    .float(time * (0.3 + ep(2, time: time) * 4.7)),
                    .float(ep(0, time: time) * 80),
                    .float(0.02 + ep(1, time: time) * 0.28)
                ),
                maxSampleOffset: CGSize(width: 80, height: 80)
            )

        case .grain:
            img.colorEffect(
                ShaderLibrary.shaderGrain(
                    .float(time),
                    .float(ep(0, time: time) * 2.0),
                    .float(0.5 + ep(1, time: time) * 19.5),
                    .float(ep(2, time: time))
                )
            )

        case .vignette:
            img.colorEffect(
                ShaderLibrary.shaderVignette(
                    .float2(CGSize(width: previewPt, height: previewPt)),
                    .float(ep(0, time: time) * 2.5),
                    .float(ep(1, time: time) * 1.5)
                )
            )

        case .swirl:
            img.distortionEffect(
                ShaderLibrary.shaderSwirl(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(ep(0, time: time) * .pi * 8),
                    .float(Float(previewPt) * ep(1, time: time))
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            )

        case .emboss:
            img.layerEffect(
                ShaderLibrary.shaderEmboss(.float(ep(0, time: time) * 20)),
                maxSampleOffset: CGSize(width: 20, height: 20)
            )

        case .hueRotate:
            img.colorEffect(
                ShaderLibrary.shaderHueRotate(
                    .float(time + ep(0, time: time) * .pi * 2)
                )
            )

        case .kaleidoscope:
            img.distortionEffect(
                ShaderLibrary.shaderKaleidoscope(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(Float(1 + Int(ep(0, time: time) * 23))),
                    .float(ep(1, time: time) * .pi * 2)
                ),
                maxSampleOffset: CGSize(width: previewPt / 2, height: previewPt / 2)
            )

        case .glitch:
            img.layerEffect(
                ShaderLibrary.shaderGlitch(
                    .float(time),
                    .float(ep(0, time: time)),
                    .float(1 + ep(1, time: time) * 99),
                    .float(0.5 + ep(2, time: time) * 59.5),
                    .float(ep(3, time: time) * 50)
                ),
                maxSampleOffset: CGSize(width: 100, height: 0)
            )

        case .crt:
            img.layerEffect(
                ShaderLibrary.shaderCRT(
                    .float2(CGSize(width: previewPt, height: previewPt)),
                    .float(ep(0, time: time)),
                    .float(ep(1, time: time) * 2.0),
                    .float(ep(2, time: time) * 5.0)
                ),
                maxSampleOffset: CGSize(width: previewPt / 2, height: previewPt / 2)
            )

        case .edgeDetect:
            img.layerEffect(
                ShaderLibrary.shaderEdgeDetect(
                    .float(ep(0, time: time) * 30),
                    .float(ep(1, time: time)),
                    .float(0.5 + ep(2, time: time) * 11.5)
                ),
                maxSampleOffset: CGSize(width: 12, height: 12)
            )

        case .fisheye:
            img.distortionEffect(
                ShaderLibrary.shaderFisheye(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(ep(0, time: time) * 5.0),
                    .float(Float(previewPt) * ep(1, time: time))
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            )

        case .progressiveBlur:
            // Native SwiftUI: stacked blur layers with gradient masks — no Metal needed
            // start/stop are normalized positions along blurDirection's axis
            let maxR  = CGFloat(ep(0, time: time)) * 60
            let start = Double(ep(1, time: time))
            let stop  = Double(max(ep(1, time: time), ep(2, time: time)))
            let range = max(stop - start, 0.01)
            let sp    = blurDirection.startPoint
            let ep2   = blurDirection.endPoint
            ZStack {
                img
                img.blur(radius: maxR * 0.3)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear,              location: start),
                        .init(color: .black.opacity(0.5), location: min(start + range * 0.4, 1))
                    ], startPoint: sp, endPoint: ep2))
                img.blur(radius: maxR * 0.65)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear,              location: min(start + range * 0.3, 1)),
                        .init(color: .black.opacity(0.8), location: min(start + range * 0.7, 1))
                    ], startPoint: sp, endPoint: ep2))
                img.blur(radius: maxR)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear, location: min(start + range * 0.6, 1)),
                        .init(color: .black, location: min(stop, 1))
                    ], startPoint: sp, endPoint: ep2))
            }

        case .dissolve:
            img.colorEffect(
                ShaderLibrary.shaderDissolve(
                    .float(ep(0, time: time)),
                    .float(ep(1, time: time)),
                    .float(ep(2, time: time)),
                    .float(0.5 + ep(3, time: time) * 9.5)
                )
            )

        case .zoomBlur:
            img.layerEffect(
                ShaderLibrary.shaderZoomBlur(
                    .float2(tapOrigin),
                    .float(ep(0, time: time) * 0.9)
                ),
                maxSampleOffset: CGSize(width: 110, height: 110)
            )

        case .holographic:
            img.colorEffect(
                ShaderLibrary.shaderHolographic(
                    .float(time),
                    .float(ep(0, time: time) * 1.2),
                    .float(4 + ep(1, time: time) * 96),
                    .float(ep(2, time: time) * 3.0)
                )
            )

        case .duotone:
            img.colorEffect(
                ShaderLibrary.shaderDuotone(
                    .float(ep(0, time: time)),
                    .float(ep(1, time: time)),
                    .float(ep(2, time: time))
                )
            )

        case .halftone:
            img.colorEffect(
                ShaderLibrary.shaderHalftone(
                    .float(3 + ep(0, time: time) * 21),
                    .float(ep(1, time: time) * .pi),
                    .float(ep(2, time: time))
                )
            )

        case .solarize:
            img.colorEffect(
                ShaderLibrary.shaderSolarize(
                    .float(ep(0, time: time)),
                    .float(0.2 + ep(1, time: time) * 0.8)
                )
            )

        case .frosted:
            img.layerEffect(
                ShaderLibrary.shaderFrosted(
                    .float(ep(0, time: time) * 20),
                    .float(ep(1, time: time) * 0.3)
                ),
                maxSampleOffset: CGSize(width: 20, height: 20)
            )

        case .refractLens:
            img.distortionEffect(
                ShaderLibrary.shaderRefractLens(
                    .float2(tapOrigin),
                    .float(20 + ep(0, time: time) * 100),
                    .float(ep(1, time: time) * 0.55)
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            )
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Controls")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                row {
                    LabeledPicker(label: "Asset") {
                        Picker("Asset", selection: $subject) {
                            ForEach(PreviewSubject.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                    }
                }
                divider
                row {
                    LabeledPicker(label: "Shader") {
                        Picker("Shader", selection: $effect) {
                            ForEach(ShaderEffect.allCases) { e in
                                Label(e.rawValue, systemImage: e.icon).tag(e)
                            }
                        }
                    }
                }
                if effect == .progressiveBlur {
                    divider
                    row {
                        LabeledPicker(label: "Direction") {
                            Picker("Direction", selection: $blurDirection) {
                                ForEach(BlurDirection.allCases, id: \.self) { d in
                                    Text(d.rawValue).tag(d)
                                }
                            }
                        }
                    }
                }
                ForEach(controlRows, id: \.label) { ctrl in
                    divider
                    row {
                        LabeledSlider(label: ctrl.label, value: ctrl.binding, display: ctrl.display)
                    }
                }
                if effect.isTapBased {
                    divider
                    row {
                        HStack {
                            Text("Interaction").foregroundStyle(.secondary)
                            Spacer()
                            Text("Tap preview").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Animation Section

    private var animationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Animation")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                if anyParamAnimated {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                        Text("Live")
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                if effect.alwaysAnimates {
                    row {
                        Label("Effect animates continuously", systemImage: "play.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    divider
                    row {
                        Text("Per-param drift runs on top of the effect's built-in animation.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    let rows = controlRows
                    ForEach(Array(rows.enumerated()), id: \.offset) { idx, ctrl in
                        let anim = $animParams[idx]
                        divider
                        row { Toggle(ctrl.label, isOn: anim.enabled) }
                        if anim.enabled.wrappedValue {
                            divider
                            row {
                                LabeledSlider(
                                    label: "Drift",
                                    value: anim.drift,
                                    display: String(format: "%.0f%%", anim.drift.wrappedValue * 100)
                                )
                            }
                            divider
                            row {
                                LabeledSlider(
                                    label: "Duration",
                                    value: anim.duration,
                                    display: String(format: "%.0fs", 1 + anim.duration.wrappedValue * 19)
                                )
                            }
                        }
                    }
                } else {
                    let rows = controlRows
                    ForEach(Array(rows.enumerated()), id: \.offset) { idx, ctrl in
                        let anim = $animParams[idx]
                        if idx > 0 { divider }
                        row { Toggle(ctrl.label, isOn: anim.enabled) }
                        if anim.enabled.wrappedValue {
                            divider
                            row {
                                LabeledSlider(
                                    label: "Drift",
                                    value: anim.drift,
                                    display: String(format: "%.0f%%", anim.drift.wrappedValue * 100)
                                )
                            }
                            divider
                            row {
                                LabeledSlider(
                                    label: "Duration",
                                    value: anim.duration,
                                    display: String(format: "%.0fs", 1 + anim.duration.wrappedValue * 19)
                                )
                            }
                        }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Control Rows

    private var controlRows: [(label: String, binding: Binding<Float>, display: String)] {
        switch effect {
        case .ripple:
            return [
                ("Amplitude",     $params[0], "\(Int(params[0] * 80))pt"),
                ("Wavelength",    $params[1], "\(Int(1 + params[1] * 59))pt"),
                ("Spread",        $params[2], "\(Int(params[2] * 80))pt"),
                ("Decay",         $params[3], String(format: "%.3f", 0.001 + params[3] * 0.049)),
                ("Speed",         $params[4], String(format: "%.1f", 1 + params[4] * 24))
            ]
        case .pixelate:
            return [("Block Size", $params[0], "\(Int(1 + params[0] * 199))px")]
        case .chromatic:
            return [
                ("H Offset", $params[0], "\(Int(params[0] * 80))pt"),
                ("V Offset", $params[1], "\(Int(params[1] * 40))pt")
            ]
        case .wave:
            return [
                ("Amplitude",  $params[0], "\(Int(params[0] * 80))pt"),
                ("Frequency",  $params[1], String(format: "%.3f", 0.02 + params[1] * 0.28)),
                ("Speed",      $params[2], String(format: "%.1f×", 0.3 + params[2] * 4.7))
            ]
        case .grain:
            return [
                ("Intensity",  $params[0], String(format: "%.0f%%", params[0] * 200)),
                ("Size",       $params[1], String(format: "%.1fpx", 0.5 + params[1] * 19.5)),
                ("Chroma",     $params[2], String(format: "%.0f%%", params[2] * 100))
            ]
        case .vignette:
            return [
                ("Radius",     $params[0], String(format: "%.2f", params[0] * 2.5)),
                ("Softness",   $params[1], String(format: "%.2f", params[1] * 1.5))
            ]
        case .swirl:
            return [
                ("Angle",      $params[0], String(format: "%.0f°", params[0] * 1440)),
                ("Radius",     $params[1], "\(Int(Float(previewPt) * params[1]))pt")
            ]
        case .emboss:
            return [("Depth", $params[0], String(format: "%.1f", params[0] * 20))]
        case .hueRotate:
            return [("Shift", $params[0], String(format: "%.0f°", params[0] * 360))]
        case .kaleidoscope:
            return [
                ("Segments",   $params[0], "\(1 + Int(params[0] * 23))"),
                ("Rotation",   $params[1], String(format: "%.0f°", params[1] * 360))
            ]
        case .glitch:
            return [
                ("Intensity",     $params[0], String(format: "%.0f%%", params[0] * 100)),
                ("Block Size",    $params[1], "\(Int(1 + params[1] * 99))pt"),
                ("Speed",         $params[2], String(format: "%.0ffps", 0.5 + params[2] * 59.5)),
                ("Channel Split", $params[3], "\(Int(params[3] * 50))pt")
            ]
        case .crt:
            return [
                ("Scanlines",  $params[0], String(format: "%.0f%%", params[0] * 100)),
                ("Curvature",  $params[1], String(format: "%.2f", params[1] * 2.0)),
                ("Vignette",   $params[2], String(format: "%.1f", params[2] * 5.0))
            ]
        case .edgeDetect:
            return [
                ("Strength",   $params[0], String(format: "%.1f", params[0] * 30)),
                ("Threshold",  $params[1], String(format: "%.2f", params[1])),
                ("Step",       $params[2], String(format: "%.1fpx", 0.5 + params[2] * 11.5))
            ]
        case .fisheye:
            return [
                ("Strength",   $params[0], String(format: "%.2f", params[0] * 5.0)),
                ("Radius",     $params[1], "\(Int(Float(previewPt) * params[1]))pt")
            ]
        case .progressiveBlur:
            return [
                ("Radius",      $params[0], "\(Int(params[0] * 60))pt"),
                ("Blur Start",  $params[1], String(format: "%.0f%%", params[1] * 100)),
                ("Blur Stop",   $params[2], String(format: "%.0f%%", params[2] * 100))
            ]
        case .dissolve:
            return [
                ("Threshold",  $params[0], String(format: "%.0f%%", params[0] * 100)),
                ("Softness",   $params[1], String(format: "%.0f%%", params[1] * 100)),
                ("Glow",       $params[2], String(format: "%.0f%%", params[2] * 100)),
                ("Scale",      $params[3], String(format: "%.1f", 0.5 + params[3] * 9.5))
            ]
        case .zoomBlur:
            return [("Strength", $params[0], String(format: "%.0f%%", params[0] * 90))]
        case .holographic:
            return [
                ("Intensity", $params[0], String(format: "%.0f%%", params[0] * 120)),
                ("Band Width", $params[1], "\(Int(4 + params[1] * 96))pt"),
                ("Speed",     $params[2], String(format: "%.1f×", params[2] * 3.0))
            ]
        case .duotone:
            return [
                ("Shadow Hue",    $params[0], String(format: "%.0f°", params[0] * 360)),
                ("Highlight Hue", $params[1], String(format: "%.0f°", params[1] * 360)),
                ("Contrast",      $params[2], String(format: "%.0f%%", params[2] * 100))
            ]
        case .halftone:
            return [
                ("Cell Size", $params[0], "\(Int(3 + params[0] * 21))px"),
                ("Angle",     $params[1], String(format: "%.0f°", params[1] * 180)),
                ("Ink",       $params[2], String(format: "%.0f%%", params[2] * 100))
            ]
        case .solarize:
            return [
                ("Threshold", $params[0], String(format: "%.2f", params[0])),
                ("Amount",    $params[1], String(format: "%.0f%%", (0.2 + params[1] * 0.8) * 100))
            ]
        case .frosted:
            return [
                ("Radius",     $params[0], "\(Int(params[0] * 20))pt"),
                ("Brightness", $params[1], String(format: "%.0f%%", params[1] * 30))
            ]
        case .refractLens:
            return [
                ("Radius",   $params[0], "\(Int(20 + params[0] * 100))pt"),
                ("Strength", $params[1], String(format: "%.0f%%", params[1] * 55))
            ]
        }
    }

    // MARK: - Default params

    private func defaultParams(for effect: ShaderEffect) -> [Float] {
        switch effect {
        case .ripple:          return [0.35, 0.35, 0.2,  0.3,  0.35]
        case .pixelate:        return [0.05, 0.5,  0.5,  0.5,  0.5 ]
        case .chromatic:       return [0.3,  0.3,  0.5,  0.5,  0.5 ]
        case .wave:            return [0.55, 0.45, 0.45, 0.5,  0.5 ] // amp=44pt, freq=0.146, speed=2.4×
        case .grain:           return [0.35, 0.25, 0.5,  0.5,  0.5 ]
        case .vignette:        return [0.4,  0.3,  0.5,  0.5,  0.5 ]
        case .swirl:           return [0.25, 0.5,  0.5,  0.5,  0.5 ]
        case .emboss:          return [0.2,  0.5,  0.5,  0.5,  0.5 ]
        case .hueRotate:       return [0.5,  0.5,  0.5,  0.5,  0.5 ]
        case .kaleidoscope:    return [0.25, 0.5,  0.5,  0.5,  0.5 ]
        case .glitch:          return [0.4,  0.2,  0.25, 0.2,  0.5 ]
        case .crt:             return [0.45, 0.2,  0.15, 0.5,  0.5 ]
        case .edgeDetect:      return [0.2,  0.15, 0.1,  0.5,  0.5 ]
        case .fisheye:         return [0.25, 0.55, 0.5,  0.5,  0.5 ]
        case .progressiveBlur: return [0.45, 0.2,  0.65, 0.5,  0.5 ]
        case .dissolve:        return [0.35, 0.25, 0.8,  0.35, 0.5 ]
        case .zoomBlur:        return [0.35, 0.5,  0.5,  0.5,  0.5 ]
        case .holographic:     return [0.6,  0.35, 0.4,  0.5,  0.5 ]
        case .duotone:         return [0.62, 0.12, 0.5,  0.5,  0.5 ] // indigo shadows → warm highlights
        case .halftone:        return [0.4,  0.25, 0.6,  0.5,  0.5 ]
        case .solarize:        return [0.5,  0.7,  0.5,  0.5,  0.5 ]
        case .frosted:         return [0.5,  0.4,  0.5,  0.5,  0.5 ]
        case .refractLens:     return [0.45, 0.5,  0.5,  0.5,  0.5 ]
        }
    }

    // MARK: - Helpers

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    private func shuffle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            effect  = ShaderEffect.allCases.randomElement()!
            subject = PreviewSubject.allCases.randomElement()!
            params  = (0..<5).map { _ in Float.random(in: 0.15...0.85) }
        }
    }
}

// MARK: - Labeled Picker

private struct LabeledPicker<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label).frame(width: 88, alignment: .leading)
            Spacer()
            content().labelsHidden()
        }
    }
}

// MARK: - Labeled Slider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Float
    let display: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .frame(width: 104, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Slider(value: $value)
            Text(display)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private extension View {
    // Clips the shader result to a rounded rect and backs it with ultraThinMaterial.
    // progressiveBlur passes clipped:false so the native SwiftUI blur can bleed
    // past the frame edge naturally (matching how it behaves in real UI like Control Center).
    @ViewBuilder
    func previewCanvas(clipped: Bool) -> some View {
        if clipped {
            self
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        }
    }
}

#Preview {
    NavigationStack {
        ShadersPlaygroundView()
    }
    .environmentObject(PinsStore())
}
