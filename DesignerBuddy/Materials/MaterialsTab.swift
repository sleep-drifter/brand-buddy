import SwiftUI

// MARK: - Combined Glass Tab

struct CombinedGlassTab: View {
    enum GlassMode: String, CaseIterable {
        case ios26 = "iOS 26"
        case material = "Material"
    }
    @State private var mode: GlassMode = .ios26

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(GlassMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 4)

            switch mode {
            case .ios26: GlassEffectPlayground()
            case .material: GlassPlayground()
            }
        }
    }
}

// MARK: - iOS 26 GlassEffect Playground

struct GlassEffectPlayground: View {
    @State private var cornerRadius: CGFloat = 24
    @State private var isInteractive: Bool = false
    @State private var backgroundType: GlassBG = .blobs
    @State private var bgColor1 = Color.purple
    @State private var bgColor2 = Color.blue

    enum GlassBG: String, CaseIterable {
        case blobs = "Blobs"
        case gradient = "Gradient"
        case mesh = "Mesh"
    }

    var body: some View {
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

            Section("How it works") {
                Text("`.glassEffect(in:)` is the iOS 26 liquid glass modifier. The system synthesizes the blur, specular highlights, and refraction — you only specify the shape.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("`.interactive` makes the glass surface respond to press gestures with a physical scale-and-dim feedback, matching system button behavior.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .pinnedPreview {
            ZStack {
                bgContent
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 16) {
                    glassCard(label: "Hello, glass.")
                    HStack(spacing: 12) {
                        glassChip("Confirm")
                        glassChip("Cancel")
                    }
                }
            }
        }
    }

    @ViewBuilder
    func glassCard(label: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if isInteractive {
            Button(action: {}) {
                VStack(spacing: 10) {
                    Image(systemName: "bubbles.and.sparkles")
                        .font(.system(size: 28))
                    Text(label)
                        .font(.headline)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
            }
            .buttonStyle(InteractiveGlassButtonStyle(shape: shape))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "bubbles.and.sparkles")
                    .font(.system(size: 28))
                Text(label)
                    .font(.headline)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .glassEffect(in: shape)
        }
    }

    @ViewBuilder
    func glassChip(_ label: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: max(cornerRadius / 2, 8), style: .continuous)
        if isInteractive {
            Button(action: {}) {
                Text(label)
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(InteractiveGlassButtonStyle(shape: shape))
        } else {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(in: shape)
        }
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

struct InteractiveGlassButtonStyle<S: Shape>: ButtonStyle {
    let shape: S

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .glassEffect(in: shape)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
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
        List {
            controlSections
        }
        .pinnedPreview {
            ZStack {
                backgroundContent
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                glassCard
            }
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

    @ViewBuilder
    var controlSections: some View {
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
}

// MARK: - Surfaces Playground

struct SurfacesPlayground: View {
    var body: some View {
        List {
            Section {
                Text("These are the semantic background and fill colors iOS uses for layered UI. They automatically adapt to light and dark mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Backgrounds") {
                ForEach(SemanticSurface.backgrounds) { s in
                    SurfaceRow(surface: s)
                }
            }

            Section("Grouped Backgrounds") {
                ForEach(SemanticSurface.groupedBackgrounds) { s in
                    SurfaceRow(surface: s)
                }
            }

            Section("Fills") {
                Text("Fills are semi-transparent, intended for overlaying content on any background.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(SemanticSurface.fills) { s in
                    SurfaceRow(surface: s)
                }
            }

            Section("Separators") {
                ForEach(SemanticSurface.separators) { s in
                    SurfaceRow(surface: s)
                }
            }

            Section("When to use each") {
                VStack(alignment: .leading, spacing: 10) {
                    UsageRow(token: ".systemBackground", note: "Root view background — the canvas everything sits on")
                    UsageRow(token: ".secondarySystemBackground", note: "Cards, inset grouped sections, raised surfaces")
                    UsageRow(token: ".tertiarySystemBackground", note: "Nested cards or a third layer within a view")
                    UsageRow(token: ".systemGroupedBackground", note: "Form / settings screen base")
                    UsageRow(token: ".secondarySystemGroupedBackground", note: "List rows inside a grouped form")
                    UsageRow(token: ".systemFill", note: "Thin UI chrome: sliders, switches, progress bars")
                    UsageRow(token: ".secondarySystemFill", note: "Text field backgrounds")
                    UsageRow(token: ".tertiarySystemFill", note: "Input accessories, search bar fill")
                    UsageRow(token: ".quaternarySystemFill", note: "Skeleton loaders, placeholder shapes")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct SemanticSurface: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let isTranslucent: Bool

    static let backgrounds: [SemanticSurface] = [
        .init(name: ".systemBackground", color: Color(.systemBackground), isTranslucent: false),
        .init(name: ".secondarySystemBackground", color: Color(.secondarySystemBackground), isTranslucent: false),
        .init(name: ".tertiarySystemBackground", color: Color(.tertiarySystemBackground), isTranslucent: false),
    ]

    static let groupedBackgrounds: [SemanticSurface] = [
        .init(name: ".systemGroupedBackground", color: Color(.systemGroupedBackground), isTranslucent: false),
        .init(name: ".secondarySystemGroupedBackground", color: Color(.secondarySystemGroupedBackground), isTranslucent: false),
        .init(name: ".tertiarySystemGroupedBackground", color: Color(.tertiarySystemGroupedBackground), isTranslucent: false),
    ]

    static let fills: [SemanticSurface] = [
        .init(name: ".systemFill", color: Color(.systemFill), isTranslucent: true),
        .init(name: ".secondarySystemFill", color: Color(.secondarySystemFill), isTranslucent: true),
        .init(name: ".tertiarySystemFill", color: Color(.tertiarySystemFill), isTranslucent: true),
        .init(name: ".quaternarySystemFill", color: Color(.quaternarySystemFill), isTranslucent: true),
    ]

    static let separators: [SemanticSurface] = [
        .init(name: ".separator", color: Color(.separator), isTranslucent: true),
        .init(name: ".opaqueSeparator", color: Color(.opaqueSeparator), isTranslucent: false),
    ]
}

struct SurfaceRow: View {
    let surface: SemanticSurface

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                CheckerboardPattern()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .opacity(surface.isTranslucent ? 1 : 0)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(surface.color)
                    .frame(width: 44, height: 44)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(surface.name)
                    .font(.mono(.caption))
                if surface.isTranslucent {
                    Text("translucent")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CheckerboardPattern: View {
    var body: some View {
        Canvas { ctx, size in
            let tileSize: CGFloat = 6
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let isLight = (row + col) % 2 == 0
                    ctx.fill(
                        Path(CGRect(x: x, y: y, width: tileSize, height: tileSize)),
                        with: .color(isLight ? .white : Color(.systemGray5))
                    )
                    x += tileSize
                    col += 1
                }
                y += tileSize
                row += 1
            }
        }
    }
}

struct UsageRow: View {
    let token: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(token).font(.mono(.caption)).foregroundStyle(.primary)
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Vibrancy Playground

struct VibrancyPlayground: View {
    @State private var backgroundType: BackgroundType = .gradient
    @State private var materialThickness: MaterialThickness = .ultraThin
    @State private var cornerRadius: CGFloat = 16
    @State private var showPrimary = true
    @State private var showSecondary = true
    @State private var showTertiary = true
    @State private var showQuaternary = true

    private enum BackgroundType: String, CaseIterable {
        case gradient = "Gradient"
        case blobs = "Blobs"
        case mesh = "Mesh"
    }

    private enum MaterialThickness: String, CaseIterable {
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
        List {
            Section {
                Text("Vibrancy adapts label and fill colors to stand out against any background material.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Background") {
                Picker("Background", selection: $backgroundType) {
                    ForEach(BackgroundType.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
            }

            Section("Material") {
                Picker("Thickness", selection: $materialThickness) {
                    ForEach(MaterialThickness.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.menu)
                LabeledContent("Corner Radius: \(Int(cornerRadius))") {
                    Slider(value: $cornerRadius, in: 0...32)
                }
            }

            Section("Labels") {
                Toggle(".primary", isOn: $showPrimary)
                Toggle(".secondary", isOn: $showSecondary)
                Toggle(".tertiary", isOn: $showTertiary)
                Toggle(".quaternary", isOn: $showQuaternary)
            }

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
        .pinnedPreview {
            ZStack {
                backgroundContent
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(materialThickness.material)
                    .frame(width: 240, height: 140)
                    .overlay(
                        VStack(alignment: .leading, spacing: 8) {
                            if showPrimary {
                                Label("Primary label", systemImage: "star.fill")
                                    .font(.subheadline)
                            }
                            if showSecondary {
                                Label("Secondary label", systemImage: "circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            if showTertiary {
                                Label("Tertiary label", systemImage: "triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            }
                            if showQuaternary {
                                Divider()
                                Text("Separator above")
                                    .font(.caption)
                                    .foregroundStyle(.quaternary)
                            }
                        }
                        .padding(16)
                    )
                    .animation(.spring(duration: 0.3), value: cornerRadius)
                    .animation(.spring(duration: 0.3), value: [showPrimary, showSecondary, showTertiary, showQuaternary])
            }
        }
    }

    @ViewBuilder
    var backgroundContent: some View {
        switch backgroundType {
        case .gradient:
            LinearGradient(colors: [.purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blobs:
            BlobBackground()
        case .mesh:
            Rectangle().fill(MeshGradient(width: 3, height: 3, points: [
                [0,0],[0.5,0],[1,0],
                [0,0.5],[0.5,0.5],[1,0.5],
                [0,1],[0.5,1],[1,1]
            ], colors: [.red,.orange,.yellow,.purple,.pink,.orange,.blue,.cyan,.green]))
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
    NavigationStack {
        CombinedGlassTab()
    }
}
