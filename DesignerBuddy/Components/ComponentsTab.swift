import SwiftUI

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let section: String
    let tab: String

    // Keep ComponentEntry as a typealias for backwards compat with ComponentSearchView
    static let all: [AppEntry] = components + patterns + materials + more

    static let components: [AppEntry] = [
        .init(name: "Color",                 section: "Visual",      tab: "Components"),
        .init(name: "Typography",            section: "Visual",      tab: "Components"),
        .init(name: "Spacing & Grid",        section: "Primitives",  tab: "Components"),
        .init(name: "Layout Primitives",     section: "Primitives",  tab: "Components"),
        .init(name: "Buttons",               section: "Actions",     tab: "Components"),
        .init(name: "Menus & Context Menus", section: "Actions",     tab: "Components"),
        .init(name: "Context Menus",         section: "Actions",     tab: "Components"),
        .init(name: "Text Fields",           section: "Inputs",      tab: "Components"),
        .init(name: "Toggles & Switches",    section: "Inputs",      tab: "Components"),
        .init(name: "Sliders",               section: "Inputs",      tab: "Components"),
        .init(name: "Steppers",              section: "Inputs",      tab: "Components"),
        .init(name: "Pickers",               section: "Selection",   tab: "Components"),
        .init(name: "Segmented Controls",    section: "Selection",   tab: "Components"),
        .init(name: "Date & Time Pickers",   section: "Selection",   tab: "Components"),
        .init(name: "Color Picker",          section: "Selection",   tab: "Components"),
        .init(name: "Labels & Text",         section: "Display",     tab: "Components"),
        .init(name: "Images & Icons",        section: "Display",     tab: "Components"),
        .init(name: "Progress Indicators",   section: "Display",     tab: "Components"),
        .init(name: "Gauges",                section: "Display",     tab: "Components"),
        .init(name: "Badges",                section: "Display",     tab: "Components"),
        .init(name: "Tags",                  section: "Display",     tab: "Components"),
        .init(name: "Lists & Tables",        section: "Layout",      tab: "Components"),
        .init(name: "Swipeable Rows",        section: "Layout",      tab: "Components"),
        .init(name: "Scroll Views",          section: "Layout",      tab: "Components"),
        .init(name: "Grids",                 section: "Layout",      tab: "Components"),
        .init(name: "Grouped Forms",         section: "Layout",      tab: "Components"),
        .init(name: "Cards",                 section: "Layout",      tab: "Components"),
        .init(name: "Navigation Bars",       section: "Navigation",  tab: "Components"),
        .init(name: "Tab Bars",              section: "Navigation",  tab: "Components"),
        .init(name: "Toolbars",              section: "Navigation",  tab: "Components"),
        .init(name: "Search",                section: "Navigation",  tab: "Components"),
        .init(name: "Sheets & Modals",       section: "Overlays",    tab: "Components"),
        .init(name: "Alerts & Dialogs",      section: "Overlays",    tab: "Components"),
        .init(name: "Action Sheets",         section: "Overlays",    tab: "Components"),
        .init(name: "Popovers",              section: "Overlays",    tab: "Components"),
        .init(name: "Toasts & Banners",      section: "Overlays",    tab: "Components"),
    ]

    static let patterns: [AppEntry] = [
        .init(name: "Navigation Patterns",   section: "Navigation",  tab: "Patterns"),
        .init(name: "Tab Bar Patterns",      section: "Navigation",  tab: "Patterns"),
        .init(name: "Modal Patterns",        section: "Presentation",tab: "Patterns"),
        .init(name: "Sheet Flows",           section: "Presentation",tab: "Patterns"),
        .init(name: "Search Patterns",       section: "Input",       tab: "Patterns"),
        .init(name: "Form Patterns",         section: "Input",       tab: "Patterns"),
        .init(name: "Empty States",          section: "Content",     tab: "Patterns"),
        .init(name: "Loading States",        section: "Content",     tab: "Patterns"),
        .init(name: "Error States",          section: "Content",     tab: "Patterns"),
        .init(name: "Settings Patterns",     section: "Settings",    tab: "Patterns"),
        .init(name: "Onboarding Flows",      section: "Onboarding",  tab: "Patterns"),
    ]

    static let materials: [AppEntry] = [
        .init(name: "iOS 26 Glass",          section: "Glass",       tab: "Materials"),
        .init(name: "Material (blur)",       section: "Glass",       tab: "Materials"),
        .init(name: "Surfaces",              section: "Surfaces",    tab: "Materials"),
        .init(name: "Vibrancy",              section: "Vibrancy",    tab: "Materials"),
    ]

    static let more: [AppEntry] = [
        .init(name: "Spring Physics",        section: "Playgrounds", tab: "More"),
        .init(name: "Haptics",               section: "Playgrounds", tab: "More"),
        .init(name: "Corner Radius",         section: "Playgrounds", tab: "More"),
        .init(name: "Concentric Radius",     section: "Playgrounds", tab: "More"),
        .init(name: "Shadow Explorer",       section: "Playgrounds", tab: "More"),
        .init(name: "Blur Stack",            section: "Playgrounds", tab: "More"),
        .init(name: "Safe Areas",            section: "Reference",   tab: "More"),
        .init(name: "Dynamic Type Scale",    section: "Reference",   tab: "More"),
        .init(name: "Sheet Detents",         section: "Reference",   tab: "More"),
    ]
}

// Keep old name working in ComponentSearchView
typealias ComponentEntry = AppEntry

struct ComponentsTab: View {
    var body: some View {
        NavigationStack {
            List {
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
                    NavigationLink("Context Menus") { ContextMenusView() }
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
                    NavigationLink("Swipeable Rows") { SwipeableRowsView() }
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
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentsTab()
}
