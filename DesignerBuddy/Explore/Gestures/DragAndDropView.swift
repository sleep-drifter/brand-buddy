import SwiftUI

// Drag & Drop — the Transferable-based APIs: .draggable sources,
// .dropDestination targets, drop-target highlighting, moving items between
// containers, and reordering inside one. The Gestures pages cover raw drag
// gestures; this page covers *payloads*.
//
// Hosted in a ScrollView, not a List: List's underlying collection view owns
// drag interactions for its rows, so .draggable views inside rows lift the
// entire row as the drag preview and drops land unreliably.

struct DragAndDropView: View {

    // Drop targets
    private enum HighlightStyle: String, CaseIterable {
        case dashed = "Dashed", fill = "Fill", scale = "Scale"
    }
    @State private var highlightStyle: HighlightStyle = .dashed
    @State private var droppedChips: [String] = []
    @State private var zoneTargeted = false

    // Board transfer
    @State private var todo = ["Wireframes", "Icon pass", "Empty states"]
    @State private var done = ["Kickoff deck"]
    @State private var todoTargeted = false
    @State private var doneTargeted = false

    // Grid reorder
    private struct Tile: Identifiable, Equatable {
        let id: String
        let color: Color
    }
    @State private var tiles: [Tile] = [
        Tile(id: "T1", color: .blue),   Tile(id: "T2", color: .orange),
        Tile(id: "T3", color: .green),  Tile(id: "T4", color: .purple),
        Tile(id: "T5", color: .pink),   Tile(id: "T6", color: .teal),
        Tile(id: "T7", color: .indigo), Tile(id: "T8", color: .mint),
    ]

