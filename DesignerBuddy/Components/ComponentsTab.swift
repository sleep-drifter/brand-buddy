import SwiftUI

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let section: String
    let tab: String

    // Keep ComponentEntry as a typealias for backwards compat with ComponentSearchView
    static let all: [AppEntry] = components + materials + patterns + native + more + exploreA

    static let components: [AppEntry] = [
        .init(name: "Color",                 section: "Visual",      tab: "Components"),
        .init(name: "Typography",            section: "Visual",      tab: "Components"),
        .init(name: "Spacing & Layout",      section: "Visual",      tab: "Components"),
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
        .init(name: "iOS 26 Glass",          section: "Glass",       tab: "Components"),
        .init(name: "Material (blur)",       section: "Glass",       tab: "Components"),
        .init(name: "Surfaces",              section: "Surfaces",    tab: "Components"),
        .init(name: "Vibrancy",              section: "Vibrancy",    tab: "Components"),
    ]

    static let native: [AppEntry] = [
        .init(name: "Permission Requests",        section: "Permissions",   tab: "Native"),
        .init(name: "Permission Denied Recovery", section: "Permissions",   tab: "Native"),
        .init(name: "Push Notifications",         section: "Permissions",   tab: "Native"),
        .init(name: "Camera Viewfinder",          section: "Camera",        tab: "Native"),
        .init(name: "Capture UI Patterns",        section: "Camera",        tab: "Native"),
        .init(name: "Photo Picker",               section: "Photo Library", tab: "Native"),
        .init(name: "Photo Library Patterns",     section: "Photo Library", tab: "Native"),
        .init(name: "Audio Recording",            section: "Audio",         tab: "Native"),
        .init(name: "Waveform Visualization",     section: "Audio",         tab: "Native"),
        .init(name: "Playback UI Patterns",       section: "Audio",         tab: "Native"),
        .init(name: "Map Basics",                 section: "Maps",          tab: "Native"),
        .init(name: "Map Annotations",            section: "Maps",          tab: "Native"),
        .init(name: "Map Overlays",               section: "Maps",          tab: "Native"),
    ]

    static let more: [AppEntry] = [
        .init(name: "Spring Physics",        section: "Playgrounds", tab: "More"),
        .init(name: "Haptics",               section: "Playgrounds", tab: "More"),
        .init(name: "Corner Radius",         section: "Playgrounds", tab: "More"),
        .init(name: "Concentric Radius",     section: "Playgrounds", tab: "More"),
        .init(name: "Shadow Explorer",       section: "Playgrounds", tab: "More"),
        .init(name: "Blur Stack",            section: "Playgrounds", tab: "More"),
        .init(name: "Safe Areas",            section: "Reference",   tab: "More"),
        .init(name: "Sheet Detents",         section: "Reference",   tab: "More"),
    ]

    static let exploreA: [AppEntry] = [
        .init(name: "Tap & Long Press",    section: "Gestures",      tab: "Explore"),
        .init(name: "Swipe & Drag",        section: "Gestures",      tab: "Explore"),
        .init(name: "Pinch & Zoom",        section: "Gestures",      tab: "Explore"),
        .init(name: "Rotation",            section: "Gestures",      tab: "Explore"),
        .init(name: "Transitions",         section: "Animations",    tab: "Explore"),
        .init(name: "Keyframe Animations", section: "Animations",    tab: "Explore"),
        .init(name: "Phase Animations",    section: "Animations",    tab: "Explore"),
        .init(name: "Symbol Effects",      section: "Animations",    tab: "Explore"),
        .init(name: "Matched Geometry",    section: "Animations",    tab: "Explore"),
        .init(name: "VoiceOver Labels",    section: "Accessibility", tab: "Explore"),
        .init(name: "Dynamic Type",        section: "Accessibility", tab: "Explore"),
        .init(name: "Reduce Motion",       section: "Accessibility", tab: "Explore"),
        .init(name: "High Contrast",       section: "Accessibility", tab: "Explore"),
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
                    NavigationLink("Spacing & Layout") { SpacingView() }
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
