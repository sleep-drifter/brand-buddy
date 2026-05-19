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
    @State private var replaceStatus: String? = nil

    private let palette: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .teal, .cyan, .indigo, .mint]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                previewCard
                effectScroller
                optionsSection
                colorPickerRow
                codeCard
            }
            .padding(16)
        }
        .navigationTitle("Symbol Playground")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSymbolPicker) {
            SymbolPickerSheet(selectedSymbol: $symbolName)
        }
        .sheet(isPresented: $showingReplacePicker) {
            SymbolPickerSheet(selectedSymbol: $replaceSymbol)
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.regularMaterial)
                animatedPreview
            }
            .frame(height: 200)

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

    @ViewBuilder
    private var animatedPreview: some View {
        if selectedEffect == .replace {
            ZStack(alignment: .bottom) {
                Button {
                    showPlay.toggle()
                    if preferMagicReplace {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            replaceStatus = "✅ Smart Replace active"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.2)) { replaceStatus = nil }
                        }
                    }
                } label: {
                    replaceImage
                }
                .buttonStyle(.plain)

                if let status = replaceStatus {
                    Text(status)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.55), in: Capsule())
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.bottom, 10)
                }
            }
        } else {
            effectAppliedImage
        }
    }

    // Builds the replace image with the correct contentTransition for current options.
    // Using @ViewBuilder + if/else avoids having to erase two different SymbolEffect types.
    @ViewBuilder
    private var replaceImage: some View {
        let directional = replaceByLayer ? replaceDirection.effect.byLayer : replaceDirection.effect
        if preferMagicReplace {
            Image(systemName: showPlay ? symbolName : replaceSymbol)
                .font(.system(size: 80))
                .foregroundStyle(symbolColor)
                .contentTransition(.symbolEffect(.replace.magic(fallback: directional)))
                .animation(.default, value: showPlay)
        } else {
            Image(systemName: showPlay ? symbolName : replaceSymbol)
                .font(.system(size: 80))
                .foregroundStyle(symbolColor)
                .contentTransition(.symbolEffect(directional))
                .animation(.default, value: showPlay)
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

    private var baseImage: some View {
        Image(systemName: symbolName)
            .font(.system(size: 80))
            .foregroundStyle(symbolColor)
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
            // Control
            GroupBox {
                if selectedEffect.isTrigger {
                    Button("Trigger Animation") { trigger += 1 }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                } else if selectedEffect == .variableColor {
                    Text("Loops automatically")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    Toggle("Active", isOn: $isActive)
                }
            } label: {
                Text("Control").font(.subheadline.weight(.medium))
            }

            // By Layer
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
                Button("Toggle Symbol") { showPlay.toggle() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            } label: {
                Text("Control").font(.subheadline.weight(.medium))
            }

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

    // MARK: - Color Picker

    private var colorPickerRow: some View {
        GroupBox {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(palette, id: \.self) { color in
                        Button {
                            symbolColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .strokeBorder(.white.opacity(symbolColor == color ? 1 : 0), lineWidth: 2.5)
                                        .padding(3)
                                )
                                .shadow(color: color.opacity(0.4), radius: symbolColor == color ? 6 : 2)
                                .scaleEffect(symbolColor == color ? 1.15 : 1)
                                .animation(.spring(duration: 0.2), value: symbolColor == color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        } label: {
            Text("Color").font(.subheadline.weight(.medium))
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
        switch selectedEffect {
        case .bounce:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.bounce.byLayer, value: trigger)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.bounce, value: trigger)"
        case .pulse:
            return "Image(systemName: \"\(sym)\")\n    .symbolEffect(.pulse, value: trigger)"
        case .wiggle:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.wiggle.byLayer, value: trigger)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.wiggle, value: trigger)"
        case .rotate:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.rotate.byLayer, value: trigger)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.rotate, value: trigger)"
        case .breathe:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.breathe.byLayer, isActive: isActive)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.breathe, isActive: isActive)"
        case .variableColor:
            return "Image(systemName: \"\(sym)\")\n    .symbolEffect(.variableColor)"
        case .appear:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.appear.byLayer, isActive: isActive)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.appear, isActive: isActive)"
        case .disappear:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.disappear.byLayer, isActive: isActive)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.disappear, isActive: isActive)"
        case .drawOn:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.drawOn.byLayer, isActive: isActive)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.drawOn, isActive: isActive)"
        case .drawOff:
            return layer
                ? "Image(systemName: \"\(sym)\")\n    .symbolEffect(.drawOff.byLayer, isActive: isActive)"
                : "Image(systemName: \"\(sym)\")\n    .symbolEffect(.drawOff, isActive: isActive)"
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
            Image(systemName: showState ? "\(sym)" : "\(rep)")
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
