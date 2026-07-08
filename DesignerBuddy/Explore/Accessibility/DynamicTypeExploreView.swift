import SwiftUI

struct DynamicTypeExploreView: View {
    @Environment(\.dynamicTypeSize) private var currentSize
    @State private var simulatedCategory: ContentSizeCategory = .large

    private let toolbarItems = [("square.and.arrow.up", "Share"), ("heart", "Like"), ("bookmark", "Save")]
    private let gridItems = ["Photos", "Videos", "Music", "Podcasts", "Books", "News"]

    private let allSizes: [DynamicTypeSize] = [
        .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
        .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5
    ]

    private let textStyles: [(name: String, style: Font.TextStyle)] = [
        ("Large Title", .largeTitle),
        ("Title 1", .title),
        ("Title 2", .title2),
        ("Title 3", .title3),
        ("Headline", .headline),
        ("Body", .body),
        ("Callout", .callout),
        ("Subheadline", .subheadline),
        ("Footnote", .footnote),
        ("Caption 1", .caption),
        ("Caption 2", .caption2),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Current system size
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Current System Size", systemImage: "textformat.size")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your device is set to:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(currentSize.label)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(currentSize.isAccessibilitySize ? .orange : .primary)
                        }
                        Spacer()
                        if currentSize.isAccessibilitySize {
                            Label("Accessibility size", systemImage: "accessibility")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }
                    }
                    Text("Change in Settings → Accessibility → Display & Text Size → Larger Text, or drag the slider in Control Center.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Type scale simulator
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Type Scale Simulator", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        Spacer()
                    }
                    Text("Simulate any size category and read the resulting point size per text style — independent of your device setting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Size category", selection: $simulatedCategory) {
                        ForEach(ContentSizeCategory.allAccessibilitySizes, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(spacing: 0) {
                        ForEach(textStyles, id: \.name) { entry in
                            HStack {
                                Text("Ag")
                                    .font(Font.system(entry.style))
                                    .environment(\.sizeCategory, simulatedCategory)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(entry.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(pointSize(for: entry.style, category: simulatedCategory))pt")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            if entry.name != textStyles.last?.name {
                                Divider().padding(.leading, 10)
                            }
                        }
                    }
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                    Text("Body text across all sizes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 16) {
                            ForEach(ContentSizeCategory.allAccessibilitySizes, id: \.self) { cat in
                                VStack(spacing: 6) {
                                    Text("Ag")
                                        .font(.body)
                                        .environment(\.sizeCategory, cat)
                                    Text(cat.shortLabel)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 36)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Type scale reference
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Type Scale Reference", systemImage: "list.number")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        ForEach(allSizes, id: \.self) { size in
                            HStack {
                                Text(size.label)
                                    .font(.caption2)
                                    .foregroundStyle(size == currentSize ? .primary : .secondary)
                                    .frame(width: 100, alignment: .leading)
                                Text("The quick brown fox")
                                    .dynamicTypeSize(size)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundStyle(size == currentSize ? .primary : .secondary)
                                Spacer()
                                if size == currentSize {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(size == currentSize ? Color.blue.opacity(0.08) : Color.clear)
                            if size != allSizes.last {
                                Divider().padding(.leading, 10)
                            }
                        }
                    }
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Truncation behavior
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Truncation & Wrapping", systemImage: "text.word.spacing")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 10) {
                        truncationRow(
                            label: "lineLimit(1)",
                            text: "This long label will be truncated at the end",
                            limit: 1
                        )
                        truncationRow(
                            label: "lineLimit(2)",
                            text: "This long label will wrap to a second line before truncating",
                            limit: 2
                        )
                        truncationRow(
                            label: "lineLimit(3)",
                            text: "This long label has three lines to work with before it truncates at the end of the third line",
                            limit: 3
                        )
                    }
                    Text("Use lineLimit(_:) to control wrapping. At accessibility sizes, prefer lineLimit(nil) or higher limits to avoid data loss.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Layout tip: ViewThatFits
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Layout Tip: ViewThatFits", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                            .font(.headline)
                        Spacer()
                    }
                    Text("ViewThatFits picks the first child that fits available space. These demos respond to your device's actual Dynamic Type setting.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Demo 1: HStack → VStack swap
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HStack → VStack swap")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .foregroundStyle(.blue)
                                Text("Sunset at the Beach")
                                    .lineLimit(1)
                                Spacer()
                                Button("Save") {}
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.blue)
                                    Text("Sunset at the Beach")
                                        .lineLimit(2)
                                }
                                Button("Save") {}
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        Text("Switches from HStack → VStack at large accessibility sizes")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Demo 2: Truncating label → multiline
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Badge: single-line → two-line")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ViewThatFits(in: .horizontal) {
                            // Compact: single line pill
                            Text("New Feature Available")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue, in: Capsule())
                                .fixedSize(horizontal: true, vertical: false)
                            // Fallback: two-line badge
                            Text("New Feature Available")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Badge switches from single-line pill to wrapped rectangle")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Demo 3: Toolbar icon+label → icon-only
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Toolbar: icon+label → icon-only")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            ForEach(toolbarItems, id: \.0) { icon, label in
                                ViewThatFits(in: .horizontal) {
                                    Button {} label: {
                                        Label(label, systemImage: icon)
                                            .labelStyle(.titleAndIcon)
                                            .font(.caption.weight(.medium))
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    Button {} label: {
                                        Image(systemName: icon)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            Spacer()
                        }
                        Text("Labels collapse to icon-only under space pressure")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Demo 4: 2-column grid → single column list
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Grid → list swap")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ViewThatFits(in: .vertical) {
                            // 2-column grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(gridItems, id: \.self) { item in
                                    Text(item)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            // Single column
                            VStack(spacing: 4) {
                                ForEach(gridItems, id: \.self) { item in
                                    Text(item)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                        .frame(maxHeight: 240)
                        Text("2-column grid collapses to single-column list at accessibility sizes")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Text("ViewThatFits picks the first child that fits in the specified axes. Combine it with .dynamicTypeSize(_:) overrides to test layouts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Dynamic Type")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func truncationRow(label: String, text: String, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .lineLimit(limit)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private func sampleBadge(color: Color, label: String) -> some View {
        Text(label)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color, in: Capsule())
    }

    private func pointSize(for style: Font.TextStyle, category: ContentSizeCategory) -> Int {
        let sizeTable: [ContentSizeCategory: [Font.TextStyle: CGFloat]] = [
            .extraSmall: [.largeTitle: 31, .title: 25, .title2: 19, .title3: 17, .headline: 13, .body: 14, .callout: 13, .subheadline: 12, .footnote: 12, .caption: 11, .caption2: 11],
            .small: [.largeTitle: 32, .title: 26, .title2: 20, .title3: 18, .headline: 14, .body: 15, .callout: 14, .subheadline: 13, .footnote: 12, .caption: 11, .caption2: 11],
            .medium: [.largeTitle: 33, .title: 27, .title2: 21, .title3: 19, .headline: 15, .body: 16, .callout: 15, .subheadline: 14, .footnote: 13, .caption: 12, .caption2: 11],
            .large: [.largeTitle: 34, .title: 28, .title2: 22, .title3: 20, .headline: 17, .body: 17, .callout: 16, .subheadline: 15, .footnote: 13, .caption: 12, .caption2: 11],
            .extraLarge: [.largeTitle: 36, .title: 30, .title2: 24, .title3: 22, .headline: 19, .body: 19, .callout: 18, .subheadline: 17, .footnote: 15, .caption: 14, .caption2: 13],
            .extraExtraLarge: [.largeTitle: 38, .title: 32, .title2: 26, .title3: 24, .headline: 21, .body: 21, .callout: 20, .subheadline: 19, .footnote: 17, .caption: 16, .caption2: 15],
            .extraExtraExtraLarge: [.largeTitle: 40, .title: 34, .title2: 28, .title3: 26, .headline: 23, .body: 23, .callout: 22, .subheadline: 21, .footnote: 19, .caption: 18, .caption2: 17],
            .accessibilityMedium: [.largeTitle: 44, .title: 38, .title2: 34, .title3: 31, .headline: 28, .body: 28, .callout: 26, .subheadline: 25, .footnote: 23, .caption: 22, .caption2: 20],
            .accessibilityLarge: [.largeTitle: 48, .title: 43, .title2: 39, .title3: 37, .headline: 33, .body: 33, .callout: 32, .subheadline: 30, .footnote: 27, .caption: 26, .caption2: 24],
            .accessibilityExtraLarge: [.largeTitle: 52, .title: 48, .title2: 44, .title3: 43, .headline: 40, .body: 40, .callout: 38, .subheadline: 36, .footnote: 33, .caption: 32, .caption2: 29],
            .accessibilityExtraExtraLarge: [.largeTitle: 56, .title: 53, .title2: 50, .title3: 50, .headline: 47, .body: 47, .callout: 44, .subheadline: 42, .footnote: 38, .caption: 37, .caption2: 34],
            .accessibilityExtraExtraExtraLarge: [.largeTitle: 60, .title: 58, .title2: 56, .title3: 56, .headline: 53, .body: 53, .callout: 51, .subheadline: 49, .footnote: 44, .caption: 43, .caption2: 40],
        ]
        return Int(sizeTable[category]?[style] ?? 17)
    }
}

// MARK: - ContentSizeCategory helpers (shared with the Dynamic Type simulator)

extension ContentSizeCategory {
    var label: String {
        switch self {
        case .extraSmall: return "xSmall"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (default)"
        case .extraLarge: return "xLarge"
        case .extraExtraLarge: return "xxLarge"
        case .extraExtraExtraLarge: return "xxxLarge"
        case .accessibilityMedium: return "A11y Medium"
        case .accessibilityLarge: return "A11y Large"
        case .accessibilityExtraLarge: return "A11y xLarge"
        case .accessibilityExtraExtraLarge: return "A11y xxLarge"
        case .accessibilityExtraExtraExtraLarge: return "A11y xxxLarge"
        @unknown default: return "Unknown"
        }
    }

    var shortLabel: String {
        switch self {
        case .extraSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        case .extraExtraLarge: return "XXL"
        case .extraExtraExtraLarge: return "XXXL"
        case .accessibilityMedium: return "aM"
        case .accessibilityLarge: return "aL"
        case .accessibilityExtraLarge: return "aXL"
        case .accessibilityExtraExtraLarge: return "aXXL"
        case .accessibilityExtraExtraExtraLarge: return "aXXXL"
        @unknown default: return "?"
        }
    }

    static let allAccessibilitySizes: [ContentSizeCategory] = [
        .extraSmall, .small, .medium, .large, .extraLarge,
        .extraExtraLarge, .extraExtraExtraLarge,
        .accessibilityMedium, .accessibilityLarge,
        .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge,
    ]
}

// MARK: - DynamicTypeSize helpers

private extension DynamicTypeSize {
    var label: String {
        switch self {
        case .xSmall:        return "xSmall"
        case .small:         return "Small"
        case .medium:        return "Medium"
        case .large:         return "Large (default)"
        case .xLarge:        return "xLarge"
        case .xxLarge:       return "xxLarge"
        case .xxxLarge:      return "xxxLarge"
        case .accessibility1: return "A1"
        case .accessibility2: return "A2"
        case .accessibility3: return "A3"
        case .accessibility4: return "A4"
        case .accessibility5: return "A5"
        @unknown default:    return "Unknown"
        }
    }
}

#Preview {
    NavigationStack { DynamicTypeExploreView() }
}