    private let chips = ["Blue", "Mint", "Coral", "Lilac"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("**.draggable** turns any view into a drag source carrying a *Transferable* payload; **.dropDestination** turns any view into a target. Strings, images, and URLs work out of the box — custom types conform via `Transferable`.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                // ── Drop targets ───────────────────────────────────────────
                demoCard(title: "Drop Targets", tag: "isTargeted") {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(chipColor(chip).opacity(0.18), in: Capsule())
                                .foregroundStyle(chipColor(chip))
                                .draggable(chip)
                        }
                    }

                    dropZone
                        .dropDestination(for: String.self) { items, _ in
                            withAnimation(.snappy) { droppedChips.append(contentsOf: items) }
                            return true
                        } isTargeted: { targeting in
                            withAnimation(.easeOut(duration: 0.15)) { zoneTargeted = targeting }
                        }

                    Picker("Highlight", selection: $highlightStyle) {
                        ForEach(HighlightStyle.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    if !droppedChips.isEmpty {
                        Button("Clear drop zone") {
                            withAnimation(.snappy) { droppedChips.removeAll() }
                        }
                        .font(.subheadline)
                    }
                    RefCaption(".draggable(payload) · .dropDestination(for:) { } isTargeted: { }")
                    HIGNoteRow("The target must announce itself the moment a drag hovers over it — `isTargeted` is that signal. Whatever the treatment, it should read as \"let go here\" before the finger lifts.")
                }

                // ── Transfer between containers ────────────────────────────
                demoCard(title: "Transfer Between Lists", tag: "Board") {
                    HStack(alignment: .top, spacing: 12) {
                        boardColumn(title: "To do", items: todo, tint: .orange,
                                    targeted: todoTargeted)
                            .dropDestination(for: String.self) { items, _ in
                                moveTasks(items, toDone: false)
                                return true
                            } isTargeted: { todoTargeted = $0 }
                        boardColumn(title: "Done", items: done, tint: .green,
                                    targeted: doneTargeted)
                            .dropDestination(for: String.self) { items, _ in
                                moveTasks(items, toDone: true)
                                return true
                            } isTargeted: { doneTargeted = $0 }
                    }

                    RefCaption("drag a card across columns — the payload is the task name")
                    HIGNoteRow("A *transfer* changes which container owns the item; the source visibly loses it and the destination gains it. Keep the drag preview recognizable — the row itself, not a generic ghost.")
                }

                // ── Reorder in place ───────────────────────────────────────
                demoCard(title: "Reorder a Grid", tag: "In place") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10),
                                             count: 4),
                              spacing: 10) {
                        ForEach(tiles) { tile in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(tile.color.gradient)
                                .frame(height: 64)
                                .overlay {
                                    Text(tile.id)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                                .draggable(tile.id)
                                .dropDestination(for: String.self) { items, _ in
                                    reorder(draggedID: items.first, onto: tile)
                                } isTargeted: { _ in }
                        }
                    }

                    RefCaption("every cell is both .draggable and a .dropDestination")
                    HIGNoteRow("A *reorder* keeps items in one container and changes position — animate the make-room shuffle so the final order is never a surprise. Lists get this free with `onMove`; grids wire it manually like this.")
                }

                // ── Guidance ───────────────────────────────────────────────
                demoCard(title: "HIG guidance") {
                    DoDontRow(good: true,  text: "Offer a non-drag path to the same result (a context menu, a move button) — drag is fast, not discoverable.")
                    DoDontRow(good: true,  text: "Accept drops leniently: trim, de-duplicate, and coerce payloads rather than rejecting near-misses.")
                    DoDontRow(good: false, text: "Don't rely on hover-only affordances from the Mac — on iPhone the drag itself is the first feedback moment.")
                    DoDontRow(good: false, text: "Don't start drags from controls that also scroll or swipe without testing the gesture collision.")
                }

                // ── Code ───────────────────────────────────────────────────
                demoCard(title: "Code") {
                    CodeBlockRow(code: """
                        Text(task.name)
                            .draggable(task.name)

                        column
                            .dropDestination(for: String.self) { items, location in
                                move(items, to: column)
                                return true
                            } isTargeted: { isHovering in
                                highlighted = isHovering
                            }
                        """)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Drag & Drop")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Card chrome

    private func demoCard<Content: View>(
        title: String, tag: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTagHeader(title: title, tag: tag)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        VStack(spacing: 8) {
            if droppedChips.isEmpty {
                Image(systemName: "square.on.square.dashed")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("Drop chips here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(droppedChips.joined(separator: " · "))
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(zoneFill, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    zoneTargeted ? Color.blue : Color.secondary.opacity(0.4),
                    style: StrokeStyle(
                        lineWidth: zoneTargeted ? 2 : 1,
                        dash: highlightStyle == .dashed ? [6, 4] : []))
        }
        .scaleEffect(highlightStyle == .scale && zoneTargeted ? 1.03 : 1)
    }

    private var zoneFill: Color {
        highlightStyle == .fill && zoneTargeted
            ? Color.blue.opacity(0.12)
            : Color(.tertiarySystemGroupedBackground)
    }

    private func chipColor(_ chip: String) -> Color {
        switch chip {
        case "Blue":  return .blue
        case "Mint":  return .mint
        case "Coral": return .orange
        default:      return .purple
        }
    }

    // MARK: - Board

    private func boardColumn(title: String, items: [String], tint: Color,
                             targeted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground),
                                in: RoundedRectangle(cornerRadius: 8))
                    .draggable(item)
            }
            if items.isEmpty {
                Text("Empty")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            targeted ? tint.opacity(0.12) : Color(.tertiarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(targeted ? tint : .clear, lineWidth: 2)
        }
        .animation(.easeOut(duration: 0.15), value: targeted)
    }

    private func moveTasks(_ items: [String], toDone: Bool) {
        withAnimation(.snappy) {
            for item in items {
                todo.removeAll { $0 == item }
                done.removeAll { $0 == item }
                if toDone { done.append(item) } else { todo.append(item) }
            }
        }
    }

    // MARK: - Grid reorder

    private func reorder(draggedID: String?, onto target: Tile) -> Bool {
        guard let draggedID,
              let from = tiles.firstIndex(where: { $0.id == draggedID }),
              let to = tiles.firstIndex(of: target),
              from != to else { return false }
        withAnimation(.snappy) {
            tiles.move(fromOffsets: IndexSet(integer: from),
                       toOffset: to > from ? to + 1 : to)
        }
        return true
    }
}

#Preview {
    NavigationStack { DragAndDropView() }
}
