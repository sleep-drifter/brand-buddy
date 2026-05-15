import SwiftUI

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let section: String
    let tab: String
    // Pre-lowercased so fuzzyMatch never calls lowercased() at search time.
    // ICU Unicode tables are also warmed during AppEntry.all initialization.
    let nameLower: String
    let sectionLower: String
    let tabLower: String
    let keywordsLower: String

    init(name: String, section: String, tab: String, keywords: [String] = []) {
        self.name = name
        self.section = section
        self.tab = tab
        self.nameLower = name.lowercased()
        self.sectionLower = section.lowercased()
        self.tabLower = tab.lowercased()
        self.keywordsLower = keywords.joined(separator: " ").lowercased()
    }

    // Keep ComponentEntry as a typealias for backwards compat with ComponentSearchView
    static let all: [AppEntry] = components + materials + patterns + native + more + exploreD

    static let components: [AppEntry] = [
        .init(name: "Color",                 section: "Visual",      tab: "Components", keywords: ["colour", "palette", "dark mode", "light mode", "semantic", "tint"]),
        .init(name: "Typography",            section: "Visual",      tab: "Components", keywords: ["dynamic type", "font size", "accessibility", "text scale", "a11y", "fonts", "type styles", "font weight"]),
        .init(name: "Spacing & Layout",      section: "Visual",      tab: "Components", keywords: ["margin", "padding", "grid", "layout", "inset", "frame", "alignment"]),
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

    static let native: [AppEntry] = [
        .init(name: "Permission Requests",        section: "Permissions",   tab: "Native", keywords: ["auth", "authorization", "camera", "microphone", "photos", "location", "contacts", "privacy"]),
        .init(name: "Permission Denied Recovery", section: "Permissions",   tab: "Native", keywords: ["denied", "settings", "privacy", "blocked", "restricted"]),
        .init(name: "Push Notifications",         section: "Permissions",   tab: "Native", keywords: ["push", "notifications", "alerts", "badge", "UNUserNotificationCenter"]),
        .init(name: "Camera Viewfinder",          section: "Camera",        tab: "Native", keywords: ["camera", "capture", "AVFoundation", "preview", "viewfinder"]),
        .init(name: "Capture UI Patterns",        section: "Camera",        tab: "Native", keywords: ["shutter", "camera", "capture", "chrome", "flip"]),
        .init(name: "Photo Picker",               section: "Photo Library", tab: "Native", keywords: ["photos", "picker", "PHPicker", "library", "gallery", "PhotosPicker"]),
        .init(name: "Photo Library Patterns",     section: "Photo Library", tab: "Native", keywords: ["avatar", "crop", "thumbnail", "gallery", "photos"]),
        .init(name: "Audio Recording",            section: "Audio",         tab: "Native", keywords: ["record", "microphone", "AVAudioRecorder", "waveform", "playback"]),
        .init(name: "Waveform Visualization",     section: "Audio",         tab: "Native", keywords: ["waveform", "audio", "canvas", "animation", "visualizer"]),
        .init(name: "Playback UI Patterns",       section: "Audio",         tab: "Native", keywords: ["player", "playback", "mini player", "music", "audio"]),
        .init(name: "Map Basics",                 section: "Maps",          tab: "Native", keywords: ["map", "MapKit", "location", "region", "satellite"]),
        .init(name: "Map Annotations",            section: "Maps",          tab: "Native", keywords: ["pin", "marker", "annotation", "map", "MapKit"]),
        .init(name: "Map Overlays",               section: "Maps",          tab: "Native", keywords: ["polyline", "circle", "overlay", "route", "map"]),
    ]

    static let more: [AppEntry] = [
        .init(name: "Spring Physics",        section: "Playgrounds", tab: "More", keywords: ["animation", "bounce", "easing", "motion", "damping", "stiffness"]),
        .init(name: "Haptics",               section: "Playgrounds", tab: "More", keywords: ["vibration", "feedback", "taptic", "impact", "selection"]),
        .init(name: "Corner Radius",         section: "Playgrounds", tab: "More", keywords: ["rounded", "border radius", "roundrectangle"]),
        .init(name: "Concentric Radius",     section: "Playgrounds", tab: "More"),
        .init(name: "Shadow Explorer",       section: "Playgrounds", tab: "More"),
        .init(name: "Blur Stack",            section: "Playgrounds", tab: "More"),
        .init(name: "Safe Areas",            section: "Reference",   tab: "More", keywords: ["insets", "home indicator", "notch", "status bar"]),
        .init(name: "Sheet Detents",         section: "Reference",   tab: "More"),
    ]

    static let exploreD: [AppEntry] = [
        .init(name: "Custom Haptics",            section: "Device & Sensors", tab: "Explore", keywords: ["haptics", "CHHapticEngine", "taptic", "vibration", "pattern", "transient", "continuous"]),
        .init(name: "Accelerometer & Gyroscope", section: "Device & Sensors", tab: "Explore", keywords: ["accelerometer", "gyroscope", "CMMotionManager", "CoreMotion", "tilt", "motion"]),
        .init(name: "Barometer",                 section: "Device & Sensors", tab: "Explore", keywords: ["barometer", "CMAltimeter", "altitude", "pressure", "sensor"]),
        .init(name: "Proximity & Ambient Light", section: "Device & Sensors", tab: "Explore", keywords: ["proximity", "ambient light", "brightness", "UIScreen", "sensor"]),
        .init(name: "Battery State",             section: "Device & Sensors", tab: "Explore", keywords: ["battery", "batteryLevel", "batteryState", "low power mode", "UIDevice"]),
    ]
}

