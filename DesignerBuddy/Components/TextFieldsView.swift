import SwiftUI

private enum TextFieldStyleKind: String, CaseIterable {
    case plain = "Plain"
    case roundedBorder = "Rounded Border"
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
                    Text("Default").tag(UIKeyboardType.default)
                    Text("Email Address").tag(UIKeyboardType.emailAddress)
                    Text("Number Pad").tag(UIKeyboardType.numberPad)
                    Text("Decimal Pad").tag(UIKeyboardType.decimalPad)
                    Text("URL").tag(UIKeyboardType.URL)
                    Text("Phone Pad").tag(UIKeyboardType.phonePad)
                }
                .pickerStyle(.menu)

                Picker("Submit label", selection: $submit) {
                    ForEach(SubmitLabelKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Presets") {
                PresetChipRow(
                    chips: FieldPreset.all.map { preset in
                        PresetChip(name: preset.name, detail: preset.detail)
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
        .pinnedPreview(entry: "Text Fields") {
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
    let type: UIKeyboardType

    static let all: [KeyboardTypeItem] = [
        KeyboardTypeItem(name: "Default", type: .default),
        KeyboardTypeItem(name: "Numbers & Punctuation", type: .numbersAndPunctuation),
        KeyboardTypeItem(name: "Number Pad", type: .numberPad),
        KeyboardTypeItem(name: "Decimal Pad", type: .decimalPad),
        KeyboardTypeItem(name: "Phone Pad", type: .phonePad),
        KeyboardTypeItem(name: "Email Address", type: .emailAddress),
        KeyboardTypeItem(name: "URL", type: .URL),
        KeyboardTypeItem(name: "Twitter", type: .twitter),
        KeyboardTypeItem(name: "Web Search", type: .webSearch),
        KeyboardTypeItem(name: "ASCII Capable", type: .asciiCapable),
    ]
}

#Preview {
    NavigationStack {
        TextFieldsView()
    }
    .environmentObject(PinsStore())
}
