import SwiftUI

struct ColorReferenceView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            ForEach(ColorGroup.all) { group in
                Section(group.name) {
                    ForEach(group.colors) { item in
                        ColorRow(item: item)
                    }
                }
            }
        }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(item.token)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ColorItem: Identifiable {
    let id = UUID()
    let name: String
    let token: String
    let color: Color
}

struct ColorGroup: Identifiable {
    let id = UUID()
    let name: String
    let colors: [ColorItem]

    static let all: [ColorGroup] = [
        ColorGroup(name: "Labels", colors: [
            ColorItem(name: "Label", token: ".label", color: Color(uiColor: .label)),
            ColorItem(name: "Secondary Label", token: ".secondaryLabel", color: Color(uiColor: .secondaryLabel)),
            ColorItem(name: "Tertiary Label", token: ".tertiaryLabel", color: Color(uiColor: .tertiaryLabel)),
            ColorItem(name: "Quaternary Label", token: ".quaternaryLabel", color: Color(uiColor: .quaternaryLabel)),
            ColorItem(name: "Placeholder Text", token: ".placeholderText", color: Color(uiColor: .placeholderText)),
        ]),
        ColorGroup(name: "Fills", colors: [
            ColorItem(name: "System Fill", token: ".systemFill", color: Color(uiColor: .systemFill)),
            ColorItem(name: "Secondary Fill", token: ".secondarySystemFill", color: Color(uiColor: .secondarySystemFill)),
            ColorItem(name: "Tertiary Fill", token: ".tertiarySystemFill", color: Color(uiColor: .tertiarySystemFill)),
            ColorItem(name: "Quaternary Fill", token: ".quaternarySystemFill", color: Color(uiColor: .quaternarySystemFill)),
        ]),
        ColorGroup(name: "Backgrounds", colors: [
            ColorItem(name: "System Background", token: ".systemBackground", color: Color(uiColor: .systemBackground)),
            ColorItem(name: "Secondary Background", token: ".secondarySystemBackground", color: Color(uiColor: .secondarySystemBackground)),
            ColorItem(name: "Tertiary Background", token: ".tertiarySystemBackground", color: Color(uiColor: .tertiarySystemBackground)),
            ColorItem(name: "Grouped Background", token: ".systemGroupedBackground", color: Color(uiColor: .systemGroupedBackground)),
            ColorItem(name: "Secondary Grouped", token: ".secondarySystemGroupedBackground", color: Color(uiColor: .secondarySystemGroupedBackground)),
            ColorItem(name: "Tertiary Grouped", token: ".tertiarySystemGroupedBackground", color: Color(uiColor: .tertiarySystemGroupedBackground)),
        ]),
        ColorGroup(name: "Separators", colors: [
            ColorItem(name: "Separator", token: ".separator", color: Color(uiColor: .separator)),
            ColorItem(name: "Opaque Separator", token: ".opaqueSeparator", color: Color(uiColor: .opaqueSeparator)),
        ]),
        ColorGroup(name: "System Colors", colors: [
            ColorItem(name: "Blue", token: ".systemBlue", color: Color(uiColor: .systemBlue)),
            ColorItem(name: "Green", token: ".systemGreen", color: Color(uiColor: .systemGreen)),
            ColorItem(name: "Indigo", token: ".systemIndigo", color: Color(uiColor: .systemIndigo)),
            ColorItem(name: "Orange", token: ".systemOrange", color: Color(uiColor: .systemOrange)),
            ColorItem(name: "Pink", token: ".systemPink", color: Color(uiColor: .systemPink)),
            ColorItem(name: "Purple", token: ".systemPurple", color: Color(uiColor: .systemPurple)),
            ColorItem(name: "Red", token: ".systemRed", color: Color(uiColor: .systemRed)),
            ColorItem(name: "Teal", token: ".systemTeal", color: Color(uiColor: .systemTeal)),
            ColorItem(name: "Yellow", token: ".systemYellow", color: Color(uiColor: .systemYellow)),
            ColorItem(name: "Cyan", token: ".systemCyan", color: Color(uiColor: .systemCyan)),
            ColorItem(name: "Mint", token: ".systemMint", color: Color(uiColor: .systemMint)),
            ColorItem(name: "Brown", token: ".systemBrown", color: Color(uiColor: .systemBrown)),
        ]),
        ColorGroup(name: "Gray Scale", colors: [
            ColorItem(name: "Gray", token: ".systemGray", color: Color(uiColor: .systemGray)),
            ColorItem(name: "Gray 2", token: ".systemGray2", color: Color(uiColor: .systemGray2)),
            ColorItem(name: "Gray 3", token: ".systemGray3", color: Color(uiColor: .systemGray3)),
            ColorItem(name: "Gray 4", token: ".systemGray4", color: Color(uiColor: .systemGray4)),
            ColorItem(name: "Gray 5", token: ".systemGray5", color: Color(uiColor: .systemGray5)),
            ColorItem(name: "Gray 6", token: ".systemGray6", color: Color(uiColor: .systemGray6)),
        ]),
    ]
}

#Preview {
    NavigationStack {
        ColorReferenceView()
    }
}
