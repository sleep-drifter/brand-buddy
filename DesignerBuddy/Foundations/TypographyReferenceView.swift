import SwiftUI

struct TypographyReferenceView: View {
    @State private var showSizeInfo = true

    private let styles: [(name: String, style: Font.TextStyle, uiStyle: UIFont.TextStyle)] = [
        ("Large Title", .largeTitle, .largeTitle),
        ("Title 1",     .title,      .title1),
        ("Title 2",     .title2,     .title2),
        ("Title 3",     .title3,     .title3),
        ("Headline",    .headline,   .headline),
        ("Body",        .body,       .body),
        ("Callout",     .callout,    .callout),
        ("Subheadline", .subheadline,.subheadline),
        ("Footnote",    .footnote,   .footnote),
        ("Caption 1",   .caption,    .caption1),
        ("Caption 2",   .caption2,   .caption2),
    ]

    var body: some View {
        List {
            Section {
                Toggle("Show size info", isOn: $showSizeInfo)
            }

            Section("Dynamic Type Styles") {
                ForEach(styles, id: \.name) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The quick brown fox")
                            .font(Font.system(entry.style))
                        if showSizeInfo {
                            HStack(spacing: 8) {
                                Text(entry.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(UIFont.preferredFont(forTextStyle: entry.uiStyle).pointSize))pt")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Typography")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TypographyReferenceView()
    }
}
