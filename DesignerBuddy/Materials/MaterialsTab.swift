import SwiftUI

struct MaterialsTab: View {
    @State private var selectedSection: MaterialSection = .glass

    enum MaterialSection: String, CaseIterable {
        case glass = "Glass"
        case materials = "Materials"
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
                case .glass:
                    GlassPlayground()
                case .materials:
                    MaterialsPlayground()
                case .vibrancy:
                    VibrancyPlayground()
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Glass Playground

struct GlassPlayground: View {
    @State private var cornerRadius: CGFloat = 24
    @State private var backgroundType: BackgroundType = .gradient
    @State private var gradientAngle: Double = 45
    @State private var bgColor1 = Color.purple
    @State private var bgColor2 = Color.blue
    @State private var showControls = true

    enum BackgroundType: String, CaseIterable {
        case gradient = "Gradient"
        case photo = "Photo"
        case blobs = "Blobs"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Live preview
                ZStack {
                    backgroundContent
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    glassCard
                }
                .padding(.horizontal)

                if showControls {
                    controlsPanel
                }

                Button(showControls ? "Hide Controls" : "Show Controls") {
                    withAnimation(.spring(duration: 0.3)) { showControls.toggle() }
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
            }
            .padding(.top)
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
        case .photo:
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
            Text("iOS 26 liquid glass")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
        .frame(width: 200)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }

    var controlsPanel: some View {
        VStack(spacing: 0) {
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

                Section("Glass Surface") {
                    LabeledContent("Corner Radius: \(Int(cornerRadius))") {
                        Slider(value: $cornerRadius, in: 0...48)
                    }
                }

                Section("iOS 26 Note") {
                    Text("In iOS 26, use .glassEffect() on views placed over rich backgrounds. The system automatically applies the correct blur, tint, and specular highlights.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 420)
            .scrollDisabled(true)
        }
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
