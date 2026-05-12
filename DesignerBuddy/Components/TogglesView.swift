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
                Toggle(isOn: $toggle3) {
                    Label("With icon", systemImage: "wifi")
                }
                Toggle("Disabled (on)", isOn: .constant(true))
                    .disabled(true)
                Toggle("Disabled (off)", isOn: .constant(false))
                    .disabled(true)
            }

            Section("Toggle Styles") {
                Toggle("Switch style (default)", isOn: $toggle1)
                    .toggleStyle(.switch)
                Toggle("Button style", isOn: $toggle2)
                    .toggleStyle(.button)
                Toggle("Checkbox style", isOn: $toggle3)
                    .toggleStyle(.checkbox)
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
