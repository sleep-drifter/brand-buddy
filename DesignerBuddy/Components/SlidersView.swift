import SwiftUI

struct SlidersView: View {
    @State private var value = 40.0
    @State private var rangeMin = 0.0
    @State private var rangeMax = 100.0
    @State private var useStep = false
    @State private var stepSize = 5.0
    @State private var tint: Color = .blue
    @State private var volume = 60.0

    var body: some View {
        List {
            Section("Range") {
                LabeledContent("min: \(Int(rangeMin))") {
                    Slider(value: $rangeMin, in: 0...99)
                }
                .onChange(of: rangeMin) { _, newMin in
                    rangeMax = max(rangeMax, newMin + 1)
                    value = min(max(value, newMin), rangeMax)
                }
                LabeledContent("max: \(Int(rangeMax))") {
                    Slider(value: $rangeMax, in: 1...100)
                }
                .onChange(of: rangeMax) { _, newMax in
                    rangeMin = min(rangeMin, newMax - 1)
                    value = min(max(value, rangeMin), newMax)
                }
            }

            Section("Step") {
                Toggle("Stepped", isOn: $useStep.animation(.spring(duration: 0.3)))
                if useStep {
                    LabeledContent("step: \(Int(stepSize))") {
                        Slider(value: $stepSize, in: 1...25, step: 1)
                    }
                }
            }

            Section("Tint") {
                ColorPicker("Tint", selection: $tint, supportsOpacity: false)
            }

            Section("Value Labels") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $volume, in: 0...100) {
                        Text("Volume")
                    } minimumValueLabel: {
                        Image(systemName: "speaker")
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3")
                    }
                    Text("minimumValueLabel / maximumValueLabel accept any view. The Text label is hidden on iOS but read by VoiceOver.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .pinnedPreview {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .frame(height: 140)

                VStack(spacing: 14) {
                    Text(readout)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(tint)

                    demoSlider
                        .tint(tint)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle("Sliders")
        .navigationBarTitleDisplayMode(.large)
    }

    private var readout: String {
        useStep ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    @ViewBuilder
    private var demoSlider: some View {
        if useStep {
            Slider(value: $value, in: rangeMin...rangeMax, step: stepSize) {
                Text("Value")
            } minimumValueLabel: {
                boundLabel(rangeMin)
            } maximumValueLabel: {
                boundLabel(rangeMax)
            }
        } else {
            Slider(value: $value, in: rangeMin...rangeMax) {
                Text("Value")
            } minimumValueLabel: {
                boundLabel(rangeMin)
            } maximumValueLabel: {
                boundLabel(rangeMax)
            }
        }
    }

    private func boundLabel(_ bound: Double) -> some View {
        Text("\(Int(bound))")
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        SlidersView()
    }
}
