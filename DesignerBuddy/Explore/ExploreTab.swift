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
                    NavigationLink { SymbolPlaygroundView() } label: {
                        Label("Symbol Playground", systemImage: "theatermask.and.paintbrush")
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
                    NavigationLink { ShareSheetView() } label: {
                        Label("Share Sheet", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink { FaceIDView() } label: {
                        Label("Face ID / Touch ID", systemImage: "faceid")
                    }
                    NavigationLink { ClipboardView() } label: {
                        Label("Clipboard", systemImage: "doc.on.clipboard")
                    }
                    NavigationLink { QuickLookView() } label: {
                        Label("Quick Look", systemImage: "eye")
                    }
                    NavigationLink { DocumentPickerView() } label: {
                        Label("Document Picker", systemImage: "folder")
                    }
                }

                Section("AI & Generation") {
                    NavigationLink { StreamingTextView() } label: {
                        Label("Streaming Text", systemImage: "ellipsis.message")
                    }
                    NavigationLink { WritingToolsView() } label: {
                        Label("Writing Tools Integration", systemImage: "pencil.and.sparkles")
                    }
                    NavigationLink { ImageGenerationView() } label: {
                        Label("Image Generation", systemImage: "photo.badge.plus")
                    }
                    NavigationLink { PromptInputView() } label: {
                        Label("Prompt Input Patterns", systemImage: "text.bubble")
                    }
                }

                Section("Device & Sensors") {
                    NavigationLink { CustomHapticsView() } label: {
                        Label("Custom Haptics", systemImage: "waveform.path.ecg.rectangle")
                    }
                    NavigationLink { AccelerometerView() } label: {
                        Label("Accelerometer & Gyroscope", systemImage: "gyroscope")
                    }
                    NavigationLink { BarometerView() } label: {
                        Label("Barometer", systemImage: "thermometer.medium")
                    }
                    NavigationLink { ProximityLightView() } label: {
                        Label("Proximity & Ambient Light", systemImage: "light.max")
                    }
                    NavigationLink { BatteryStateView() } label: {
                        Label("Battery State", systemImage: "battery.75percent")
                    }
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
