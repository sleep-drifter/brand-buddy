import SwiftUI

struct FoundationsTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Visual") {
                    NavigationLink("Color") { ColorReferenceView() }
                    NavigationLink("Typography") { TypographyReferenceView() }
                    NavigationLink("Icons & SF Symbols") { SFSymbolsView() }
                }
                Section("Layout") {
                    NavigationLink("Spacing & Grid") { SpacingView() }
                    NavigationLink("Layout Primitives") { LayoutPrimitivesView() }
                }
                Section("Motion") {
                    NavigationLink("Animation Curves") { AnimationCurvesView() }
                }
            }
            .navigationTitle("Foundations")
        }
    }
}

#Preview {
    FoundationsTab()
}
