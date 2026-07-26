import SwiftUI

// iOS 27 reorderable containers: drag-to-rearrange in any container, not just
// List. The ForEach opts in with .reorderable(); the parent declares the
// interaction scope with .reorderContainer(for:), whose closure receives a
// ReorderDifference describing which IDs moved and where to insert them.

private struct ReorderChip: Identifiable, Equatable {
    let id: Int
    let symbol: String
    let color: Color
}

private let chipSet: [ReorderChip] = [
    .init(id: 0, symbol: "bolt.fill",       color: .orange),
    .init(id: 1, symbol: "heart.fill",      color: .pink),
    .init(id: 2, symbol: "star.fill",       color: .yellow),
    .init(id: 3, symbol: "bell.fill",       color: .indigo),
    .init(id: 4, symbol: "paperplane.fill", color: .teal),
    .init(id: 5, symbol: "moon.fill",       color: .purple),
    .init(id: 6, symbol: "leaf.fill",       color: .green),
    .init(id: 7, symbol: "flame.fill",      color: .red),
]

struct ReorderContainersView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case grid = "Grid", rail = "Rail", stack = "Stack"
        var id: String { rawValue }
    }

    @State private var chips = chipSet
    @State private var mode: Mode = .grid
    @State private var lastMove = "Drag a chip to rearrange."

    var body: some View {
        List {
            Section {
                Picker("Container", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Try it") {
                demo
                    .reorderContainer(for: Int.self) { difference in
                        var before: Int?
                        if case .before(let id) = difference.destination.position {
                            before = id
                        }
                        applyMove(sources: Array(difference.sources), before: before)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Section("Last ReorderDifference") {
                Text(lastMove)
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("How it works") {
                Text("The same `ForEach` + `.reorderable()` powers all three containers — `LazyVGrid`, a horizontal rail, and a plain `VStack`. Before iOS 27 this took `onDrag`/`onDrop` plumbing or a `List` in edit mode.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("`.reorderContainer(for: Int.self)` scopes the interaction and hands you a `ReorderDifference`: `sources` holds the moved IDs, `destination.position` is `.before(id)` or the end of the collection. You apply it to your data however you like — an array here, but equally a view model or server-backed order.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Reordering also reached watchOS this year, and the same code runs across List, grids, stacks, and custom Layout types.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reorder Containers")
    }

    @ViewBuilder
    private var demo: some View {
        switch mode {
        case .grid:
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                reorderableChips
            }
        case .rail:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    reorderableChips
                }
                .padding(.vertical, 2)
            }
        case .stack:
            VStack(spacing: 8) {
                reorderableRows
            }
        }
    }

    private var reorderableChips: some View {
        ForEach(chips) { chip in
            chipFace(chip)
                .frame(width: 52, height: 52)
                .background(chip.color.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .reorderable()
    }

    private var reorderableRows: some View {
        ForEach(chips) { chip in
            HStack(spacing: 12) {
                chipFace(chip)
                    .frame(width: 34, height: 34)
                    .background(chip.color.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(chip.symbol)
                    .font(.mono(.caption))
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .reorderable()
    }

    private func chipFace(_ chip: ReorderChip) -> some View {
        Image(systemName: chip.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
    }

    private func applyMove(sources: [Int], before: Int?) {
        withAnimation(.snappy) {
            let moving = chips.filter { sources.contains($0.id) }
            chips.removeAll { sources.contains($0.id) }
            let index = before.flatMap { id in chips.firstIndex { $0.id == id } } ?? chips.endIndex
            chips.insert(contentsOf: moving, at: index)
        }
        let destination = before.map { "before id \($0)" } ?? "end"
        lastMove = "sources: \(sources) → \(destination)"
    }
}

#Preview {
    NavigationStack { ReorderContainersView() }
        .environmentObject(PinsStore())
}
