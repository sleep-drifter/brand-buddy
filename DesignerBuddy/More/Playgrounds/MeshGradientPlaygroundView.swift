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
    case none        = "None"
    case circle      = "Circle"
    case roundedRect = "Rounded"
    case capsule     = "Capsule"
    case diamond     = "Diamond"
    case star        = "Star"
}

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path {
            $0.move(to:    .init(x: rect.midX, y: rect.minY))
            $0.addLine(to: .init(x: rect.maxX, y: rect.midY))
            $0.addLine(to: .init(x: rect.midX, y: rect.maxY))
            $0.addLine(to: .init(x: rect.minX, y: rect.midY))
            $0.closeSubpath()
        }
    }
}

private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer  = min(rect.width, rect.height) / 2
        let inner  = outer * 0.42
        return Path {
            for i in 0..<10 {
                let angle  = Double(i) * .pi / 5 - .pi / 2
                let radius = i.isMultiple(of: 2) ? outer : inner
                let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                 y: center.y + CGFloat(sin(angle)) * radius)
                if i == 0 { $0.move(to: pt) } else { $0.addLine(to: pt) }
            }
            $0.closeSubpath()
        }
    }
}

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

    // Animation
    @State private var isAnimating        = true
    @State private var animSpeed: Double  = 1.0
    @State private var animIntensity: Double = 0.12

    // Mask
    @State private var maskShape          = MeshMaskShape.none
    @State private var maskCornerRadius: Double = 32

    // Options
    @State private var smoothsColors      = true
    @State private var blendModeIdx       = 0
    @State private var bgColor            = Color.black
    @State private var gradientOpacity: Double = 1.0

    private var blendMode: BlendMode { meshBlendModes[blendModeIdx].mode }

    var body: some View {
        List {
            previewSection
            gridAndColorSection
            animationSection
            maskSection
            optionsSection
        }
        .navigationTitle("Mesh Gradient")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: gridSize) { _, new in
            colors = palette.colors(for: new.count)
            selectedColorIdx = nil
        }
        .onChange(of: palette) { _, new in
            colors = new.colors(for: gridSize.count)
            selectedColorIdx = nil
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var previewSection: some View {
        Section {
            ZStack {
                bgColor
                gradientLayer
                    .clipShape(currentMaskShape)
                    .blendMode(blendMode)
                    .opacity(gradientOpacity)
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var gradientLayer: some View {
        if isAnimating {
            TimelineView(.animation) { tl in
                meshGradient(at: tl.date.timeIntervalSinceReferenceDate)
            }
        } else {
            meshGradient(at: 0)
        }
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

            if maskShape == .roundedRect {
                LabeledContent("Corner Radius: \(Int(maskCornerRadius))") {
                    Slider(value: $maskCornerRadius, in: 4...100)
                }
                .transition(.opacity)
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

    private func meshPoints(at t: Double) -> [SIMD2<Float>] {
        let dim = gridSize.dimension
        var pts: [SIMD2<Float>] = []
        pts.reserveCapacity(dim * dim)
        for row in 0..<dim {
            for col in 0..<dim {
                let baseX = Float(col) / Float(max(dim - 1, 1))
                let baseY = Float(row) / Float(max(dim - 1, 1))
                let isCorner = (row == 0 || row == dim - 1) && (col == 0 || col == dim - 1)
                let isEdge   = row == 0 || row == dim - 1 || col == 0 || col == dim - 1
                let amp: Float = isCorner ? 0 : isEdge ? Float(animIntensity) * 0.5 : Float(animIntensity)
                let idx   = Double(row * dim + col)
                let phase = idx * 0.85
                let freq  = (0.22 + idx * 0.06) * animSpeed
                let x = baseX + amp * Float(sin(t * freq + phase))
                let y = baseY + amp * Float(cos(t * freq * 1.37 + phase + 1.2))
                pts.append(SIMD2<Float>(min(1, max(0, x)), min(1, max(0, y))))
            }
        }
        return pts
    }

    // MARK: - Mask Shape

    private var currentMaskShape: AnyShape {
        switch maskShape {
        case .none:        AnyShape(Rectangle())
        case .circle:      AnyShape(Circle())
        case .roundedRect: AnyShape(RoundedRectangle(cornerRadius: maskCornerRadius, style: .continuous))
        case .capsule:     AnyShape(Capsule())
        case .diamond:     AnyShape(DiamondShape())
        case .star:        AnyShape(StarShape())
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
