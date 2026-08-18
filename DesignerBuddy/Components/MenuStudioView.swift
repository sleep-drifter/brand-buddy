import Combine
import SwiftUI
import UIKit

// Menu Studio — compose a real SwiftUI menu item by item and present it from
// three anchors: an inline Menu button, a long-press context menu (with or
// without a custom preview), and a toolbar item. Covers the iOS 26 menu
// surface minus nested submenus: buttons with roles and subtitles, toggles,
// inline and palette pickers, control groups (compact and palette), share
// links, dividers, and titled sections, plus the menu-level dials —
// menuIndicator, menuOrder, menuActionDismissBehavior, and primaryAction.
// The trailing clipboard button copies the composed menu as SwiftUI source.

// MARK: - Model

enum MenuItemKind: String, Codable, CaseIterable, Identifiable {
    case action = "Button"
    case toggle = "Toggle"
    case picker = "Picker"
    case controlGroup = "Control Group"
    case share = "Share Link"
    case divider = "Divider"
    case section = "Section"

    var id: String { rawValue }

    var addSymbol: String {
        switch self {
        case .action: "hand.tap"
        case .toggle: "checkmark.circle"
        case .picker: "checklist"
        case .controlGroup: "square.grid.3x1.below.line.grid.1x2"
        case .share: "square.and.arrow.up"
        case .divider: "minus"
        case .section: "text.justify.leading"
        }
    }
}

struct MenuItemSpec: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: MenuItemKind = .action
    var title = "Action"
    var subtitle = ""
    var symbol = "star"
    var destructive = false
    var disabled = false
    var isOn = true
    /// Picker options, or control-group SF Symbols — comma separated.
    var optionsText = "Small, Medium, Large"
    var selection = 0
    var palette = false

    var options: [String] {
        optionsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

struct MenuStudioSetup: Codable, Equatable {
    enum LabelChrome: String, Codable, CaseIterable, Identifiable {
        case plain = "Plain", tinted = "Tint", glass = "Glass"
        var id: String { rawValue }
    }

    var menuTitle = "Options"
    var menuSymbol = "ellipsis.circle"
    var indicator = true
    var fixedOrder = true
    var keepPresented = false
    var primaryAction = false
    var contextPreview = true
    var chrome: LabelChrome = .glass
}

struct MenuStudioPreset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var setup: MenuStudioSetup
    var items: [MenuItemSpec]
}

final class MenuStudioStore: ObservableObject {
    @Published private(set) var presets: [MenuStudioPreset] = []
    private let key = "menuStudioPresets.v1"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([MenuStudioPreset].self, from: data) else { return }
        presets = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ preset: MenuStudioPreset) {
        presets.append(preset)
        persist()
    }

    func delete(_ preset: MenuStudioPreset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }
}

// MARK: - View

struct MenuStudioView: View {
    private enum Anchor: String, CaseIterable, Identifiable {
        case button = "Button", context = "Context", toolbar = "Toolbar"
        var id: String { rawValue }
    }

    @StateObject private var store = MenuStudioStore()

