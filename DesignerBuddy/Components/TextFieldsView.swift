import SwiftUI

struct TextFieldsView: View {
    @State private var text1 = ""
    @State private var text2 = "Prefilled value"
    @State private var text3 = ""
    @State private var secureText = ""
    @State private var multilineText = ""
    @FocusState private var focused: Field?

    enum Field: Hashable { case plain, rounded, secure }

    var body: some View {
        List {
            Section("Plain Style (default)") {
                TextField("Placeholder text", text: $text1)
                    .focused($focused, equals: .plain)
                TextField("With prefilled value", text: $text2)
            }

            Section("Rounded Border") {
                TextField("Placeholder", text: $text3)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused, equals: .rounded)
            }

            Section("Secure") {
                SecureField("Password", text: $secureText)
                    .focused($focused, equals: .secure)
                SecureField("Password (rounded)", text: $secureText)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Multiline") {
                TextEditor(text: $multilineText)
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

            Section("With Icons") {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $text1)
                }
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    TextField("Email address", text: $text1)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !text1.isEmpty {
                        Button {
                            text1 = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Keyboard Types") {
                ForEach(KeyboardTypeItem.all) { item in
                    HStack {
                        TextField(item.name, text: .constant(""))
                            .keyboardType(item.type)
                        Spacer()
                        Text(item.token)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Text Fields")
        .navigationBarTitleDisplayMode(.large)
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
