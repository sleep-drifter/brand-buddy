import SwiftUI

struct ModalPatternsView: View {
    @State private var showMediumSheet = false
    @State private var showLargeSheet = false
    @State private var showSwitchableSheet = false
    @State private var showFullScreen = false
    @State private var showConfirmation = false
    @State private var showAlert = false
    @State private var showFlowSheet = false

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

            Section("Modal Types — Live Demos") {
                ModalDemoRow(
                    name: "Sheet (.medium)",
                    useWhen: "Quick action or short form. Content is secondary to what's behind.",
                    buttonLabel: ".sheet + .medium",
                    action: { showMediumSheet = true }
                )
                ModalDemoRow(
                    name: "Sheet (.large)",
                    useWhen: "Multi-step flow or rich content that needs space but can be dismissed.",
                    buttonLabel: ".sheet + .large",
                    action: { showLargeSheet = true }
                )
                ModalDemoRow(
                    name: "Sheet (switchable)",
                    useWhen: "When user needs to expand for more detail — medium and large detents.",
                    buttonLabel: ".medium + .large",
                    action: { showSwitchableSheet = true }
                )
                ModalDemoRow(
                    name: "Full Screen Cover",
                    useWhen: "Onboarding, immersive flows where going back should not be trivial.",
                    buttonLabel: ".fullScreenCover",
                    action: { showFullScreen = true }
                )
                ModalDemoRow(
                    name: "Confirmation Dialog",
                    useWhen: "Destructive or irreversible actions with 2–3 choices.",
                    buttonLabel: ".confirmationDialog",
                    action: { showConfirmation = true }
                )
                ModalDemoRow(
                    name: "Alert",
                    useWhen: "Critical decisions or errors with 1–2 choices.",
                    buttonLabel: ".alert",
                    action: { showAlert = true }
                )
            }

            Section {
                Button("Show multi-step sheet flow") { showFlowSheet = true }
            } header: {
                Text("Multi-Step Sheet Flow")
            } footer: {
                Text("A guided flow presented in a single sheet — steps advance in place with a progress indicator.")
            }

            Section("Sheet Flow Rules") {
                Text("• Each step in a sheet flow should have a clear title and progress indicator if there are 3+ steps.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("• The final step should have a prominent completion action, not just 'Next'.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("• Cancel should always be available on the first step.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Modal Patterns")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showMediumSheet) {
            Text("Medium sheet content").presentationDetents([.medium])
        }
        .sheet(isPresented: $showLargeSheet) {
            Text("Large sheet content").presentationDetents([.large])
        }
        .sheet(isPresented: $showSwitchableSheet) {
            VStack {
                Text("Switchable sheet").font(.headline).padding()
                Text("Drag up to expand").foregroundStyle(.secondary)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            VStack(spacing: 24) {
                Text("Full Screen Cover").font(.title2).fontWeight(.semibold)
                Text("No swipe to dismiss.").foregroundStyle(.secondary)
                Button("Dismiss") { showFullScreen = false }
                    .buttonStyle(.borderedProminent)
            }
        }
        .confirmationDialog("Confirm Action", isPresented: $showConfirmation) {
            Button("Delete", role: .destructive) {}
            Button("Archive") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose what to do with this item.")
        }
        .alert("Alert Title", isPresented: $showAlert) {
            Button("OK") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This is an alert message with OK and Cancel.")
        }
        .sheet(isPresented: $showFlowSheet) {
            MultiStepSheetDemo()
        }
    }
}

private struct ModalDemoRow: View {
    let name: String
    let useWhen: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.subheadline).fontWeight(.semibold)
            Text(useWhen).font(.caption).foregroundStyle(.secondary)
            Button(buttonLabel, action: action)
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
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

struct MultiStepSheetDemo: View {
    @State private var step = 1
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(step), total: 3)
                    .tint(.accentColor)
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

struct FormPatternView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var agree = false
    @State private var submitted = false

    // Validation on Submit state
    @State private var name2 = ""
    @State private var email2 = ""
    @State private var agree2 = false
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var agreeError: String? = nil

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

            Section {
                Text("Validation on Submit")
                    .font(.headline)
                    .listRowBackground(Color.clear)
                    .padding(.top, 8)
            } header: {
                Text("Validation on Submit")
            }

            Section("Details") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Full name", text: $name2)
                        .textContentType(.name)
                        .onChange(of: name2) { _, _ in nameError = nil }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(nameError != nil ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                    if let err = nameError {
                        Text(err).font(.caption).foregroundStyle(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email2)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: email2) { _, _ in emailError = nil }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(emailError != nil ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                    if let err = emailError {
                        Text(err).font(.caption).foregroundStyle(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("I agree to the terms", isOn: $agree2)
                        .onChange(of: agree2) { _, _ in agreeError = nil }
                    if let err = agreeError {
                        Text(err).font(.caption).foregroundStyle(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            Section {
                Button("Submit") {
                    withAnimation {
                        nameError = name2.isEmpty ? "Name is required" : nil
                        emailError = email2.isEmpty ? "Email is required" : (email2.contains("@") ? nil : "Enter a valid email")
                        agreeError = agree2 ? nil : "You must agree to the terms"
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
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
    enum RetryState { case error, loading, success }
    @State private var retryState: RetryState = .error

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
                ZStack {
                    switch retryState {
                    case .error:
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Something went wrong")
                                .font(.headline)
                            Text("Check your connection and try again.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                withAnimation(.easeInOut(duration: 0.3)) { retryState = .loading }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeInOut(duration: 0.3)) { retryState = .success }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation(.easeInOut(duration: 0.3)) { retryState = .error }
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    case .loading:
                        VStack(spacing: 8) {
                            ProgressView()
                            Text("Retrying…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    case .success:
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                            Text("Connected")
                                .font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .padding(.vertical, 8)
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
    @State private var email = "bad-email"
    @FocusState private var emailFocused: Bool
    @State private var hasError = true

    var body: some View {
        List {
            Section("Inline Error") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .focused($emailFocused)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hasError ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                        .background(hasError ? Color.red.opacity(0.04) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        .onChange(of: emailFocused) { _, focused in
                            if !focused {
                                hasError = !email.contains("@") || email.isEmpty
                            }
                        }
                    if hasError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text("Enter a valid email address")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
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
                        .fill(.tint)
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
