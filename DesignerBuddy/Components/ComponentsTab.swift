import SwiftUI

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let section: String
    let tab: String
    let icon: String
    // Pre-lowercased so fuzzyMatch never calls lowercased() at search time.
    // ICU Unicode tables are also warmed during AppEntry.all initialization.
    let nameLower: String
    let sectionLower: String
    let tabLower: String
    let keywordsLower: String

    var pinKey: String { "\(tab):\(name)" }

    init(name: String, section: String, tab: String, icon: String, keywords: [String] = []) {
        self.name = name
        self.section = section
        self.tab = tab
        self.icon = icon
        self.nameLower = name.lowercased()
        self.sectionLower = section.lowercased()
        self.tabLower = tab.lowercased()
        self.keywordsLower = keywords.joined(separator: " ").lowercased()
    }

    // Keep ComponentEntry as a typealias for backwards compat with ComponentSearchView
    static let all: [AppEntry] = components + materials + patterns + native + more + exploreA + exploreB + exploreC + exploreD

    static let components: [AppEntry] = [
        .init(name: "Color",                 section: "Visual",      tab: "Components", icon: "paintpalette",                   keywords: ["colour", "palette", "dark mode", "light mode", "semantic", "tint"]),
        .init(name: "Typography",            section: "Visual",      tab: "Components", icon: "textformat",                     keywords: ["dynamic type", "font size", "accessibility", "text scale", "a11y", "fonts", "type styles", "font weight"]),
        .init(name: "Spacing & Layout",      section: "Visual",      tab: "Components", icon: "ruler",                          keywords: ["margin", "padding", "grid", "layout", "inset", "frame", "alignment"]),
        .init(name: "Buttons",               section: "Actions",     tab: "Components", icon: "hand.tap"),
        .init(name: "Menus & Context Menus", section: "Actions",     tab: "Components", icon: "list.bullet.rectangle"),
        .init(name: "Context Menus",         section: "Actions",     tab: "Components", icon: "contextualmenu.and.cursorarrow"),
        .init(name: "Text Fields",           section: "Inputs",      tab: "Components", icon: "character.cursor.ibeam"),
        .init(name: "Toggles & Switches",    section: "Inputs",      tab: "Components", icon: "switch.2"),
        .init(name: "Sliders",               section: "Inputs",      tab: "Components", icon: "slider.horizontal.3"),
        .init(name: "Steppers",              section: "Inputs",      tab: "Components", icon: "plus.forwardslash.minus"),
        .init(name: "Pickers",               section: "Selection",   tab: "Components", icon: "checklist"),
        .init(name: "Segmented Controls",    section: "Selection",   tab: "Components", icon: "rectangle.split.3x1"),
        .init(name: "Date & Time Pickers",   section: "Selection",   tab: "Components", icon: "calendar"),
        .init(name: "Color Picker",          section: "Selection",   tab: "Components", icon: "eyedropper"),
        .init(name: "Images & Icons",        section: "Display",     tab: "Components", icon: "photo"),
        .init(name: "Progress Indicators",   section: "Display",     tab: "Components", icon: "progress.indicator"),
        .init(name: "Gauges",                section: "Display",     tab: "Components", icon: "gauge.with.needle"),
        .init(name: "Badges",                section: "Display",     tab: "Components", icon: "bell.badge"),
        .init(name: "Tags",                  section: "Display",     tab: "Components", icon: "tag"),
        .init(name: "Lists & Tables",        section: "Layout",      tab: "Components", icon: "list.bullet"),
        .init(name: "Swipeable Rows",        section: "Layout",      tab: "Components", icon: "arrow.left.arrow.right"),
        .init(name: "Scroll Views",          section: "Layout",      tab: "Components", icon: "scroll"),
        .init(name: "Grids",                 section: "Layout",      tab: "Components", icon: "grid"),
        .init(name: "Grouped Forms",         section: "Layout",      tab: "Components", icon: "rectangle.grid.1x2"),
        .init(name: "Cards",                 section: "Layout",      tab: "Components", icon: "rectangle.on.rectangle"),
        .init(name: "Navigation Bars",       section: "Navigation",  tab: "Components", icon: "chevron.left"),
        .init(name: "Tab Bars",              section: "Navigation",  tab: "Components", icon: "rectangle.bottomthird.inset.filled"),
        .init(name: "Toolbars",              section: "Navigation",  tab: "Components", icon: "menubar.rectangle"),
        .init(name: "Search",                section: "Navigation",  tab: "Components", icon: "magnifyingglass"),
        .init(name: "Sheets & Modals",       section: "Overlays",    tab: "Components", icon: "rectangle.topthird.inset.filled"),
        .init(name: "Alerts & Dialogs",      section: "Overlays",    tab: "Components", icon: "exclamationmark.triangle"),
        .init(name: "Action Sheets",         section: "Overlays",    tab: "Components", icon: "filemenu.and.selection"),
        .init(name: "Popovers",              section: "Overlays",    tab: "Components", icon: "rectangle.connected.to.line.below"),
        .init(name: "Toasts & Banners",      section: "Overlays",    tab: "Components", icon: "bell"),
    ]

    static let patterns: [AppEntry] = [
        .init(name: "Navigation Patterns",   section: "Navigation",   tab: "Patterns", icon: "arrow.triangle.turn.up.right.diamond"),
        .init(name: "Tab Bar Patterns",      section: "Navigation",   tab: "Patterns", icon: "rectangle.bottomthird.inset.filled"),
        .init(name: "Modal Patterns",        section: "Presentation", tab: "Patterns", icon: "rectangle.topthird.inset.filled"),
        .init(name: "Sheet Flows",           section: "Presentation", tab: "Patterns", icon: "arrow.up.and.down.square"),
        .init(name: "Search Patterns",       section: "Input & Search", tab: "Patterns", icon: "magnifyingglass"),
        .init(name: "Form Patterns",         section: "Input & Search", tab: "Patterns", icon: "list.clipboard"),
        .init(name: "Empty States",          section: "Content",      tab: "Patterns", icon: "tray"),
        .init(name: "Loading States",        section: "Content",      tab: "Patterns", icon: "progress.indicator"),
        .init(name: "Error States",          section: "Content",      tab: "Patterns", icon: "exclamationmark.triangle"),
        .init(name: "Settings Patterns",     section: "Settings",     tab: "Patterns", icon: "gear"),
        .init(name: "Onboarding Flows",      section: "Onboarding",   tab: "Patterns", icon: "hand.wave"),
    ]

    static let materials: [AppEntry] = [
        .init(name: "iOS 26 Glass",          section: "Glass",        tab: "Components", icon: "bubbles.and.sparkles"),
        .init(name: "Material (blur)",       section: "Glass",        tab: "Components", icon: "camera.filters"),
        .init(name: "Surfaces",              section: "Surfaces",     tab: "Components", icon: "square.stack"),
        .init(name: "Vibrancy",              section: "Vibrancy",     tab: "Components", icon: "sparkles"),
    ]

    static let native: [AppEntry] = [
        .init(name: "Permission Requests",        section: "Permissions",   tab: "Native", icon: "lock.shield",               keywords: ["auth", "authorization", "camera", "microphone", "photos", "location", "contacts", "privacy"]),
        .init(name: "Permission Denied Recovery", section: "Permissions",   tab: "Native", icon: "exclamationmark.lock",      keywords: ["denied", "settings", "privacy", "blocked", "restricted"]),
        .init(name: "Push Notifications",         section: "Permissions",   tab: "Native", icon: "bell.badge",                keywords: ["push", "notifications", "alerts", "badge", "UNUserNotificationCenter"]),
        .init(name: "Camera",                     section: "Camera",        tab: "Native", icon: "camera",                    keywords: ["camera", "capture", "AVFoundation", "preview", "viewfinder"]),
        .init(name: "Photo Picker",               section: "Photo Library", tab: "Native", icon: "photo.on.rectangle.angled", keywords: ["photos", "picker", "PHPicker", "library", "gallery", "PhotosPicker"]),
        .init(name: "Photo Library Patterns",     section: "Photo Library", tab: "Native", icon: "photo.stack",               keywords: ["avatar", "crop", "thumbnail", "gallery", "photos"]),
        .init(name: "Audio Recording",            section: "Audio",         tab: "Native", icon: "mic.fill",                  keywords: ["record", "microphone", "AVAudioRecorder", "waveform", "playback"]),
        .init(name: "Waveform Visualization",     section: "Audio",         tab: "Native", icon: "waveform",                  keywords: ["waveform", "audio", "canvas", "animation", "visualizer"]),
        .init(name: "Playback UI Patterns",       section: "Audio",         tab: "Native", icon: "play.circle",               keywords: ["player", "playback", "mini player", "music", "audio"]),
        .init(name: "Map Basics",                 section: "Maps",          tab: "Native", icon: "map",                       keywords: ["map", "MapKit", "location", "region", "satellite"]),
        .init(name: "Map Annotations",            section: "Maps",          tab: "Native", icon: "mappin.and.ellipse",        keywords: ["pin", "marker", "annotation", "map", "MapKit"]),
        .init(name: "Map Overlays",               section: "Maps",          tab: "Native", icon: "map.circle",                keywords: ["polyline", "circle", "overlay", "route", "map"]),
    ]

    static let more: [AppEntry] = [
        .init(name: "Spring Physics",        section: "Playgrounds", tab: "More", icon: "waveform.path.ecg",       keywords: ["animation", "bounce", "easing", "motion", "damping", "stiffness"]),
        .init(name: "Haptics",               section: "Playgrounds", tab: "More", icon: "hand.tap",                keywords: ["vibration", "feedback", "taptic", "impact", "selection"]),
        .init(name: "Corner Radius",         section: "Playgrounds", tab: "More", icon: "square.on.square",        keywords: ["rounded", "border radius", "roundrectangle"]),
        .init(name: "Concentric Radius",     section: "Playgrounds", tab: "More", icon: "square.inset.filled"),
        .init(name: "Shadow Explorer",       section: "Playgrounds", tab: "More", icon: "shadow"),
        .init(name: "Blur Stack",            section: "Playgrounds", tab: "More", icon: "square.stack.3d.up"),
        .init(name: "Safe Areas",            section: "Reference",   tab: "More", icon: "iphone",                  keywords: ["insets", "home indicator", "notch", "status bar"]),
        .init(name: "Sheet Detents",         section: "Reference",   tab: "More", icon: "rectangle.bottomhalf.inset.filled"),
    ]

    static let exploreA: [AppEntry] = [
        .init(name: "Tap & Long Press",    section: "Gestures",      tab: "Explore", icon: "hand.tap"),
        .init(name: "Swipe & Drag",        section: "Gestures",      tab: "Explore", icon: "hand.draw"),
        .init(name: "Pinch & Zoom",        section: "Gestures",      tab: "Explore", icon: "arrow.up.left.and.arrow.down.right"),
        .init(name: "Rotation",            section: "Gestures",      tab: "Explore", icon: "arrow.clockwise"),
        .init(name: "Transitions",         section: "Animations",    tab: "Explore", icon: "arrow.left.arrow.right.square"),
        .init(name: "Keyframe Animations", section: "Animations",    tab: "Explore", icon: "timeline.selection"),
        .init(name: "Phase Animations",    section: "Animations",    tab: "Explore", icon: "waveform.path"),
        .init(name: "Symbol Effects",      section: "Animations",    tab: "Explore", icon: "sparkle"),
        .init(name: "Symbol Playground",   section: "Animations",    tab: "Explore", icon: "theatermask.and.paintbrush", keywords: ["sf symbols", "animate", "symbol effect", "replace", "bounce", "wiggle", "rotate", "breathe", "pulse", "appear", "playground"]),
        .init(name: "Matched Geometry",    section: "Animations",    tab: "Explore", icon: "rectangle.on.rectangle.angled"),
        .init(name: "VoiceOver Labels",    section: "Accessibility", tab: "Explore", icon: "accessibility"),
        .init(name: "Dynamic Type",        section: "Accessibility", tab: "Explore", icon: "textformat.size"),
        .init(name: "Reduce Motion",       section: "Accessibility", tab: "Explore", icon: "hand.raised"),
        .init(name: "High Contrast",       section: "Accessibility", tab: "Explore", icon: "circle.lefthalf.filled"),
    ]

    static let exploreB: [AppEntry] = [
        .init(name: "Share Sheet",        section: "System Integrations", tab: "Explore", icon: "square.and.arrow.up",   keywords: ["share", "ShareLink", "UIActivityViewController", "send", "export"]),
        .init(name: "Face ID / Touch ID", section: "System Integrations", tab: "Explore", icon: "faceid",               keywords: ["face id", "touch id", "biometrics", "LocalAuthentication", "auth"]),
        .init(name: "Clipboard",          section: "System Integrations", tab: "Explore", icon: "doc.on.clipboard",     keywords: ["clipboard", "pasteboard", "UIPasteboard", "copy", "paste"]),
        .init(name: "Quick Look",         section: "System Integrations", tab: "Explore", icon: "eye",                  keywords: ["quick look", "preview", "QuickLookPreviewController", "document"]),
        .init(name: "Document Picker",    section: "System Integrations", tab: "Explore", icon: "folder",               keywords: ["document", "picker", "UIDocumentPicker", "file", "importer"]),
    ]

    static let exploreC: [AppEntry] = [
        .init(name: "Streaming Text",             section: "AI & Generation", tab: "Explore", icon: "ellipsis.message",     keywords: ["streaming", "typewriter", "token", "cursor", "chat", "LLM"]),
        .init(name: "Writing Tools Integration",  section: "AI & Generation", tab: "Explore", icon: "pencil.and.sparkles",  keywords: ["writing tools", "iOS 18", "writingToolsBehavior", "text editor", "AI"]),
        .init(name: "Image Generation",           section: "AI & Generation", tab: "Explore", icon: "photo.badge.plus",     keywords: ["image generation", "skeleton", "shimmer", "loading", "AI", "placeholder"]),
        .init(name: "Prompt Input Patterns",      section: "AI & Generation", tab: "Explore", icon: "text.bubble",          keywords: ["prompt", "input", "chat", "multi-line", "grow", "attachment", "send button"]),
    ]

    static let exploreD: [AppEntry] = [
        .init(name: "Custom Haptics",            section: "Device & Sensors", tab: "Explore", icon: "waveform.path.ecg.rectangle", keywords: ["haptics", "CHHapticEngine", "taptic", "vibration", "pattern", "transient", "continuous"]),
        .init(name: "Accelerometer & Gyroscope", section: "Device & Sensors", tab: "Explore", icon: "gyroscope",                  keywords: ["accelerometer", "gyroscope", "CMMotionManager", "CoreMotion", "tilt", "motion"]),
        .init(name: "Barometer",                 section: "Device & Sensors", tab: "Explore", icon: "thermometer.medium",          keywords: ["barometer", "CMAltimeter", "altitude", "pressure", "sensor"]),
        .init(name: "Proximity & Ambient Light", section: "Device & Sensors", tab: "Explore", icon: "light.max",                  keywords: ["proximity", "ambient light", "brightness", "UIScreen", "sensor"]),
        .init(name: "Battery State",             section: "Device & Sensors", tab: "Explore", icon: "battery.75percent",           keywords: ["battery", "batteryLevel", "batteryState", "low power mode", "UIDevice"]),
    ]
}

