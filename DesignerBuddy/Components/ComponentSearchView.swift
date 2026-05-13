import SwiftUI

struct ComponentSearchView: View {
    @State private var searchText = ""

    var results: [AppEntry] {
        guard !searchText.isEmpty else { return [] }
        return AppEntry.all.filter {
            fuzzyMatch(searchText, in: $0.name) ||
            fuzzyMatch(searchText, in: $0.section) ||
            fuzzyMatch(searchText, in: $0.tab)
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
                            NavigationLink(destination: appDestination(for: entry)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.name)
                                        Text(entry.section)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.tab)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.quaternary, in: Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Components, patterns, materials…")
        }
    }

    var allSections: some View {
        List {
            ForEach(["Components", "Patterns", "Materials", "More"], id: \.self) { tab in
                let entries = AppEntry.all.filter { $0.tab == tab }
                Section(tab) {
                    ForEach(entries) { entry in
                        NavigationLink(destination: appDestination(for: entry)) {
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
func appDestination(for entry: AppEntry) -> some View {
    switch entry.name {
    // Components
    case "Color":                  ColorReferenceView()
    case "Typography":             TypographyReferenceView()
    case "Spacing & Grid":         SpacingView()
    case "Layout Primitives":      LayoutPrimitivesView()
    case "Buttons":                ButtonsView()
    case "Menus & Context Menus":  MenusView()
    case "Text Fields":            TextFieldsView()
    case "Toggles & Switches":     TogglesView()
    case "Sliders":                SlidersView()
    case "Steppers":               SteppersView()
    case "Pickers":                PickersView()
    case "Segmented Controls":     SegmentedControlsView()
    case "Date & Time Pickers":    DateTimePickersView()
    case "Color Picker":           ColorPickerView()
    case "Labels & Text":          LabelsView()
    case "Images & Icons":         ImagesView()
    case "Progress Indicators":    ProgressIndicatorsView()
    case "Gauges":                 GaugesView()
    case "Badges":                 BadgesView()
    case "Tags":                   TagsView()
    case "Lists & Tables":         ListsView()
    case "Scroll Views":           ScrollViewsView()
    case "Grids":                  GridsView()
    case "Grouped Forms":          GroupedFormsView()
    case "Cards":                  CardsView()
    case "Navigation Bars":        NavigationBarsView()
    case "Tab Bars":               TabBarsView()
    case "Toolbars":               ToolbarsView()
    case "Search":                 SearchComponentView()
    case "Sheets & Modals":        SheetsModalsView()
    case "Alerts & Dialogs":       AlertsView()
    case "Action Sheets":          ActionSheetsView()
    case "Popovers":               PopoversView()
    case "Toasts & Banners":       ToastsView()
    // Patterns
    case "Navigation Patterns":    NavigationPatternsView()
    case "Tab Bar Patterns":       TabPatternView()
    case "Modal Patterns":         ModalPatternsView()
    case "Sheet Flows":            SheetFlowsView()
    case "Search Patterns":        SearchPatternView()
    case "Form Patterns":          FormPatternView()
    case "Empty States":           EmptyStatesView()
    case "Loading States":         LoadingStatesView()
    case "Error States":           ErrorStatesView()
    case "Settings Patterns":      SettingsPatternView()
    case "Onboarding Flows":       OnboardingView()
    // Materials
    case "iOS 26 Glass":           GlassEffectPlayground()
    case "Material (blur)":        GlassPlayground()
    case "Surfaces":               SurfacesPlayground()
    case "Vibrancy":               VibrancyPlayground()
    // More
    case "Spring Physics":         SpringPhysicsView()
    case "Haptics":                HapticsView()
    case "Corner Radius":          CornerRadiusView()
    case "Concentric Radius":      ConcentricRadiusView()
    case "Shadow Explorer":        ShadowExplorerView()
    case "Blur Stack":             BlurStackView()
    case "Safe Areas":             SafeAreasView()
    case "Dynamic Type Scale":     DynamicTypeScaleView()
    default:                       SheetDetentsView()
    }
}

// Keep old name working
func componentDestination(for entry: AppEntry) -> some View {
    appDestination(for: entry)
}

#Preview {
    ComponentSearchView()
}
