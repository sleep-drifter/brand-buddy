import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Components", systemImage: "rectangle.3.group") {
                ComponentsTab()
            }
            Tab("Patterns", systemImage: "arrow.triangle.2.circlepath") {
                PatternsTab()
            }
            Tab("Native", systemImage: "cpu") {
                NativeTab()
            }
            Tab("Explore", systemImage: "safari") {
                ExploreTab()
            }

            Tab(role: .search) {
                ComponentSearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
