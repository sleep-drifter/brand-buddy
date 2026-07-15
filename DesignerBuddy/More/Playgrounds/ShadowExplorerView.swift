import SwiftUI

struct ShadowExplorerView: View {
    @State private var radius: CGFloat = 16
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 8
    @State private var opacity: Double = 0.2
    @State private var shadowColor = Color.black
    @State private var cardColor = Color.white
    @State private var cornerRadius: CGFloat = 16
    @State private var bgIndex = 0
    @State private var selectedPreset: String?

    private let backgrounds: [(String, Color)] = [
        ("White", .white),
        ("Light Gray", Color(.systemGroupedBackground)),
        ("Dark", .black),
        ("Blue", .blue.opacity(0.15)),
    ]

    var body: some View {
        List {
            Section("Code") {
                Text(".shadow(\n  color: \(shadowColor == .black ? ".black" : "color").opacity(\(opacity, specifier: "%.2f")),\n  radius: \(Int(radius)),\n  x: \(Int(x)), y: \(Int(y))\n)")
                    .font(.mono(.caption))
                    .foregroundStyle(.secondary)
            }

            Section("Shadow") {
                LabeledContent("radius: \(Int(radius))") {
                    Slider(value: $radius, in: 0...60)
                }
                LabeledContent("x: \(Int(x))") {
                    Slider(value: $x, in: -40...40)
                }
                LabeledContent("y: \(Int(y))") {
                    Slider(value: $y, in: -40...40)
                }
                LabeledContent("opacity: \(opacity, specifier: "%.2f")") {
                    Slider(value: $opacity, in: 0...1)
                }
                ColorPicker("Shadow color", selection: $shadowColor, supportsOpacity: false)
            }

            Section("Card") {
                LabeledContent("cornerRadius: \(Int(cornerRadius))") {
                    Slider(value: $cornerRadius, in: 0...48)
                }
                ColorPicker("Card color", selection: $cardColor, supportsOpacity: false)
            }

            Section("Background") {
                Picker("Background", selection: $bgIndex) {
                    ForEach(Array(backgrounds.enumerated()), id: \.offset) { i, bg in
                        Text(bg.0).tag(i)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Presets") {
                PresetChipRow(
                    chips: ShadowPreset.all.map { preset in
                        PresetChip(
                            name: preset.name,
                            detail: preset.description,
                            code: "radius: \(Int(preset.radius)), x: \(Int(preset.x)), y: \(Int(preset.y)), opacity: \(String(format: "%.2f", preset.opacity))"
                        )
                    },
                    selectedID: $selectedPreset
                ) { chip in
                    guard let preset = ShadowPreset.all.first(where: { $0.name == chip.name }) else { return }
                    withAnimation(.spring(duration: 0.3)) {
                        radius = preset.radius
                        x = preset.x
                        y = preset.y
                        opacity = preset.opacity
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .pinnedPreview(entry: "Shadow Explorer") {
            ZStack {
                backgrounds[bgIndex].1
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(cardColor)
                    .frame(width: 140, height: 90)
                    .shadow(
                        color: shadowColor.opacity(opacity),
                        radius: radius,
                        x: x,
                        y: y
                    )
                    .overlay(
                        Text("Card")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .navigationTitle("Shadow Explorer")
    }
}

struct ShadowPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double

    static let all: [ShadowPreset] = [
        ShadowPreset(name: "None", description: "Flat design, no elevation", radius: 0, x: 0, y: 0, opacity: 0),
        ShadowPreset(name: "Hairline", description: "Subtle separation, cards on white", radius: 1, x: 0, y: 1, opacity: 0.1),
        ShadowPreset(name: "Small", description: "Cards, form fields", radius: 4, x: 0, y: 2, opacity: 0.12),
        ShadowPreset(name: "Medium", description: "Dropdowns, menus", radius: 8, x: 0, y: 4, opacity: 0.15),
        ShadowPreset(name: "Large", description: "Sheets, modals", radius: 16, x: 0, y: 8, opacity: 0.20),
        ShadowPreset(name: "Elevated", description: "Floating elements, FABs", radius: 24, x: 0, y: 12, opacity: 0.25),
        ShadowPreset(name: "Directional", description: "Dramatic side lighting", radius: 12, x: 8, y: 4, opacity: 0.18),
        ShadowPreset(name: "Deep", description: "High contrast, marketing", radius: 40, x: 0, y: 20, opacity: 0.35),
    ]
}

#Preview {
    NavigationStack {
        ShadowExplorerView()
    }
    .environmentObject(PinsStore())
}