    @State private var items = MenuStudioView.editingStarter
    @State private var setup = MenuStudioSetup()
    @State private var anchor: Anchor = .button
    @State private var selectedID: UUID?
    @State private var lastEvent = "Interact with the menu to log events."
    @State private var copied = false
    @State private var showSaveAlert = false
    @State private var presetName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                anchorRowCard
                setupCard
                itemsCard
                if let idx = selectedIndex {
                    editorCard(idx)
                }
                presetsCard
                caption
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .pinnedPreview(entry: "Menu Studio") {
            stage
        }
        .navigationTitle("Menu Studio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = generatedCode()
                    glassMorphHaptic(.soft)
                    copied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark.circle" : "doc.on.clipboard")
                }
                .accessibilityLabel("Copy SwiftUI code")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if anchor == .toolbar {
                    composedMenu {
                        Image(systemName: setup.menuSymbol)
                    }
                }
            }
        }
        .alert("Save preset", isPresented: $showSaveAlert) {
            TextField("Name", text: $presetName)
            Button("Save") {
                let trimmed = presetName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                store.add(MenuStudioPreset(name: trimmed, setup: setup, items: items))
                presetName = ""
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var selectedIndex: Int? {
        guard let id = selectedID else { return nil }
        return items.firstIndex { $0.id == id }
    }

    // MARK: - Stage

    private var stage: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple.opacity(0.8), .cyan],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            switch anchor {
            case .button:
                menuButtonAnchor
            case .context:
                contextAnchor
            case .toolbar:
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.title3.weight(.semibold))
                    Text("Composed menu is mounted\nin the navigation bar")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .bottom) {
            Text(lastEvent)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.black.opacity(0.35), in: Capsule())
                .padding(.bottom, 8)
        }
    }

    private var menuButtonAnchor: some View {
        composedMenu {
            anchorLabel
        }
        .menuOrder(setup.fixedOrder ? .fixed : .priority)
        .menuActionDismissBehavior(setup.keepPresented ? .disabled : .automatic)
        .menuIndicator(setup.indicator ? .visible : .hidden)
    }

    @ViewBuilder
    private var anchorLabel: some View {
        let base = Label(setup.menuTitle, systemImage: setup.menuSymbol)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        switch setup.chrome {
        case .plain:
            base
        case .tinted:
            base.background(.indigo.opacity(0.85), in: Capsule())
        case .glass:
            base.glassEffect(.regular.tint(.indigo.opacity(0.5)), in: .capsule)
        }
    }

    @ViewBuilder
    private var contextAnchor: some View {
        let card = VStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
            Text("Long-press me")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white)
        .frame(width: 170, height: 110)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        if setup.contextPreview {
            card.contextMenu {
                composedContent
            } preview: {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                    Text("Custom preview view")
                        .font(.headline)
                    Text("contextMenu(menuItems:preview:)")
                        .font(.mono(.caption2))
                        .foregroundStyle(.secondary)
                }
                .padding(30)
                .background(LinearGradient(colors: [.indigo, .cyan],
                                           startPoint: .top, endPoint: .bottom))
                .foregroundStyle(.white)
            }
        } else {
            card.contextMenu {
                composedContent
            }
        }
    }

    /// The composed Menu with or without a primary action, shared by the
    /// button and toolbar anchors.
    @ViewBuilder
    private func composedMenu<L: View>(@ViewBuilder label: () -> L) -> some View {
        if setup.primaryAction {
            Menu {
                composedContent
            } label: {
                label()
            } primaryAction: {
                lastEvent = "primaryAction fired"
            }
        } else {
            Menu {
                composedContent
            } label: {
                label()
            }
        }
    }

    // MARK: - Composed menu content

    private var grouped: [(header: String?, indices: [Int])] {
        var out: [(header: String?, indices: [Int])] = []
        var header: String?
        var bucket: [Int] = []
        func flush() {
            if header != nil || !bucket.isEmpty {
                out.append((header, bucket))
            }
            bucket = []
        }
        for (i, item) in items.enumerated() {
            if item.kind == .section {
                flush()
                header = item.title
            } else {
                bucket.append(i)
            }
        }
        flush()
        return out
    }

    @ViewBuilder
    private var composedContent: some View {
        ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
            if let header = group.header {
                Section(header) {
                    ForEach(group.indices, id: \.self) { i in
                        itemView(i)
                    }
                }
            } else {
                ForEach(group.indices, id: \.self) { i in
                    itemView(i)
                }
            }
        }
    }

    @ViewBuilder
    private func itemView(_ i: Int) -> some View {
        let item = items[i]
        switch item.kind {
        case .action:
            Button(role: item.destructive ? .destructive : nil) {
                lastEvent = "“\(item.title)” tapped"
            } label: {
                if item.subtitle.isEmpty {
                    Label(item.title, systemImage: item.symbol)
                } else {
                    Text(item.title)
                    Text(item.subtitle)
                    if !item.symbol.isEmpty {
                        Image(systemName: item.symbol)
                    }
                }
            }
            .disabled(item.disabled)

        case .toggle:
            Toggle(isOn: toggleBinding(i)) {
                if item.subtitle.isEmpty {
                    Label(item.title, systemImage: item.symbol)
                } else {
                    Text(item.title)
                    Text(item.subtitle)
                }
            }
            .disabled(item.disabled)

        case .picker:
            let opts = item.options
            if item.palette {
                Picker(item.title, selection: selectionBinding(i)) {
                    ForEach(opts.indices, id: \.self) { k in
                        Image(systemName: opts[k]).tag(k)
                    }
                }
                .pickerStyle(.palette)
            } else {
                Picker(item.title, selection: selectionBinding(i)) {
                    ForEach(opts.indices, id: \.self) { k in
                        Text(opts[k]).tag(k)
                    }
                }
            }

        case .controlGroup:
            // Automatic style in a menu renders labeled items as captioned
            // tiles (UIKit's medium element size); icon-only items collapse
            // to the compact icon row. Palette overrides both.
            let opts = item.options
            if item.palette {
                ControlGroup {
                    controlGroupButtons(opts)
                }
                .controlGroupStyle(.palette)
            } else {
                ControlGroup {
                    controlGroupButtons(opts)
                }
            }

        case .share:
            ShareLink(item: URL(string: "https://developer.apple.com/design/")!) {
                Label(item.title, systemImage: item.symbol.isEmpty ? "square.and.arrow.up" : item.symbol)
            }

        case .divider:
            Divider()

        case .section:
            EmptyView()
        }
    }

    /// Entries are either bare SF Symbols ("scissors") for icon-only items,
    /// or "Title:symbol" pairs ("Cut:scissors") for captioned tiles.
    private func controlGroupButtons(_ entries: [String]) -> some View {
        ForEach(entries.indices, id: \.self) { k in
            let parts = entries[k]
                .split(separator: ":", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            Button {
                lastEvent = "“\(parts.first ?? "?")” tapped"
            } label: {
                if parts.count == 2 {
                    Label(parts[0], systemImage: parts[1])
                } else {
                    Image(systemName: parts.first ?? "questionmark")
                }
            }
        }
    }

    private func toggleBinding(_ i: Int) -> Binding<Bool> {
        Binding(
            get: { i < items.count ? items[i].isOn : false },
            set: { newValue in
                guard i < items.count else { return }
                items[i].isOn = newValue
                lastEvent = "“\(items[i].title)” → \(newValue ? "on" : "off")"
            }
        )
    }

    private func selectionBinding(_ i: Int) -> Binding<Int> {
        Binding(
            get: { i < items.count ? items[i].selection : 0 },
            set: { newValue in
                guard i < items.count else { return }
                items[i].selection = newValue
                let opts = items[i].options
                if newValue < opts.count {
                    lastEvent = "“\(items[i].title)” → \(opts[newValue])"
                }
            }
        )
    }

    // MARK: - Cards

    private var anchorRowCard: some View {
        card {
            row {
                Picker("Anchor", selection: $anchor) {
                    ForEach(Anchor.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var setupCard: some View {
        card {
            fieldRow("Title", text: $setup.menuTitle)
            divider
            fieldRow("Symbol", text: $setup.menuSymbol, mono: true)
            divider
            row {
                HStack {
                    Text("Label Chrome").frame(width: 110, alignment: .leading)
                    Spacer()
                    Picker("Chrome", selection: $setup.chrome) {
                        ForEach(MenuStudioSetup.LabelChrome.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(width: 190)
                }
            }
            divider
            row { Toggle("Menu Indicator", isOn: $setup.indicator) }
            divider
            row { Toggle("Fixed Order (vs. priority)", isOn: $setup.fixedOrder) }
            divider
            row { Toggle("Keep Presented on Toggle", isOn: $setup.keepPresented) }
            divider
            row { Toggle("Primary Action (split button)", isOn: $setup.primaryAction) }
            if anchor == .context {
                divider
                row { Toggle("Custom Context Preview", isOn: $setup.contextPreview) }
            }
        }
    }

    private var itemsCard: some View {
        card {
            ForEach(items) { item in
                let isSelected = item.id == selectedID
                Button {
                    selectedID = isSelected ? nil : item.id
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: item.kind == .divider ? "minus"
                              : (item.symbol.isEmpty ? item.kind.addSymbol : item.symbol))
                            .frame(width: 26)
                            .foregroundStyle(isSelected ? Color.accentColor : .primary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.kind == .divider ? "Divider" : item.title)
                                .foregroundStyle(.primary)
                            Text(item.kind.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                divider
            }
            row {
                Menu {
                    ForEach(MenuItemKind.allCases) { kind in
                        Button(kind.rawValue, systemImage: kind.addSymbol) {
                            addItem(kind)
                        }
                    }
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
            }
        }
    }

    @ViewBuilder
    private func editorCard(_ idx: Int) -> some View {
        let kind = items[idx].kind
        card {
            row {
                HStack {
                    Text("Kind").frame(width: 110, alignment: .leading)
                    Spacer()
                    Picker("Kind", selection: $items[idx].kind) {
                        ForEach(MenuItemKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
            if kind != .divider {
                divider
                fieldRow("Title", text: $items[idx].title)
            }
            if kind == .action || kind == .toggle {
                divider
                fieldRow("Subtitle", text: $items[idx].subtitle)
            }
            if kind == .action || kind == .toggle || kind == .share {
                divider
                fieldRow("Symbol", text: $items[idx].symbol, mono: true)
            }
            if kind == .picker || kind == .controlGroup {
                divider
                fieldRow(kind == .picker ? "Options" : "Items", text: $items[idx].optionsText, mono: true)
                if kind == .controlGroup {
                    row {
                        Text("Title:symbol pairs (Copy:doc.on.doc) render captioned tiles — the medium element size. Bare symbols give the compact icon row.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                divider
                row { Toggle("Palette Style", isOn: $items[idx].palette) }
            }
            if kind == .action {
                divider
                row { Toggle("Destructive Role", isOn: $items[idx].destructive) }
            }
            if kind == .action || kind == .toggle {
                divider
                row { Toggle("Disabled", isOn: $items[idx].disabled) }
            }
            divider
            row {
                HStack(spacing: 18) {
                    Button {
                        move(idx, by: -1)
                    } label: {
                        Image(systemName: "arrow.up")
                    }
                    .disabled(idx == 0)
                    Button {
                        move(idx, by: 1)
                    } label: {
                        Image(systemName: "arrow.down")
                    }
                    .disabled(idx == items.count - 1)
                    Spacer()
                    Button(role: .destructive) {
                        selectedID = nil
                        items.remove(at: idx)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var presetsCard: some View {
        card {
            row {
                HStack(spacing: 10) {
                    Button {
                        showSaveAlert = true
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    Spacer()
                    Button("Editing") { load(MenuStudioView.editingStarter) }
                    Button("Playback") { load(MenuStudioView.playbackStarter) }
                }
                .font(.subheadline)
            }
            ForEach(store.presets) { preset in
                divider
                row {
                    HStack {
                        Button {
                            setup = preset.setup
                            load(preset.items)
                        } label: {
                            Text(preset.name).foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            store.delete(preset)
                        } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    private var caption: some View {
        Text("Every item type iOS menus support, minus nested submenus: buttons with roles and two-line subtitles, toggles, inline and palette pickers, control groups (captioned tiles with Title:symbol items, icon rows with bare symbols, or palette), share links, dividers, and titled sections. Menu-level dials cover `menuIndicator`, `menuOrder(.fixed/.priority)`, `menuActionDismissBehavior(.disabled)` (toggles keep the menu open), and the `primaryAction` split button. The clipboard button in the nav bar copies the composed menu as paste-ready SwiftUI.")
            .font(.footnote).foregroundStyle(.secondary)
            .padding(.horizontal, 4).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Mutations

    private func addItem(_ kind: MenuItemKind) {
        var item = MenuItemSpec(kind: kind)
        switch kind {
        case .action: item.title = "Action"; item.symbol = "star"
        case .toggle: item.title = "Enabled"; item.symbol = "checkmark.circle"
        case .picker: item.title = "Size"; item.optionsText = "Small, Medium, Large"
        case .controlGroup: item.title = "Clipboard"; item.optionsText = "Copy:doc.on.doc, Cut:scissors, Paste:doc.on.clipboard"
        case .share: item.title = "Share"; item.symbol = "square.and.arrow.up"
        case .divider: item.title = ""
        case .section: item.title = "Section"
        }
        items.append(item)
        selectedID = item.id
    }

    private func move(_ idx: Int, by offset: Int) {
        let target = idx + offset
        guard items.indices.contains(target) else { return }
        items.swapAt(idx, target)
    }

    private func load(_ newItems: [MenuItemSpec]) {
        selectedID = nil
        items = newItems
    }

    // MARK: - Starters

    static var editingStarter: [MenuItemSpec] {
        [
            MenuItemSpec(kind: .controlGroup, title: "Clipboard",
                         optionsText: "Copy:doc.on.doc, Cut:scissors, Paste:doc.on.clipboard"),
            MenuItemSpec(kind: .action, title: "Rename", subtitle: "Change the file name", symbol: "pencil"),
            MenuItemSpec(kind: .action, title: "Duplicate", symbol: "plus.square.on.square"),
            MenuItemSpec(kind: .share, title: "Share", symbol: "square.and.arrow.up"),
            MenuItemSpec(kind: .section, title: "Danger Zone"),
            MenuItemSpec(kind: .action, title: "Delete", symbol: "trash", destructive: true),
        ]
    }

    static var playbackStarter: [MenuItemSpec] {
        [
            MenuItemSpec(kind: .toggle, title: "Shuffle", symbol: "shuffle"),
            MenuItemSpec(kind: .toggle, title: "Repeat", symbol: "repeat", isOn: false),
            MenuItemSpec(kind: .divider),
            MenuItemSpec(kind: .picker, title: "Speed", optionsText: "0.5×, 1×, 1.5×, 2×", selection: 1),
            MenuItemSpec(kind: .section, title: "Quality"),
            MenuItemSpec(kind: .picker, title: "Resolution", optionsText: "Auto, 720p, 1080p, 4K"),
        ]
    }

    // MARK: - Code generation

    private func generatedCode() -> String {
        var lines: [String] = []
        func item(_ spec: MenuItemSpec, indent: String) {
            switch spec.kind {
            case .action:
                let role = spec.destructive ? "role: .destructive" : ""
                lines.append("\(indent)Button(\(role)) {")
                lines.append("\(indent)    // \(spec.title)")
                lines.append("\(indent)} label: {")
                if spec.subtitle.isEmpty {
                    lines.append("\(indent)    Label(\"\(spec.title)\", systemImage: \"\(spec.symbol)\")")
                } else {
                    lines.append("\(indent)    Text(\"\(spec.title)\")")
                    lines.append("\(indent)    Text(\"\(spec.subtitle)\")")
                    lines.append("\(indent)    Image(systemName: \"\(spec.symbol)\")")
                }
                lines.append("\(indent)}\(spec.disabled ? ".disabled(true)" : "")")
            case .toggle:
                lines.append("\(indent)Toggle(isOn: $\(camel(spec.title))) {")
                lines.append("\(indent)    Label(\"\(spec.title)\", systemImage: \"\(spec.symbol)\")")
                lines.append("\(indent)}")
            case .picker:
                lines.append("\(indent)Picker(\"\(spec.title)\", selection: $\(camel(spec.title))) {")
                for opt in spec.options {
                    if spec.palette {
                        lines.append("\(indent)    Image(systemName: \"\(opt)\")")
                    } else {
                        lines.append("\(indent)    Text(\"\(opt)\")")
                    }
                }
                lines.append("\(indent)}\(spec.palette ? ".pickerStyle(.palette)" : "")")
            case .controlGroup:
                lines.append("\(indent)ControlGroup {")
                for opt in spec.options {
                    let parts = opt.split(separator: ":", maxSplits: 1)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        lines.append("\(indent)    Button { } label: { Label(\"\(parts[0])\", systemImage: \"\(parts[1])\") }")
                    } else {
                        lines.append("\(indent)    Button { } label: { Image(systemName: \"\(opt)\") }")
                    }
                }
                lines.append("\(indent)}\(spec.palette ? ".controlGroupStyle(.palette)" : "")")
            case .share:
                lines.append("\(indent)ShareLink(item: url) {")
                lines.append("\(indent)    Label(\"\(spec.title)\", systemImage: \"\(spec.symbol)\")")
                lines.append("\(indent)}")
            case .divider:
                lines.append("\(indent)Divider()")
            case .section:
                break
            }
        }

        lines.append("Menu {")
        for group in grouped {
            if let header = group.header {
                lines.append("    Section(\"\(header)\") {")
                for i in group.indices { item(items[i], indent: "        ") }
                lines.append("    }")
            } else {
                for i in group.indices { item(items[i], indent: "    ") }
            }
        }
        lines.append("} label: {")
        lines.append("    Label(\"\(setup.menuTitle)\", systemImage: \"\(setup.menuSymbol)\")")
        if setup.primaryAction {
            lines.append("} primaryAction: {")
            lines.append("    // primary action")
        }
        lines.append("}")
        lines.append(".menuOrder(.\(setup.fixedOrder ? "fixed" : "priority"))")
        lines.append(".menuActionDismissBehavior(.\(setup.keepPresented ? "disabled" : "automatic"))")
        lines.append(".menuIndicator(.\(setup.indicator ? "visible" : "hidden"))")
        return lines.joined(separator: "\n")
    }

    private func camel(_ s: String) -> String {
        let parts = s.split(separator: " ")
        guard let first = parts.first else { return "value" }
        let head = first.lowercased()
        let tail = parts.dropFirst().map { $0.capitalized }.joined()
        return head + tail
    }

    // MARK: - Row helpers

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func fieldRow(_ label: String, text: Binding<String>, mono: Bool = false) -> some View {
        row {
            HStack {
                Text(label).frame(width: 110, alignment: .leading)
                TextField(label, text: text)
                    .font(mono ? .mono(.subheadline) : .subheadline)
                    .multilineTextAlignment(.trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View { Divider().padding(.leading, 16) }
}

#Preview {
    NavigationStack { MenuStudioView() }
        .environmentObject(PinsStore())
}
