import SwiftUI

struct ComponentEntry: Identifiable {
    let id = UUID()
    let name: String
    let section: String

    static let all: [ComponentEntry] = [
        // Visual
        .init(name: "Color",                 section: "Visual"),
        .init(name: "Typography",            section: "Visual"),
        // Primitives
        .init(name: "Spacing & Grid",        section: "Primitives"),
        .init(name: "Layout Primitives",     section: "Primitives"),
        // Actions
        .init(name: "Buttons",               section: "Actions"),
        .init(name: "Menus & Context Menus", section: "Actions"),
        // Inputs
        .init(name: "Text Fields",           section: "Inputs"),
        .init(name: "Toggles & Switches",    section: "Inputs"),
        .init(name: "Sliders",               section: "Inputs"),
        .init(name: "Steppers",              section: "Inputs"),
        // Selection
        .init(name: "Pickers",               section: "Selection"),
        .init(name: "Segmented Controls",    section: "Selection"),
        .init(name: "Date & Time Pickers",   section: "Selection"),
        .init(name: "Color Picker",          section: "Selection"),
        // Display
        .init(name: "Labels & Text",         section: "Display"),
        .init(name: "Images & Icons",        section: "Display"),
        .init(name: "Progress Indicators",   section: "Display"),
        .init(name: "Gauges",                section: "Display"),
        .init(name: "Badges",                section: "Display"),
        .init(name: "Tags",                  section: "Display"),
        // Layout
        .init(name: "Lists & Tables",        section: "Layout"),
        .init(name: "Scroll Views",          section: "Layout"),
        .init(name: "Grids",                 section: "Layout"),
        .init(name: "Grouped Forms",         section: "Layout"),
        .init(name: "Cards",                 section: "Layout"),
        // Navigation
        .init(name: "Navigation Bars",       section: "Navigation"),
        .init(name: "Tab Bars",              section: "Navigation"),
        .init(name: "Toolbars",              section: "Navigation"),
        .init(name: "Search",                section: "Navigation"),
        // Overlays
        .init(name: "Sheets & Modals",       section: "Overlays"),
        .init(name: "Alerts & Dialogs",      section: "Overlays"),
        .init(name: "Action Sheets",         section: "Overlays"),
        .init(name: "Popovers",              section: "Overlays"),
        .init(name: "Toasts & Banners",      section: "Overlays"),
    ]
}

// Fuzzy match: all characters in query must appear in order in target
private func fuzzyMatch(_ query: String, in target: String) -> Bool {
    guard !query.isEmpty else { return true }
    let q = query.lowercased()
    let t = target.lowercased()
    var qi = q.startIndex
    for ch in t {
        if qi == q.endIndex { break }
        if ch == q[qi] { qi = q.index(after: qi) }
    }
    return qi == q.endIndex
}

struct ComponentsTab: View {
    @State private var searchText = ""

    var searchResults: [ComponentEntry] {
        ComponentEntry.all.filter {
            fuzzyMatch(searchText, in: $0.name) ||
            fuzzyMatch(searchText, in: $0.section)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Visual") {
                        NavigationLink("Color") { ColorReferenceView() }
                        NavigationLink("Typography") { TypographyReferenceView() }
                    }
                    Section("Primitives") {
                        NavigationLink("Spacing & Grid") { SpacingView() }
                        NavigationLink("Layout Primitives") { LayoutPrimitivesView() }
                    }
                    Section("Actions") {
                        NavigationLink("Buttons") { ButtonsView() }
                        NavigationLink("Menus & Context Menus") { MenusView() }
                    }
                    Section("Inputs") {
                        NavigationLink("Text Fields") { TextFieldsView() }
                        NavigationLink("Toggles & Switches") { TogglesView() }
                        NavigationLink("Sliders") { SlidersView() }
                        NavigationLink("Steppers") { SteppersView() }
                    }
                    Section("Selection") {
                        NavigationLink("Pickers") { PickersView() }
                        NavigationLink("Segmented Controls") { SegmentedControlsView() }
                        NavigationLink("Date & Time Pickers") { DateTimePickersView() }
                        NavigationLink("Color Picker") { ColorPickerView() }
                    }
                    Section("Display") {
                        NavigationLink("Labels & Text") { LabelsView() }
                        NavigationLink("Images & Icons") { ImagesView() }
                        NavigationLink("Progress Indicators") { ProgressIndicatorsView() }
                        NavigationLink("Gauges") { GaugesView() }
                        NavigationLink("Badges") { BadgesView() }
                        NavigationLink("Tags") { TagsView() }
                    }
                    Section("Layout") {
                        NavigationLink("Lists & Tables") { ListsView() }
                        NavigationLink("Scroll Views") { ScrollViewsView() }
                        NavigationLink("Grids") { GridsView() }
                        NavigationLink("Grouped Forms") { GroupedFormsView() }
                        NavigationLink("Cards") { CardsView() }
                    }
                    Section("Navigation") {
                        NavigationLink("Navigation Bars") { NavigationBarsView() }
                        NavigationLink("Tab Bars") { TabBarsView() }
                        NavigationLink("Toolbars") { ToolbarsView() }
                        NavigationLink("Search") { SearchComponentView() }
                    }
                    Section("Overlays") {
                        NavigationLink("Sheets & Modals") { SheetsModalsView() }
                        NavigationLink("Alerts & Dialogs") { AlertsView() }
                        NavigationLink("Action Sheets") { ActionSheetsView() }
                        NavigationLink("Popovers") { PopoversView() }
                        NavigationLink("Toasts & Banners") { ToastsView() }
                    }
                } else {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ForEach(searchResults) { entry in
                            NavigationLink(destination: destination(for: entry)) {
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
            .searchable(text: $searchText, prompt: "Search components")
            .navigationTitle("Components")
        }
    }

    @ViewBuilder
    func destination(for entry: ComponentEntry) -> some View {
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
}

#Preview {
    ComponentsTab()
}
