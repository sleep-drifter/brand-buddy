import SwiftUI

// Lazy stacks demo: the point of LazyVStack/LazyHStack is that children are
// materialized on demand as they scroll into range, instead of all at once.
// The counters here make that visible — each row reports in via onAppear, so
// you can watch the eager stack claim all 400 rows instantly while the lazy
// one only pays for what you've scrolled past.

struct LazyStacksView: View {
    private enum StackMode: String, CaseIterable, Identifiable {
        case lazy = "LazyVStack", eager = "VStack"
        var id: String { rawValue }
    }

    private let rowCount = 400
    private let cardCount = 200

    @State private var mode: StackMode = .lazy
    @State private var appearedRows = Set<Int>()
    @State private var appearedCards = Set<Int>()

    var body: some View {
        List {
            Section {
                Text("Lazy stacks materialize children on demand as they approach the viewport; plain stacks build everything up front. Every row below reports in via `onAppear`, so the counter shows exactly how many views exist so far.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Materialization — \(rowCount) rows") {
                Picker("Mode", selection: $mode) {
                    ForEach(StackMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                counterRow(appeared: appearedRows.count, total: rowCount,
                           maxIndex: appearedRows.max())

                verticalDemo
                    .frame(height: 260)

                Text(mode == .lazy
                     ? "Scroll the panel — the counter climbs as rows materialize, staying just ahead of what's visible."
                     : "All \(rowCount) rows were built the moment this mode appeared — the counter maxed out before you scrolled at all.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("LazyHStack — \(cardCount) cards") {
                counterRow(appeared: appearedCards.count, total: cardCount,
                           maxIndex: appearedCards.max())

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(0..<cardCount, id: \.self) { i in
                            card(i)
                                .onAppear { appearedCards.insert(i) }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text("Same behavior on the horizontal axis — the rail only builds the cards you've flung past.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Pinned section headers") {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(0..<4, id: \.self) { s in
                            SwiftUI.Section {
                                ForEach(0..<8, id: \.self) { r in
                                    pinnedRow(section: s, row: r)
                                }
                            } header: {
                                pinnedHeader(s)
                            }
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("`pinnedViews: [.sectionHeaders]` is exclusive to lazy stacks and grids — headers stick to the top edge until the next one pushes them off, without any GeometryReader bookkeeping.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("When to use which") {
                VStack(alignment: .leading, spacing: 10) {
                    usage("Lazy", "Long or unbounded content — feeds, search results, logs. Creation cost scales with what's seen, not what exists.")
                    usage("Eager", "Small fixed sets, or when siblings must size against each other (equal heights, alignment guides). Lazy children can't measure each other.")
                    usage("List", "Unlike List, lazy stacks never recycle views — memory grows with the high-water mark. List also gives you separators, swipe actions, and editing for free.")
                    usage("onAppear", "In a lazy stack, `onAppear` fires as items materialize — which is exactly why it works as a load-more pagination trigger.")
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Lazy Stacks")
        .onChange(of: mode) {
            appearedRows.removeAll()
        }
    }

    // MARK: - Vertical demo

    @ViewBuilder
    private var verticalDemo: some View {
        ScrollView {
            if mode == .lazy {
                LazyVStack(spacing: 4) {
                    rows
                }
            } else {
                VStack(spacing: 4) {
                    rows
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var rows: some View {
        ForEach(0..<rowCount, id: \.self) { i in
            row(i)
                .onAppear { appearedRows.insert(i) }
        }
    }

    private func row(_ i: Int) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hue(for: i))
                .frame(width: 22, height: 22)
            Text("Row \(i)")
                .font(.mono(.caption))
            Spacer()
            Text(appearedRows.contains(i) ? "materialized" : "")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func card(_ i: Int) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(hue(for: i))
                .frame(width: 56, height: 40)
            Text("\(i)")
                .font(.mono(.caption2))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Pinned demo pieces

    private func pinnedHeader(_ s: Int) -> some View {
        HStack {
            Text("Section \(s + 1)")
                .font(.caption.weight(.semibold))
            Spacer()
            Image(systemName: "pin.fill")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    private func pinnedRow(section s: Int, row r: Int) -> some View {
        HStack {
            Circle()
                .fill(hue(for: s * 8 + r * 3))
                .frame(width: 18, height: 18)
            Text("Item \(s + 1).\(r + 1)")
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Helpers

    private func counterRow(appeared: Int, total: Int, maxIndex: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(appeared) of \(total) materialized")
                    .font(.mono(.caption))
                Spacer()
                Text(maxIndex.map { "max index \($0)" } ?? "none yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(.tint)
                        .frame(width: geo.size.width * CGFloat(appeared) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 6)
            .animation(.snappy(duration: 0.2), value: appeared)
        }
        .padding(.vertical, 2)
    }

    private func hue(for i: Int) -> Color {
        Color(hue: Double(i % 36) / 36.0, saturation: 0.55, brightness: 0.9)
    }

    private func usage(_ token: String, _ note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(token).font(.mono(.caption)).foregroundStyle(.primary)
            Text(note).font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack { LazyStacksView() }
        .environmentObject(PinsStore())
}
