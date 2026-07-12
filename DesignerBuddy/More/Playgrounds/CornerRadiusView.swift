import SwiftUI

struct CornerRadiusView: View {
    @State private var radius: CGFloat = 16
    @State private var showBothStyles = true
    @State private var shapeSize: CGFloat = 120
    @State private var showGrid = true

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    // Live comparison
                    if showBothStyles {
                        HStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Rectangle()
                                    .fill(.tint)
                                    .frame(width: shapeSize, height: shapeSize)
                                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                                Text(".continuous")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 8) {
                                Rectangle()
                                    .fill(.tint.opacity(0.6))
                                    .frame(width: shapeSize, height: shapeSize)
                                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .circular))
                                Text(".circular")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                    } else {
                        Rectangle()
                            .fill(.tint)
                            .frame(width: shapeSize, height: shapeSize)
                            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                            .padding(.vertical, 12)
                    }

                    Text("radius: \(Int(radius))pt")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                LabeledContent("Corner Radius: \(Int(radius))") {
                    Slider(value: $radius, in: 0...shapeSize / 2)
                }
                LabeledContent("Shape Size: \(Int(shapeSize))") {
                    Slider(value: $shapeSize, in: 60...160)
                }
                Toggle("Compare both styles", isOn: $showBothStyles)
            }

            Section("iOS Standard Radii") {
                ForEach(StandardRadius.all) { item in
                    Button {
                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                            radius = item.value
                        }
                    } label: {
                        HStack {
                            RoundedRectangle(cornerRadius: item.value / 120 * 32, style: .continuous)
                                .fill(.tint.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: item.value / 120 * 32, style: .continuous)
                                        .strokeBorder(.tint, lineWidth: 1)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline).foregroundStyle(.primary)
                                Text("\(Int(item.value))pt — \(item.usage)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if Int(radius) == Int(item.value) {
                                Image(systemName: "checkmark").foregroundStyle(.tint).font(.caption)
                            }
                        }
                    }
                }
            }

            Section("Continuous vs Circular") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(".continuous (squircle)")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("The curve starts earlier and ends later, creating a smoother transition from straight to curved. Used by Apple for all system UI since iOS 13: app icons, widgets, cards.")
                        .font(.caption).foregroundStyle(.secondary)

                    Divider()

                    Text(".circular (classic)")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("A standard circular arc clamped to the corner. The corner feels more distinct. Used in some legacy contexts and by Android.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Corner Radius")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StandardRadius: Identifiable {
    let id = UUID()
    let name: String
    let value: CGFloat
    let usage: String

    static let all: [StandardRadius] = [
        StandardRadius(name: "None", value: 0, usage: "Full bleed, edge-to-edge"),
        StandardRadius(name: "XS", value: 4, usage: "Chips, inline tags"),
        StandardRadius(name: "Small", value: 8, usage: "Buttons (compact), thumbnails"),
        StandardRadius(name: "Medium", value: 12, usage: "List row insets, small cards"),
        StandardRadius(name: "Large", value: 16, usage: "Cards, sheets, modals"),
        StandardRadius(name: "XL", value: 20, usage: "Large cards, bottom sheets"),
        StandardRadius(name: "2XL", value: 24, usage: "Full-width containers"),
        StandardRadius(name: "App Icon", value: 27, usage: "iOS app icon (120pt size)"),
        StandardRadius(name: "Pill", value: 999, usage: "Capsule / fully rounded"),
    ]
}

#Preview {
    NavigationStack {
        CornerRadiusView()
    }
}
