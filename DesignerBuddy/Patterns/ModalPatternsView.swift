import SwiftUI

struct ModalPatternsView: View {
    var body: some View {
        List {
            Section("When to Use Modals") {
                ForEach(ModalUsageRule.all) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: rule.icon)
                                .foregroundStyle(rule.color)
                                .frame(width: 20)
                            Text(rule.title).font(.subheadline).fontWeight(.medium)
                        }
                        Text(rule.detail).font(.caption).foregroundStyle(.secondary)
                            .padding(.leading, 26)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Modal Types Comparison") {
                ForEach(ModalTypeItem.all) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name).font(.subheadline).fontWeight(.semibold)
                        HStack(alignment: .top, spacing: 8) {
                            Text("Use when:")
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(item.useWhen)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("Avoid when:")
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text(item.avoidWhen)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Modal Patterns")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ModalUsageRule: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let color: Color

    static let all: [ModalUsageRule] = [
        ModalUsageRule(title: "Interrupts a task", detail: "Use modals when the user must make a decision before continuing.", icon: "exclamationmark.circle", color: .orange),
        ModalUsageRule(title: "Focused sub-task", detail: "Composing a message, adding a payment method, or filling a form that lives outside the normal flow.", icon: "pencil.circle", color: .blue),
        ModalUsageRule(title: "Don't use for navigation", detail: "Modals aren't destinations. Don't replace a push with a sheet for convenience.", icon: "xmark.circle", color: .red),
        ModalUsageRule(title: "Provide a clear exit", detail: "Cancel or Done. Never trap the user. Sheets should always be dismissable.", icon: "checkmark.circle", color: .green),
    ]
}

struct ModalTypeItem: Identifiable {
    let id = UUID()
    let name: String
    let useWhen: String
    let avoidWhen: String

    static let all: [ModalTypeItem] = [
        ModalTypeItem(
            name: "Sheet (.medium detent)",
            useWhen: "Quick action, confirmation, or short form. Content is secondary to what's behind it.",
            avoidWhen: "User needs to deeply interact with the content or needs full focus."
        ),
        ModalTypeItem(
            name: "Sheet (.large detent)",
            useWhen: "Multi-step flow or rich content that needs space but can be dismissed.",
            avoidWhen: "The task is long enough to warrant its own navigation stack destination."
        ),
        ModalTypeItem(
            name: "Full Screen Cover",
            useWhen: "Onboarding, immersive experiences, or flows where going back should not be trivial.",
            avoidWhen: "The user might need to reference content behind the modal."
        ),
        ModalTypeItem(
            name: "Alert",
            useWhen: "Critical decisions, errors, or confirmations with 1–2 choices.",
            avoidWhen: "More than 2 options — use confirmationDialog instead."
        ),
    ]
}

struct SheetFlowsView: View {
    @State private var showSheet = false

    var body: some View {
        List {
            Section {
                Button("Show multi-step sheet flow") { showSheet = true }
            }
            Section("Rules") {
                Text("• Each step in a sheet flow should have a clear title and progress indicator if there are 3+ steps.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("• The final step should have a prominent completion action, not just 'Next'.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("• Cancel should always be available on the first step.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sheet Flows")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSheet) {
            MultiStepSheetDemo()
        }
    }
}

struct MultiStepSheetDemo: View {
    @State private var step = 1
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(step), total: 3)
                    .tint(.tint)
                    .padding(.horizontal)

                Spacer()

                Image(systemName: stepIcon)
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Step \(step) of 3")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(stepDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button(step < 3 ? "Continue" : "Done") {
                    if step < 3 { step += 1 } else { dismiss() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step == 1 {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") { step -= 1 }
                    }
                }
            }
        }
    }

    var stepIcon: String {
        switch step {
        case 1: return "person.circle"
        case 2: return "bell.circle"
        default: return "checkmark.circle"
        }
    }

    var stepDescription: String {
        switch step {
        case 1: return "Set up your profile so others can recognize you."
        case 2: return "Choose which notifications you'd like to receive."
        default: return "You're all set! Your preferences have been saved."
        }
    }
}

struct SearchPatternView: View {
    @State private var query = ""

    private let results = ["Buttons", "Colors", "Typography", "Materials", "Glass Effect", "Spring Physics", "Haptics", "Safe Areas"]

