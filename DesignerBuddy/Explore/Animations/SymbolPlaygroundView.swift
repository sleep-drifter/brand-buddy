import SwiftUI

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
        case .bounce, .wiggle, .rotate, .breathe, .appear, .disappear: true
        default: false
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
    @State private var showingSymbolPicker = false
    @State private var showingReplacePicker = false
    @State private var symbolColor: Color = .blue

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
            Button { showPlay.toggle() } label: {
                Image(systemName: showPlay ? symbolName : replaceSymbol)
                    .font(.system(size: 80))
                    .foregroundStyle(symbolColor)
                    .contentTransition(.symbolEffect(replaceByLayer ? .replace.byLayer : .replace))
                    .animation(.default, value: showPlay)
            }
            .buttonStyle(.plain)
        } else {
            effectAppliedImage
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
        case .replace:
            let transition = replaceByLayer ? ".replace.byLayer" : ".replace"
            return """
            Image(systemName: showState ? "\(sym)" : "\(replaceSymbol)")
                .contentTransition(.symbolEffect(\(transition)))
                .animation(.default, value: showState)
            """
        }
    }
}

// MARK: - Symbol Picker Sheet

struct SymbolPickerSheet: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private static let symbols: [String] = [
        // Communication
        "message", "message.fill", "envelope", "envelope.fill",
        "phone", "phone.fill", "video", "video.fill",
        "bubble.left", "bubble.left.fill", "bubble.right.fill",
        // Media
        "play", "play.fill", "pause", "pause.fill",
        "stop.fill", "forward.fill", "backward.fill",
        "music.note", "waveform", "mic", "mic.fill",
        "speaker.wave.3", "speaker.wave.3.fill", "speaker.slash.fill",
        // Files
        "doc", "doc.fill", "folder", "folder.fill",
        "icloud", "icloud.fill", "tray", "tray.fill",
        "archivebox", "archivebox.fill", "externaldrive", "externaldrive.fill",
        // Favourites
        "star", "star.fill", "heart", "heart.fill",
        "bookmark", "bookmark.fill", "flag", "flag.fill",
        "tag", "tag.fill", "pin", "pin.fill",
        // Energy & Nature
        "bolt", "bolt.fill", "flame", "flame.fill",
        "sparkle", "sparkles", "leaf", "leaf.fill",
        "tree", "tree.fill", "drop.fill", "wind",
        // Alerts
        "bell", "bell.fill", "bell.badge", "bell.badge.fill",
        "exclamationmark.circle", "exclamationmark.triangle.fill",
        "checkmark.circle", "checkmark.circle.fill",
        "xmark.circle", "xmark.circle.fill",
        "info.circle", "info.circle.fill",
        // Arrows
        "arrow.up", "arrow.down", "arrow.left", "arrow.right",
        "arrow.up.circle.fill", "arrow.down.circle.fill",
        "arrow.clockwise", "arrow.counterclockwise",
        "arrow.triangle.2.circlepath",
        "chevron.up", "chevron.down", "chevron.left", "chevron.right",
        "chevron.left.forwardslash.chevron.right",
        // UI Controls
        "gear", "gear.circle.fill", "ellipsis", "ellipsis.circle",
        "magnifyingglass", "magnifyingglass.circle.fill",
        "plus", "plus.circle.fill", "minus", "minus.circle",
        "slider.horizontal.3", "line.3.horizontal", "line.3.horizontal.decrease.circle",
        // Weather
        "sun.max", "sun.max.fill", "moon", "moon.fill",
        "cloud", "cloud.fill", "cloud.rain.fill", "bolt.rain.fill",
        "snow", "thermometer.medium", "umbrella", "umbrella.fill",
        // Health & People
        "heart.pulse", "heart.pulse.fill", "lungs.fill",
        "stethoscope", "cross.fill",
        "person", "person.fill", "person.2", "person.2.fill",
        "figure.walk", "figure.run", "hand.raised", "hand.raised.fill",
        "hand.thumbsup", "hand.thumbsup.fill",
        // Transport
        "car", "car.fill", "airplane", "airplane.circle.fill",
        "bicycle", "bus", "tram.fill", "ferry.fill",
        // Places
        "house", "house.fill", "building.2", "building.2.fill",
        "map", "map.fill", "mappin", "mappin.circle.fill",
        "globe", "globe.americas.fill",
        // Tech
        "wifi", "wifi.slash", "antenna.radiowaves.left.and.right",
        "cpu", "cpu.fill", "memorychip", "memorychip.fill",
        "tv", "tv.fill", "iphone", "ipad", "keyboard",
        // Time
        "clock", "clock.fill", "calendar", "calendar.circle.fill",
        "timer", "alarm", "alarm.fill", "stopwatch",
        // Misc
        "cart", "cart.fill", "creditcard", "creditcard.fill",
        "gift", "gift.fill", "lock", "lock.fill",
        "key", "key.fill", "shield", "shield.fill",
        "square.grid.2x2", "square.grid.3x3.fill",
        "pawprint", "pawprint.fill",
        "trophy", "trophy.fill", "medal", "medal.fill"
    ]

    private var filtered: [String] {
        search.isEmpty
            ? Self.symbols
            : Self.symbols.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search or type any SF Symbol name…", text: $search)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding([.horizontal, .top], 16)
                    .padding(.bottom, 8)

                // Allow entering a custom symbol not in the list
                if !search.isEmpty, !Self.symbols.contains(search) {
                    Button {
                        selectedSymbol = search
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Group {
                                if let _ = UIImage(systemName: search) {
                                    Image(systemName: search).font(.title3)
                                } else {
                                    Image(systemName: "questionmark.circle").font(.title3)
                                }
                            }
                            .frame(width: 32, alignment: .center)
                            Text("Use \"\(search)\"")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "return")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                    }
                    .buttonStyle(.plain)

                    Divider()
                }

                if filtered.isEmpty {
                    ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Try a different search or use the name directly above."))
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filtered, id: \.self) { name in
                                symbolCell(name)
                            }
                        }
                        .padding(16)
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
        }
    }

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
                    .font(.system(size: 8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { SymbolPlaygroundView() }
}
