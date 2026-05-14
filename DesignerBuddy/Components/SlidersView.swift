import SwiftUI

struct SlidersView: View {
    @State private var value1 = 0.5
    @State private var value2 = 30.0
    @State private var value3 = 0.7
    @State private var stepped = 5.0

    var body: some View {
        List {
            Section("Default Slider") {
                Slider(value: $value1)
                Text("Value: \(value1, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("With Range & Step") {
                Slider(value: $value2, in: 0...100, step: 5) {
                    Text("Volume")
                } minimumValueLabel: {
                    Image(systemName: "speaker")
                } maximumValueLabel: {
                    Image(systemName: "speaker.wave.3")
                }
                Text("Value: \(Int(value2))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Tinted") {
                Slider(value: $value3)
                    .tint(.green)
                Slider(value: $value1)
                    .tint(.orange)
                Slider(value: $value2, in: 0...100)
                    .tint(.red)
            }

            Section("Stepped (0–10, step 1)") {
                Slider(value: $stepped, in: 0...10, step: 1)
                Text("Step: \(Int(stepped))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Sliders")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SlidersView()
    }
}
