import SwiftUI

private enum ButtonStyleKind: String, CaseIterable {
    case borderedProminent = "Prominent"
    case bordered = "Bordered"
    case borderless = "Borderless"
    case plain = "Plain"
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
                        }
                    }
                }
            }

            Section("Notes") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use one prominent button per view — it marks the primary action. Bordered suits secondary actions; borderless and plain work inline and in bars.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("A destructive role turns the button red and positions it correctly in menus, confirmation dialogs, and swipe actions.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .pinnedPreview(entry: "Buttons") {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .frame(height: 150)

                demoButton
                    .padding(.horizontal, 32)
            }
            .animation(.spring(duration: 0.3), value: size)
            .animation(.spring(duration: 0.3), value: fullWidth)
            .animation(.spring(duration: 0.3), value: isLoading)
        }
        .navigationTitle("Buttons")
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

}

extension ControlSize {
    var label: String {
        switch self {
        case .mini: return "Mini"
        case .small: return "Small"
        case .regular: return "Regular"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        ButtonsView()
    }
    .environmentObject(PinsStore())
}
