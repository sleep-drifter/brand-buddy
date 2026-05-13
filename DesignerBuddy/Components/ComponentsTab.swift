import SwiftUI

struct ComponentEntry: Identifiable {
    let id = UUID()
    let name: String
    let section: String

    static let all: [ComponentEntry] = [
        .init(name: "Color",                 section: "Visual"),
        .init(name: "Typography",            section: "Visual"),
        .init(name: "Spacing & Grid",        section: "Primitives"),
        .init(name: "Layout Primitives",     section: "Primitives"),
        .init(name: "Buttons",               section: "Actions"),
        .init(name: "Menus & Context Menus", section: "Actions"),
        .init(name: "Text Fields",           section: "Inputs"),
        .init(name: "Toggles & Switches",    section: "Inputs"),
        .init(name: "Sliders",               section: "Inputs"),
        .init(name: "Steppers",              section: "Inputs"),
        .init(name: "Pickers",               section: "Selection"),
        .init(name: "Segmented Controls",    section: "Selection"),
        .init(name: "Date & Time Pickers",   section: "Selection"),
        .init(name: "Color Picker",          section: "Selection"),
        .init(name: "Labels & Text",         section: "Display"),
        .init(name: "Images & Icons",        section: "Display"),
        .init(name: "Progress Indicators",   section: "Display"),
        .init(name: "Gauges",                section: "Display"),
        .init(name: "Badges",                section: "Display"),
        .init(name: "Tags",                  section: "Display"),
        .init(name: "Lists & Tables",        section: "Layout"),
        .init(name: "Scroll Views",          section: "Layout"),
        .init(name: "Grids",                 section: "Layout"),
        .init(name: "Grouped Forms",         section: "Layout"),
        .init(name: "Cards",                 section: "Layout"),
        .init(name: "Navigation Bars",       section: "Navigation"),
        .init(name: "Tab Bars",              section: "Navigation"),
        .init(name: "Toolbars",              section: "Navigation"),
        .init(name: "Search",                section: "Navigation"),
        .init(name: "Sheets & Modals",       section: "Overlays"),
        .init(name: "Alerts & Dialogs",      section: "Overlays"),
        .init(name: "Action Sheets",         section: "Overlays"),
        .init(name: "Popovers",              section: "Overlays"),
        .init(name: "Toasts & Banners",      section: "Overlays"),
    ]
}

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
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentsTab()
}
