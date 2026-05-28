import SwiftUI

struct ComponentSearchView: View {
    @State private var searchText = ""
    @State private var results: [AppEntry] = []

    var body: some View {
        NavigationStack {
            // Single persistent List — never torn down. Switching between the
            // all-sections browse and search results happens inside the List so
            // SwiftUI only diffs row content, not the entire view tree.
            List {
                if searchText.isEmpty {
                    ForEach(["Elements", "Patterns & System", "Playgrounds"], id: \.self) { tab in
                        Section(tab) {
                            ForEach(AppEntry.all.filter { $0.tab == tab }) { entry in
                                NavigationLink(value: entry) {
                                    Text(entry.name)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(results) { entry in
                        NavigationLink(value: entry) {
                            HStack {
                                Text(entry.name)
                                Spacer()
                                Text(entry.section)
                                    .font(.caption2)
                                    .foregroundStyle(entry.tab.chipColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(entry.tab.chipColor.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                }
            }
            // Empty-state overlay — cheaper than a third conditional branch.
            .overlay {
                if !searchText.isEmpty && results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .background(.background)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search for anything")
            .onChange(of: searchText) { _, newValue in
                guard !newValue.isEmpty else { results = []; return }
                let q = newValue.lowercased()
                results = AppEntry.all.filter {
                    fuzzyMatch(q, in: $0.nameLower) ||
                    fuzzyMatch(q, in: $0.sectionLower) ||
                    fuzzyMatch(q, in: $0.tabLower) ||
                    (!$0.keywordsLower.isEmpty && $0.keywordsLower.contains(q))
                }
            }
            .navigationDestination(for: AppEntry.self) { entry in
                appDestination(for: entry)
            }
        }
    }
}

private extension String {
    var chipColor: Color {
        switch self {
        case "Elements":          return .blue
        case "Patterns & System": return .purple
        case "Playgrounds":       return .orange
        default:                  return .secondary
        }
    }
}

// Both query and target must already be lowercased before calling.
private func fuzzyMatch(_ query: String, in lowerTarget: String) -> Bool {
    guard !query.isEmpty else { return true }
    var qi = query.startIndex
    for ch in lowerTarget {
        if qi == query.endIndex { break }
        if ch == query[qi] { qi = query.index(after: qi) }
    }
    return qi == query.endIndex
}

#Preview {
    ComponentSearchView()
}
