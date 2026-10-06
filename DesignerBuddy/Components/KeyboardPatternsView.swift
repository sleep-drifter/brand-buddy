import SwiftUI

// Keyboard Patterns — the plumbing every form-heavy screen needs:
// @FocusState flows with submit labels, a keyboard accessory toolbar,
// keyboard types matched to content, and scroll-to-dismiss behavior.

struct KeyboardPatternsView: View {

    // Focus flow
    private enum Field: Hashable, CaseIterable {
        case name, email, password
    }
    @FocusState private var focus: Field?
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    // Submit labels
    private enum SubmitChoice: String, CaseIterable {
        case done = "Done", go = "Go", search = "Search",
             send = "Send", join = "Join", next = "Next"
        var label: SubmitLabel {
            switch self {
            case .done:   return .done
            case .go:     return .go
            case .search: return .search
            case .send:   return .send
            case .join:   return .join
            case .next:   return .next
            }
        }
    }
    @State private var submitChoice: SubmitChoice = .send
    @State private var submitDemoText = ""
    @State private var lastSubmitted = ""

    // Keyboard types
    private enum KeyboardChoice: String, CaseIterable {
        case standard = "Default", emailAddress = "Email", numberPad = "Numbers",
             decimalPad = "Decimal", url = "URL", phonePad = "Phone"
        var type: UIKeyboardType {
            switch self {
            case .standard:     return .default
            case .emailAddress: return .emailAddress
            case .numberPad:    return .numberPad
            case .decimalPad:   return .decimalPad
            case .url:          return .URL
            case .phonePad:     return .phonePad
            }
        }
    }
    @State private var keyboardChoice: KeyboardChoice = .emailAddress
    @State private var keyboardDemoText = ""

    // OTP
    @State private var otp = ""

    // Scroll dismissal
    @State private var interactiveDismiss = true

    var body: some View {
        List {

            // ── Overview ───────────────────────────────────────────────────
            Section {
                Text("SwiftUI scroll views already keep the focused field above the keyboard — the design work is everything else: where focus goes next, what the return key promises, and how the keyboard gets out of the way.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // ── Focus flow ─────────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Focus Flow", tag: "@FocusState")) {
                TextField("Name", text: $name)
                    .focused($focus, equals: .name)
                    .submitLabel(.next)
                    .textContentType(.name)
                    .onSubmit { focus = .email }
                TextField("Email", text: $email)
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .keyboardType(.emailAddress)
                    .textContentType(.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { focus = .password }
                SecureField("Password", text: $password)
                    .focused($focus, equals: .password)
                    .submitLabel(.done)
                    .textContentType(.newPassword)
                    .onSubmit { focus = nil }

                Button("Start at the top") { focus = .name }
                RefCaption(".focused($focus, equals:) · .onSubmit { focus = .next }")
                HIGNoteRow("Return should always *do* something — advance to the next field or finish. A form where Return just dismisses the keyboard makes people re-tap every field.")
            }

            // ── Keyboard toolbar ───────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Keyboard Toolbar", tag: "Accessory")) {
                Text("Focus any field above, then use the ‹ › arrows and **Done** in the bar riding the keyboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                RefCaption("ToolbarItemGroup(placement: .keyboard) { … }")
                HIGNoteRow("Attach the keyboard toolbar once, at the container — attaching it per-field stacks duplicate bars. Previous/Next plus Done is the whole convention; resist putting actions there.")
            }

            // ── Submit labels ──────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Submit Labels", tag: "Return key")) {
                Picker("Label", selection: $submitChoice) {
                    ForEach(SubmitChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                TextField("Try the return key", text: $submitDemoText)
                    .submitLabel(submitChoice.label)
                    .onSubmit {
                        lastSubmitted = submitDemoText
                        submitDemoText = ""
                    }
                if !lastSubmitted.isEmpty {
                    LabeledContent("Submitted", value: lastSubmitted)
                }
                RefCaption(".submitLabel(.send) + .onSubmit { … }")
                HIGNoteRow("The return key is a promise: **Search** searches, **Send** sends. Pick the verb that matches what onSubmit actually does.")
            }

            // ── Keyboard types ─────────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Keyboard Types", tag: "Input")) {
                Picker("Keyboard", selection: $keyboardChoice) {
                    ForEach(KeyboardChoice.allCases, id: \.self) { Text($0.rawValue) }
                }
                TextField("Focus to see the keyboard", text: $keyboardDemoText)
                    .keyboardType(keyboardChoice.type)
                    .id(keyboardChoice)   // retype so the keyboard actually swaps
                TextField("One-time code", text: $otp)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                RefCaption(".keyboardType(…) · .textContentType(.oneTimeCode) autofills from SMS")
                HIGNoteRow("Matching the keyboard to the content removes a mode switch per field. Number pads have no Return key, so give those fields a toolbar Done or auto-advance on length.")
            }

            // ── Scroll dismissal ───────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Dismissing", tag: "Scroll")) {
                Toggle("Interactive drag-to-dismiss", isOn: $interactiveDismiss)
                Text(interactiveDismiss
                     ? "Drag the list down over the keyboard — it follows the finger, like Messages."
                     : "Keyboard dismisses the instant scrolling starts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                RefCaption(".scrollDismissesKeyboard(.interactively / .immediately)")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "Always leave a visible way out — a Done in the toolbar, drag-to-dismiss, or tapping outside the form.")
                DoDontRow(good: true,  text: "Set textContentType everywhere it applies: it powers AutoFill for names, emails, passwords, and SMS codes.")
                DoDontRow(good: false, text: "Don't block paste or autofill in password and code fields to \"improve security\" — it does the opposite.")
                DoDontRow(good: false, text: "Don't cover the focused field with your own accessory chrome; test the bottom-most field of every form.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    enum Field { case name, email }
                    @FocusState private var focus: Field?

                    TextField("Email", text: $email)
                        .focused($focus, equals: .email)
                        .keyboardType(.emailAddress)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }

                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button { focusPrevious() } label: {
                                Image(systemName: "chevron.up")
                            }
                            Button { focusNext() } label: {
                                Image(systemName: "chevron.down")
                            }
                            Spacer()
                            Button("Done") { focus = nil }
                        }
                    }
                    """)
            }
        }
        .scrollDismissesKeyboard(interactiveDismiss ? .interactively : .immediately)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button { focusPrevious() } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(focus == nil || focus == .name)
                Button { focusNext() } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(focus == nil || focus == .password)
                Spacer()
                Button("Done") { focus = nil }
                    .fontWeight(.semibold)
            }
        }
        .navigationTitle("Keyboard Patterns")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Focus movement

    private func focusPrevious() {
        switch focus {
        case .email:    focus = .name
        case .password: focus = .email
        default:        break
        }
    }

    private func focusNext() {
        switch focus {
        case .name:  focus = .email
        case .email: focus = .password
        default:     break
        }
    }
}

#Preview {
    NavigationStack { KeyboardPatternsView() }
}
