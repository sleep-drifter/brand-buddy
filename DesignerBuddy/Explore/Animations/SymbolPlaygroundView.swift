import SwiftUI
import Combine

// MARK: - Effect Model

enum PlaygroundEffect: String, CaseIterable, Identifiable {
    case bounce = "Bounce"
    case pulse = "Pulse"
    case wiggle = "Wiggle"
    case rotate = "Rotate"
    case breathe = "Breathe"
    case variableColor = "Variable Color"
    case appear = "Appear"
    case disappear = "Disappear"
    case drawOn = "Draw On"
    case drawOff = "Draw Off"
    case replace = "Replace"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .bounce:        "arrow.up.and.down"
        case .pulse:         "dot.radiowaves.left.and.right"
        case .wiggle:        "hand.raised.fingers.spread"
        case .rotate:        "arrow.clockwise"
        case .breathe:       "lungs.fill"
        case .variableColor: "chart.bar.fill"
        case .appear:        "eye"
        case .disappear:     "eye.slash"
        case .drawOn:        "pencil.line"
        case .drawOff:       "eraser.line.dashed"
        case .replace:       "arrow.triangle.2.circlepath"
        }
    }

    var isTrigger: Bool {
        switch self {
        case .bounce, .pulse, .wiggle, .rotate: true
        default: false
        }
    }

    var supportsLayerControl: Bool {
        switch self {
        case .bounce, .wiggle, .rotate, .breathe, .appear, .disappear, .drawOn, .drawOff: true
        default: false
        }
    }
}

// MARK: - Replace Direction

private enum ReplaceDirection: String, CaseIterable {
    case downUp = "Down-Up"
    case upUp   = "Up-Up"
    case offUp  = "Off-Up"

    var effect: ReplaceSymbolEffect {
        switch self {
        case .downUp: .replace.downUp
        case .upUp:   .replace.upUp
        case .offUp:  .replace.offUp
        }
    }
}

// MARK: - Rendering Mode

private enum RenderingModeOption: String, CaseIterable {
    case monochrome   = "Monochrome"
    case hierarchical = "Hierarchical"
    case palette      = "Palette"
    case multicolor   = "Multicolor"

    var mode: SymbolRenderingMode {
        switch self {
        case .monochrome:   .monochrome
        case .hierarchical: .hierarchical
        case .palette:      .palette
        case .multicolor:   .multicolor
        }
    }
}

// MARK: - Symbol Playground View

struct SymbolPlaygroundView: View {
    @State private var symbolName = "star.fill"
    @State private var selectedEffect: PlaygroundEffect = .bounce
    @State private var trigger = 0
    @State private var isActive = false
    @State private var byLayer = false
    @State private var showPlay = true
    @State private var replaceSymbol = "pause.fill"
    @State private var replaceByLayer = false
    @State private var replaceDirection: ReplaceDirection = .downUp
    @State private var preferMagicReplace = true
    @State private var showingSymbolPicker = false
    @State private var showingReplacePicker = false
    @State private var symbolColor: Color = .blue

    @State private var renderingMode: RenderingModeOption = .monochrome
    @State private var variableEnabled = false
    @State private var variableValue: Double = 1.0
    @State private var paletteColor2: Color = .green
    @State private var paletteColor3: Color = .red

