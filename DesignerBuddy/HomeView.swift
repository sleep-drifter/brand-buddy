import SwiftUI

enum SectionDest: Hashable {
    case elements, patternsAndSystem, playgrounds, shaders
}

struct HomeView: View {
    @EnvironmentObject var pinsStore: PinsStore
    @State private var showSaved = false
    @State private var showProfile = false
    @State private var searchText = ""

    private var searchResults: [AppEntry] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return AppEntry.all.filter {
            fuzzyMatch(q, in: $0.nameLower) ||
            fuzzyMatch(q, in: $0.sectionLower) ||
            (!$0.keywordsLower.isEmpty && $0.keywordsLower.contains(q))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            HomeSectionRow(
                                title: "Elements",
                                entries: AppEntry.elements,
                                dest: SectionDest.elements
                            )
                            HomeSectionRow(
                                title: "Patterns & System",
                                entries: AppEntry.patternsAndSystem,
                                dest: SectionDest.patternsAndSystem
                            )
                            HomeSectionRow(
                                title: "Shaders",
                                entries: AppEntry.shaders,
                                dest: SectionDest.shaders
                            )
                            HomeSectionRow(
                                title: "Playgrounds",
                                entries: AppEntry.playgrounds,
                                dest: SectionDest.playgrounds
                            )
                            HomeFullCatalogSection(entries: AppEntry.all)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                } else if searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(searchResults) { entry in
                        NavigationLink(value: entry) {
                            Label(entry.name, systemImage: entry.icon)
                        }
                    }
                }
            }
            .navigationTitle("Designer Buddy")
            .searchable(text: $searchText, prompt: "Find something specific")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSaved = true } label: {
                        Image(systemName: "bookmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person")
                    }
                }
            }
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
            .navigationDestination(for: SectionDest.self) { dest in
                switch dest {
                case .elements:
                    CategoryListView(
                        title: "Elements",
                        entries: AppEntry.elements,
                        sectionOrder: ["Visual", "Actions", "Inputs & Forms", "Selection",
                                       "Indicators", "Layout", "Navigation", "Overlays", "Materials"]
                    )
                case .patternsAndSystem:
                    CategoryListView(
                        title: "Patterns & System",
                        entries: AppEntry.patternsAndSystem,
                        sectionOrder: ["Navigation & Flows", "Content States", "Settings & Onboarding",
                                       "Gestures", "Animations", "Accessibility",
                                       "System", "Permissions", "Media", "Maps",
                                       "AI & Generation", "Device & Sensors"]
                    )
                case .playgrounds:
                    CategoryListView(
                        title: "Playgrounds",
                        entries: AppEntry.playgrounds,
                        sectionOrder: ["Playgrounds"]
                    )
                case .shaders:
                    ShaderListView()
                }
            }
            .sheet(isPresented: $showSaved) {
                SavedView()
                    .environmentObject(pinsStore)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }
}

private func fuzzyMatch(_ query: String, in lowerTarget: String) -> Bool {
    guard !query.isEmpty else { return true }
    var qi = query.startIndex
    for ch in lowerTarget {
        if qi == query.endIndex { break }
        if ch == query[qi] { qi = query.index(after: qi) }
    }
    return qi == query.endIndex
}

// MARK: - Home Section Row

struct HomeSectionRow: View {
    @EnvironmentObject var pinsStore: PinsStore
    let title: String
    let entries: [AppEntry]
    let dest: SectionDest

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var previewEntries: [AppEntry] { Array(entries.prefix(6)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: dest) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.callout.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(previewEntries) { entry in
                    NavigationLink(value: entry) {
                        EntryGridCard(entry: entry, isPinned: pinsStore.isPinned(entry))
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            pinsStore.toggle(entry)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Entry Grid Card

struct EntryGridCard: View {
    let entry: AppEntry
    var isPinned: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Image(systemName: entry.icon)
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text(entry.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.horizontal, 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if isPinned {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .padding(6)
            }
        }
    }
}

// MARK: - Full Catalog Section (flat list of every page, no card grid)

enum CatalogSort: String, CaseIterable, Identifiable {
    case updated = "Recently Updated"
    case section = "Section"
    case alphabetical = "A to Z"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .updated: "clock"
        case .section: "list.bullet.indent"
        case .alphabetical: "textformat"
        }
    }
}

struct HomeFullCatalogSection: View {
    @EnvironmentObject var pinsStore: PinsStore
    let entries: [AppEntry]

