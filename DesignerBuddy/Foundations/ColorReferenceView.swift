import SwiftUI

struct ColorReferenceView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var colorSchemeOverride: ColorScheme? = nil

    var body: some View {
        List {
            Section {
                Picker("Appearance", selection: $colorSchemeOverride) {
                    Text("System").tag(Optional<ColorScheme>.none)
                    Text("Light").tag(Optional<ColorScheme>(.light))
                    Text("Dark").tag(Optional<ColorScheme>(.dark))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            ForEach(ColorGroup.all) { group in
                Section(group.name) {
                    ForEach(group.colors) { item in
                        ColorRow(item: item)
                    }
                }
            }
        }
        .preferredColorScheme(colorSchemeOverride)
        .navigationTitle("Color")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ColorRow: View {
    let item: ColorItem

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(item.color)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
            Spacer()
            HStack(spacing: 6) {
                ColorSwatch(color: item.color, scheme: .dark)
                ColorSwatch(color: item.color, scheme: .light)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ColorSwatch: View {
    let color: Color
    let scheme: ColorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
            .environment(\.colorScheme, scheme)
    }
}

struct ColorItem: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct ColorGroup: Identifiable {
    let id = UUID()
    let name: String
    let colors: [ColorItem]

    static let all: [ColorGroup] = [
        ColorGroup(name: "Labels", colors: [
            ColorItem(name: "Label", color: Color(uiColor: .label)),
            ColorItem(name: "Secondary Label", color: Color(uiColor: .secondaryLabel)),
            ColorItem(name: "Tertiary Label", color: Color(uiColor: .tertiaryLabel)),
            ColorItem(name: "Quaternary Label", color: Color(uiColor: .quaternaryLabel)),
            ColorItem(name: "Placeholder Text", color: Color(uiColor: .placeholderText)),
        ]),
        ColorGroup(name: "Fills", colors: [
            ColorItem(name: "System Fill", color: Color(uiColor: .systemFill)),
            ColorItem(name: "Secondary Fill", color: Color(uiColor: .secondarySystemFill)),
            ColorItem(name: "Tertiary Fill", color: Color(uiColor: .tertiarySystemFill)),
            ColorItem(name: "Quaternary Fill", color: Color(uiColor: .quaternarySystemFill)),
        ]),
        ColorGroup(name: "Backgrounds", colors: [
            ColorItem(name: "System Background", color: Color(uiColor: .systemBackground)),
            ColorItem(name: "Secondary Background", color: Color(uiColor: .secondarySystemBackground)),
            ColorItem(name: "Tertiary Background", color: Color(uiColor: .tertiarySystemBackground)),
            ColorItem(name: "Grouped Background", color: Color(uiColor: .systemGroupedBackground)),
            ColorItem(name: "Secondary Grouped", color: Color(uiColor: .secondarySystemGroupedBackground)),
            ColorItem(name: "Tertiary Grouped", color: Color(uiColor: .tertiarySystemGroupedBackground)),
        ]),
        ColorGroup(name: "Separators", colors: [
            ColorItem(name: "Separator", color: Color(uiColor: .separator)),
            ColorItem(name: "Opaque Separator", color: Color(uiColor: .opaqueSeparator)),
        ]),
        ColorGroup(name: "System Colors", colors: [
            ColorItem(name: "Blue", color: Color(uiColor: .systemBlue)),
            ColorItem(name: "Green", color: Color(uiColor: .systemGreen)),
            ColorItem(name: "Indigo", color: Color(uiColor: .systemIndigo)),
            ColorItem(name: "Orange", color: Color(uiColor: .systemOrange)),
            ColorItem(name: "Pink", color: Color(uiColor: .systemPink)),
            ColorItem(name: "Purple", color: Color(uiColor: .systemPurple)),
            ColorItem(name: "Red", color: Color(uiColor: .systemRed)),
            ColorItem(name: "Teal", color: Color(uiColor: .systemTeal)),
            ColorItem(name: "Yellow", color: Color(uiColor: .systemYellow)),
            ColorItem(name: "Cyan", color: Color(uiColor: .systemCyan)),
            ColorItem(name: "Mint", color: Color(uiColor: .systemMint)),
            ColorItem(name: "Brown", color: Color(uiColor: .systemBrown)),
        ]),
        ColorGroup(name: "Gray Scale", colors: [
            ColorItem(name: "Gray", color: Color(uiColor: .systemGray)),
            ColorItem(name: "Gray 2", color: Color(uiColor: .systemGray2)),
            ColorItem(name: "Gray 3", color: Color(uiColor: .systemGray3)),
            ColorItem(name: "Gray 4", color: Color(uiColor: .systemGray4)),
            ColorItem(name: "Gray 5", color: Color(uiColor: .systemGray5)),
            ColorItem(name: "Gray 6", color: Color(uiColor: .systemGray6)),
        ]),
    ]
}

#Preview {
    NavigationStack {
        ColorReferenceView()
    }
}
