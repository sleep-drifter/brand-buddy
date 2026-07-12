import SwiftUI

struct AlertsView: View {
    @State private var showSimple = false
    @State private var showTwoButton = false
    @State private var showDestructive = false
    @State private var showWithTextField = false
    @State private var alertInput = ""

    // Mock alert canvas
    @State private var mockTitle = "Delete Item?"
    @State private var showMockMessage = true
    @State private var mockMessage = "This item will be permanently deleted."
    @State private var mockButtonCount = 2
    @State private var destructiveAction = true
    @State private var includeMockTextField = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        Color(.secondarySystemGroupedBackground)
                        Color.black.opacity(0.3)

                        mockAlertCard
                            .padding(20)
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .animation(.spring(duration: 0.3), value: mockButtonCount)
                    .animation(.spring(duration: 0.3), value: destructiveAction)
                    .animation(.spring(duration: 0.3), value: showMockMessage)
                    .animation(.spring(duration: 0.3), value: includeMockTextField)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Content") {
                TextField("Title", text: $mockTitle)
                Toggle("Message", isOn: $showMockMessage.animation(.spring(duration: 0.3)))
                if showMockMessage {
                    TextField("Message text", text: $mockMessage)
                }
                Toggle("Text field in alert", isOn: $includeMockTextField.animation(.spring(duration: 0.3)))
            }

            Section("Buttons") {
                Picker("Buttons", selection: $mockButtonCount) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                }
                .pickerStyle(.segmented)
                Toggle("Destructive action", isOn: $destructiveAction)
            }

            Section("Try the real thing") {
                Button("Simple (1 button)") { showSimple = true }
                Button("Two button") { showTwoButton = true }
                Button("Destructive action") { showDestructive = true }
                Button("With text field") { showWithTextField = true }
            }

            Section("Anatomy") {
                VStack(alignment: .leading, spacing: 8) {
                    AlertAnatomyRow(part: "Title", description: "Short, sentence-case. State the problem, not what to do.")
                    AlertAnatomyRow(part: "Message", description: "Optional. One or two sentences max. Explain consequences.")
                    AlertAnatomyRow(part: "Default action", description: "Right-aligned or bottom. Sentence-case label.")
                    AlertAnatomyRow(part: "Cancel", description: "Always provided when action is optional.")
                    AlertAnatomyRow(part: "Destructive", description: "Red text. Place on the left (iOS) or top (iPad).")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Alerts & Dialogs")
        .navigationBarTitleDisplayMode(.large)
        .alert("Enable Notifications?", isPresented: $showSimple) {
            Button("OK") {}
        } message: {
            Text("You can change this later in Settings.")
        }
        .alert("Save Changes?", isPresented: $showTwoButton) {
            Button("Save") {}
            Button("Don't Save", role: .cancel) {}
        } message: {
            Text("Your changes will be lost if you don't save them.")
        }
        .alert("Delete Item?", isPresented: $showDestructive) {
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be permanently deleted.")
        }
        .alert("Enter Name", isPresented: $showWithTextField) {
            TextField("Name", text: $alertInput)
            Button("Save") {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for this item.")
        }
    }

    private var mockAlertCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(mockTitle.isEmpty ? "Alert Title" : mockTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                if showMockMessage {
                    Text(mockMessage.isEmpty ? "Alert message." : mockMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                if includeMockTextField {
                    Text("Name")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(.separator, lineWidth: 0.5)
                        )
                        .padding(.top, 6)
                }
            }
            .padding(16)

            Divider()

            if mockButtonCount == 1 {
                mockAlertButton("OK", isCancel: true)
            } else if mockButtonCount == 2 {
                HStack(spacing: 0) {
                    mockAlertButton("Cancel", isCancel: true)
                    Divider()
                    mockAlertButton(destructiveAction ? "Delete" : "Save", isDestructive: destructiveAction)
                }
                .frame(height: 44)
            } else {
                VStack(spacing: 0) {
                    mockAlertButton("Save")
                    Divider()
                    mockAlertButton(destructiveAction ? "Delete" : "Don't Save", isDestructive: destructiveAction)
                    Divider()
                    mockAlertButton("Cancel", isCancel: true)
                }
            }
        }
        .frame(maxWidth: 270)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func mockAlertButton(_ label: String, isDestructive: Bool = false, isCancel: Bool = false) -> some View {
        Text(label)
            .font(.body)
            .fontWeight(isCancel ? .semibold : .regular)
            .foregroundStyle(isDestructive ? Color.red : Color.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
    }
}

struct AlertAnatomyRow: View {
    let part: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(part)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
                .frame(width: 90, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
}