    private let palette: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .teal, .cyan, .indigo, .mint]

    var body: some View {
        VStack(spacing: 0) {
            previewCard
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 20) {
                    effectScroller
                    optionsSection
                    appearanceSection
                    colorPickerRow
                    codeCard
                }
                .padding(16)
            }
        }
        .navigationTitle("Symbol Playground")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let random = SFSymbolLibrary.all.randomElement() {
                        symbolName = random
                    }
                } label: {
                    Image(systemName: "shuffle")
                }
            }
        }
        .sheet(isPresented: $showingSymbolPicker) {
            SymbolPickerSheet(selectedSymbol: $symbolName)
        }
        .sheet(isPresented: $showingReplacePicker) {
            SymbolPickerSheet(selectedSymbol: $replaceSymbol)
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)

                if selectedEffect == .replace {
                    replaceImage
                } else {
                    effectAppliedImage
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if selectedEffect != .variableColor {
                    canvasControlBadge.padding(10)
                }
            }
            .frame(height: 200)
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture { handleCanvasTap() }

            Button {
                showingSymbolPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(symbolName)
                        .font(.caption.monospaced())
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var canvasControlBadge: some View {
        let icon: String
        switch selectedEffect {
        case .bounce, .pulse, .wiggle, .rotate:
            icon = "play.fill"
        case .breathe, .appear, .disappear, .drawOn, .drawOff:
            icon = isActive ? "pause.fill" : "play.fill"
        case .replace:
            icon = "arrow.2.squarepath"
        case .variableColor:
            icon = "play.fill"
        }
        return Image(systemName: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())
    }

    private func handleCanvasTap() {
        switch selectedEffect {
        case .bounce, .pulse, .wiggle, .rotate:
            trigger += 1
        case .breathe, .appear, .disappear, .drawOn, .drawOff:
            withAnimation { isActive.toggle() }
        case .variableColor:
            break
        case .replace:
            showPlay.toggle()
        }
    }

    // Builds the replace image with the correct contentTransition for current options.
    // Using @ViewBuilder + if/else avoids having to erase two different SymbolEffect types.
    @ViewBuilder
    private var replaceImage: some View {
        let directional = replaceByLayer ? replaceDirection.effect.byLayer : replaceDirection.effect
        let varVal: Double? = variableEnabled ? variableValue : nil
        let sym = showPlay ? symbolName : replaceSymbol
        if renderingMode == .palette {
            if preferMagicReplace {
                Image(systemName: sym, variableValue: varVal)
                    .font(.system(size: 80))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(symbolColor, paletteColor2, paletteColor3)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: directional)))
                    .animation(.default, value: showPlay)
            } else {
                Image(systemName: sym, variableValue: varVal)
                    .font(.system(size: 80))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(symbolColor, paletteColor2, paletteColor3)
                    .contentTransition(.symbolEffect(directional))
                    .animation(.default, value: showPlay)
            }
        } else {
            if preferMagicReplace {
                Image(systemName: sym, variableValue: varVal)
                    .font(.system(size: 80))
                    .symbolRenderingMode(renderingMode.mode)
                    .foregroundStyle(symbolColor)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: directional)))
                    .animation(.default, value: showPlay)
            } else {
                Image(systemName: sym, variableValue: varVal)
                    .font(.system(size: 80))
                    .symbolRenderingMode(renderingMode.mode)
                    .foregroundStyle(symbolColor)
                    .contentTransition(.symbolEffect(directional))
                    .animation(.default, value: showPlay)
            }
        }
    }

    @ViewBuilder
    private var effectAppliedImage: some View {
        switch selectedEffect {
        case .bounce:
            if byLayer {
                baseImage.symbolEffect(.bounce.byLayer, value: trigger)
            } else {
                baseImage.symbolEffect(.bounce, value: trigger)
            }
        case .pulse:
            baseImage.symbolEffect(.pulse, value: trigger)

        case .wiggle:
            if byLayer {
                baseImage.symbolEffect(.wiggle.byLayer, value: trigger)
            } else {
                baseImage.symbolEffect(.wiggle, value: trigger)
            }
        case .rotate:
            if byLayer {
                baseImage.symbolEffect(.rotate.byLayer, value: trigger)
            } else {
                baseImage.symbolEffect(.rotate, value: trigger)
            }
        case .breathe:
            if byLayer {
                baseImage.symbolEffect(.breathe.byLayer, isActive: isActive)
            } else {
                baseImage.symbolEffect(.breathe, isActive: isActive)
            }
        case .variableColor:
            baseImage.symbolEffect(.variableColor)

        case .appear:
            if byLayer {
                baseImage.symbolEffect(.appear.byLayer, isActive: isActive)
            } else {
                baseImage.symbolEffect(.appear, isActive: isActive)
            }
        case .disappear:
            if byLayer {
                baseImage.symbolEffect(.disappear.byLayer, isActive: isActive)
            } else {
                baseImage.symbolEffect(.disappear, isActive: isActive)
            }
        case .drawOn:
            if byLayer {
                baseImage.symbolEffect(.drawOn.byLayer, isActive: isActive)
            } else {
                baseImage.symbolEffect(.drawOn, isActive: isActive)
            }
        case .drawOff:
            if byLayer {
                baseImage.symbolEffect(.drawOff.byLayer, isActive: isActive)
            } else {
                baseImage.symbolEffect(.drawOff, isActive: isActive)
            }
        case .replace:
            baseImage
        }
    }

    @ViewBuilder
    private var baseImage: some View {
        let varVal: Double? = variableEnabled ? variableValue : nil
        if renderingMode == .palette {
            Image(systemName: symbolName, variableValue: varVal)
                .font(.system(size: 80))
                .symbolRenderingMode(.palette)
                .foregroundStyle(symbolColor, paletteColor2, paletteColor3)
        } else {
            Image(systemName: symbolName, variableValue: varVal)
                .font(.system(size: 80))
                .symbolRenderingMode(renderingMode.mode)
                .foregroundStyle(symbolColor)
        }
    }

    // MARK: - Effect Scroller

    private var effectScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlaygroundEffect.allCases) { effect in
                    effectChip(effect)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, -16)
    }

    private func effectChip(_ effect: PlaygroundEffect) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedEffect = effect
                trigger = 0
                isActive = false
                showPlay = true
            }
        } label: {
            Label(effect.rawValue, systemImage: effect.icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selectedEffect == effect ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selectedEffect == effect ? Color.accentColor : Color(.systemGray5),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Options Section

    @ViewBuilder
    private var optionsSection: some View {
        if selectedEffect == .replace {
            replaceOptions
        } else {
            generalOptions
        }
    }

    private var generalOptions: some View {
        VStack(spacing: 8) {
            if selectedEffect.supportsLayerControl {
                GroupBox {
                    Picker("Animate", selection: $byLayer) {
                        Text("Whole Symbol").tag(false)
                        Text("By Layer").tag(true)
                    }
                    .pickerStyle(.segmented)
                } label: {
                    Text("Animate").font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private var replaceOptions: some View {
        VStack(spacing: 8) {
            GroupBox {
                Button {
                    showingReplacePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: replaceSymbol)
                            .font(.title3)
                            .foregroundStyle(symbolColor)
                            .frame(width: 28, alignment: .center)
                        Text(replaceSymbol)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } label: {
                Text("With").font(.subheadline.weight(.medium))
            }

            GroupBox {
                Picker("Animate", selection: $replaceByLayer) {
                    Text("Whole Symbol").tag(false)
                    Text("By Layer").tag(true)
                }
                .pickerStyle(.segmented)
            } label: {
                Text("Animate").font(.subheadline.weight(.medium))
            }

            GroupBox {
                Picker("Direction", selection: $replaceDirection) {
                    ForEach(ReplaceDirection.allCases, id: \.self) { dir in
                        Text(dir.rawValue).tag(dir)
                    }
                }
                .pickerStyle(.segmented)
            } label: {
                Text("Direction").font(.subheadline.weight(.medium))
            }

            GroupBox {
                Toggle("Prefer Magic Replace", isOn: $preferMagicReplace)
            } label: {
                Text("Magic Replace").font(.subheadline.weight(.medium))
            }
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(spacing: 8) {
            GroupBox {
                HStack(spacing: 8) {
                    ForEach(RenderingModeOption.allCases, id: \.self) { mode in
                        Button {
                            withAnimation(.spring(duration: 0.2)) { renderingMode = mode }
                        } label: {
                            renderingModeChip(mode)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } label: {
                Label("Rendering Mode", systemImage: "paintpalette")
                    .font(.subheadline.weight(.medium))
            }

            GroupBox {
                VStack(spacing: 10) {
                    Toggle("Variable Value", isOn: $variableEnabled)
                    if variableEnabled {
                        HStack {
                            Slider(value: $variableValue, in: 0...1)
                            Text("\(Int(variableValue * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 38, alignment: .trailing)
                        }
                    }
                }
            } label: {
                Label("Variable", systemImage: "slider.horizontal.3")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    @ViewBuilder
    private func renderingModeChip(_ mode: RenderingModeOption) -> some View {
        let isSelected = renderingMode == mode
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                switch mode {
                case .monochrome:
                    Image(systemName: symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(isSelected ? .white : symbolColor)
                case .hierarchical:
                    Image(systemName: symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSelected ? .white : symbolColor)
                case .palette:
                    Image(systemName: symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(symbolColor),
                            isSelected ? AnyShapeStyle(Color.white.opacity(0.7)) : AnyShapeStyle(paletteColor2),
                            isSelected ? AnyShapeStyle(Color.white.opacity(0.5)) : AnyShapeStyle(paletteColor3)
                        )
                case .multicolor:
                    Image(systemName: symbolName)
                        .font(.title2)
                        .symbolRenderingMode(.multicolor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)

            Text(mode.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // MARK: - Color Picker

    private var colorPickerRow: some View {
        VStack(spacing: 8) {
            colorSwatchRow(label: renderingMode == .palette ? "Primary" : "Color",
                           binding: $symbolColor)
            if renderingMode == .palette {
                colorSwatchRow(label: "Secondary", binding: $paletteColor2)
                colorSwatchRow(label: "Tertiary",  binding: $paletteColor3)
            }
        }
    }

    private func colorSwatchRow(label: String, binding: Binding<Color>) -> some View {
        GroupBox {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(palette, id: \.self) { color in
                        Button {
                            binding.wrappedValue = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(binding.wrappedValue == color ? 1 : 0), lineWidth: 2.5)
                                        .padding(3)
                                )
                                .shadow(color: color.opacity(0.4), radius: binding.wrappedValue == color ? 6 : 2)
                                .scaleEffect(binding.wrappedValue == color ? 1.15 : 1)
                                .animation(.spring(duration: 0.2), value: binding.wrappedValue == color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
        } label: {
            Text(label).font(.subheadline.weight(.medium))
        }
    }

    // MARK: - Code Card

    private var codeCard: some View {
        GroupBox {
            Text(generatedCode)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        } label: {
            Label("Swift", systemImage: "doc.plaintext")
                .font(.subheadline.weight(.medium))
        }
    }

    private var generatedCode: String {
        let sym = symbolName
        let layer = byLayer

        // Build Image init and shared modifier lines
        let varArg = variableEnabled ? String(format: ", variableValue: %.2f", variableValue) : ""
        var prefix = ""
        if renderingMode != .monochrome {
            prefix += "\n    .symbolRenderingMode(.\(renderingMode.rawValue.lowercased()))"
        }
        if renderingMode == .palette {
            prefix += "\n    .foregroundStyle(primary, secondary, tertiary)"
        }

        func wrap(_ effect: String) -> String {
            "Image(systemName: \"\(sym)\"\(varArg))\(prefix)\n    \(effect)"
        }

        switch selectedEffect {
        case .bounce:
            return wrap(layer
                ? ".symbolEffect(.bounce.byLayer, value: trigger)"
                : ".symbolEffect(.bounce, value: trigger)")
        case .pulse:
            return wrap(".symbolEffect(.pulse, value: trigger)")
        case .wiggle:
            return wrap(layer
                ? ".symbolEffect(.wiggle.byLayer, value: trigger)"
                : ".symbolEffect(.wiggle, value: trigger)")
        case .rotate:
            return wrap(layer
                ? ".symbolEffect(.rotate.byLayer, value: trigger)"
                : ".symbolEffect(.rotate, value: trigger)")
        case .breathe:
            return wrap(layer
                ? ".symbolEffect(.breathe.byLayer, isActive: isActive)"
                : ".symbolEffect(.breathe, isActive: isActive)")
        case .variableColor:
            return wrap(".symbolEffect(.variableColor)")
        case .appear:
            return wrap(layer
                ? ".symbolEffect(.appear.byLayer, isActive: isActive)"
                : ".symbolEffect(.appear, isActive: isActive)")
        case .disappear:
            return wrap(layer
                ? ".symbolEffect(.disappear.byLayer, isActive: isActive)"
                : ".symbolEffect(.disappear, isActive: isActive)")
        case .drawOn:
            return wrap(layer
                ? ".symbolEffect(.drawOn.byLayer, isActive: isActive)"
                : ".symbolEffect(.drawOn, isActive: isActive)")
        case .drawOff:
            return wrap(layer
                ? ".symbolEffect(.drawOff.byLayer, isActive: isActive)"
                : ".symbolEffect(.drawOff, isActive: isActive)")
        case .replace:
            let rep = replaceSymbol
            let dir = replaceDirection
            let magic = preferMagicReplace
            let rLayer = replaceByLayer
            let dirStr: String
            switch dir {
            case .downUp: dirStr = ".replace.downUp"
            case .upUp:   dirStr = ".replace.upUp"
            case .offUp:  dirStr = ".replace.offUp"
            }
            let layeredDir = rLayer ? "\(dirStr).byLayer" : dirStr
            let effectStr = magic
                ? ".replace.magic(fallback: \(layeredDir))"
                : layeredDir
            return """
            Image(systemName: showState ? "\(sym)" : "\(rep)"\(varArg))\(prefix)
                .contentTransition(.symbolEffect(\(effectStr)))
                .animation(.default, value: showState)
            """
        }
    }
}

// MARK: - Symbol Picker Sheet

struct SymbolPickerSheet: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var debouncedQuery = ""
    @State private var selectedCategory: SFSymbolCategory? = nil
    @State private var displayedSymbols: [String] = SFSymbolLibrary.featured
    @State private var isCapped = false
    @State private var isSearchPresented = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    private let searchSubject = PassthroughSubject<String, Never>()
    @State private var cancellable: AnyCancellable?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category chips
                categoryChips

                Divider()

                // Custom-name shortcut when query is a plausible direct name
                if query.count >= 1, !SFSymbolLibrary.all.contains(query),
                   UIImage(systemName: query) != nil {
                    Button {
                        selectedSymbol = query
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: query).font(.title3).frame(width: 32)
                            Text("Use \"\(query)\"")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "return").font(.caption).foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                    }
                    .buttonStyle(.plain)
                    Divider()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Landing caption when nothing searched / filtered
                        if query.count < 3 && selectedCategory == nil {
                            Text("Search to explore 6,000+ symbols")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                        }

                        if displayedSymbols.isEmpty {
                            ContentUnavailableView(
                                "No matches",
                                systemImage: "magnifyingglass",
                                description: Text("Try a different search term.")
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(displayedSymbols, id: \.self) { name in
                                    symbolCell(name)
                                }
                            }
                            .padding(12)

                            if isCapped {
                                Text("Showing top 100 results — refine your search")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(
                text: $query,
                isPresented: $isSearchPresented,
                placement: .automatic,
                prompt: "Search or type any SF Symbol name..."
            )
            .onChange(of: query) { _, newValue in
                searchSubject.send(newValue)
            }
            .onChange(of: selectedCategory) { _, _ in
                applyFilter(query: debouncedQuery)
            }
            .onAppear {
                cancellable = searchSubject
                    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                    .sink { q in
                        debouncedQuery = q
                        applyFilter(query: q)
                    }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchPresented = true
                }
            }
            .onDisappear { cancellable?.cancel() }
        }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All", icon: "square.grid.2x2")
                ForEach(SFSymbolCategory.allCases) { cat in
                    categoryChip(cat, label: cat.rawValue, icon: cat.icon)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func categoryChip(_ cat: SFSymbolCategory?, label: String, icon: String) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            withAnimation(.spring(duration: 0.2)) { selectedCategory = cat }
        } label: {
            Label(label, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Logic (background thread)

    private func applyFilter(query: String) {
        let cat = selectedCategory
        let q = query

        DispatchQueue.global(qos: .userInitiated).async {
            let pool: [String]
            if let cat {
                pool = cat.symbolNames
            } else {
                pool = SFSymbolLibrary.all
            }

            let results: [String]
            let capped: Bool
            if q.count < 3 && cat == nil {
                results = SFSymbolLibrary.featured
                capped = false
            } else if q.count < 3 {
                let r = Array(pool.prefix(100))
                results = r
                capped = pool.count > 100
            } else {
                let filtered = pool.filter { $0.localizedCaseInsensitiveContains(q) }
                let r = Array(filtered.prefix(100))
                results = r
                capped = filtered.count > 100
            }

            DispatchQueue.main.async {
                displayedSymbols = results
                isCapped = capped
            }
        }
    }

    // MARK: - Symbol Cell

    private func symbolCell(_ name: String) -> some View {
        let isSelected = selectedSymbol == name
        return Button {
            selectedSymbol = name
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: name)
                    .font(.title2)
                    .frame(height: 32)
                Text(name)
                    .font(.system(size: 7, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { SymbolPlaygroundView() }
}
