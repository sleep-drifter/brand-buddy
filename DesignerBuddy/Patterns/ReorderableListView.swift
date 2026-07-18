import SwiftUI

struct ReorderableListView: View {
    @State private var items: [ReorderItem] = ReorderItem.samples
    @State private var editingItems: [ReorderItem] = []
    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                Text("Tap Edit to enter reorder mode. Drag rows to rearrange. Save commits the new order; Cancel discards it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("Items") {
                ForEach(isEditing ? $editingItems : $items) { $item in
                    Label(item.title, systemImage: item.icon)
                }
                .onMove { source, destination in
                    editingItems.move(fromOffsets: source, toOffset: destination)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    ForEach(notes, id: \.self) { note in
                        Label(note, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Reorderable List")
        .navigationBarTitleDisplayMode(.large)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingItems = []
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        items = editingItems
                        editingItems = []
                        isEditing = false
                    }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        editingItems = items
                        isEditing = true
                    }
                }
            }
        }
    }

    private let notes = [
        "Edit works on a draft copy of the list, so Cancel is always safe",
        "Rows can only be dragged while edit mode is active",
        "Save and Cancel sit in the standard confirmation/cancellation slots",
        "Save replaces the real order; Cancel simply discards the draft",
    ]
}

struct ReorderItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String

    static let samples: [ReorderItem] = [
        .init(title: "Notifications",  icon: "bell"),
        .init(title: "Appearance",     icon: "paintbrush"),
        .init(title: "Privacy",        icon: "lock.shield"),
        .init(title: "Accessibility",  icon: "accessibility"),
        .init(title: "Sounds",         icon: "speaker.wave.2"),
        .init(title: "Storage",        icon: "internaldrive"),
        .init(title: "Battery",        icon: "battery.100"),
        .init(title: "Developer",      icon: "hammer"),
    ]
}

#Preview {
    NavigationStack {
        ReorderableListView()
    }
}
