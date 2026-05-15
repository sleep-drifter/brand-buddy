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
            Tab("Materials", systemImage: "bubbles.and.sparkles") {
                MaterialsTab()
            }
            Tab("Explore", systemImage: "sparkles") {
                ExploreTab()
            }
            Tab("More", systemImage: "ellipsis.circle") {
                MoreTab()
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
