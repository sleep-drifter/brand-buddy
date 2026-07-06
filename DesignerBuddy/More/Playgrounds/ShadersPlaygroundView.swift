import SwiftUI
import PhotosUI
import UIKit
import Combine

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
    case colorGrade      = "Color Grade"
    case topographic     = "Topographic"

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
        case .colorGrade:      return "camera.aperture"
        case .topographic:     return "mountain.2"
        }
    }

    // Default slider positions (5 slots) for each effect.
    var defaultParams: [Float] {
        switch self {
        case .ripple:          return [0.35, 0.35, 0.2,  0.3,  0.35]
        case .pixelate:        return [0.05, 0.5,  0.5,  0.5,  0.5 ]
        case .chromatic:       return [0.3,  0.3,  0.5,  0.5,  0.5 ]
        case .wave:            return [0.55, 0.45, 0.45, 0.5,  0.5 ]
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
        case .duotone:         return [0.62, 0.12, 0.5,  0.5,  0.5 ]
        case .halftone:        return [0.4,  0.25, 0.6,  0.5,  0.5 ]
        case .solarize:        return [0.5,  0.7,  0.5,  0.5,  0.5 ]
        case .frosted:         return [0.5,  0.4,  0.5,  0.5,  0.5 ]
        case .refractLens:     return [0.45, 0.5,  0.5,  0.5,  0.5 ]
        case .colorGrade:      return [1.0,  0.5,  0.5,  0.5,  0.5 ]
        case .topographic:     return [0.4,  0.2,  0.6,  0.5,  0.5 ]
        }
    }
}

// MARK: - Grade Look

enum GradeLook: String, CaseIterable {
    case neutral      = "Neutral"
    case tealOrange   = "Teal-Orange"
    case warmVintage  = "Warm Vintage"
    case bleachBypass = "Bleach Bypass"
    case noir         = "Noir"
    case crossProcess = "Cross Process"
    case faded        = "Faded"

    var index: Float { Float(GradeLook.allCases.firstIndex(of: self) ?? 0) }
}

// MARK: - Preview Subject

enum PreviewSubject: String, CaseIterable {
    case wallpaper = "Wallpaper"
    case palette   = "Palette"
    case photo     = "Photo"

    var assetName: String {
        switch self {
        case .wallpaper: return "PreviewBackground"
        case .palette:   return "PreviewPalette"
        case .photo:     return ""
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

// MARK: - Layer Model

struct ShaderLayer: Identifiable {
    let id = UUID()
    var effect: ShaderEffect
    var params: [Float]
    var anim:   [ParamAnimation]
    var blurDirection: BlurDirection = .bottom
    var gradeLook:     GradeLook     = .tealOrange

    init(effect: ShaderEffect) {
        self.effect = effect
        self.params = effect.defaultParams
        self.anim   = Array(repeating: ParamAnimation(), count: 5)
    }
}

// MARK: - Presets (persisted)

struct PresetLayer: Codable {
    var effect: String
    var params: [Float]
    var blurDirection: String
    var gradeLook: String
}

struct ShaderPreset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var layers: [PresetLayer]
}

final class ShaderPresetStore: ObservableObject {
    @Published private(set) var presets: [ShaderPreset] = []
    private let key = "shaderPresets.v1"

    init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ShaderPreset].self, from: data) else { return }
        presets = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ preset: ShaderPreset) {
        presets.append(preset)
        persist()
    }

    func delete(_ preset: ShaderPreset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }
}

// MARK: - View

struct ShadersPlaygroundView: View {
    @EnvironmentObject private var pinsStore: PinsStore
    @StateObject private var presetStore = ShaderPresetStore()

    @State private var layers: [ShaderLayer] = [ShaderLayer(effect: .ripple)]
    @State private var selectedLayerID: UUID?

    @State private var subject: PreviewSubject = .wallpaper
    @State private var photoItem:  PhotosPickerItem?
    @State private var photoImage: Image?

