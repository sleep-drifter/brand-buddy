import SwiftUI

struct MaterialsTab: View {
    @State private var selectedSection: MaterialSection = .glassEffect

    enum MaterialSection: String, CaseIterable {
        case glassEffect = "iOS 26 Glass"
        case material = "Material"
        case vibrancy = "Vibrancy"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(MaterialSection.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedSection {
                case .glassEffect:
                    GlassEffectPlayground()
                case .material:
                    GlassPlayground()
                case .vibrancy:
                    VibrancyPlayground()
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - iOS 26 GlassEffect Playground

struct GlassEffectPlayground: View {
    @State private var cornerRadius: CGFloat = 24
    @State private var isInteractive: Bool = false
    @State private var tintColor: Color = .clear
    @State private var useTint: Bool = false
    @State private var backgroundType: GlassBG = .blobs
    @State private var bgColor1 = Color.purple
    @State private var bgColor2 = Color.blue
    @State private var showControls = true

    enum GlassBG: String, CaseIterable {
        case blobs = "Blobs"
        case gradient = "Gradient"
        case mesh = "Mesh"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    bgContent
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(spacing: 16) {
                        glassCard(label: "Hello, glass.")
                        HStack(spacing: 12) {
                            glassChip("Button")
                            glassChip("Cancel")
                        }
                    }
                }
                .padding(.horizontal)

                Button(showControls ? "Hide Controls" : "Show Controls") {
                    withAnimation(.spring(duration: 0.3)) { showControls.toggle() }
                }
                .buttonStyle(.bordered)

                if showControls {
                    List {
                        Section("Background") {
                            Picker("Background", selection: $backgroundType) {
                                ForEach(GlassBG.allCases, id: \.self) { Text($0.rawValue) }
                            }
                            .pickerStyle(.segmented)
                            if backgroundType == .gradient {
                                ColorPicker("Color 1", selection: $bgColor1, supportsOpacity: false)
                                ColorPicker("Color 2", selection: $bgColor2, supportsOpacity: false)
                            }
                        }

                        Section("GlassEffect") {
                            LabeledContent("Corner Radius: \(Int(cornerRadius))") {
                                Slider(value: $cornerRadius, in: 0...56)
                            }
                            Toggle(".interactive", isOn: $isInteractive)
                        }

                        Section("Tint") {
                            Toggle("Apply .tint()", isOn: $useTint)
                            if useTint {
                                ColorPicker("Tint Color", selection: $tintColor, supportsOpacity: false)
                            }
                        }

                        Section("How it works") {
                            Text("`.glassEffect(in:)` is the iOS 26 liquid glass modifier. Unlike Material, the system controls the blur, specular layer, and refraction — you only specify the shape.")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("`.interactive` adds a press-response scale animation to the glass surface, matching system button behavior.")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("`.tint()` on the view colors the glass tint layer. Use sparingly — neutral glass works best over colorful backgrounds.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 560)
                    .scrollDisabled(true)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    func glassCard(label: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "bubbles.and.sparkles")
                .font(.system(size: 28))
            Text(label)
                .font(.headline)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .glassEffect(
            isInteractive ? GlassEffect.regular.interactive() : GlassEffect.regular,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .tint(useTint ? tintColor : nil)
    }

    @ViewBuilder
    func glassChip(_ label: String) -> some View {
        Text(label)
            .font(.subheadline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(
                isInteractive ? GlassEffect.regular.interactive() : GlassEffect.regular,
                in: RoundedRectangle(cornerRadius: cornerRadius / 2, style: .continuous)
            )
            .tint(useTint ? tintColor : nil)
    }

    @ViewBuilder
    var bgContent: some View {
        switch backgroundType {
        case .blobs:
            BlobBackground()
        case .gradient:
            LinearGradient(colors: [bgColor1, bgColor2], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mesh:
            Rectangle().fill(MeshGradient(width: 3, height: 3, points: [
                [0,0],[0.5,0],[1,0],
                [0,0.5],[0.5,0.5],[1,0.5],
                [0,1],[0.5,1],[1,1]
            ], colors: [.red,.orange,.yellow,.purple,.pink,.orange,.blue,.cyan,.green]))
        }
    }
}

// MARK: - Material Playground (old API)

struct GlassPlayground: View {
    // Background
    @State private var backgroundType: BackgroundType = .blobs
    @State private var gradientAngle: Double = 45
    @State private var bgColor1 = Color.purple
    @State private var bgColor2 = Color.blue

    // Material
    @State private var materialThickness: MaterialThickness = .ultraThin
    @State private var cardOpacity: Double = 1.0

    // Tint
    @State private var tintColor = Color.white
    @State private var tintOpacity: Double = 0.08

    // Shape
    @State private var cornerRadius: CGFloat = 24

    // Border
    @State private var borderColor = Color.white
    @State private var borderOpacity: Double = 0.3
    @State private var borderWidth: Double = 0.5

    // Shadow
    @State private var shadowOpacity: Double = 0.2
    @State private var shadowRadius: Double = 20
    @State private var shadowY: Double = 10

    @State private var showControls = true

    enum BackgroundType: String, CaseIterable {
        case gradient = "Gradient"
        case mesh = "Mesh"
        case blobs = "Blobs"
    }

    enum MaterialThickness: String, CaseIterable {
        case ultraThin = "ultraThin"
        case thin = "thin"
        case regular = "regular"
        case thick = "thick"
        case ultraThick = "ultraThick"

        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    backgroundContent
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    glassCard
                }
                .padding(.horizontal)

                Button(showControls ? "Hide Controls" : "Show Controls") {
                    withAnimation(.spring(duration: 0.3)) { showControls.toggle() }
                }
                .buttonStyle(.bordered)

                if showControls {
                    controlsPanel
                }
            }
            .padding(.top)
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    var backgroundContent: some View {
        switch backgroundType {
        case .gradient:
            LinearGradient(
                colors: [bgColor1, bgColor2],
                startPoint: UnitPoint(
                    x: cos(gradientAngle * .pi / 180) * 0.5 + 0.5,
                    y: sin(gradientAngle * .pi / 180) * 0.5 + 0.5
                ),
                endPoint: UnitPoint(
                    x: cos((gradientAngle + 180) * .pi / 180) * 0.5 + 0.5,
                    y: sin((gradientAngle + 180) * .pi / 180) * 0.5 + 0.5
                )
            )
        case .blobs:
            BlobBackground()
        case .mesh:
            Rectangle()
                .fill(
                    MeshGradient(width: 3, height: 3, points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.5, 0.5], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1],
                    ], colors: [
                        .red, .orange, .yellow,
                        .purple, .pink, .orange,
                        .blue, .cyan, .green,
                    ])
                )
        }
    }

    var glassCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubbles.and.sparkles")
                .font(.system(size: 32))
                .foregroundStyle(.white)
            Text("Glass Surface")
                .font(.headline)
                .foregroundStyle(.white)
            Text(".\(materialThickness.rawValue)Material")
                .font(.mono(.caption))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .frame(width: 200)
        .background(materialThickness.material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tintColor.opacity(tintOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor.opacity(borderOpacity), lineWidth: borderWidth)
        )
        .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
        .opacity(cardOpacity)
    }

    var controlsPanel: some View {
        List {
            Section("Background") {
                Picker("Type", selection: $backgroundType) {
                    ForEach(BackgroundType.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                if backgroundType == .gradient {
                    ColorPicker("Color 1", selection: $bgColor1, supportsOpacity: false)
                    ColorPicker("Color 2", selection: $bgColor2, supportsOpacity: false)
                    LabeledContent("Angle: \(Int(gradientAngle))°") {
                        Slider(value: $gradientAngle, in: 0...360)
                    }
                }
            }

            Section("Material") {
                Picker("Thickness", selection: $materialThickness) {
                    ForEach(MaterialThickness.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)
                LabeledContent("Opacity: \(cardOpacity, specifier: "%.2f")") {
                    Slider(value: $cardOpacity, in: 0.1...1.0)
                }
            }

            Section("Shape") {
                LabeledContent("Corner Radius: \(Int(cornerRadius))") {
                    Slider(value: $cornerRadius, in: 0...56)
                }
            }

            Section("Tint Overlay") {
                ColorPicker("Tint Color", selection: $tintColor, supportsOpacity: false)
                LabeledContent("Opacity: \(tintOpacity, specifier: "%.2f")") {
                    Slider(value: $tintOpacity, in: 0...0.5)
                }
            }

            Section("Border") {
                ColorPicker("Color", selection: $borderColor, supportsOpacity: false)
                LabeledContent("Opacity: \(borderOpacity, specifier: "%.2f")") {
                    Slider(value: $borderOpacity, in: 0...1.0)
                }
                LabeledContent("Width: \(borderWidth, specifier: "%.1f")pt") {
                    Slider(value: $borderWidth, in: 0...4)
                }
            }

            Section("Shadow") {
                LabeledContent("Opacity: \(shadowOpacity, specifier: "%.2f")") {
                    Slider(value: $shadowOpacity, in: 0...0.8)
                }
                LabeledContent("Radius: \(Int(shadowRadius))") {
                    Slider(value: $shadowRadius, in: 0...60)
                }
                LabeledContent("Y Offset: \(Int(shadowY))") {
                    Slider(value: $shadowY, in: -30...30)
                }
            }
        }
        .frame(height: 820)
        .scrollDisabled(true)
        .padding(.horizontal)
    }
}

// MARK: - Materials Playground

struct MaterialsPlayground: View {
    @State private var selectedMaterial: MaterialItem = .ultraThin
    @State private var backgroundHue: Double = 220

    enum MaterialItem: String, CaseIterable {
        case ultraThin = "ultraThinMaterial"
        case thin = "thinMaterial"
        case regular = "regularMaterial"
        case thick = "thickMaterial"
        case ultraThick = "ultraThickMaterial"
        case bar = "bar"

        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            case .bar: return .bar
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    coloredBackground
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(selectedMaterial.material)
                        .frame(width: 200, height: 120)
                        .overlay(
                            VStack(spacing: 6) {
                                Text(selectedMaterial.rawValue)
                                    .font(.mono(.caption))
                                Text("The quick brown fox")
                                    .font(.subheadline)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(.separator, lineWidth: 0.5)
                        )
                }
                .padding(.horizontal)

                List {
                    Section("Material") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MaterialItem.allCases, id: \.self) { item in
                                    Button(item.rawValue) {
                                        selectedMaterial = item
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .buttonBorderShape(.capsule)
                                    .tint(selectedMaterial == item ? .accentColor : .secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Background") {
                        LabeledContent("Hue: \(Int(backgroundHue))°") {
                            Slider(value: $backgroundHue, in: 0...360)
                        }
                    }

                    Section("All Materials") {
                        ForEach(MaterialItem.allCases, id: \.self) { item in
                            HStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(item.material)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(.separator, lineWidth: 0.5)
                                    )
                                    .background(coloredBackground.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous)))
                                Text(".\(item.rawValue)")
                                    .font(.mono(.caption))
                            }
                        }
                    }
                }
                .frame(height: 500)
                .scrollDisabled(true)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    var coloredBackground: some View {
        LinearGradient(
            colors: [
                Color(hue: backgroundHue / 360, saturation: 0.8, brightness: 0.7),
                Color(hue: (backgroundHue + 60) / 360, saturation: 0.7, brightness: 0.5),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Vibrancy Playground

struct VibrancyPlayground: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(spacing: 16) {
                        Text("Vibrancy adapts label and fill colors to stand out against any background material.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 260, height: 160)
                            .overlay(
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Primary label", systemImage: "star.fill")
                                        .font(.subheadline)
                                    Label("Secondary label", systemImage: "circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Label("Tertiary label", systemImage: "triangle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                    Divider()
                                    Text("Separator above")
                                        .font(.caption)
                                        .foregroundStyle(.quaternary)
                                }
                                .padding(16)
                            )
                    }
                }
                .padding(.horizontal)

                List {
                    Section("Vibrancy Labels") {
                        ForEach(["primary", "secondary", "tertiary", "quaternary"], id: \.self) { level in
                            HStack {
                                Text(".\(level)")
                                    .font(.mono(.caption))
                                Spacer()
                                Text("Label")
                                    .foregroundStyle(labelStyle(for: level))
                                    .padding(8)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                    Section("Usage") {
                        Text("Vibrancy effects are automatic when using .foregroundStyle(.primary/.secondary/.tertiary) on views placed inside a material background. The system synthesizes appropriate contrast.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 380)
                .scrollDisabled(true)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }

    func labelStyle(for level: String) -> HierarchicalShapeStyle {
        switch level {
        case "secondary": return .secondary
        case "tertiary": return .tertiary
        case "quaternary": return .quaternary
        default: return .primary
        }
    }
}

// MARK: - Helpers

struct BlobBackground: View {
    var body: some View {
        ZStack {
            Color.indigo
            Circle()
                .fill(.purple.opacity(0.6))
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: -60, y: -40)
            Circle()
                .fill(.cyan.opacity(0.5))
                .frame(width: 140, height: 140)
                .blur(radius: 40)
                .offset(x: 60, y: 30)
            Circle()
                .fill(.pink.opacity(0.4))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .offset(x: 0, y: 60)
        }
    }
}

#Preview {
    MaterialsTab()
}
