import SwiftUI

struct TogglesView: View {
    @State private var toggle1 = true
    @State private var toggle2 = false
    @State private var toggle3 = true

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
                Toggle("Blue (default tint)", isOn: $toggle1)
                Toggle("Green tint", isOn: $toggle2)
                    .tint(.green)
                Toggle("Orange tint", isOn: $toggle3)
                    .tint(.orange)
                Toggle("Red tint", isOn: $toggle1)
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
