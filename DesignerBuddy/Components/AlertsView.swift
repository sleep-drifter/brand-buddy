import SwiftUI

struct AlertsView: View {
    @State private var showSimple = false
    @State private var showTwoButton = false
    @State private var showDestructive = false
    @State private var showWithTextField = false
    @State private var alertInput = ""

    var body: some View {
        List {
            Section("Alert Types") {
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