// Keep old name working in ComponentSearchView
typealias ComponentEntry = AppEntry

// MARK: - Pinnable Row Helper

@ViewBuilder
func pinnableRow(_ entry: AppEntry, pinsStore: PinsStore) -> some View {
    NavigationLink(value: entry) {
        Label(entry.name, systemImage: entry.icon)
    }
    .contextMenu {
        Button {
            pinsStore.toggle(entry)
        } label: {
            Label(pinsStore.isPinned(entry) ? "Unpin" : "Pin",
                  systemImage: pinsStore.isPinned(entry) ? "pin.slash" : "pin")
        }
    }
    .swipeActions(edge: .leading) {
        Button {
            pinsStore.toggle(entry)
        } label: {
            Label(pinsStore.isPinned(entry) ? "Unpin" : "Pin",
                  systemImage: pinsStore.isPinned(entry) ? "pin.slash" : "pin")
        }
        .tint(.yellow)
    }
}

// MARK: - Components Tab

struct ComponentsTab: View {
    @EnvironmentObject var pinsStore: PinsStore

    private let tabEntries: [AppEntry] = AppEntry.components + AppEntry.materials + AppEntry.more
    private let sectionOrder = ["Visual", "Actions", "Inputs", "Selection", "Display", "Layout",
                                "Navigation", "Overlays", "Glass", "Surfaces", "Vibrancy",
                                "Playgrounds", "Reference"]

    private var pinnedEntries: [AppEntry] {
        tabEntries.filter { pinsStore.isPinned($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !pinnedEntries.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedEntries) { entry in
                            pinnableRow(entry, pinsStore: pinsStore)
                        }
                    }
                }

                ForEach(sectionOrder, id: \.self) { section in
                    let entries = tabEntries.filter { $0.section == section }
                    if !entries.isEmpty {
                        Section(section) {
                            ForEach(entries) { entry in
                                pinnableRow(entry, pinsStore: pinsStore)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Components")
            .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
        }
    }
}

#Preview {
    ComponentsTab()
        .environmentObject(PinsStore())
}
