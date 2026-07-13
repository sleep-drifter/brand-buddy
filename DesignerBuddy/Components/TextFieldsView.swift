import SwiftUI

private enum TextFieldStyleKind: String, CaseIterable {
    case plain = "Plain"
    case roundedBorder = "Rounded Border"

    var token: String {
        switch self {
        case .plain: return ".plain"
        case .roundedBorder: return ".roundedBorder"
        }
    }
}

private enum SubmitLabelKind: String, CaseIterable {
    case done, go, search, send

    var label: SubmitLabel {
        switch self {
        case .done: return .done
        case .go: return .go
        case .search: return .search
        case .send: return .send
        }
    }
}

private struct FieldPreset: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let placeholder: String
    var style: TextFieldStyleKind = .plain
    var secure = false
    var icon = false
    var keyboard: UIKeyboardType = .default
    var submit: SubmitLabelKind = .done

    static let all: [FieldPreset] = [
        FieldPreset(name: "Search", detail: "Plain field with a leading icon", placeholder: "Search", icon: true, submit: .search),
        FieldPreset(name: "Email", detail: "Email keyboard, rounded border", placeholder: "Email address", style: .roundedBorder, keyboard: .emailAddress),
        FieldPreset(name: "Password", detail: "SecureField hides input", placeholder: "Password", style: .roundedBorder, secure: true),
        FieldPreset(name: "Phone", detail: "Digits-only phone pad", placeholder: "Phone number", keyboard: .phonePad),
        FieldPreset(name: "Website", detail: "URL keyboard with Go", placeholder: "example.com", style: .roundedBorder, keyboard: .URL, submit: .go),
    ]
}

struct TextFieldsView: View {
    @State private var text = ""
    @State private var placeholder = "Email address"
    @State private var styleKind: TextFieldStyleKind = .roundedBorder
    @State private var isSecure = false
    @State private var showIcon = false
    @State private var keyboard: UIKeyboardType = .emailAddress
    @State private var submit: SubmitLabelKind = .done
    @State private var emailText = ""
    @State private var multilineText = ""
    @State private var selectedPreset: String?
    @FocusState private var focused: Field?

    enum Field: Hashable { case specimen, editor }