    // Persisted so the catalog opens the way it was left.
    @AppStorage("catalogSortMode") private var sortModeRaw = CatalogSort.updated.rawValue

    private var sortMode: CatalogSort {
        CatalogSort(rawValue: sortModeRaw) ?? .updated
    }

    private var sortBinding: Binding<CatalogSort> {
        Binding(get: { sortMode }, set: { sortModeRaw = $0.rawValue })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Full catalog")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Menu {
                    Picker("Sort", selection: sortBinding) {
                        ForEach(CatalogSort.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption.weight(.semibold))
                        Text(sortMode.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 0) {
                if sortMode == .section {
                    ForEach(sectionGroups, id: \.name) { group in
                        sectionHeader(group.name)
                        rowsBlock(group.items, isLastGroup: group.name == sectionGroups.last?.name)
                    }
                } else {
                    rowsBlock(sortedEntries, isLastGroup: true)
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .animation(.snappy(duration: 0.25), value: sortModeRaw)
    }

    // MARK: - Sorting

    private var sortedEntries: [AppEntry] {
        switch sortMode {
        case .updated:
            // Newest first; entries sharing a date keep their catalog order.
            return entries.enumerated().sorted { a, b in
                if a.element.updated != b.element.updated {
                    return a.element.updated > b.element.updated
                }
                return a.offset < b.offset
            }.map(\.element)
        case .alphabetical:
            return entries.sorted { $0.nameLower < $1.nameLower }
        case .section:
            return entries
        }
    }

    /// Sections in catalog order, entries in catalog order within each.
    private var sectionGroups: [(name: String, items: [AppEntry])] {
        var order: [String] = []
        var buckets: [String: [AppEntry]] = [:]
        for entry in entries {
            if buckets[entry.section] == nil { order.append(entry.section) }
            buckets[entry.section, default: []].append(entry)
        }
        return order.map { (name: $0, items: buckets[$0] ?? []) }
    }

    // MARK: - Rows

    @ViewBuilder
    private func rowsBlock(_ items: [AppEntry], isLastGroup: Bool) -> some View {
        ForEach(items) { entry in
            row(entry)
            if entry.id != items.last?.id || !isLastGroup {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }

    private func sectionHeader(_ name: String) -> some View {
        Text(name)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func row(_ entry: AppEntry) -> some View {
        NavigationLink(value: entry) {
            HStack(spacing: 12) {
                Image(systemName: entry.icon)
                    .foregroundStyle(.primary)
                    .frame(width: 28)
                Text(entry.name)
                    .foregroundStyle(.primary)
                Spacer()
                if sortMode == .updated, entry.updated > AppEntry.baselineDate {
                    Text(shortDate(entry.updated))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if pinsStore.isPinned(entry) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                pinsStore.toggle(entry)
            } label: {
                Label(pinsStore.isPinned(entry) ? "Remove Bookmark" : "Bookmark",
                      systemImage: pinsStore.isPinned(entry) ? "bookmark.slash" : "bookmark")
            }
        }
    }

    /// "2026-07-26" → "Jul 26" without touching DateFormatter.
    private func shortDate(_ iso: String) -> String {
        let parts = iso.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]),
              (1...12).contains(month) else { return iso }
        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return "\(names[month - 1]) \(day)"
    }
}

// MARK: - Category List View (shared section detail view)

struct CategoryListView: View {
    @EnvironmentObject var pinsStore: PinsStore
    let title: String
    let entries: [AppEntry]
    let sectionOrder: [String]

    var body: some View {
        List {
            ForEach(sectionOrder, id: \.self) { section in
                let sectionEntries = entries.filter { $0.section == section }
                if !sectionEntries.isEmpty {
                    Section(section) {
                        ForEach(sectionEntries) { entry in
                            pinnableRow(entry, pinsStore: pinsStore)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
    }
}

// MARK: - Shader List View (flat — all shader pages share one catalog section)

struct ShaderListView: View {
    @EnvironmentObject var pinsStore: PinsStore

    var body: some View {
        List {
            Section {
                ForEach(AppEntry.shaders) { entry in
                    pinnableRow(entry, pinsStore: pinsStore)
                }
            } footer: {
                Text("Metal-backed effects: SwiftUI colorEffect/layerEffect shaders and the Stable Fluid compute pipeline.")
            }
        }
        .navigationTitle("Shaders")
        .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
    }
}

#Preview {
    HomeView()
        .environmentObject(PinsStore())
}