    @State private var tapOrigin:     CGPoint = .init(x: 60, y: 60)
    @State private var rippleTapTime: Date    = .distantPast

    @State private var showSaveAlert = false
    @State private var presetName    = ""

    private let previewPt: CGFloat = 120
    private let maxLayers  = 4

    // MARK: - Derived state

    private var selectedIndex: Int {
        if let id = selectedLayerID, let i = layers.firstIndex(where: { $0.id == id }) { return i }
        return 0
    }
    private var selectedLayer: ShaderLayer { layers[selectedIndex] }

    private var anyTap:             Bool { layers.contains { $0.effect.isTapBased } }
    private var anyAlways:          Bool { layers.contains { $0.effect.alwaysAnimates } }
    private var anyParamAnimated:   Bool { layers.contains { $0.anim.contains { $0.enabled } } }
    private var anyProgressiveBlur: Bool { layers.contains { $0.effect == .progressiveBlur } }

    private var timeSinceTap: Float {
        Float(max(0, -rippleTapTime.timeIntervalSinceNow))
    }

    private var previewAreaHeight: CGFloat {
        previewPt + 20 + (anyTap ? 28 : 0)
    }

    private var shadersEntry: AppEntry? {
        AppEntry.all.first { $0.name == "Shaders" }
    }
    private var isBookmarked: Bool {
        shadersEntry.map { pinsStore.isPinned($0) } ?? false
    }

    // MARK: - Animation helpers

    private func animatedValue(_ base: Float, anim: ParamAnimation, time: Float) -> Float {
        guard anim.enabled else { return base }
        let period = 1 + anim.duration * 19
        return min(1, max(0, base + anim.drift * sin(time * 2 * .pi / period)))
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
                    .init(color: Color(white: 0.45),                        location: 0.0),
                    .init(color: Color(white: 0.18),                        location: 0.2),
                    .init(color: .black,                                     location: 0.32),
                    .init(color: Color(red: 0.0,  green: 0.10, blue: 0.58), location: 0.45),
                    .init(color: Color(red: 0.09, green: 0.46, blue: 0.78), location: 0.65),
                    .init(color: Color(red: 0.13, green: 0.60, blue: 0.37), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .photo:
            Color(.systemGray5)
        }
    }

