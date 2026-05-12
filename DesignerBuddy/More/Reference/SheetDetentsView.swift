import SwiftUI

struct SheetDetentsView: View {
    @State private var showSheet = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var availableDetents: Set<PresentationDetent> = [.medium, .large]
    @State private var showDragIndicator = true
    @State private var customFraction: Double = 0.4
    @State private var customHeight: Double = 300

    private let presetDetents: [(name: String, detent: PresentationDetent)] = [
        ("medium", .medium),
        ("large", .large),
    ]

    var body: some View {
        List {
            Section("Live Demo") {
                Button("Show Interactive Sheet") { showSheet = true }
                Toggle("Show drag indicator", isOn: $showDragIndicator)
            }

            Section("Active Detents") {
                Toggle(".medium", isOn: Binding(
                    get: { availableDetents.contains(.medium) },
                    set: { if $0 { availableDetents.insert(.medium) } else { availableDetents.remove(.medium) } }
                ))
                Toggle(".large", isOn: Binding(
                    get: { availableDetents.contains(.large) },
                    set: { if $0 { availableDetents.insert(.large) } else { availableDetents.remove(.large) } }
                ))
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(".fraction(\(customFraction, specifier: "%.2f"))", isOn: Binding(
                        get: { availableDetents.contains(.fraction(customFraction)) },
                        set: { if $0 { availableDetents.insert(.fraction(customFraction)) } else { availableDetents.remove(.fraction(customFraction)) } }
                    ))
                    Slider(value: $customFraction, in: 0.1...0.9)
                        .padding(.leading, 4)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(".height(\(Int(customHeight)))", isOn: Binding(
                        get: { availableDetents.contains(.height(customHeight)) },
                        set: { if $0 { availableDetents.insert(.height(customHeight)) } else { availableDetents.remove(.height(customHeight)) } }
                    ))
                    Slider(value: $customHeight, in: 100...700)
                        .padding(.leading, 4)
                }
            }

            Section("Detent Reference") {
                ForEach(DetentReferenceItem.all) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.token)
                            .font(.mono(.subheadline))
                            .fontWeight(.medium)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let example = item.example {
                            Text("e.g. \(example)")
                                .font(.caption)
                                .foregroundStyle(.tint)
                                .italic()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Sheet Modifiers") {
                ForEach(SheetModifierItem.all) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.modifier)
                            .font(.mono(.caption))
                            .foregroundStyle(.tint)
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Sheet Detents")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSheet) {
            SheetDetentsDemo(
                selectedDetent: $selectedDetent,
                availableDetents: availableDetents.isEmpty ? [.large] : availableDetents,
                showDragIndicator: showDragIndicator
            )
        }
    }
}

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
        SheetDetentsView()
    }
}
