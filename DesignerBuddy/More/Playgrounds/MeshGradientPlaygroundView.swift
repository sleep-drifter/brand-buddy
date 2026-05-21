import SwiftUI

// MARK: - Supporting Types

enum MeshGridSize: String, CaseIterable {
    case two   = "2×2"
    case three = "3×3"
    case four  = "4×4"

    var dimension: Int {
        switch self { case .two: 2; case .three: 3; case .four: 4 }
    }
    var count: Int { dimension * dimension }
}

enum MeshColorPalette: String, CaseIterable {
    case cosmic = "Cosmic"
    case sunset = "Sunset"
    case ocean  = "Ocean"
    case aurora = "Aurora"
    case candy  = "Candy"
    case ember  = "Ember"
    case arctic = "Arctic"
    case forest = "Forest"

    private var base: [Color] {
        switch self {
        case .cosmic: [.purple, .blue, .indigo, .pink, .purple, .cyan, .blue, .mint, .indigo,
                       .purple, .teal, .blue, .indigo, .pink, .cyan, .blue]
        case .sunset: [.orange, .red, .pink, .yellow, .orange, .red, .pink, .purple, .indigo,
                       .orange, .yellow, .red, .pink, .orange, .purple, .red]
        case .ocean:  [.blue, .cyan, .teal, .blue, .teal, .cyan, .indigo, .blue, .mint,
                       .cyan, .blue, .teal, .indigo, .cyan, .mint, .blue]
        case .aurora: [.green, .teal, .blue, .mint, .cyan, .purple, .green, .teal, .indigo,
                       .mint, .cyan, .green, .teal, .purple, .blue, .mint]
        case .candy:  [.pink, .purple, .yellow, .red, .pink, .cyan, .orange, .purple, .mint,
                       .pink, .yellow, .red, .cyan, .purple, .orange, .pink]
        case .ember:  [.red, .orange, .yellow, .red, .orange, .pink, .purple, .red, .orange,
                       .yellow, .red, .orange, .pink, .red, .orange, .yellow]
        case .arctic: [Color(white: 0.9), .cyan, .blue, .mint, Color(white: 0.95), .teal,
                       .blue, .cyan, .indigo, .mint, .cyan, .blue, .teal, Color(white: 0.9), .cyan, .blue]
        case .forest: [.green, .teal, .yellow, .mint, .green, .teal, .brown, .green, .yellow,
                       .mint, .teal, .green, .brown, .green, .yellow, .mint]
        }
    }

    func colors(for count: Int) -> [Color] {
        (0..<count).map { base[$0 % base.count] }
    }
}

enum MeshMaskShape: String, CaseIterable {
    case none   = "None"
    case circle = "Circle"
    case icon   = "Icon"
    case text   = "Text"
}

// Circle scaled to 0.6, centered in the canvas
private struct ScaledCircle: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height) * 0.6
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        return Circle().path(in: CGRect(origin: origin, size: CGSize(width: side, height: side)))
    }
}

enum MeshSymbolAnimation: String, CaseIterable {
    case none          = "None"
    case pulse         = "Pulse"
    case breathe       = "Breathe"
    case wiggle        = "Wiggle"
    case rotate        = "Rotate"
    case bounce        = "Bounce"
    case variableColor = "Variable"
}

private let maskWeights: [(name: String, weight: Font.Weight)] = [
    ("Light",    .light),
    ("Regular",  .regular),
    ("Medium",   .medium),
    ("Semibold", .semibold),
    ("Bold",     .bold),
    ("Heavy",    .heavy),
    ("Black",    .black),
]

private let meshBlendModes: [(name: String, mode: BlendMode)] = [
    ("Normal",      .normal),
    ("Screen",      .screen),
    ("Multiply",    .multiply),
    ("Overlay",     .overlay),
    ("Soft Light",  .softLight),
    ("Hard Light",  .hardLight),
    ("Color Dodge", .colorDodge),
    ("Color Burn",  .colorBurn),
    ("Difference",  .difference),
    ("Exclusion",   .exclusion),
    ("Hue",         .hue),
    ("Saturation",  .saturation),
    ("Luminosity",  .luminosity),
]

// MARK: - Playground View

struct MeshGradientPlaygroundView: View {

    // Grid & colors
    @State private var gridSize           = MeshGridSize.three
    @State private var palette            = MeshColorPalette.cosmic
    @State private var colors: [Color]    = MeshColorPalette.cosmic.colors(for: 9)
    @State private var selectedColorIdx: Int? = nil

    // Points
    @State private var basePoints: [SIMD2<Float>] = Self.defaultPoints(for: .three)
    @State private var isEditingPoints    = false

    // Animation
    @State private var isAnimating        = true
    @State private var animSpeed: Double  = 1.0
    @State private var animIntensity: Double = 0.12

    // Mask
    @State private var maskShape          = MeshMaskShape.none
    @State private var showSymbolPicker   = false
    // icon mask
    @State private var iconName           = "heart.fill"
    @State private var iconSize: Double   = 120
    @State private var iconWeightIdx      = 4          // Bold
    @State private var iconAnimation      = MeshSymbolAnimation.none
    // text mask
    @State private var maskText           = "Hello"
    @State private var textSize: Double   = 80
    @State private var textWeightIdx      = 5          // Heavy

