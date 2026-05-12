import SwiftUI

struct TypographyReferenceView: View {
    @State private var showMonospaced = false
    @State private var showSizeInfo = true

    private let styles: [(name: String, style: Font.TextStyle, uiStyle: UIFont.TextStyle)] = [
        ("Large Title", .largeTitle, .largeTitle),
        ("Title 1", .title, .title1),
        ("Title 2", .title2, .title2),
        ("Title 3", .title3, .title3),
        ("Headline", .headline, .headline),
        ("Body", .body, .body),
        ("Callout", .callout, .callout),
        ("Subheadline", .subheadline, .subheadline),
        ("Footnote", .footnote, .footnote),
        ("Caption 1", .caption, .caption1),
        ("Caption 2", .caption2, .caption2),
    ]

    var body: some View {
        List {
            Section {
                Toggle("Show size info", isOn: $showSizeInfo)
                Toggle("Monospaced", isOn: $showMonospaced)
            }

            Section("Dynamic Type Styles") {
                ForEach(styles, id: \.name) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The quick brown fox")
                            .font(
                                showMonospaced
                                    ? Font.system(entry.style).monospaced()
                                    : Font.system(entry.style)
                            )
                        if showSizeInfo {
                            HStack(spacing: 8) {
                                Text(entry.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fontDesign(.monospaced)
                                Spacer()
                                Text("\(Int(UIFont.preferredFont(forTextStyle: entry.uiStyle).pointSize))pt")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fontDesign(.monospaced)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("Weight Scale") {
                ForEach(FontWeightItem.all) { item in
                    HStack {
                        Text("Ag")
                            .font(.title2)
                            .fontWeight(item.weight)
                        Spacer()
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)
                    }
                }
            }

            Section("Font Design") {
                ForEach(FontDesignItem.all) { item in
                    HStack {
                        Text("The quick brown fox jumps")
                            .font(.body)
                            .fontDesign(item.design)
                        Spacer()
                        Text(item.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontDesign(.monospaced)
                    }
                }
            }
        }
        .navigationTitle("Typography")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct FontWeightItem: Identifiable {
    let id = UUID()
    let name: String
    let weight: Font.Weight

    static let all: [FontWeightItem] = [
        FontWeightItem(name: ".ultraLight", weight: .ultraLight),
        FontWeightItem(name: ".thin", weight: .thin),
        FontWeightItem(name: ".light", weight: .light),
        FontWeightItem(name: ".regular", weight: .regular),
        FontWeightItem(name: ".medium", weight: .medium),
        FontWeightItem(name: ".semibold", weight: .semibold),
        FontWeightItem(name: ".bold", weight: .bold),
        FontWeightItem(name: ".heavy", weight: .heavy),
        FontWeightItem(name: ".black", weight: .black),
    ]
}

struct FontDesignItem: Identifiable {
    let id = UUID()
    let name: String
    let design: Font.Design

    static let all: [FontDesignItem] = [
        FontDesignItem(name: ".default", design: .default),
        FontDesignItem(name: ".rounded", design: .rounded),
        FontDesignItem(name: ".serif", design: .serif),
        FontDesignItem(name: ".monospaced", design: .monospaced),
    ]
}

#Preview {
    NavigationStack {
        TypographyReferenceView()
    }
}