    var body: some View {
        List {
            Section("Code") {
                Text(codeSnippet)
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("Field") {
                Picker("Style", selection: $styleKind) {
                    ForEach(TextFieldStyleKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Secure", isOn: $isSecure)
                Toggle("Leading icon", isOn: $showIcon)
                LabeledContent("Placeholder") {
                    TextField("Placeholder", text: $placeholder)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Keyboard") {
                Picker("Keyboard type", selection: $keyboard) {
                    Text("default").tag(UIKeyboardType.default)
                    Text("emailAddress").tag(UIKeyboardType.emailAddress)
                    Text("numberPad").tag(UIKeyboardType.numberPad)
                    Text("decimalPad").tag(UIKeyboardType.decimalPad)
                    Text("URL").tag(UIKeyboardType.URL)
                    Text("phonePad").tag(UIKeyboardType.phonePad)
                }
                .pickerStyle(.menu)

                Picker("Submit label", selection: $submit) {
                    ForEach(SubmitLabelKind.allCases, id: \.self) { kind in
                        Text(".\(kind.rawValue)").tag(kind)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Presets") {
                PresetChipRow(
                    chips: FieldPreset.all.map { preset in
                        PresetChip(name: preset.name, detail: preset.detail, code: preset.style.token)
                    },
                    selectedID: $selectedPreset
                ) { chip in
                    guard let preset = FieldPreset.all.first(where: { $0.name == chip.name }) else { return }
                    withAnimation(.spring(duration: 0.3)) {
                        styleKind = preset.style
                        isSecure = preset.secure
                        showIcon = preset.icon
                        placeholder = preset.placeholder
                        keyboard = preset.keyboard
                        submit = preset.submit
                        text = ""
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    TextField("Email address", text: $emailText)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !emailText.isEmpty {
                        Button {
                            emailText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Inline Accessories")
            } footer: {
                Text("Compose accessories with an HStack — a leading icon and a trailing clear button. Disable autocorrection and capitalization for identifiers.")
            }

            Section("Multiline") {
                TextEditor(text: $multilineText)
                    .focused($focused, equals: .editor)
                    .frame(minHeight: 80)
                    .overlay(
                        Group {
                            if multilineText.isEmpty {
                                Text("Type your notes here...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            Section {
                ForEach(KeyboardTypeItem.all) { item in
                    KeyboardTypeRow(item: item)
                }
            } header: {
                Text("Keyboard Types")
            } footer: {
                Text("Tap any field to trigger that keyboard type.")
            }
        }
        .pinnedPreview {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .frame(height: 140)

                HStack(spacing: 10) {
                    if showIcon {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                    }
                    specimenField
                        .keyboardType(keyboard)
                        .submitLabel(submit.label)
                        .focused($focused, equals: .specimen)
                }
                .padding(.horizontal, 28)
                .animation(.spring(duration: 0.3), value: showIcon)
            }
        }
        .navigationTitle("Text Fields")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    focused = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
    }

    // MARK: - Configured field

    @ViewBuilder
    private var specimenField: some View {
        switch styleKind {
        case .plain:
            specimenCore.textFieldStyle(.plain)
        case .roundedBorder:
            specimenCore.textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var specimenCore: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
        } else {
            TextField(placeholder, text: $text)
        }
    }

    private var keyboardToken: String {
        switch keyboard {
        case .emailAddress: return ".emailAddress"
        case .numberPad: return ".numberPad"
        case .decimalPad: return ".decimalPad"
        case .URL: return ".URL"
        case .phonePad: return ".phonePad"
        default: return ".default"
        }
    }

    private var codeSnippet: String {
        let field = isSecure ? "SecureField" : "TextField"
        var lines = ["\(field)(\"\(placeholder)\", text: $text)"]
        lines.append("  .textFieldStyle(\(styleKind.token))")
        if keyboard != .default {
            lines.append("  .keyboardType(\(keyboardToken))")
        }
        if submit != .done {
            lines.append("  .submitLabel(.\(submit.rawValue))")
        }
        return lines.joined(separator: "\n")
    }
}

struct KeyboardTypeRow: View {
    let item: KeyboardTypeItem
    @State private var text = ""

    var body: some View {
        HStack(spacing: 10) {
            TextField("tap to type…", text: $text)
                .keyboardType(item.type)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(item.token)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .overlay(alignment: .topLeading) {
            Text(item.name)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .offset(y: -16)
        }
        .padding(.top, 12)
    }
}

struct KeyboardTypeItem: Identifiable {
    let id = UUID()
    let name: String
    let token: String
    let type: UIKeyboardType

    static let all: [KeyboardTypeItem] = [
        KeyboardTypeItem(name: "Default", token: ".default", type: .default),
        KeyboardTypeItem(name: "Numbers & Punctuation", token: ".numbersAndPunctuation", type: .numbersAndPunctuation),
        KeyboardTypeItem(name: "Number Pad", token: ".numberPad", type: .numberPad),
        KeyboardTypeItem(name: "Decimal Pad", token: ".decimalPad", type: .decimalPad),
        KeyboardTypeItem(name: "Phone Pad", token: ".phonePad", type: .phonePad),
        KeyboardTypeItem(name: "Email Address", token: ".emailAddress", type: .emailAddress),
        KeyboardTypeItem(name: "URL", token: ".URL", type: .URL),
        KeyboardTypeItem(name: "Twitter", token: ".twitter", type: .twitter),
        KeyboardTypeItem(name: "Web Search", token: ".webSearch", type: .webSearch),
        KeyboardTypeItem(name: "ASCII Capable", token: ".asciiCapable", type: .asciiCapable),
    ]
}

#Preview {
    NavigationStack {
        TextFieldsView()
    }
}
