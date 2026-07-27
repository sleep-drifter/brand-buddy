import SwiftUI

struct AppEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let section: String
    let tab: String
    let icon: String
    /// Last content update, ISO yyyy-MM-dd — lexicographic order is date
    /// order, so sorting never parses. Entries predating tracking share the
    /// baseline date and fall back to catalog order.
    let updated: String
    // Pre-lowercased so fuzzyMatch never calls lowercased() at search time.
    // ICU Unicode tables are also warmed during AppEntry.all initialization.
    let nameLower: String
    let sectionLower: String
    let tabLower: String
    let keywordsLower: String

    static let baselineDate = "2026-06-01"

    var pinKey: String { "\(tab):\(name)" }

    init(name: String, section: String, tab: String, icon: String, keywords: [String] = [],
         updated: String = AppEntry.baselineDate) {
        self.name = name
        self.section = section
        self.tab = tab
        self.icon = icon
        self.updated = updated
        self.nameLower = name.lowercased()
        self.sectionLower = section.lowercased()
        self.tabLower = tab.lowercased()
        self.keywordsLower = keywords.joined(separator: " ").lowercased()
    }

    static let all: [AppEntry] = elements + patternsAndSystem + playgrounds

    // MARK: - Elements

    static let elements: [AppEntry] = [
        // Visual
        .init(name: "Color",                 section: "Visual",          tab: "Elements", icon: "paintpalette",                   keywords: ["colour", "palette", "dark mode", "light mode", "semantic", "tint"]),
        .init(name: "Typography",            section: "Visual",          tab: "Elements", icon: "textformat",                     keywords: ["dynamic type", "font size", "accessibility", "text scale", "a11y", "fonts", "type styles", "font weight"]),
        .init(name: "Text Layout Anatomy",   section: "Visual",          tab: "Elements", icon: "text.line.first.and.arrowtriangle.forward", keywords: ["textkit", "textkit 2", "baseline", "line height", "ascender", "descender", "cap height", "x-height", "line fragment", "layout fragment", "nstextlayoutmanager", "font metrics", "glyph"], updated: "2026-07-27"),
        .init(name: "Paragraph & Line Control", section: "Visual",       tab: "Elements", icon: "text.justify.leading", keywords: ["tracking", "kerning", "letterspacing", "line spacing", "hyphenation", "justified", "justification", "line height multiple", "indent", "paragraph style", "nsparagraphstyle", "truncation", "line limit"], updated: "2026-07-27"),
        .init(name: "Spacing & Layout",      section: "Visual",          tab: "Elements", icon: "ruler",                          keywords: ["margin", "padding", "grid", "layout", "inset", "frame", "alignment"]),
        .init(name: "Images & Icons",        section: "Visual",          tab: "Elements", icon: "photo"),
        // Actions
        .init(name: "Buttons",               section: "Actions",         tab: "Elements", icon: "hand.tap"),
        .init(name: "Menus & Context Menus", section: "Actions",         tab: "Elements", icon: "list.bullet.rectangle", keywords: ["context menu", "pull-down", "long press", "preview", "imessage", "spotify"]),
        // Inputs & Forms
        .init(name: "Text Fields",           section: "Inputs & Forms",  tab: "Elements", icon: "character.cursor.ibeam"),
        .init(name: "Rich Text Editor",      section: "Inputs & Forms",  tab: "Elements", icon: "richtext.page", keywords: ["rich text", "attributedstring", "texteditor", "bold", "italic", "underline", "strikethrough", "formatting", "selection", "attribute runs", "ios 26", "wwdc25"], updated: "2026-07-27"),
        .init(name: "Toggles & Switches",    section: "Inputs & Forms",  tab: "Elements", icon: "switch.2"),
        .init(name: "Sliders",               section: "Inputs & Forms",  tab: "Elements", icon: "slider.horizontal.3"),
        .init(name: "Steppers",              section: "Inputs & Forms",  tab: "Elements", icon: "plus.forwardslash.minus"),
        .init(name: "Grouped Forms",         section: "Inputs & Forms",  tab: "Elements", icon: "rectangle.grid.1x2"),
        .init(name: "Form Patterns",         section: "Inputs & Forms",  tab: "Elements", icon: "list.clipboard"),
        // Selection
        .init(name: "Pickers",               section: "Selection",       tab: "Elements", icon: "checklist"),
        .init(name: "Segmented Controls",    section: "Selection",       tab: "Elements", icon: "rectangle.split.3x1"),
        .init(name: "Date & Time Pickers",   section: "Selection",       tab: "Elements", icon: "calendar"),
        .init(name: "Color Picker",          section: "Selection",       tab: "Elements", icon: "eyedropper"),
        // Indicators
        .init(name: "Progress Indicators",   section: "Indicators",      tab: "Elements", icon: "progress.indicator"),
        .init(name: "Gauges",                section: "Indicators",      tab: "Elements", icon: "gauge.with.needle"),
        .init(name: "Badges",                section: "Indicators",      tab: "Elements", icon: "bell.badge"),
        .init(name: "Tags",                  section: "Indicators",      tab: "Elements", icon: "tag"),
        // Layout
        .init(name: "Lists & Tables",        section: "Layout",          tab: "Elements", icon: "list.bullet"),
        .init(name: "Swipeable Rows",        section: "Layout",          tab: "Elements", icon: "arrow.left.arrow.right"),
        .init(name: "Scroll Views",          section: "Layout",          tab: "Elements", icon: "scroll"),
        .init(name: "Lazy Stacks",           section: "Layout",          tab: "Elements", icon: "rectangle.stack",  keywords: ["lazy", "lazyvstack", "lazyhstack", "performance", "on demand", "materialize", "viewport", "pinned", "section headers", "pagination", "onappear", "feed", "infinite scroll"], updated: "2026-07-26"),
        .init(name: "Carousels",             section: "Layout",          tab: "Elements", icon: "rectangle.portrait.on.rectangle.portrait.angled", keywords: ["carousel", "cover flow", "coverflow", "snap", "paging", "horizontal scroll", "peeking", "page control", "swipe", "gallery", "3d", "rotation", "auto advance", "infinite", "loop", "wallet", "stacked deck", "stories", "reels", "banner"]),
        .init(name: "Grids",                 section: "Layout",          tab: "Elements", icon: "grid"),
        .init(name: "Cards",                 section: "Layout",          tab: "Elements", icon: "rectangle.on.rectangle"),
        .init(name: "Reorderable List",      section: "Layout",          tab: "Elements", icon: "list.number", keywords: ["reorder", "move", "drag", "onMove", "EditMode", "sort", "rearrange"]),
        .init(name: "Safe Areas",            section: "Layout",          tab: "Elements", icon: "iphone", keywords: ["insets", "home indicator", "notch", "status bar", "safe area"]),
        // Navigation
        .init(name: "Navigation Bars & Toolbars", section: "Navigation", tab: "Elements", icon: "menubar.rectangle", keywords: ["navigation bar", "nav bar", "toolbar", "title", "large title", "inline", "bottom bar", "placement", "button group", "glass"]),
        .init(name: "Tab Bars",              section: "Navigation",      tab: "Elements", icon: "rectangle.bottomthird.inset.filled"),
        .init(name: "Search",                section: "Navigation",      tab: "Elements", icon: "magnifyingglass", keywords: ["searchable", "search bar", "scopes", "recent", "suggested", "results", "filter"]),
        // Overlays
        .init(name: "Sheets & Modals",       section: "Overlays",        tab: "Elements", icon: "rectangle.topthird.inset.filled", keywords: ["sheet", "modal", "detent", "medium", "large", "fraction", "height", "presentationDetents", "drag indicator", "full screen cover"]),
        .init(name: "Alerts & Dialogs",      section: "Overlays",        tab: "Elements", icon: "exclamationmark.triangle"),
        .init(name: "Action Sheets",         section: "Overlays",        tab: "Elements", icon: "filemenu.and.selection"),
        .init(name: "Popovers",              section: "Overlays",        tab: "Elements", icon: "rectangle.connected.to.line.below"),
        .init(name: "Toasts & Banners",      section: "Overlays",        tab: "Elements", icon: "bell"),
        // Materials
        .init(name: "iOS 26 Glass",          section: "Materials",       tab: "Elements", icon: "bubbles.and.sparkles"),
        .init(name: "Material (blur)",       section: "Materials",       tab: "Elements", icon: "camera.filters"),
        .init(name: "Surfaces",              section: "Materials",       tab: "Elements", icon: "square.stack"),
        .init(name: "Vibrancy",              section: "Materials",       tab: "Elements", icon: "sparkles"),
    ]

    // MARK: - Patterns & System

    static let patternsAndSystem: [AppEntry] = [
        // Navigation & Flows
        .init(name: "Navigation Patterns",   section: "Navigation & Flows", tab: "Patterns & System", icon: "arrow.triangle.turn.up.right.diamond"),
        .init(name: "Tab Bar Patterns",      section: "Navigation & Flows", tab: "Patterns & System", icon: "rectangle.bottomthird.inset.filled"),
        .init(name: "Modal Patterns",        section: "Navigation & Flows", tab: "Patterns & System", icon: "rectangle.topthird.inset.filled", keywords: ["modal", "sheet", "full screen cover", "confirmation dialog", "alert", "multi-step", "sheet flow", "wizard"]),
        // Content States
        .init(name: "Empty States",          section: "Content States",     tab: "Patterns & System", icon: "tray"),
        .init(name: "Loading States",        section: "Content States",     tab: "Patterns & System", icon: "progress.indicator"),
        .init(name: "Error States",          section: "Content States",     tab: "Patterns & System", icon: "exclamationmark.triangle"),
        // Settings & Onboarding
        .init(name: "Settings Patterns",     section: "Settings & Onboarding", tab: "Patterns & System", icon: "gear"),
        .init(name: "Onboarding Flows",      section: "Settings & Onboarding", tab: "Patterns & System", icon: "hand.wave"),
        // Gestures
        .init(name: "Tap & Long Press",      section: "Gestures",           tab: "Patterns & System", icon: "hand.tap"),
        .init(name: "Swipe & Drag",          section: "Gestures",           tab: "Patterns & System", icon: "hand.draw"),
        .init(name: "Pinch & Zoom",          section: "Gestures",           tab: "Patterns & System", icon: "arrow.up.left.and.arrow.down.right"),
        .init(name: "Rotation",              section: "Gestures",           tab: "Patterns & System", icon: "arrow.clockwise"),
        // Animations
        .init(name: "Transitions",           section: "Animations",         tab: "Patterns & System", icon: "arrow.left.arrow.right.square"),
        .init(name: "Keyframe Animations",   section: "Animations",         tab: "Patterns & System", icon: "timeline.selection"),
        .init(name: "Keyframe Studio",       section: "Animations",         tab: "Patterns & System", icon: "wand.and.sparkles.rectangle", keywords: ["keyframe", "animation", "timeline", "studio", "editor", "builder", "interpolation"]),
        .init(name: "Phase Animations",      section: "Animations",         tab: "Patterns & System", icon: "waveform.path"),
        .init(name: "Symbol Effects",        section: "Animations",         tab: "Patterns & System", icon: "sparkle"),
        .init(name: "Symbol Playground",     section: "Animations",         tab: "Patterns & System", icon: "theatermask.and.paintbrush", keywords: ["sf symbols", "animate", "symbol effect", "replace", "bounce", "wiggle", "rotate", "breathe", "pulse", "appear", "playground"]),
        .init(name: "Matched Geometry",      section: "Animations",         tab: "Patterns & System", icon: "rectangle.on.rectangle.angled"),
        .init(name: "Content Transition",    section: "Animations",         tab: "Patterns & System", icon: "textformat.abc.dottedunderline", keywords: ["contentTransition", "interpolate", "numericText", "glyph", "morph", "text animation", "counter", "string"]),
        // Accessibility
        .init(name: "VoiceOver Labels",      section: "Accessibility",      tab: "Patterns & System", icon: "accessibility"),
        .init(name: "Dynamic Type",          section: "Accessibility",      tab: "Patterns & System", icon: "textformat.size"),
        .init(name: "Reduce Motion",         section: "Accessibility",      tab: "Patterns & System", icon: "hand.raised"),
        .init(name: "High Contrast",         section: "Accessibility",      tab: "Patterns & System", icon: "circle.lefthalf.filled"),
        // System
        .init(name: "Live Activity Anatomy", section: "System",             tab: "Patterns & System", icon: "platter.filled.top.iphone", keywords: ["live activity", "dynamic island", "activitykit", "lock screen", "standby", "smart stack", "compact", "minimal", "expanded", "regions", "widget", "anatomy", "wwdc26", "event", "check in", "career fair", "ticket", "boarding pass", "concert", "countdown", "timer", "push-to-start", "alert", "qr"], updated: "2026-07-26"),
        .init(name: "Share Sheet",           section: "System",             tab: "Patterns & System", icon: "square.and.arrow.up",   keywords: ["share", "ShareLink", "UIActivityViewController", "send", "export"]),
        .init(name: "Face ID / Touch ID",    section: "System",             tab: "Patterns & System", icon: "faceid",               keywords: ["face id", "touch id", "biometrics", "LocalAuthentication", "auth"]),
        .init(name: "Clipboard",             section: "System",             tab: "Patterns & System", icon: "doc.on.clipboard",     keywords: ["clipboard", "pasteboard", "UIPasteboard", "copy", "paste"]),
        .init(name: "Quick Look",            section: "System",             tab: "Patterns & System", icon: "eye",                  keywords: ["quick look", "preview", "QuickLookPreviewController", "document"]),
        .init(name: "Document Picker",       section: "System",             tab: "Patterns & System", icon: "folder",               keywords: ["document", "picker", "UIDocumentPicker", "file", "importer"]),
        // Permissions
        .init(name: "Permission Requests",        section: "Permissions",   tab: "Patterns & System", icon: "lock.shield",               keywords: ["auth", "authorization", "camera", "microphone", "photos", "location", "contacts", "privacy"]),
        .init(name: "Permission Denied Recovery", section: "Permissions",   tab: "Patterns & System", icon: "exclamationmark.lock",      keywords: ["denied", "settings", "privacy", "blocked", "restricted"]),
        .init(name: "Push Notifications",         section: "Permissions",   tab: "Patterns & System", icon: "bell.badge",                keywords: ["push", "notifications", "alerts", "badge", "UNUserNotificationCenter"]),
        // Media
        .init(name: "Camera",                     section: "Media",         tab: "Patterns & System", icon: "camera",                    keywords: ["camera", "capture", "AVFoundation", "preview", "viewfinder"]),
        .init(name: "Photo Picker",               section: "Media",         tab: "Patterns & System", icon: "photo.on.rectangle.angled", keywords: ["photos", "picker", "PHPicker", "library", "gallery", "PhotosPicker"]),
        .init(name: "Photo Library Patterns",     section: "Media",         tab: "Patterns & System", icon: "photo.stack",               keywords: ["avatar", "crop", "thumbnail", "gallery", "photos"]),
        .init(name: "Audio Recording",            section: "Media",         tab: "Patterns & System", icon: "mic.fill",                  keywords: ["record", "microphone", "AVAudioRecorder", "waveform", "playback"]),
        .init(name: "Waveform Visualization",     section: "Media",         tab: "Patterns & System", icon: "waveform",                  keywords: ["waveform", "audio", "canvas", "animation", "visualizer"]),
        .init(name: "Playback UI Patterns",       section: "Media",         tab: "Patterns & System", icon: "play.circle",               keywords: ["player", "playback", "mini player", "music", "audio"]),
        // Maps
        .init(name: "Map Basics",                 section: "Maps",          tab: "Patterns & System", icon: "map",                       keywords: ["map", "MapKit", "location", "region", "satellite"]),
        .init(name: "Map Annotations",            section: "Maps",          tab: "Patterns & System", icon: "mappin.and.ellipse",        keywords: ["pin", "marker", "annotation", "map", "MapKit"]),
        .init(name: "Map Overlays",               section: "Maps",          tab: "Patterns & System", icon: "map.circle",                keywords: ["polyline", "circle", "overlay", "route", "map"]),
        // AI & Generation
        .init(name: "Streaming Text",             section: "AI & Generation", tab: "Patterns & System", icon: "ellipsis.message",     keywords: ["streaming", "typewriter", "token", "cursor", "chat", "LLM"]),
        .init(name: "Writing Tools Integration",  section: "AI & Generation", tab: "Patterns & System", icon: "pencil.and.sparkles",  keywords: ["writing tools", "iOS 18", "writingToolsBehavior", "text editor", "AI"]),
        .init(name: "Image Generation",           section: "AI & Generation", tab: "Patterns & System", icon: "photo.badge.plus",     keywords: ["image generation", "skeleton", "shimmer", "loading", "AI", "placeholder"]),
        .init(name: "Prompt Input Patterns",      section: "AI & Generation", tab: "Patterns & System", icon: "text.bubble",          keywords: ["prompt", "input", "chat", "multi-line", "grow", "attachment", "send button"]),
        // Text & Editing
        .init(name: "Live Token Highlighting",    section: "Text & Editing", tab: "Patterns & System", icon: "highlighter",           keywords: ["hashtag", "mention", "syntax highlighting", "textkit", "nstextstorage", "uitextview", "regex", "tokens", "editor", "compose", "links"], updated: "2026-07-27"),
        .init(name: "Inline Text Attachments",    section: "Text & Editing", tab: "Patterns & System", icon: "puzzlepiece.extension", keywords: ["nstextattachment", "attachment", "chip", "pill", "badge", "inline view", "textkit 2", "view provider", "token field", "tag", "live view"], updated: "2026-07-27"),
        // Device & Sensors
        .init(name: "Custom Haptics",            section: "Device & Sensors", tab: "Patterns & System", icon: "waveform.path.ecg.rectangle", keywords: ["haptics", "CHHapticEngine", "taptic", "vibration", "pattern", "transient", "continuous", "impact", "notification", "selection", "UIFeedbackGenerator", "feedback"]),
        .init(name: "Haptic Studio",             section: "Device & Sensors", tab: "Patterns & System", icon: "slider.horizontal.below.rectangle", keywords: ["haptic", "ahap", "editor", "timeline", "pattern", "waveform", "CoreHaptics", "keyframe"]),
        .init(name: "Accelerometer & Gyroscope", section: "Device & Sensors", tab: "Patterns & System", icon: "gyroscope",                  keywords: ["accelerometer", "gyroscope", "CMMotionManager", "CoreMotion", "tilt", "motion"]),
        .init(name: "Barometer",                 section: "Device & Sensors", tab: "Patterns & System", icon: "thermometer.medium",          keywords: ["barometer", "CMAltimeter", "altitude", "pressure", "sensor"]),
        .init(name: "Proximity & Ambient Light", section: "Device & Sensors", tab: "Patterns & System", icon: "light.max",                  keywords: ["proximity", "ambient light", "brightness", "UIScreen", "sensor"]),
        .init(name: "Battery State",             section: "Device & Sensors", tab: "Patterns & System", icon: "battery.75percent",           keywords: ["battery", "batteryLevel", "batteryState", "low power mode", "UIDevice"]),
    ]

    // MARK: - Playgrounds

    static let playgrounds: [AppEntry] = [
        .init(name: "Shaders",               section: "Playgrounds", tab: "Playgrounds", icon: "sparkles.rectangle.stack", keywords: ["metal", "shader", "filter", "effect", "ripple", "pixelate", "distortion", "gpu", "grain", "vignette", "chromatic", "emboss", "swirl", "wave", "holographic", "foil", "duotone", "halftone", "solarize", "frosted", "glass", "lens", "refract", "color grade", "lut", "cinematic", "topographic", "contour", "stack", "layers", "preset", "photo", "metaball", "liquid", "blobs", "water", "shimmer", "skeleton", "infrared", "thermal", "circle wave", "sinebow", "light grid", "inferno", "shadertoy", "seascape", "ocean", "star nest", "starfield", "galaxy", "protean", "clouds", "volumetric", "raymarching", "plasma", "tesla", "domain warp", "warp field", "fbm", "marble", "smoke", "iq", "wallpaper", "oil paint", "kuwahara", "painterly", "dither", "bayer", "retro", "1-bit", "sketch", "crosshatch", "pencil", "hatching", "rain", "droplets", "weather"], updated: "2026-07-26"),
        .init(name: "Spring Physics",        section: "Playgrounds", tab: "Playgrounds", icon: "waveform.path.ecg",       keywords: ["animation", "bounce", "easing", "motion", "damping", "stiffness"]),
        .init(name: "Corner Radius",         section: "Playgrounds", tab: "Playgrounds", icon: "square.on.square",        keywords: ["rounded", "border radius", "roundrectangle"]),
        .init(name: "Concentric Radius",     section: "Playgrounds", tab: "Playgrounds", icon: "square.inset.filled"),
        .init(name: "Shadow Explorer",       section: "Playgrounds", tab: "Playgrounds", icon: "shadow"),
        .init(name: "Blur Stack",            section: "Playgrounds", tab: "Playgrounds", icon: "square.stack.3d.up"),
        .init(name: "Mesh Gradient",         section: "Playgrounds", tab: "Playgrounds", icon: "mosaic",                  keywords: ["mesh", "gradient", "color", "animation", "mask", "blend"]),
        .init(name: "Fluid Gradient",        section: "Playgrounds", tab: "Playgrounds", icon: "drop.halffull",          keywords: ["fluid", "gradient", "generative", "metaball", "blob", "grain", "noise", "animated", "background", "ishader", "mesh"], updated: "2026-07-07"),
        .init(name: "Random Metaball 2D",    section: "Playgrounds", tab: "Playgrounds", icon: "circle.hexagongrid.fill", keywords: ["metaball", "blob", "goo", "liquid", "merge", "fuse", "field", "generative", "shader", "organic", "lava", "mercury", "ishader"], updated: "2026-07-07"),
        .init(name: "Circle SDF 1",          section: "Playgrounds", tab: "Playgrounds", icon: "circle.circle",           keywords: ["sdf", "signed distance field", "circle", "metaball", "smooth min", "blend", "shader", "metal", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Circle SDF 2",          section: "Playgrounds", tab: "Playgrounds", icon: "circle.circle.fill",      keywords: ["sdf", "signed distance field", "circle", "iso", "contour", "smooth min", "shader", "metal", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Smooth Min 2D",         section: "Playgrounds", tab: "Playgrounds", icon: "drop.circle",             keywords: ["sdf", "smooth min", "smoothmin", "blend", "field", "metaball", "shader", "metal", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Implicit Equation",     section: "Playgrounds", tab: "Playgrounds", icon: "function",                keywords: ["implicit", "equation", "contour", "curve", "math", "field", "layer effect", "shader", "metal", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Lissajous Curve",       section: "Playgrounds", tab: "Playgrounds", icon: "scribble.variable",       keywords: ["lissajous", "curve", "parametric", "harmonic", "canvas", "oscillator", "sine", "cosine", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Radial Layout",         section: "Playgrounds", tab: "Playgrounds", icon: "circle.grid.cross",       keywords: ["layout", "radial", "ring", "circular", "custom layout", "arrange", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Flow Layout",           section: "Playgrounds", tab: "Playgrounds", icon: "square.grid.3x2",         keywords: ["layout", "flow", "wrap", "tags", "chips", "reflow", "custom layout", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Flow Distortion",       section: "Playgrounds", tab: "Playgrounds", icon: "water.waves",             keywords: ["flow", "distortion", "curl", "noise", "warp", "chromatic aberration", "layer effect", "shader", "metal", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Physics Tag",           section: "Playgrounds", tab: "Playgrounds", icon: "tag.circle",              keywords: ["physics", "spritekit", "gravity", "motion", "tilt", "coremotion", "tag cloud", "drag", "throw", "collision", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Stable Fluid",          section: "Playgrounds", tab: "Playgrounds", icon: "drop.degreesign",        keywords: ["fluid", "stable fluid", "navier stokes", "simulation", "smoke", "ink", "metal", "compute", "gpu", "jos stam", "my-toybox", "toybox"], updated: "2026-07-07"),
        .init(name: "Liquid Wallet",         section: "Playgrounds", tab: "Playgrounds", icon: "wallet.pass",             keywords: ["glass", "liquid glass", "wallet", "carousel", "stack", "deck", "merge", "union", "morph", "metaball", "glasseffect", "glasseffectcontainer", "ios 26"], updated: "2026-07-08"),
        .init(name: "Liquid Carousel",       section: "Playgrounds", tab: "Playgrounds", icon: "rectangle.split.2x1",     keywords: ["glass", "liquid glass", "carousel", "merge", "blend", "proximity", "spacing", "metaball", "train", "dock", "scrub", "neck", "glasseffectcontainer", "ios 26"], updated: "2026-07-09"),
        .init(name: "Glass Morph",           section: "Playgrounds", tab: "Playgrounds", icon: "circle.hexagonpath.fill", keywords: ["glass", "liquid glass", "morph", "identity", "glasseffectid", "namespace", "matched geometry", "materialize", "transition", "fab", "expand", "shape", "metaball", "stagger", "scrub", "gooey", "drag", "bloom", "magnetic", "swipe", "slingshot", "haptic", "gesture", "glasseffectcontainer", "ios 26"], updated: "2026-07-26"),
        .init(name: "Sheet Detent Morph",    section: "Playgrounds", tab: "Playgrounds", icon: "inset.filled.bottomhalf.rectangle", keywords: ["glass", "liquid glass", "sheet", "detent", "bottom sheet", "grabber", "modal", "morph", "button", "present", "dismiss", "drag", "glasseffectid", "ios 26"], updated: "2026-07-25"),
        .init(name: "Tab Mini Player",       section: "Playgrounds", tab: "Playgrounds", icon: "play.square.stack",       keywords: ["glass", "liquid glass", "tab bar", "mini player", "now playing", "music", "pill", "card", "tear", "drag", "scrub", "morph", "glasseffectcontainer", "ios 26"], updated: "2026-07-25"),
        .init(name: "Toolbar Condense",      section: "Playgrounds", tab: "Playgrounds", icon: "menubar.rectangle",       keywords: ["glass", "liquid glass", "toolbar", "nav bar", "condense", "collapse", "scroll", "pill", "merge", "onscrollgeometrychange", "momentum", "morph", "ios 26"], updated: "2026-07-25"),
        .init(name: "Text Wrap & Exclusion", section: "Playgrounds", tab: "Playgrounds", icon: "text.below.photo",        keywords: ["exclusion path", "text wrap", "wrap around", "shape outside", "textkit", "nstextcontainer", "magazine", "reflow", "drag", "uitextview"], updated: "2026-07-27"),
        .init(name: "Text Effects",          section: "Playgrounds", tab: "Playgrounds", icon: "wand.and.sparkles",       keywords: ["textrenderer", "text animation", "per glyph", "blur in", "shimmer", "wave", "reveal", "apple intelligence", "run slice", "ios 18", "typewriter", "stagger"], updated: "2026-07-27"),
    ]

    // MARK: - Shaders

    /// Metal/GPU-effect pages, surfaced as their own Home section. These reference
    /// the existing playground entries (not copies), so pins and search stay unified.
    static let shaders: [AppEntry] = [
        "Shaders",
        "Fluid Gradient",
        "Stable Fluid",
        "Flow Distortion",
        "Implicit Equation",
        "Random Metaball 2D",
        "Circle SDF 1",
        "Circle SDF 2",
        "Smooth Min 2D",
    ].compactMap { name in playgrounds.first { $0.name == name } }
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
            Label(pinsStore.isPinned(entry) ? "Remove Bookmark" : "Bookmark",
                  systemImage: pinsStore.isPinned(entry) ? "bookmark.slash" : "bookmark")
        }
    }
    .swipeActions(edge: .leading) {
        Button {
            pinsStore.toggle(entry)
        } label: {
            Label(pinsStore.isPinned(entry) ? "Remove" : "Bookmark",
                  systemImage: pinsStore.isPinned(entry) ? "bookmark.slash" : "bookmark")
        }
        .tint(.blue)
    }
}