    var body: some View {
        List {
            if !query.isEmpty {
                Section("Results") {
                    ForEach(results.filter { $0.localizedCaseInsensitiveContains(query) }, id: \.self) {
                        Text($0)
                    }
                }
            } else {
                Section("Recent") {
                    ForEach(["Glass Effect", "Typography", "Buttons"], id: \.self) { item in
                        Label(item, systemImage: "clock")
                    }
                }
                Section("Suggested") {
                    ForEach(["Materials", "Spring Physics"], id: \.self) { item in
                        Label(item, systemImage: "sparkles")
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search Designer Buddy")
        .navigationTitle("Search Patterns")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FormPatternView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var agree = false
    @State private var submitted = false

    var canSubmit: Bool { !name.isEmpty && !email.isEmpty && agree }

    var body: some View {
        Form {
            Section("Personal Info") {
                TextField("Full name", text: $name)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            Section {
                Toggle("I agree to the terms", isOn: $agree)
            } footer: {
                Text("By continuing you accept our Terms of Service and Privacy Policy.")
            }
            Section {
                Button("Submit") { submitted = true }
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubmit)
            }
        }
        .navigationTitle("Form Patterns")
        .navigationBarTitleDisplayMode(.large)
        .alert("Submitted", isPresented: $submitted) {
            Button("OK") {}
        } message: {
            Text("Your form was submitted successfully.")
        }
    }
}

struct EmptyStatesView: View {
    var body: some View {
        List {
            Section("No Content") {
                EmptyStateExample(
                    icon: "tray",
                    title: "No Messages",
                    subtitle: "When you receive messages, they'll appear here.",
                    action: nil
                )
            }
            Section("No Search Results") {
                EmptyStateExample(
                    icon: "magnifyingglass",
                    title: "No Results",
                    subtitle: "Try a different search term or browse by category.",
                    action: "Clear Search"
                )
            }
            Section("Error State") {
                EmptyStateExample(
                    icon: "exclamationmark.triangle",
                    title: "Something went wrong",
                    subtitle: "Check your connection and try again.",
                    action: "Retry"
                )
            }
        }
        .navigationTitle("Empty States")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct EmptyStateExample: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action) {}
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct LoadingStatesView: View {
    var body: some View {
        List {
            Section("Inline spinner") {
                HStack {
                    ProgressView()
                    Text("Loading content…")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Full screen loading") {
                ZStack {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Loading…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Skeleton loading") {
                SkeletonRow()
                SkeletonRow()
                SkeletonRow()
            }
        }
        .navigationTitle("Loading States")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SkeletonRow: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.quaternary)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.quaternary)
                    .frame(width: 120, height: 12)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.quaternary)
                    .frame(width: 80, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ErrorStatesView: View {
    var body: some View {
        List {
            Section("Inline Error") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: .constant("bad-email"))
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("Enter a valid email address")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Error Banner") {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.red, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Internet Connection")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Check your connection and try again.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Error States")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct SettingsPatternView: View {
    @State private var notifications = true
    @State private var darkMode = false
    @State private var haptics = true
    @State private var units = "Metric"

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Circle()
                        .fill(.tint.gradient)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text("MW")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Matt Wujek")
                            .font(.headline)
                        Text("matt@example.com")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notifications)
                Toggle("Haptic Feedback", isOn: $haptics)
            }

            Section("Appearance") {
                Toggle("Dark Mode Override", isOn: $darkMode)
                Picker("Units", selection: $units) {
                    Text("Metric").tag("Metric")
                    Text("Imperial").tag("Imperial")
                }
            }

            Section("Support") {
                NavigationLink("Help & FAQ") { Text("Help content") }
                NavigationLink("Send Feedback") { Text("Feedback form") }
                LabeledContent("Version", value: "1.0.0 (1)")
            }

            Section {
                Button("Sign Out", role: .destructive) {}
            }
        }
        .navigationTitle("Settings Patterns")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct OnboardingView: View {
    @State private var page = 0

    private let pages: [(icon: String, title: String, description: String, color: Color)] = [
        ("paintbrush.fill", "Design Reference", "Browse every iOS HIG pattern, component, and primitive in one place.", .blue),
        ("bubbles.and.sparkles.fill", "Materials Playground", "Tune glass effects and materials in real time. See exactly how iOS 26 surfaces behave.", .purple),
        ("slider.horizontal.3", "Interactive Tools", "Spring physics, haptics, corner radii — explore the mechanics behind great iOS feel.", .orange),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                    OnboardingPage(icon: p.icon, title: p.title, description: p.description, color: p.color)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: .infinity)

            Button("Get Started") {}
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 32)
        }
        .navigationTitle("Onboarding Flows")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(color.gradient)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ModalPatternsView()
    }
}
