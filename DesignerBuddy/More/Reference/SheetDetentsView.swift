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
                    Text("At **.medium** detent, dragging up on the scroll content expands the sheet first. Once at **.large**, scrolling takes over.")
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
                    Text("Detent: \(selectedDetent == .medium ? ".medium" : ".large")")
                        .font(.mono(.caption))
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
    let token: String
    let description: String
    let example: String?

    static let all: [DetentReferenceItem] = [
        DetentReferenceItem(token: ".medium", description: "Approximately 50% of screen height. Ideal for quick tasks and peeking at content beneath.", example: "Quick actions, share sheets"),
        DetentReferenceItem(token: ".large", description: "Full available height (below safe area top). Default when no detent is specified.", example: "Full forms, detail views"),
        DetentReferenceItem(token: ".fraction(0.0...1.0)", description: "Percentage of available height. 0.4 = 40% of screen.", example: ".fraction(0.35) for a mini sheet"),
        DetentReferenceItem(token: ".height(points)", description: "Fixed point height measured from the bottom.", example: ".height(400) for a fixed map preview"),
        DetentReferenceItem(token: "Custom (PresentationDetent.custom)", description: "Height derived from a type conforming to CustomPresentationDetent. Reacts to environment changes.", example: "Content-sized sheet that adapts to text"),
    ]
}

struct SheetModifierItem: Identifiable {
    let id = UUID()
    let modifier: String
    let description: String

    static let all: [SheetModifierItem] = [
        SheetModifierItem(modifier: ".presentationDetents([.medium, .large])", description: "Define which detents the sheet can snap to."),
        SheetModifierItem(modifier: ".presentationDetents([...], selection: $detent)", description: "Bind current detent to observe or control programmatically."),
        SheetModifierItem(modifier: ".presentationDragIndicator(.visible)", description: "Show the grab bar at the top of the sheet."),
        SheetModifierItem(modifier: ".presentationBackgroundInteraction(.enabled)", description: "Allow tapping/scrolling content behind the sheet."),
        SheetModifierItem(modifier: ".presentationCornerRadius(24)", description: "Override the sheet's corner radius."),
        SheetModifierItem(modifier: ".presentationBackground(.regularMaterial)", description: "Apply a material background to the sheet."),
        SheetModifierItem(modifier: ".interactiveDismissDisabled()", description: "Prevent swipe-to-dismiss — requires explicit button."),
    ]
}

#Preview {
    NavigationStack {
        SheetsModalsView()
    }
}
