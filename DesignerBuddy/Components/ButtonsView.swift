import SwiftUI

private enum ButtonStyleKind: String, CaseIterable {
    case borderedProminent = "Prominent"
    case bordered = "Bordered"
    case borderless = "Borderless"
    case plain = "Plain"

    var token: String {
        switch self {
        case .borderedProminent: return ".borderedProminent"
        case .bordered: return ".bordered"
        case .borderless: return ".borderless"
        case .plain: return ".plain"
        }
    }
}

private enum ButtonLabelKind: String, CaseIterable {
    case title = "Title"
    case icon = "Icon"
    case titleAndIcon = "Title + Icon"
}

private enum ButtonRoleKind: String, CaseIterable {
    case none = "None"
    case destructive = "Destructive"
}

private struct ButtonPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var style: ButtonStyleKind = .borderedProminent
    var size: ControlSize = .regular
    var labelKind: ButtonLabelKind = .title
    var roleKind: ButtonRoleKind = .none
    var loading = false
    var fullWidth = false

    static let all: [ButtonPreset] = [
        ButtonPreset(name: "Primary action", description: "The single most important action on screen"),
        ButtonPreset(name: "Secondary", description: "Supporting actions beside a primary", style: .bordered),
        ButtonPreset(name: "Toolbar icon", description: "Compact inline and bar actions", style: .borderless, size: .small, labelKind: .icon),
        ButtonPreset(name: "Destructive", description: "Delete, remove, sign out", style: .bordered, roleKind: .destructive),
        ButtonPreset(name: "Loading", description: "Async work in flight", loading: true),
        ButtonPreset(name: "Full-width CTA", description: "Checkout, sign in, onboarding", size: .large, fullWidth: true),
    ]
}

struct ButtonsView: View {
    @State private var style: ButtonStyleKind = .borderedProminent
    @State private var size: ControlSize = .regular
    @State private var labelKind: ButtonLabelKind = .title
    @State private var roleKind: ButtonRoleKind = .none
    @State private var tint: Color = .blue
    @State private var isDisabled = false
    @State private var isLoading = false
    @State private var fullWidth = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    // Preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(.separator, lineWidth: 0.5)
                            )
                            .frame(height: 220)

                        demoButton
                            .padding(.horizontal, 32)
                    }
                    .animation(.spring(duration: 0.3), value: size)
                    .animation(.spring(duration: 0.3), value: fullWidth)
                    .animation(.spring(duration: 0.3), value: isLoading)

                    // Code output
                    Text(codeSnippet)
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Style") {
                Picker("Style", selection: $style) {
                    ForEach(ButtonStyleKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Size") {
                Picker("Size", selection: $size) {
                    ForEach([ControlSize.mini, .small, .regular, .large], id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Label") {
                Picker("Label", selection: $labelKind) {
                    ForEach(ButtonLabelKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Role", selection: $roleKind) {
                    ForEach(ButtonRoleKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Options") {
                ColorPicker("Tint", selection: $tint, supportsOpacity: false)
                Toggle("Disabled", isOn: $isDisabled)
                Toggle("Loading", isOn: $isLoading)
                Toggle("Full width", isOn: $fullWidth)
            }

            Section("Presets") {
                ForEach(ButtonPreset.all) { preset in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            style = preset.style
                            size = preset.size
                            labelKind = preset.labelKind
                            roleKind = preset.roleKind
                            isLoading = preset.loading
                            fullWidth = preset.fullWidth
                            isDisabled = false
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).font(.subheadline).foregroundStyle(.primary)
                                Text(preset.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(preset.style.token)
                                .font(.mono(.caption2)).foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("Notes") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Button · .buttonStyle · .controlSize · .tint")
                        .font(.mono(.caption)).fontWeight(.medium)
                    Text("Use one .borderedProminent button per view — it marks the primary action. .bordered suits secondary actions; .borderless and .plain work inline and in bars.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("role: .destructive turns the button red and positions it correctly in menus, confirmation dialogs, and swipe actions.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Full-width buttons need .frame(maxWidth: .infinity) inside the label — outside the style it widens the tap target but not the visible background.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Buttons")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Configured button

    @ViewBuilder
    private var demoButton: some View {
        switch style {
        case .borderedProminent: baseButton.buttonStyle(.borderedProminent)
        case .bordered:          baseButton.buttonStyle(.bordered)
        case .borderless:        baseButton.buttonStyle(.borderless)
        case .plain:             baseButton.buttonStyle(.plain)
        }
    }

    private var baseButton: some View {
        Button(role: roleKind == .destructive ? .destructive : nil) {
        } label: {
            demoLabel
                .frame(maxWidth: fullWidth ? .infinity : nil)
        }
        .controlSize(size)
        .tint(tint)
        .disabled(isDisabled)
    }

    @ViewBuilder
    private var demoLabel: some View {
        if isLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(style == .borderedProminent ? Color.white : nil)
                if labelKind != .icon {
                    Text("Loading")
                }
            }
        } else {
            switch labelKind {
            case .title:
                Label("Share", systemImage: "square.and.arrow.up")
                    .labelStyle(.titleOnly)
            case .icon:
                Label("Share", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
            case .titleAndIcon:
                Label("Share", systemImage: "square.and.arrow.up")
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private var codeSnippet: String {
        let roleArg = roleKind == .destructive ? ", role: .destructive" : ""
        var lines: [String] = []
        switch labelKind {
        case .title:
            lines.append("Button(\"Share\"\(roleArg)) { }")
        case .icon, .titleAndIcon:
            lines.append("Button(\"Share\", systemImage: \"square.and.arrow.up\"\(roleArg)) { }")
        }
        if labelKind == .icon {
            lines.append("  .labelStyle(.iconOnly)")
        }
        lines.append("  .buttonStyle(\(style.token))")
        if size != .regular {
            lines.append("  .controlSize(\(size.label))")
        }
        lines.append("  .tint(\(tint == .blue ? ".blue" : "tint"))")
        if isDisabled {
            lines.append("  .disabled(true)")
        }
        if fullWidth {
            lines.append("  .frame(maxWidth: .infinity) // inside the label")
        }
        return lines.joined(separator: "\n")
    }
}

extension ControlSize {
    var label: String {
        switch self {
        case .mini: return ".mini"
        case .small: return ".small"
        case .regular: return ".regular"
        case .large: return ".large"
        case .extraLarge: return ".extraLarge"
        @unknown default: return "unknown"
        }
    }
}

#Preview {
    NavigationStack {
        ButtonsView()
    }
}
