import SwiftUI

// Detent demos and reference data — surfaced through Sheets & Modals.

struct SheetDetentsDemo: View {
    @Binding var selectedDetent: PresentationDetent
    let availableDetents: Set<PresentationDetent>
    let showDragIndicator: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "rectangle.bottomhalf.inset.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Interactive Sheet")
                    .font(.title2).fontWeight(.semibold)
                Text("Drag to snap between detents. The current detent is reflected below.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
                Spacer()
                Text("Background content is dimmed and interactive.\nSwipe down or tap Done to dismiss.")
                    .font(.caption).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .presentationDetents(availableDetents, selection: $selectedDetent)
            .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScrollingSheetDemo: View {
    let showDragIndicator: Bool
    @Environment(\.dismiss) var dismiss
    @State private var selectedDetent: PresentationDetent = .medium

    private let items = (1...40).map { "Row \($0) — scrollable content inside a sheet" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("At the **medium** detent, dragging up on the scroll content expands the sheet first. Once at **large**, scrolling takes over.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("How it works")
                }

                Section("Content") {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.tint.opacity(0.12))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text("\(items.firstIndex(of: item)! + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.tint)
                                )
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Scrolling Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Text("Detent: \(selectedDetent == .medium ? "Medium" : "Large")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(showDragIndicator ? .visible : .hidden)
    }
}

struct DetentReferenceItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let example: String?

    static let all: [DetentReferenceItem] = [
        DetentReferenceItem(name: "Medium", description: "Approximately 50% of screen height. Ideal for quick tasks and peeking at content beneath.", example: "Quick actions, share sheets"),
        DetentReferenceItem(name: "Large", description: "Full available height (below safe area top). The default when nothing else is specified.", example: "Full forms, detail views"),
        DetentReferenceItem(name: "Fraction", description: "Percentage of available height. 40% = a bit under half the screen.", example: "35% for a mini sheet"),
        DetentReferenceItem(name: "Fixed height", description: "Fixed point height measured from the bottom.", example: "400pt for a fixed map preview"),
        DetentReferenceItem(name: "Custom", description: "Height derived from custom rules — can adapt to content or environment changes.", example: "Content-sized sheet that adapts to text"),
    ]
}

struct SheetModifierItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String

    static let all: [SheetModifierItem] = [
        SheetModifierItem(name: "Snap detents", description: "Define which detents the sheet can snap to."),
        SheetModifierItem(name: "Drag indicator", description: "Show the grab bar at the top of the sheet."),
        SheetModifierItem(name: "Background interaction", description: "Allow tapping/scrolling content behind the sheet."),
        SheetModifierItem(name: "Corner radius", description: "Override the sheet's corner radius."),
        SheetModifierItem(name: "Background material", description: "Apply a material background to the sheet."),
        SheetModifierItem(name: "Dismiss lock", description: "Prevent swipe-to-dismiss — requires an explicit button."),
    ]
}

#Preview {
    NavigationStack {
        SheetsModalsView()
    }
}
