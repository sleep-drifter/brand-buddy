import SwiftUI

// MARK: - Explore Tab

struct ExploreTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Gestures") {
                    ExploreComingSoonRow(name: "Tap & Long Press", icon: "hand.tap")
                    ExploreComingSoonRow(name: "Swipe & Drag", icon: "hand.draw")
                    ExploreComingSoonRow(name: "Pinch & Zoom", icon: "arrow.up.left.and.arrow.down.right")
                    ExploreComingSoonRow(name: "Rotation", icon: "arrow.clockwise")
                }

                Section("Animations") {
                    ExploreComingSoonRow(name: "Transitions", icon: "arrow.left.arrow.right.square")
                    ExploreComingSoonRow(name: "Keyframe Animations", icon: "timeline.selection")
                    ExploreComingSoonRow(name: "Phase Animations", icon: "waveform.path")
                    ExploreComingSoonRow(name: "Symbol Effects", icon: "sparkle")
                    ExploreComingSoonRow(name: "Matched Geometry", icon: "rectangle.on.rectangle.angled")
                }

                Section("Accessibility") {
                    ExploreComingSoonRow(name: "VoiceOver Labels", icon: "accessibility")
                    ExploreComingSoonRow(name: "Dynamic Type", icon: "textformat.size")
                    ExploreComingSoonRow(name: "Reduce Motion", icon: "hand.raised")
                    ExploreComingSoonRow(name: "High Contrast", icon: "circle.lefthalf.filled")
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
