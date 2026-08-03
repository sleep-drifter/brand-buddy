import SwiftUI
import UIKit

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

    private let palette: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .teal, .cyan, .indigo, .mint, .white, Color(.systemGray3), .gray, .black]

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
            .contextMenu { copyNameButton(symbolName) }
        }
    }

    /// Long-press affordance for the symbol name labels: tap still opens the picker,
    /// long-press puts the exact name on the clipboard.
    @ViewBuilder
    private func copyNameButton(_ name: String) -> some View {
        Button {
            UIPasteboard.general.string = name
        } label: {
            Label("Copy Name", systemImage: "doc.on.doc")
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
                .contextMenu { copyNameButton(replaceSymbol) }
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
                                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(selectionRing(for: color).opacity(binding.wrappedValue == color ? 1 : 0), lineWidth: 2.5)
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

    private func selectionRing(for color: Color) -> Color {
        color == .white ? .gray : .white
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
    @State private var selectedCategory: SFSymbolCategory? = nil
    @State private var results = SFSymbolSearch.PickerResults.featured
    @State private var displayLimit = Self.pageSize
    @State private var isSearchPresented = false

    /// Results are ranked, so the first page is the useful one. The rest stay one
    /// tap away rather than being discarded.
    private static let pageSize = 300
    private static let debounce = Duration.milliseconds(150)

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    private var visibleSymbols: ArraySlice<String> {
        results.symbols.prefix(displayLimit)
    }

    /// Identity for the debounced search task: changing either input restarts it.
    /// The separator can't occur in a category name or a normalized query.
    private var searchKey: String {
        "\(selectedCategory?.rawValue ?? "")\u{1}\(query)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category chips
                categoryChips

                Divider()

                // Custom-name shortcut when query is a plausible direct name
                if query.count >= 1, !SFSymbolLibrary.allSet.contains(query),
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
                        resultsHeader

                        if results.symbols.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(visibleSymbols, id: \.self) { name in
                                    symbolCell(name)
                                }
                            }
                            .padding(12)

                            showMoreFooter
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
            // .task(id:) restarts on every keystroke or category change and cancels the
            // previous run, which debounces typing and drops stale results in one step.
            .task(id: searchKey) {
                await runSearch(query: query, category: selectedCategory)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchPresented = true
                }
            }
        }
    }

    // MARK: - Result Chrome

    @ViewBuilder
    private var resultsHeader: some View {
        if results.isFeatured {
            Text("Search to explore \(SFSymbolLibrary.all.count.formatted()) symbols")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 4)
        } else if results.isApproximate, !results.symbols.isEmpty {
            Label("No exact match — showing the closest symbols", systemImage: "sparkle.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 4)
        }
    }

    private var emptyStateDescription: String {
        guard let category = results.category else { return "Try a different search term." }
        return "Nothing in \(category.rawValue) matches this search."
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No matches",
                systemImage: "magnifyingglass",
                description: Text(emptyStateDescription)
            )

            // Never dead-end inside a category when the full library has answers.
            if results.category != nil, results.libraryMatchCount > 0 {
                Button {
                    withAnimation(.spring(duration: 0.2)) { selectedCategory = nil }
                } label: {
                    Text("Search all symbols (\(results.libraryMatchCount.formatted()) matches)")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 40)
    }

    @ViewBuilder
    private var showMoreFooter: some View {
        if results.symbols.count > displayLimit {
            VStack(spacing: 8) {
                Text("Showing \(displayLimit.formatted()) of \(results.symbols.count.formatted()) matches")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("Show all \(results.symbols.count.formatted())") {
                    displayLimit = .max
                }
                .font(.caption.weight(.medium))
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 16)
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

    // MARK: - Search

    @MainActor
    private func runSearch(query: String, category: SFSymbolCategory?) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Only typing needs settling time; a category tap should feel instant.
        if !trimmed.isEmpty {
            try? await Task.sleep(for: Self.debounce)
            guard !Task.isCancelled else { return }
        }

        let outcome = await Task.detached(priority: .userInitiated) {
            SFSymbolSearch.pickerResults(query: trimmed, category: category)
        }.value

        guard !Task.isCancelled else { return }
        results = outcome
        displayLimit = Self.pageSize
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
        // Cells are small enough that long names get truncated, so long-press offers
        // the full name rather than making people read it off the grid.
        .contextMenu {
            Button {
                UIPasteboard.general.string = name
            } label: {
                Label("Copy Name", systemImage: "doc.on.doc")
            }
        }
    }
}

#Preview {
    NavigationStack { SymbolPlaygroundView() }
}
