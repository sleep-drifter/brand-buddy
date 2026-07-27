import SwiftUI

// MARK: - Rich Text Editor
//
// iOS 26's TextEditor accepts an AttributedString binding plus an
// AttributedTextSelection, making rich text editing fully native to
// SwiftUI — no UITextView wrapper. Formatting is applied through
// AttributedString.transformAttributes(in:), which keeps the selection
// valid across mutations.

struct RichTextEditorView: View {
    @State private var text: AttributedString = RichTextEditorView.sampleText
    @State private var selection = AttributedTextSelection()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                editorCard
                styleCard
                inspectorCard
                notesCard
            }
            .padding(16)
        }
        .navigationTitle("Rich Text Editor")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Editor Card

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Editor", systemImage: "richtext.page").font(.headline)
                Spacer()
                Text("iOS 26")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }

            formattingBar

            TextEditor(text: $text, selection: $selection)
                .frame(minHeight: 220)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Text("Select a range, then format it. The selection binding survives every transform.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var formattingBar: some View {
        HStack(spacing: 8) {
            formatButton("bold") {
                transformSelection { container in
                    let font: Font = container.font ?? .body
                    container.font = font.bold()
                }
            }
            formatButton("italic") {
                transformSelection { container in
                    let font: Font = container.font ?? .body
                    container.font = font.italic()
                }
            }
            formatButton("underline") {
                transformSelection { container in
                    let current: Text.LineStyle? = container.underlineStyle
                    container.underlineStyle = current == nil ? Text.LineStyle.single : nil
                }
            }
            formatButton("strikethrough") {
                transformSelection { container in
                    let current: Text.LineStyle? = container.strikethroughStyle
                    container.strikethroughStyle = current == nil ? Text.LineStyle.single : nil
                }
            }

            Divider().frame(height: 20)

            ForEach(Self.palette, id: \.name) { entry in
                Button {
                    let color = entry.color
                    transformSelection { container in
                        container.foregroundColor = color
                    }
                } label: {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Set color to \(entry.name)")
            }

            Spacer()

            Button {
                transformSelection { container in
                    container.font = nil as Font?
                    container.foregroundColor = nil as Color?
                    container.underlineStyle = nil as Text.LineStyle?
                    container.strikethroughStyle = nil as Text.LineStyle?
                }
            } label: {
                Image(systemName: "eraser")
            }
            .accessibilityLabel("Clear formatting")
        }
        .padding(.horizontal, 4)
    }

    private func formatButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 30, height: 30)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
    }

    private static let palette: [(name: String, color: Color)] = [
        ("blue", .blue), ("pink", .pink), ("orange", .orange), ("mint", .mint),
    ]

    private func transformSelection(_ transform: (inout AttributeContainer) -> Void) {
        text.transformAttributes(in: &selection) { container in
            transform(&container)
        }
    }

    // MARK: Style Card

    private var styleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Text Styles", systemImage: "textformat.alt").font(.headline)

            HStack(spacing: 8) {
                styleChip("Title", font: .title2.bold())
                styleChip("Headline", font: .headline)
                styleChip("Body", font: .body)
                styleChip("Caption", font: .caption)
            }

            Text("Styles set the SwiftUI font attribute on the selected runs — the same attribute the Bold and Italic buttons modify.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func styleChip(_ name: String, font: Font) -> some View {
        Button {
            transformSelection { container in
                container.font = font
            }
        } label: {
            Text(name)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Inspector Card

    private var inspectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Live Inspector", systemImage: "character.magnify").font(.headline)

            HStack(spacing: 12) {
                statTile(value: "\(characterCount)", label: "characters")
                statTile(value: "\(wordCount)", label: "words")
                statTile(value: "\(runCount)", label: "runs")
            }

            Text(selectionSummary)
                .font(.mono(.caption2))
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            Button("Reset sample text") {
                text = Self.sampleText
                selection = AttributedTextSelection()
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.mono(.title3))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var characterCount: Int { text.characters.count }

    private var wordCount: Int {
        String(text.characters)
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
    }

    private var runCount: Int { text.runs.count }

    private var selectionSummary: String {
        switch selection.indices(in: text) {
        case .insertionPoint(let index):
            let offset = text.characters.distance(from: text.startIndex, to: index)
            return "selection: insertion point at offset \(offset)"
        case .ranges(let rangeSet):
            let count = rangeSet.ranges.reduce(0) { total, range in
                total + text.characters.distance(from: range.lowerBound, to: range.upperBound)
            }
            return "selection: \(count) characters in \(rangeSet.ranges.count) range(s)"
        }
    }

    // MARK: Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("The API Surface", systemImage: "list.bullet.rectangle").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                apiRow("TextEditor(text:selection:)", "Binds an AttributedString and an AttributedTextSelection")
                apiRow("transformAttributes(in:)", "Mutates attributes over the selection; indices stay valid")
                apiRow("selection.indices(in:)", "Insertion point or RangeSet — what the inspector above reads")
                apiRow("text.runs", "Attribute runs: each maximal span with uniform styling")
            }

            Text("Before iOS 26 this whole page meant wrapping UITextView and shuttling NSAttributedString across the bridge.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func apiRow(_ api: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(api).font(.caption.monospaced()).foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Sample Content

    private static var sampleText: AttributedString {
        var title = AttributedString("Rich text, natively.\n")
        title.font = .title3.bold()

        var body = AttributedString("Select any of this text and use the toolbar above. Make it ")
        body.font = .body

        var bold = AttributedString("bold")
        bold.font = .body.bold()

        var middle = AttributedString(", give it ")
        middle.font = .body

        var color = AttributedString("color")
        color.font = .body
        color.foregroundColor = .pink

        var tail = AttributedString(", or clear everything back to plain. Every change is an attribute run on one AttributedString value.")
        tail.font = .body

        return title + body + bold + middle + color + tail
    }
}

#Preview {
    NavigationStack { RichTextEditorView() }
}
