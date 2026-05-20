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

                Text(codeSnippet)
                    .font(.mono(.caption))
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
        "Copy items into a draft array on Edit so Cancel is always safe",
        ".onMove only fires when editMode is .active",
        "Use .confirmationAction / .cancellationAction for correct button placement",
        "Save replaces the source-of-truth; Cancel simply discards the draft",
    ]

    private let codeSnippet = """
// Enter edit mode — snapshot current order
editingItems = items
isEditing = true

// Reorder handler (fires while dragging)
.onMove { source, destination in
    editingItems.move(fromOffsets: source, toOffset: destination)
}

// Save
items = editingItems; isEditing = false

// Cancel
editingItems = []; isEditing = false
"""
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
