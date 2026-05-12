import SwiftUI

struct ComponentsTab: View {
    var body: some View {
        NavigationStack {
            List {
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
