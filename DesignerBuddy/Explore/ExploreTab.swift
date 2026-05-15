import SwiftUI

// MARK: - Explore Tab

struct ExploreTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Gestures") {
                    NavigationLink { TapLongPressView() } label: {
                        Label("Tap & Long Press", systemImage: "hand.tap")
                    }
                    NavigationLink { SwipeDragView() } label: {
                        Label("Swipe & Drag", systemImage: "hand.draw")
                    }
                    NavigationLink { PinchZoomView() } label: {
                        Label("Pinch & Zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    NavigationLink { GestureRotationView() } label: {
                        Label("Rotation", systemImage: "arrow.clockwise")
                    }
                }

                Section("Animations") {
                    NavigationLink { TransitionsView() } label: {
                        Label("Transitions", systemImage: "arrow.left.arrow.right.square")
                    }
                    NavigationLink { KeyframeAnimationsView() } label: {
                        Label("Keyframe Animations", systemImage: "timeline.selection")
                    }
                    NavigationLink { PhaseAnimationsView() } label: {
                        Label("Phase Animations", systemImage: "waveform.path")
                    }
                    NavigationLink { SymbolEffectsView() } label: {
                        Label("Symbol Effects", systemImage: "sparkle")
                    }
                    NavigationLink { MatchedGeometryView() } label: {
                        Label("Matched Geometry", systemImage: "rectangle.on.rectangle.angled")
                    }
                }

                Section("Accessibility") {
                    NavigationLink { VoiceOverLabelsView() } label: {
                        Label("VoiceOver Labels", systemImage: "accessibility")
                    }
                    NavigationLink { DynamicTypeExploreView() } label: {
                        Label("Dynamic Type", systemImage: "textformat.size")
                    }
                    NavigationLink { ReduceMotionView() } label: {
                        Label("Reduce Motion", systemImage: "hand.raised")
                    }
                    NavigationLink { HighContrastView() } label: {
                        Label("High Contrast", systemImage: "circle.lefthalf.filled")
                    }
                }

                Section("System Integrations") {
                    ExploreComingSoonRow(name: "Share Sheet", icon: "square.and.arrow.up")
                    ExploreComingSoonRow(name: "Face ID / Touch ID", icon: "faceid")
                    ExploreComingSoonRow(name: "Clipboard", icon: "doc.on.clipboard")
                    ExploreComingSoonRow(name: "Quick Look", icon: "eye")
                    ExploreComingSoonRow(name: "Document Picker", icon: "folder")
                }

                Section("AI & Generation") {
                    ExploreComingSoonRow(name: "Streaming Text", icon: "ellipsis.message")
                    ExploreComingSoonRow(name: "Writing Tools Integration", icon: "pencil.and.sparkles")
                    ExploreComingSoonRow(name: "Image Generation", icon: "photo.badge.plus")
                    ExploreComingSoonRow(name: "Prompt Input Patterns", icon: "text.bubble")
                }

                Section("Device & Sensors") {
                    ExploreComingSoonRow(name: "Custom Haptics", icon: "waveform.path.ecg.rectangle")
                    ExploreComingSoonRow(name: "Accelerometer & Gyroscope", icon: "gyroscope")
                    ExploreComingSoonRow(name: "Barometer", icon: "thermometer.medium")
                    ExploreComingSoonRow(name: "Proximity & Ambient Light", icon: "light.max")
                    ExploreComingSoonRow(name: "Battery State", icon: "battery.75percent")
                }
            }
            .navigationTitle("Explore")
        }
    }
}

// MARK: - Coming Soon Row

private struct ExploreComingSoonRow: View {
    let name: String
    let icon: String

    var body: some View {
        Label(name, systemImage: icon)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    ExploreTab()
}
