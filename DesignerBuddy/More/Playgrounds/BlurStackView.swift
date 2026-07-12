import SwiftUI

struct BlurStackView: View {
    @State private var layer1Radius: CGFloat = 10
    @State private var layer2Radius: CGFloat = 20
    @State private var layer3Radius: CGFloat = 40
    @State private var layer1Opacity: Double = 1
    @State private var layer2Opacity: Double = 1
    @State private var layer3Opacity: Double = 1
    @State private var showLayer2 = true
    @State private var showLayer3 = true
    @State private var selectedBackground: Int = 0

    private let backgrounds = ["Gradient", "Mesh", "Blobs"]

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        backgroundContent
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // Layer 3 (bottom)
                        if showLayer3 {
                            blurLayer(
                                radius: layer3Radius,
                                opacity: layer3Opacity,
                                size: CGSize(width: 220, height: 180),
                                cornerRadius: 20,
                                label: "Layer 3 (back)"
                            )
                            .offset(x: 0, y: 8)
                        }

                        // Layer 2 (middle)
                        if showLayer2 {
                            blurLayer(
                                radius: layer2Radius,
                                opacity: layer2Opacity,
                                size: CGSize(width: 180, height: 140),
                                cornerRadius: 16,
                                label: "Layer 2"
                            )
                            .offset(x: 0, y: 0)
                        }

                        // Layer 1 (front)
                        blurLayer(
                            radius: layer1Radius,
                            opacity: layer1Opacity,
                            size: CGSize(width: 140, height: 100),
                            cornerRadius: 12,
                            label: "Layer 1 (front)"
                        )
                        .offset(x: 0, y: -8)
                    }

                    Text("Blur layers do NOT compound — each blurs the content beneath it independently.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Background") {
                Picker("Background", selection: $selectedBackground) {
                    ForEach(Array(backgrounds.enumerated()), id: \.offset) { i, name in
                        Text(name).tag(i)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Layer 1 (front, always visible)") {
                LabeledContent("blur: \(Int(layer1Radius))") {
                    Slider(value: $layer1Radius, in: 0...80)
                }
                LabeledContent("opacity: \(layer1Opacity, specifier: "%.1f")") {
                    Slider(value: $layer1Opacity, in: 0...1)
                }
            }

            Section("Layer 2") {
                Toggle("Show Layer 2", isOn: $showLayer2)
                if showLayer2 {
                    LabeledContent("blur: \(Int(layer2Radius))") {
                        Slider(value: $layer2Radius, in: 0...80)
                    }
                    LabeledContent("opacity: \(layer2Opacity, specifier: "%.1f")") {
                        Slider(value: $layer2Opacity, in: 0...1)
                    }
                }
            }

            Section("Layer 3 (back)") {
                Toggle("Show Layer 3", isOn: $showLayer3)
                if showLayer3 {
                    LabeledContent("blur: \(Int(layer3Radius))") {
                        Slider(value: $layer3Radius, in: 0...80)
                    }
                    LabeledContent("opacity: \(layer3Opacity, specifier: "%.1f")") {
                        Slider(value: $layer3Opacity, in: 0...1)
                    }
                }
            }

            Section("Notes") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("iOS materials (.ultraThinMaterial etc.) use a live blur of the content directly behind the layer, not a static blur. Each material layer independently blurs whatever is behind it in the compositing stack.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("For glass effects in iOS 26, the system applies specular highlights and tinting on top of the blur to simulate liquid glass.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Blur Stack")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    var backgroundContent: some View {
        switch selectedBackground {
        case 1:
            Rectangle()
                .fill(
                    MeshGradient(
                        width: 3, height: 3,
                        points: [[0,0],[0.5,0],[1,0],[0,0.5],[0.5,0.5],[1,0.5],[0,1],[0.5,1],[1,1]],
                        colors: [.red,.orange,.yellow,.purple,.pink,.orange,.blue,.cyan,.green]
                    )
                )
        case 2:
            BlobBackground()
        default:
            LinearGradient(
                colors: [.indigo, .purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    func blurLayer(radius: CGFloat, opacity: Double, size: CGSize, cornerRadius: CGFloat, label: String) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .blur(radius: 0)
            .frame(width: size.width, height: size.height)
            .opacity(opacity)
            .overlay(
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
            )
    }
}

#Preview {
    NavigationStack {
        BlurStackView()
    }
}