    private var imageBase: AnyView {
        AnyView(
            ZStack {
                subjectFallback
                if subject == .photo {
                    if let photoImage {
                        photoImage.resizable().scaledToFill()
                    }
                } else {
                    Image(subject.assetName).resizable().scaledToFill()
                }
            }
            .frame(width: previewPt, height: previewPt)
            .clipped()
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: previewAreaHeight + 8)

                    controlsSection
                        .padding(.top, 8)
                        .padding(.horizontal, 16)

                    layersSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                    editorSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                    if !selectedLayer.effect.isTapBased {
                        animationSection
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                    }

                    presetsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 40)
                }
            }

            previewArea
        }
        .navigationTitle("Shaders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let entry = shadersEntry { pinsStore.toggle(entry) }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: shuffle) { Image(systemName: "shuffle") }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    photoImage = Image(uiImage: ui)
                    subject = .photo
                }
            }
        }
        .alert("Save Preset", isPresented: $showSaveAlert) {
            TextField("Name", text: $presetName)
            Button("Save") {
                let name = presetName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { presetStore.add(makePreset(name: name)) }
                presetName = ""
            }
            Button("Cancel", role: .cancel) { presetName = "" }
        } message: {
            Text("Save the current \(layers.count)-layer stack.")
        }
        .onAppear {
            if selectedLayerID == nil { selectedLayerID = layers.first?.id }
        }
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        VStack(spacing: 8) {
            ZStack {
                Group {
                    if anyTap {
                        TimelineView(.animation) { _ in
                            shaderView(time: timeSinceTap)
                        }
                    } else if anyAlways || anyParamAnimated {
                        TimelineView(.animation) { tl in
                            shaderView(time: Float(tl.date.timeIntervalSinceReferenceDate))
                        }
                    } else {
                        shaderView(time: 0)
                    }
                }
                .frame(width: previewPt, height: previewPt)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onEnded { val in
                            guard anyTap else { return }
                            tapOrigin = val.location
                            if layers.contains(where: { $0.effect == .ripple }) {
                                rippleTapTime = Date()
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity)
            .previewCanvas(clipped: !anyProgressiveBlur)
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

            if anyTap {
                Text("Tap the preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Shader Stack

    private func shaderView(time: Float) -> AnyView {
        layers.reduce(imageBase) { acc, layer in
            applyEffect(to: acc, layer: layer, time: time)
        }
    }

    private func applyEffect(to view: AnyView, layer: ShaderLayer, time: Float) -> AnyView {
        func av(_ i: Int) -> Float { animatedValue(layer.params[i], anim: layer.anim[i], time: time) }

        switch layer.effect {
        case .ripple:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderRipple(
                    .float(time),
                    .float2(tapOrigin),
                    .float(av(0) * 80),
                    .float(1 + av(1) * 59),
                    .float(0.001 + av(3) * 0.049),
                    .float(av(2) * 80),
                    .float(1 + av(4) * 24)
                ),
                maxSampleOffset: CGSize(width: 80, height: 80)
            ))

        case .pixelate:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderPixelate(.float(1 + av(0) * 199)),
                maxSampleOffset: .zero
            ))

        case .chromatic:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderChromatic(.float(av(0) * 80), .float(av(1) * 40)),
                maxSampleOffset: CGSize(width: 80, height: 40)
            ))

        case .wave:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderWave(
                    .float(time * (0.3 + av(2) * 4.7)),
                    .float(av(0) * 80),
                    .float(0.02 + av(1) * 0.28)
                ),
                maxSampleOffset: CGSize(width: 80, height: 80)
            ))

        case .grain:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderGrain(
                    .float(time),
                    .float(av(0) * 2.0),
                    .float(0.5 + av(1) * 19.5),
                    .float(av(2))
                )
            ))

        case .vignette:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderVignette(
                    .float2(CGSize(width: previewPt, height: previewPt)),
                    .float(av(0) * 2.5),
                    .float(av(1) * 1.5)
                )
            ))

        case .swirl:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderSwirl(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(av(0) * .pi * 8),
                    .float(Float(previewPt) * av(1))
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            ))

        case .emboss:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderEmboss(.float(av(0) * 20)),
                maxSampleOffset: CGSize(width: 20, height: 20)
            ))

        case .hueRotate:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderHueRotate(.float(time + av(0) * .pi * 2))
            ))

        case .kaleidoscope:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderKaleidoscope(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(Float(1 + Int(av(0) * 23))),
                    .float(av(1) * .pi * 2)
                ),
                maxSampleOffset: CGSize(width: previewPt / 2, height: previewPt / 2)
            ))

        case .glitch:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderGlitch(
                    .float(time),
                    .float(av(0)),
                    .float(1 + av(1) * 99),
                    .float(0.5 + av(2) * 59.5),
                    .float(av(3) * 50)
                ),
                maxSampleOffset: CGSize(width: 100, height: 0)
            ))

        case .crt:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderCRT(
                    .float2(CGSize(width: previewPt, height: previewPt)),
                    .float(av(0)),
                    .float(av(1) * 2.0),
                    .float(av(2) * 5.0)
                ),
                maxSampleOffset: CGSize(width: previewPt / 2, height: previewPt / 2)
            ))

        case .edgeDetect:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderEdgeDetect(
                    .float(av(0) * 30),
                    .float(av(1)),
                    .float(0.5 + av(2) * 11.5)
                ),
                maxSampleOffset: CGSize(width: 12, height: 12)
            ))

        case .fisheye:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderFisheye(
                    .float2(CGPoint(x: previewPt / 2, y: previewPt / 2)),
                    .float(av(0) * 5.0),
                    .float(Float(previewPt) * av(1))
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            ))

        case .progressiveBlur:
            let maxR  = CGFloat(av(0)) * 60
            let start = Double(av(1))
            let stop  = Double(max(av(1), av(2)))
            let range = max(stop - start, 0.01)
            let sp    = layer.blurDirection.startPoint
            let ep2   = layer.blurDirection.endPoint
            return AnyView(ZStack {
                view
                view.blur(radius: maxR * 0.3)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear,              location: start),
                        .init(color: .black.opacity(0.5), location: min(start + range * 0.4, 1))
                    ], startPoint: sp, endPoint: ep2))
                view.blur(radius: maxR * 0.65)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear,              location: min(start + range * 0.3, 1)),
                        .init(color: .black.opacity(0.8), location: min(start + range * 0.7, 1))
                    ], startPoint: sp, endPoint: ep2))
                view.blur(radius: maxR)
                    .mask(LinearGradient(stops: [
                        .init(color: .clear, location: min(start + range * 0.6, 1)),
                        .init(color: .black, location: min(stop, 1))
                    ], startPoint: sp, endPoint: ep2))
            })

        case .dissolve:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderDissolve(
                    .float(av(0)),
                    .float(av(1)),
                    .float(av(2)),
                    .float(0.5 + av(3) * 9.5)
                )
            ))

        case .zoomBlur:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderZoomBlur(.float2(tapOrigin), .float(av(0) * 0.9)),
                maxSampleOffset: CGSize(width: 110, height: 110)
            ))

        case .holographic:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderHolographic(
                    .float(time),
                    .float(av(0) * 1.2),
                    .float(4 + av(1) * 96),
                    .float(av(2) * 3.0)
                )
            ))

        case .duotone:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderDuotone(.float(av(0)), .float(av(1)), .float(av(2)))
            ))

        case .halftone:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderHalftone(.float(3 + av(0) * 21), .float(av(1) * .pi), .float(av(2)))
            ))

        case .solarize:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderSolarize(.float(av(0)), .float(0.2 + av(1) * 0.8))
            ))

        case .frosted:
            return AnyView(view.layerEffect(
                ShaderLibrary.shaderFrosted(.float(av(0) * 20), .float(av(1) * 0.3)),
                maxSampleOffset: CGSize(width: 20, height: 20)
            ))

        case .refractLens:
            return AnyView(view.distortionEffect(
                ShaderLibrary.shaderRefractLens(
                    .float2(tapOrigin),
                    .float(20 + av(0) * 100),
                    .float(av(1) * 0.55)
                ),
                maxSampleOffset: CGSize(width: previewPt, height: previewPt)
            ))

        case .colorGrade:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderColorGrade(.float(layer.gradeLook.index), .float(av(0)))
            ))

        case .topographic:
            return AnyView(view.colorEffect(
                ShaderLibrary.shaderTopographic(
                    .float(2 + av(0) * 18),
                    .float(0.02 + av(1) * 0.4),
                    .float(av(2))
                )
            ))
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Source")

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
                if subject == .photo {
                    divider
                    row {
                        HStack {
                            Text("Photo").frame(width: 88, alignment: .leading)
                            Spacer()
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label(photoImage == nil ? "Choose" : "Replace",
                                      systemImage: "photo.on.rectangle")
                            }
                        }
                    }
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Layers Section

    private var layersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Stack")
                Spacer()
                Text("\(layers.count)/\(maxLayers)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                    if index > 0 { divider }
                    row {
                        HStack(spacing: 10) {
                            Image(systemName: layer.effect.icon)
                                .frame(width: 22)
                                .foregroundStyle(layer.id == selectedLayerID ? Color.accentColor : .secondary)
                            Text(layer.effect.rawValue)
                                .fontWeight(layer.id == selectedLayerID ? .semibold : .regular)
                            Spacer()
                            if layer.id == selectedLayerID {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                            }
                            if layers.count > 1 {
                                Button(role: .destructive) {
                                    deleteLayer(layer.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedLayerID = layer.id }
                    }
                }
                if layers.count < maxLayers {
                    divider
                    row {
                        Button(action: addLayer) {
                            Label("Add Layer", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Layer Editor Section

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Layer \(selectedIndex + 1)")

            VStack(spacing: 0) {
                row {
                    LabeledPicker(label: "Shader") {
                        Picker("Shader", selection: selectedEffectBinding) {
                            ForEach(ShaderEffect.allCases) { e in
                                Label(e.rawValue, systemImage: e.icon).tag(e)
                            }
                        }
                    }
                }

                if selectedLayer.effect == .progressiveBlur {
                    divider
                    row {
                        LabeledPicker(label: "Direction") {
                            Picker("Direction", selection: $layers[selectedIndex].blurDirection) {
                                ForEach(BlurDirection.allCases, id: \.self) { d in
                                    Text(d.rawValue).tag(d)
                                }
                            }
                        }
                    }
                }

                if selectedLayer.effect == .colorGrade {
                    divider
                    row {
                        LabeledPicker(label: "Look") {
                            Picker("Look", selection: $layers[selectedIndex].gradeLook) {
                                ForEach(GradeLook.allCases, id: \.self) { l in
                                    Text(l.rawValue).tag(l)
                                }
                            }
                        }
                    }
                }

                ForEach(Array(controlRows(selectedIndex).enumerated()), id: \.offset) { _, ctrl in
                    divider
                    row {
                        LabeledSlider(label: ctrl.label, value: ctrl.binding, display: ctrl.display)
                    }
                }

                if selectedLayer.effect.isTapBased {
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
            .cardBackground()
        }
    }

    // MARK: - Animation Section

    private var animationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                sectionLabel("Animation")
                if selectedLayer.anim.contains(where: { $0.enabled }) {
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
                if selectedLayer.effect.alwaysAnimates {
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
                }
                let rows = controlRows(selectedIndex)
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, ctrl in
                    let anim = $layers[selectedIndex].anim[idx]
                    if idx > 0 || selectedLayer.effect.alwaysAnimates { divider }
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
            .cardBackground()
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Presets")

            VStack(spacing: 0) {
                row {
                    Button {
                        showSaveAlert = true
                    } label: {
                        Label("Save current stack", systemImage: "square.and.arrow.down")
                    }
                }
                ForEach(presetStore.presets) { preset in
                    divider
                    row {
                        HStack {
                            Button {
                                load(preset)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                    Text(preset.layers.map(\.effect).joined(separator: " → "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button(role: .destructive) {
                                presetStore.delete(preset)
                            } label: {
                                Image(systemName: "trash").foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                if presetStore.presets.isEmpty {
                    divider
                    row {
                        Text("No saved presets yet.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .cardBackground()
        }
    }

    // MARK: - Layer actions

    private var selectedEffectBinding: Binding<ShaderEffect> {
        Binding(
            get: { layers[selectedIndex].effect },
            set: { newVal in
                let i = selectedIndex
                layers[i].effect = newVal
                layers[i].params = newVal.defaultParams
                layers[i].anim   = Array(repeating: ParamAnimation(), count: 5)
            }
        )
    }

    private func addLayer() {
        guard layers.count < maxLayers else { return }
        let layer = ShaderLayer(effect: .colorGrade)
        layers.append(layer)
        selectedLayerID = layer.id
    }

    private func deleteLayer(_ id: UUID) {
        guard layers.count > 1 else { return }
        layers.removeAll { $0.id == id }
        if selectedLayerID == id { selectedLayerID = layers.first?.id }
    }

    private func makePreset(name: String) -> ShaderPreset {
        ShaderPreset(name: name, layers: layers.map { l in
            PresetLayer(
                effect: l.effect.rawValue,
                params: l.params,
                blurDirection: l.blurDirection.rawValue,
                gradeLook: l.gradeLook.rawValue
            )
        })
    }

    private func load(_ preset: ShaderPreset) {
        let newLayers: [ShaderLayer] = preset.layers.map { pl in
            var layer = ShaderLayer(effect: ShaderEffect(rawValue: pl.effect) ?? .grain)
            if pl.params.count == 5 { layer.params = pl.params }
            layer.blurDirection = BlurDirection(rawValue: pl.blurDirection) ?? .bottom
            layer.gradeLook     = GradeLook(rawValue: pl.gradeLook) ?? .tealOrange
            return layer
        }
        guard !newLayers.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            layers = newLayers
            selectedLayerID = layers.first?.id
        }
    }

    // MARK: - Control Rows

    private func controlRows(_ index: Int) -> [(label: String, binding: Binding<Float>, display: String)] {
        let p = layers[index].params
        func b(_ i: Int) -> Binding<Float> { $layers[index].params[i] }

        switch layers[index].effect {
        case .ripple:
            return [
                ("Amplitude",  b(0), "\(Int(p[0] * 80))pt"),
                ("Wavelength", b(1), "\(Int(1 + p[1] * 59))pt"),
                ("Spread",     b(2), "\(Int(p[2] * 80))pt"),
                ("Decay",      b(3), String(format: "%.3f", 0.001 + p[3] * 0.049)),
                ("Speed",      b(4), String(format: "%.1f", 1 + p[4] * 24))
            ]
        case .pixelate:
            return [("Block Size", b(0), "\(Int(1 + p[0] * 199))px")]
        case .chromatic:
            return [
                ("H Offset", b(0), "\(Int(p[0] * 80))pt"),
                ("V Offset", b(1), "\(Int(p[1] * 40))pt")
            ]
        case .wave:
            return [
                ("Amplitude", b(0), "\(Int(p[0] * 80))pt"),
                ("Frequency", b(1), String(format: "%.3f", 0.02 + p[1] * 0.28)),
                ("Speed",     b(2), String(format: "%.1f×", 0.3 + p[2] * 4.7))
            ]
        case .grain:
            return [
                ("Intensity", b(0), String(format: "%.0f%%", p[0] * 200)),
                ("Size",      b(1), String(format: "%.1fpx", 0.5 + p[1] * 19.5)),
                ("Chroma",    b(2), String(format: "%.0f%%", p[2] * 100))
            ]
        case .vignette:
            return [
                ("Radius",   b(0), String(format: "%.2f", p[0] * 2.5)),
                ("Softness", b(1), String(format: "%.2f", p[1] * 1.5))
            ]
        case .swirl:
            return [
                ("Angle",  b(0), String(format: "%.0f°", p[0] * 1440)),
                ("Radius", b(1), "\(Int(Float(previewPt) * p[1]))pt")
            ]
        case .emboss:
            return [("Depth", b(0), String(format: "%.1f", p[0] * 20))]
        case .hueRotate:
            return [("Shift", b(0), String(format: "%.0f°", p[0] * 360))]
        case .kaleidoscope:
            return [
                ("Segments", b(0), "\(1 + Int(p[0] * 23))"),
                ("Rotation", b(1), String(format: "%.0f°", p[1] * 360))
            ]
        case .glitch:
            return [
                ("Intensity",     b(0), String(format: "%.0f%%", p[0] * 100)),
                ("Block Size",    b(1), "\(Int(1 + p[1] * 99))pt"),
                ("Speed",         b(2), String(format: "%.0ffps", 0.5 + p[2] * 59.5)),
                ("Channel Split", b(3), "\(Int(p[3] * 50))pt")
            ]
        case .crt:
            return [
                ("Scanlines", b(0), String(format: "%.0f%%", p[0] * 100)),
                ("Curvature", b(1), String(format: "%.2f", p[1] * 2.0)),
                ("Vignette",  b(2), String(format: "%.1f", p[2] * 5.0))
            ]
        case .edgeDetect:
            return [
                ("Strength",  b(0), String(format: "%.1f", p[0] * 30)),
                ("Threshold", b(1), String(format: "%.2f", p[1])),
                ("Step",      b(2), String(format: "%.1fpx", 0.5 + p[2] * 11.5))
            ]
        case .fisheye:
            return [
                ("Strength", b(0), String(format: "%.2f", p[0] * 5.0)),
                ("Radius",   b(1), "\(Int(Float(previewPt) * p[1]))pt")
            ]
        case .progressiveBlur:
            return [
                ("Radius",     b(0), "\(Int(p[0] * 60))pt"),
                ("Blur Start", b(1), String(format: "%.0f%%", p[1] * 100)),
                ("Blur Stop",  b(2), String(format: "%.0f%%", p[2] * 100))
            ]
        case .dissolve:
            return [
                ("Threshold", b(0), String(format: "%.0f%%", p[0] * 100)),
                ("Softness",  b(1), String(format: "%.0f%%", p[1] * 100)),
                ("Glow",      b(2), String(format: "%.0f%%", p[2] * 100)),
                ("Scale",     b(3), String(format: "%.1f", 0.5 + p[3] * 9.5))
            ]
        case .zoomBlur:
            return [("Strength", b(0), String(format: "%.0f%%", p[0] * 90))]
        case .holographic:
            return [
                ("Intensity",  b(0), String(format: "%.0f%%", p[0] * 120)),
                ("Band Width", b(1), "\(Int(4 + p[1] * 96))pt"),
                ("Speed",      b(2), String(format: "%.1f×", p[2] * 3.0))
            ]
        case .duotone:
            return [
                ("Shadow Hue",    b(0), String(format: "%.0f°", p[0] * 360)),
                ("Highlight Hue", b(1), String(format: "%.0f°", p[1] * 360)),
                ("Contrast",      b(2), String(format: "%.0f%%", p[2] * 100))
            ]
        case .halftone:
            return [
                ("Cell Size", b(0), "\(Int(3 + p[0] * 21))px"),
                ("Angle",     b(1), String(format: "%.0f°", p[1] * 180)),
                ("Ink",       b(2), String(format: "%.0f%%", p[2] * 100))
            ]
        case .solarize:
            return [
                ("Threshold", b(0), String(format: "%.2f", p[0])),
                ("Amount",    b(1), String(format: "%.0f%%", (0.2 + p[1] * 0.8) * 100))
            ]
        case .frosted:
            return [
                ("Radius",     b(0), "\(Int(p[0] * 20))pt"),
                ("Brightness", b(1), String(format: "%.0f%%", p[1] * 30))
            ]
        case .refractLens:
            return [
                ("Radius",   b(0), "\(Int(20 + p[0] * 100))pt"),
                ("Strength", b(1), String(format: "%.0f%%", p[1] * 55))
            ]
        case .colorGrade:
            return [("Amount", b(0), String(format: "%.0f%%", p[0] * 100))]
        case .topographic:
            return [
                ("Levels",     b(0), "\(Int(2 + p[0] * 18))"),
                ("Line Width", b(1), String(format: "%.2f", 0.02 + p[1] * 0.4)),
                ("Tint",       b(2), String(format: "%.0f%%", p[2] * 100))
            ]
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, 4)
    }

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
            let i = selectedIndex
            layers[i].effect = ShaderEffect.allCases.randomElement()!
            layers[i].params = (0..<5).map { _ in Float.random(in: 0.15...0.85) }
            layers[i].anim   = Array(repeating: ParamAnimation(), count: 5)
            if subject != .photo {
                subject = Bool.random() ? .wallpaper : .palette
            }
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
    func cardBackground() -> some View {
        background(Color(.secondarySystemGroupedBackground),
                   in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

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
