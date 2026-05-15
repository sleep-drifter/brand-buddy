import SwiftUI

struct ComponentSearchView: View {
    @State private var searchText = ""
    @State private var results: [AppEntry] = []

    var body: some View {
        NavigationStack {
            // Single persistent List — never torn down. Switching between the
            // all-sections browse and search results happens inside the List so
            // SwiftUI only diffs row content, not the entire view tree.
            List {
                if searchText.isEmpty {
                    ForEach(["Components", "Patterns", "Native", "More", "Explore"], id: \.self) { tab in
                        Section(tab) {
                            ForEach(AppEntry.all.filter { $0.tab == tab }) { entry in
                                NavigationLink(value: entry) {
                                    Text(entry.name)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(results) { entry in
                        NavigationLink(value: entry) {
                            HStack {
                                Text(entry.name)
                                Spacer()
                                Text(entry.section)
                                    .font(.caption2)
                                    .foregroundStyle(entry.tab.chipColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(entry.tab.chipColor.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                }
            }
            // Empty-state overlay — cheaper than a third conditional branch.
            .overlay {
                if !searchText.isEmpty && results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .background(.background)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search for anything")
            .onChange(of: searchText) { _, newValue in
                guard !newValue.isEmpty else { results = []; return }
                let q = newValue.lowercased()
                results = AppEntry.all.filter {
                    fuzzyMatch(q, in: $0.nameLower) ||
                    fuzzyMatch(q, in: $0.sectionLower) ||
                    fuzzyMatch(q, in: $0.tabLower) ||
                    (!$0.keywordsLower.isEmpty && $0.keywordsLower.contains(q))
                }
            }
            .navigationDestination(for: AppEntry.self) { entry in
                appDestination(for: entry)
            }
        }
    }
}

private extension String {
    var chipColor: Color {
        switch self {
        case "Components": return .blue
        case "Patterns":   return .purple
        case "Native":     return .mint
        case "More":       return .orange
        case "Explore":    return .indigo
        default:           return .secondary
        }
    }
}

// Both query and target must already be lowercased before calling.
private func fuzzyMatch(_ query: String, in lowerTarget: String) -> Bool {
    guard !query.isEmpty else { return true }
    var qi = query.startIndex
    for ch in lowerTarget {
        if qi == query.endIndex { break }
        if ch == query[qi] { qi = query.index(after: qi) }
    }
    return qi == query.endIndex
}

@ViewBuilder
func appDestination(for entry: AppEntry) -> some View {
    switch entry.name {
    case "Color":                  ColorReferenceView()
    case "Typography":             TypographyReferenceView()
    case "Spacing & Layout":       SpacingView()
    case "Buttons":                ButtonsView()
    case "Menus & Context Menus":  MenusView()
    case "Context Menus":          ContextMenusView()
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
    case "Swipeable Rows":         SwipeableRowsView()
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
    case "iOS 26 Glass":           GlassEffectPlayground()
    case "Material (blur)":        GlassPlayground()
    case "Surfaces":               SurfacesPlayground()
    case "Vibrancy":               VibrancyPlayground()
    case "Spring Physics":         SpringPhysicsView()
    case "Haptics":                HapticsView()
    case "Corner Radius":          CornerRadiusView()
    case "Concentric Radius":      ConcentricRadiusView()
    case "Shadow Explorer":        ShadowExplorerView()
    case "Blur Stack":             BlurStackView()
    case "Safe Areas":             SafeAreasView()
    case "Dynamic Type Scale":     DynamicTypeScaleView()
    case "Permission Requests":        PermissionRequestView()
    case "Permission Denied Recovery": PermissionDeniedRecoveryView()
    case "Push Notifications":         PushPermissionView()
    case "Camera Viewfinder":          CameraViewfinderView()
    case "Capture UI Patterns":        CaptureUIPatternView()
    case "Photo Picker":               PhotoPickerView()
    case "Photo Library Patterns":     PhotoLibraryPatternsView()
    case "Audio Recording":            AudioRecordingView()
    case "Waveform Visualization":     AudioWaveformView()
    case "Playback UI Patterns":       AudioPlaybackPatternsView()
    case "Map Basics":                 MapBasicsView()
    case "Map Annotations":            MapAnnotationsView()
    case "Map Overlays":               MapOverlaysView()
    case "Tap & Long Press":       TapLongPressView()
    case "Swipe & Drag":           SwipeDragView()
    case "Pinch & Zoom":           PinchZoomView()
    case "Rotation":               GestureRotationView()
    case "Transitions":            TransitionsView()
    case "Keyframe Animations":    KeyframeAnimationsView()
    case "Phase Animations":       PhaseAnimationsView()
    case "Symbol Effects":         SymbolEffectsView()
    case "Matched Geometry":       MatchedGeometryView()
    case "VoiceOver Labels":       VoiceOverLabelsView()
    case "Dynamic Type":           DynamicTypeExploreView()
    case "Reduce Motion":          ReduceMotionView()
    case "High Contrast":          HighContrastView()
    case "Share Sheet":            ShareSheetView()
    case "Face ID / Touch ID":     FaceIDView()
    case "Clipboard":              ClipboardView()
    case "Quick Look":             QuickLookView()
    case "Document Picker":        DocumentPickerView()
    case "Streaming Text":             StreamingTextView()
    case "Writing Tools Integration":  WritingToolsView()
    case "Image Generation":           ImageGenerationView()
    case "Prompt Input Patterns":      PromptInputView()
    default:                       SheetDetentsView()
    }
}

func componentDestination(for entry: AppEntry) -> some View {
    appDestination(for: entry)
}

#Preview {
    ComponentSearchView()
}
