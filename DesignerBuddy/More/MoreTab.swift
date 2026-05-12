import SwiftUI

struct MoreTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Playgrounds") {
                    NavigationLink {
                        SpringPhysicsView()
                    } label: {
                        Label("Spring Physics", systemImage: "waveform.path.ecg")
                    }
                    NavigationLink {
                        HapticsView()
                    } label: {
                        Label("Haptics", systemImage: "hand.tap")
                    }
                    NavigationLink {
                        CornerRadiusView()
                    } label: {
                        Label("Corner Radius", systemImage: "square.on.square")
                    }
                    NavigationLink {
                        ShadowExplorerView()
                    } label: {
                        Label("Shadow Explorer", systemImage: "shadow")
                    }
                    NavigationLink {
                        BlurStackView()
                    } label: {
                        Label("Blur Stack", systemImage: "square.stack.3d.up")
                    }
                }

                Section("Reference") {
                    NavigationLink {
                        SafeAreasView()
                    } label: {
                        Label("Safe Areas", systemImage: "iphone")
                    }
                    NavigationLink {
                        DynamicTypeScaleView()
                    } label: {
                        Label("Dynamic Type Scale", systemImage: "textformat.size")
                    }
                    NavigationLink {
                        SheetDetentsView()
                    } label: {
                        Label("Sheet Detents", systemImage: "rectangle.bottomhalf.inset.filled")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreTab()
}
