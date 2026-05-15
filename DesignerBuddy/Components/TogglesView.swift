import SwiftUI

struct TogglesView: View {
    @State private var toggle1 = true
    @State private var toggle2 = false
    @State private var toggle3 = true
    @State private var tintedBlue = true
    @State private var tintedGreen = true
    @State private var tintedOrange = true
    @State private var tintedRed = true

    var body: some View {
        List {
            Section("Toggle (Switch)") {
                Toggle("Default toggle", isOn: $toggle1)
                Toggle("Off by default", isOn: $toggle2)
                Toggle("Disabled (on)", isOn: .constant(true))
                    .disabled(true)
                Toggle("Disabled (off)", isOn: .constant(false))
                    .disabled(true)
            }

            Section("Tinted Toggles") {
                Toggle("Blue (default tint)", isOn: $tintedBlue)
                Toggle("Green", isOn: $tintedGreen)
                    .tint(.green)
                Toggle("Orange", isOn: $tintedOrange)
                    .tint(.orange)
                Toggle("Red", isOn: $tintedRed)
                    .tint(.red)
            }
        }
        .navigationTitle("Toggles & Switches")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TogglesView()
    }
}