// Keep old name working in ComponentSearchView
typealias ComponentEntry = AppEntry

struct ComponentsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Visual") {
                    NavigationLink { ColorReferenceView() } label: {
                        Label("Color", systemImage: "paintpalette")
                    }
                    NavigationLink { TypographyReferenceView() } label: {
                        Label("Typography", systemImage: "textformat")
                    }
                    NavigationLink { SpacingView() } label: {
                        Label("Spacing & Layout", systemImage: "ruler")
                    }
                }
                Section("Actions") {
                    NavigationLink { ButtonsView() } label: {
                        Label("Buttons", systemImage: "hand.tap")
                    }
                    NavigationLink { MenusView() } label: {
                        Label("Menus & Context Menus", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink { ContextMenusView() } label: {
                        Label("Context Menus", systemImage: "contextualmenu.and.cursorarrow")
                    }
                }
                Section("Inputs") {
                    NavigationLink { TextFieldsView() } label: {
                        Label("Text Fields", systemImage: "character.cursor.ibeam")
                    }
                    NavigationLink { TogglesView() } label: {
                        Label("Toggles & Switches", systemImage: "switch.2")
                    }
                    NavigationLink { SlidersView() } label: {
                        Label("Sliders", systemImage: "slider.horizontal.3")
                    }
                    NavigationLink { SteppersView() } label: {
                        Label("Steppers", systemImage: "plus.forwardslash.minus")
                    }
                }
                Section("Selection") {
                    NavigationLink { PickersView() } label: {
                        Label("Pickers", systemImage: "checklist")
                    }
                    NavigationLink { SegmentedControlsView() } label: {
                        Label("Segmented Controls", systemImage: "rectangle.split.3x1")
                    }
                    NavigationLink { DateTimePickersView() } label: {
                        Label("Date & Time Pickers", systemImage: "calendar")
                    }
                    NavigationLink { ColorPickerView() } label: {
                        Label("Color Picker", systemImage: "eyedropper")
                    }
                }
                Section("Display") {
                    NavigationLink { LabelsView() } label: {
                        Label("Labels & Text", systemImage: "text.alignleft")
                    }
                    NavigationLink { ImagesView() } label: {
                        Label("Images & Icons", systemImage: "photo")
                    }
                    NavigationLink { ProgressIndicatorsView() } label: {
                        Label("Progress Indicators", systemImage: "progress.indicator")
                    }
                    NavigationLink { GaugesView() } label: {
                        Label("Gauges", systemImage: "gauge.with.needle")
                    }
                    NavigationLink { BadgesView() } label: {
                        Label("Badges", systemImage: "bell.badge")
                    }
                    NavigationLink { TagsView() } label: {
                        Label("Tags", systemImage: "tag")
                    }
                }
                Section("Layout") {
                    NavigationLink { ListsView() } label: {
                        Label("Lists & Tables", systemImage: "list.bullet")
                    }
                    NavigationLink { SwipeableRowsView() } label: {
                        Label("Swipeable Rows", systemImage: "arrow.left.arrow.right")
                    }
                    NavigationLink { ScrollViewsView() } label: {
                        Label("Scroll Views", systemImage: "scroll")
                    }
                    NavigationLink { GridsView() } label: {
                        Label("Grids", systemImage: "grid")
                    }
                    NavigationLink { GroupedFormsView() } label: {
                        Label("Grouped Forms", systemImage: "rectangle.grid.1x2")
                    }
                    NavigationLink { CardsView() } label: {
                        Label("Cards", systemImage: "rectangle.on.rectangle")
                    }
                }
                Section("Navigation") {
                    NavigationLink { NavigationBarsView() } label: {
                        Label("Navigation Bars", systemImage: "chevron.left")
                    }
                    NavigationLink { TabBarsView() } label: {
                        Label("Tab Bars", systemImage: "rectangle.bottomthird.inset.filled")
                    }
                    NavigationLink { ToolbarsView() } label: {
                        Label("Toolbars", systemImage: "menubar.rectangle")
                    }
                    NavigationLink { SearchComponentView() } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
                Section("Overlays") {
                    NavigationLink { SheetsModalsView() } label: {
                        Label("Sheets & Modals", systemImage: "rectangle.topthird.inset.filled")
                    }
                    NavigationLink { AlertsView() } label: {
                        Label("Alerts & Dialogs", systemImage: "exclamationmark.triangle")
                    }
                    NavigationLink { ActionSheetsView() } label: {
                        Label("Action Sheets", systemImage: "filemenu.and.selection")
                    }
                    NavigationLink { PopoversView() } label: {
                        Label("Popovers", systemImage: "rectangle.connected.to.line.below")
                    }
                    NavigationLink { ToastsView() } label: {
                        Label("Toasts & Banners", systemImage: "bell")
                    }
                }
                Section("Playgrounds") {
                    NavigationLink { SpringPhysicsView() } label: {
                        Label("Spring Physics", systemImage: "waveform.path.ecg")
                    }
                    NavigationLink { HapticsView() } label: {
                        Label("Haptics", systemImage: "hand.tap")
                    }
                    NavigationLink { CornerRadiusView() } label: {
                        Label("Corner Radius", systemImage: "square.on.square")
                    }
                    NavigationLink { ConcentricRadiusView() } label: {
                        Label("Concentric Radius", systemImage: "square.inset.filled")
                    }
                    NavigationLink { ShadowExplorerView() } label: {
                        Label("Shadow Explorer", systemImage: "shadow")
                    }
                    NavigationLink { BlurStackView() } label: {
                        Label("Blur Stack", systemImage: "square.stack.3d.up")
                    }
                }
                Section("Reference") {
                    NavigationLink { SafeAreasView() } label: {
                        Label("Safe Areas", systemImage: "iphone")
                    }
                    NavigationLink { SheetDetentsView() } label: {
                        Label("Sheet Detents", systemImage: "rectangle.bottomhalf.inset.filled")
                    }
                }
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentsTab()
}