    // Options
    @State private var smoothsColors      = true
    @State private var blendModeIdx       = 0
    @State private var bgColor            = Color.black
    @State private var gradientOpacity: Double = 1.0

    private var blendMode: BlendMode { meshBlendModes[blendModeIdx].mode }

    var body: some View {
        VStack(spacing: 0) {
            previewCard
            List {
                gridAndColorSection
                pointsSection
                animationSection
                maskSection
                optionsSection
            }
        }
        .navigationTitle("Mesh Gradient")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: gridSize) { _, new in
            colors = palette.colors(for: new.count)
            basePoints = Self.defaultPoints(for: new)
            isEditingPoints = false
            selectedColorIdx = nil
        }
        .onChange(of: palette) { _, new in
            colors = new.colors(for: gridSize.count)
            selectedColorIdx = nil
        }
        .sheet(isPresented: $showSymbolPicker) {
            SymbolPickerSheet(selectedSymbol: $iconName)
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewCard: some View {
        ZStack {
            bgColor
            maskedGradient
                .blendMode(blendMode)
                .opacity(gradientOpacity)
            if isEditingPoints {
                GeometryReader { geo in
                    ForEach(basePoints.indices, id: \.self) { i in
                        pointHandle(at: i, in: geo.size)
                    }
                }
            }
        }
        .frame(height: 224)
    }

    @ViewBuilder
    private var maskedGradient: some View {
        switch maskShape {
        case .none:
            gradientLayer
        case .circle:
            gradientLayer.clipShape(ScaledCircle())
        case .icon:
            gradientLayer.mask {
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: maskWeights[iconWeightIdx].weight))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .symbolEffect(.pulse,         options: .repeating, isActive: iconAnimation == .pulse)
                    .symbolEffect(.breathe,       options: .repeating, isActive: iconAnimation == .breathe)
                    .symbolEffect(.wiggle,        options: .repeating, isActive: iconAnimation == .wiggle)
                    .symbolEffect(.rotate,        options: .repeating, isActive: iconAnimation == .rotate)
                    .symbolEffect(.bounce,        options: .repeating, isActive: iconAnimation == .bounce)
                    .symbolEffect(.variableColor, options: .repeating, isActive: iconAnimation == .variableColor)
            }
        case .text:
            gradientLayer.mask {
                Text(maskText.isEmpty ? " " : maskText)
                    .font(.system(size: textSize, weight: maskWeights[textWeightIdx].weight))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func pointHandle(at i: Int, in size: CGSize) -> some View {
        Circle()
            .fill(.white.opacity(0.92))
            .frame(width: 16, height: 16)
            .overlay(Circle().strokeBorder(.black.opacity(0.2), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
            .position(
                x: CGFloat(basePoints[i].x) * size.width,
                y: CGFloat(basePoints[i].y) * size.height
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        basePoints[i] = SIMD2<Float>(
                            Float(min(1, max(0, value.location.x / size.width))),
                            Float(min(1, max(0, value.location.y / size.height)))
                        )
                    }
            )
    }

    private var gradientLayer: some View {
        TimelineView(.animation) { tl in
            let t = (isAnimating && !isEditingPoints) ? tl.date.timeIntervalSinceReferenceDate : 0
            meshGradient(at: t)
        }
        .scaleEffect(isAnimating ? 1.25 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
    }

    private func meshGradient(at t: Double) -> some View {
        MeshGradient(
            width: gridSize.dimension,
            height: gridSize.dimension,
            points: meshPoints(at: t),
            colors: colors,
            smoothsColors: smoothsColors
        )
    }

    // MARK: - Grid & Colors

    @ViewBuilder
    private var gridAndColorSection: some View {
        Section("Grid & Colors") {
            Picker("Grid Size", selection: $gridSize) {
                ForEach(MeshGridSize.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            Picker("Palette", selection: $palette) {
                ForEach(MeshColorPalette.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Point Colors  —  tap to edit")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize.dimension),
                    spacing: 8
                ) {
                    ForEach(colors.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(colors[i])
                            .frame(height: 44)
                            .overlay {
                                if selectedColorIdx == i {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(.primary, lineWidth: 2.5)
                                }
                            }
                            .onTapGesture {
                                selectedColorIdx = (selectedColorIdx == i) ? nil : i
                            }
                    }
                }

                if let idx = selectedColorIdx {
                    HStack {
                        Text("Point \(idx + 1)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        ColorPicker("", selection: $colors[idx])
                            .labelsHidden()
                            .scaleEffect(1.2)
                    }
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.3), value: selectedColorIdx)
                }
            }
            .padding(.vertical, 4)

            Button("Randomize Colors") {
                let pool: [Color] = [.red, .orange, .yellow, .green, .mint, .teal,
                                     .cyan, .blue, .indigo, .purple, .pink, .brown]
                withAnimation(.spring(response: 0.4)) {
                    colors = (0..<gridSize.count).map { _ in pool.randomElement()! }
                    selectedColorIdx = nil
                }
            }
        }
    }

    // MARK: - Points

    @ViewBuilder
    private var pointsSection: some View {
        Section("Points") {
            Toggle("Edit Point Positions", isOn: $isEditingPoints.animation(.spring(response: 0.3)))
            if isEditingPoints {
                Text("Drag the white handles in the preview to reposition any control point.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Reset to Grid") {
                    withAnimation(.spring(response: 0.4)) {
                        basePoints = Self.defaultPoints(for: gridSize)
                    }
                }
            }
        }
    }

    // MARK: - Animation

    @ViewBuilder
    private var animationSection: some View {
        Section("Animation") {
            Toggle("Animate", isOn: $isAnimating.animation())

            LabeledContent("Speed: \(animSpeed, specifier: "%.1f")×") {
                Slider(value: $animSpeed, in: 0.1...6.0)
            }
            .disabled(!isAnimating)

            LabeledContent("Intensity: \(Int(animIntensity * 100))%") {
                Slider(value: $animIntensity, in: 0.0...0.40)
            }
            .disabled(!isAnimating)
        }
    }

    // MARK: - Mask

    @ViewBuilder
    private var maskSection: some View {
        Section("Mask") {
            Picker("Shape", selection: $maskShape.animation()) {
                ForEach(MeshMaskShape.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if maskShape == .icon {
                Button {
                    showSymbolPicker = true
                } label: {
                    HStack {
                        Text("Symbol")
                        Spacer()
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: maskWeights[iconWeightIdx].weight))
                            .frame(width: 28)
                        Text(iconName)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.primary)

                LabeledContent("Size: \(Int(iconSize))pt") {
                    Slider(value: $iconSize, in: 20...220)
                }
                Picker("Weight", selection: $iconWeightIdx) {
                    ForEach(maskWeights.indices, id: \.self) { Text(maskWeights[$0].name).tag($0) }
                }
                Picker("Animation", selection: $iconAnimation) {
                    ForEach(MeshSymbolAnimation.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }

            if maskShape == .text {
                HStack {
                    Text("Text")
                    Spacer()
                    TextField("Label", text: $maskText)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Size: \(Int(textSize))pt") {
                    Slider(value: $textSize, in: 20...180)
                }
                Picker("Weight", selection: $textWeightIdx) {
                    ForEach(maskWeights.indices, id: \.self) { Text(maskWeights[$0].name).tag($0) }
                }
            }
        }
    }

    // MARK: - Options

    @ViewBuilder
    private var optionsSection: some View {
        Section("Options") {
            Toggle("Smooth Colors", isOn: $smoothsColors)

            LabeledContent("Opacity: \(Int(gradientOpacity * 100))%") {
                Slider(value: $gradientOpacity, in: 0.05...1.0)
            }

            Picker("Blend Mode", selection: $blendModeIdx) {
                ForEach(meshBlendModes.indices, id: \.self) {
                    Text(meshBlendModes[$0].name).tag($0)
                }
            }

            ColorPicker("Background Color", selection: $bgColor)
        }

        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("How it works")
                    .font(.subheadline)
                    .fontWeight(.medium)
                ForEach(notes, id: \.self) { note in
                    Label(note, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Mesh Point Computation

    static func defaultPoints(for size: MeshGridSize) -> [SIMD2<Float>] {
        let dim = size.dimension
        return (0..<dim).flatMap { row in
            (0..<dim).map { col in
                SIMD2<Float>(
                    Float(col) / Float(max(dim - 1, 1)),
                    Float(row) / Float(max(dim - 1, 1))
                )
            }
        }
    }

    private func meshPoints(at t: Double) -> [SIMD2<Float>] {
        guard basePoints.count == gridSize.count else { return Self.defaultPoints(for: gridSize) }
        if isEditingPoints { return basePoints }
        let dim = gridSize.dimension
        return basePoints.enumerated().map { i, base in
            let row = i / dim
            let col = i % dim
            let isCorner = (row == 0 || row == dim - 1) && (col == 0 || col == dim - 1)
            let isEdge   = row == 0 || row == dim - 1 || col == 0 || col == dim - 1
            let amp: Float = isCorner ? 0 : isEdge ? Float(animIntensity) * 0.5 : Float(animIntensity)
            let idx   = Double(i)
            let phase = idx * 0.85
            let freq  = (0.22 + idx * 0.06) * animSpeed
            return SIMD2<Float>(
                min(1, max(0, base.x + amp * Float(sin(t * freq + phase)))),
                min(1, max(0, base.y + amp * Float(cos(t * freq * 1.37 + phase + 1.2))))
            )
        }
    }

    private let notes: [String] = [
        "MeshGradient maps a grid of SIMD2<Float> control points to Colors",
        "Corner points stay fixed; interior points drift for organic motion",
        "smoothsColors blends adjacent colors with cubic interpolation",
        "Blend modes composite the gradient layer over the background color",
        "Masks clip the gradient to any Shape — ideal for avatars, icons, cards",
        "TimelineView(.animation) drives per-frame point recalculation",
    ]
}

#Preview {
    NavigationStack {
        MeshGradientPlaygroundView()
    }
}
