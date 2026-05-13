import SwiftUI

struct ComponentSearchView: View {
    @State private var searchText = ""

    var results: [ComponentEntry] {
        guard !searchText.isEmpty else { return [] }
        return ComponentEntry.all.filter {
            fuzzyMatch(searchText, in: $0.name) ||
            fuzzyMatch(searchText, in: $0.section)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    allSections
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(results) { entry in
                            NavigationLink(destination: componentDestination(for: entry)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                    Text(entry.section)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Components, patterns, primitives…")
        }
    }

    var allSections: some View {
        List {
            ForEach(sectionOrder, id: \.self) { section in
                let entries = ComponentEntry.all.filter { $0.section == section }
                Section(section) {
                    ForEach(entries) { entry in
                        NavigationLink(destination: componentDestination(for: entry)) {
                            Text(entry.name)
                        }
                    }
                }
            }
        }
    }

    var sectionOrder: [String] {
        var seen = Set<String>()
        return ComponentEntry.all.compactMap { entry in
            seen.insert(entry.section).inserted ? entry.section : nil
        }
    }
}

// Fuzzy match: all query chars must appear in order in target
private func fuzzyMatch(_ query: String, in target: String) -> Bool {
    guard !query.isEmpty else { return true }
    let q = query.lowercased(), t = target.lowercased()
    var qi = q.startIndex
    for ch in t {
        if qi == q.endIndex { break }
        if ch == q[qi] { qi = q.index(after: qi) }
    }
    return qi == q.endIndex
}

@ViewBuilder
func componentDestination(for entry: ComponentEntry) -> some View {
    switch entry.name {
    case "Color":                 ColorReferenceView()
    case "Typography":            TypographyReferenceView()
    case "Spacing & Grid":        SpacingView()
    case "Layout Primitives":     LayoutPrimitivesView()
    case "Buttons":               ButtonsView()
    case "Menus & Context Menus": MenusView()
    case "Text Fields":           TextFieldsView()
    case "Toggles & Switches":    TogglesView()
    case "Sliders":               SlidersView()
    case "Steppers":              SteppersView()
    case "Pickers":               PickersView()
    case "Segmented Controls":    SegmentedControlsView()
    case "Date & Time Pickers":   DateTimePickersView()
    case "Color Picker":          ColorPickerView()
    case "Labels & Text":         LabelsView()
    case "Images & Icons":        ImagesView()
    case "Progress Indicators":   ProgressIndicatorsView()
    case "Gauges":                GaugesView()
    case "Badges":                BadgesView()
    case "Tags":                  TagsView()
    case "Lists & Tables":        ListsView()
    case "Scroll Views":          ScrollViewsView()
    case "Grids":                 GridsView()
    case "Grouped Forms":         GroupedFormsView()
    case "Cards":                 CardsView()
    case "Navigation Bars":       NavigationBarsView()
    case "Tab Bars":              TabBarsView()
    case "Toolbars":              ToolbarsView()
    case "Search":                SearchComponentView()
    case "Sheets & Modals":       SheetsModalsView()
    case "Alerts & Dialogs":      AlertsView()
    case "Action Sheets":         ActionSheetsView()
    case "Popovers":              PopoversView()
    default:                      ToastsView()
    }
}

#Preview {
    ComponentSearchView()
}
