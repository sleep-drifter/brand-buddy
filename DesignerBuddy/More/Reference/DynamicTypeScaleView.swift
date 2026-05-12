import SwiftUI

struct DynamicTypeScaleView: View {
    @State private var selectedCategory: ContentSizeCategory = .large
    @State private var showAllCategories = false

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
        List {
            Section {
                Toggle("Show all size categories at once", isOn: $showAllCategories)
            }

            if showAllCategories {
                allCategoriesView
            } else {
                Section("Size Category") {
                    Picker("Size", selection: $selectedCategory) {
                        ForEach(ContentSizeCategory.allAccessibilitySizes, id: \.self) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }

                Section("Type Scale at \(selectedCategory.label)") {
                    ForEach(textStyles, id: \.name) { entry in
                        HStack {
                            Text("Ag")
                                .font(Font.system(entry.style))
                                .environment(\.sizeCategory, selectedCategory)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(entry.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(pointSize(for: entry.style, category: selectedCategory))pt")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Dynamic Type Scale")
        .navigationBarTitleDisplayMode(.large)
    }

    var allCategoriesView: some View {
        Section("Body text across all sizes") {
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
    }

    func pointSize(for style: Font.TextStyle, category: ContentSizeCategory) -> Int {
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

#Preview {
    NavigationStack {
        DynamicTypeScaleView()
    }
}
