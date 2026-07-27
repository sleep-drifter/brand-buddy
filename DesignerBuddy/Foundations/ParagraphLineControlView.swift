import SwiftUI
import UIKit

// MARK: - Paragraph & Line Control
//
// Two tiers of typographic control on iOS: what SwiftUI exposes directly
// on Text, and what still requires NSParagraphStyle through TextKit
// (hyphenation, justification, line-height multiples, indents).

struct ParagraphLineControlView: View {
    // SwiftUI-native knobs
    @State private var tracking: CGFloat = 0
    @State private var lineSpacing: CGFloat = 4
    @State private var alignment: TextAlignment = .leading
    @State private var limitLines = false
    @State private var lineLimit = 3
    @State private var truncation: Text.TruncationMode = .tail

    // TextKit-only knobs
    @State private var hyphenation: Double = 0
    @State private var justified = false
    @State private var lineHeightMultiple: Double = 1.0
    @State private var firstLineIndent: Double = 0

    private static let sample = "Great typography is invisible until it fails. Letterspacing, line height, hyphenation, and justification each shift a paragraph's texture — tune one at a time and watch the rhythm of the block change."

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                swiftUICard
                textKitCard
                cheatSheetCard
            }
            .padding(16)
        }
        .navigationTitle("Paragraph & Line Control")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: SwiftUI Card

    private var swiftUICard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("SwiftUI Text", systemImage: "swift").font(.headline)
                Spacer()
                Text("view modifiers")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }

            Text(Self.sample)
                .font(.callout)
                .tracking(tracking)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(alignment)
                .lineLimit(limitLines ? lineLimit : nil)
                .truncationMode(truncation)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .animation(.spring(response: 0.3), value: alignment)

            sliderRow(title: "Tracking", value: $tracking, range: -2...8, format: "%.1f pt")
            sliderRow(title: "Line spacing", value: $lineSpacing, range: 0...24, format: "%.0f pt")

            Picker("Alignment", selection: $alignment) {
                Text("Leading").tag(TextAlignment.leading)
                Text("Center").tag(TextAlignment.center)
                Text("Trailing").tag(TextAlignment.trailing)
            }
            .pickerStyle(.segmented)

            Toggle("Limit lines", isOn: $limitLines.animation())
            if limitLines {
                Stepper("Line limit: \(lineLimit)", value: $lineLimit, in: 1...6)
                Picker("Truncation", selection: $truncation) {
                    Text("Head").tag(Text.TruncationMode.head)
                    Text("Middle").tag(Text.TruncationMode.middle)
                    Text("Tail").tag(Text.TruncationMode.tail)
                }
                .pickerStyle(.segmented)
            }

            modifierReadout
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var modifierReadout: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(".tracking(\(String(format: "%.1f", tracking)))")
            Text(".lineSpacing(\(String(format: "%.0f", lineSpacing)))")
            Text(".multilineTextAlignment(.\(alignmentName))")
            if limitLines {
                Text(".lineLimit(\(lineLimit))")
                Text(".truncationMode(.\(truncationName))")
            }
        }
        .font(.mono(.caption2))
        .foregroundStyle(.secondary)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private var alignmentName: String {
        switch alignment {
        case .leading: "leading"
        case .center: "center"
        case .trailing: "trailing"
        }
    }

    private var truncationName: String {
        switch truncation {
        case .head: "head"
        case .middle: "middle"
        default: "tail"
        }
    }

    // MARK: TextKit Card

    private var textKitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("NSParagraphStyle", systemImage: "paragraphsign").font(.headline)
                Spacer()
                Text("TextKit only")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }

            ParagraphStylePreview(attributed: textKitAttributedString)
                .frame(height: 210)
                .padding(4)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Toggle("Justified", isOn: $justified)
            sliderRow(title: "Hyphenation factor", value: $hyphenation, range: 0...1, format: "%.2f")
            sliderRow(title: "Line height multiple", value: $lineHeightMultiple, range: 0.8...1.8, format: "%.2f×")
            sliderRow(title: "First line indent", value: $firstLineIndent, range: 0...40, format: "%.0f pt")

            Text("Justification without hyphenation produces rivers of whitespace — turn both on to see why body text justification needs a hyphenation factor around 0.9.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var textKitAttributedString: NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = justified ? .justified : .natural
        style.hyphenationFactor = Float(hyphenation)
        style.lineHeightMultiple = CGFloat(lineHeightMultiple)
        style.firstLineHeadIndent = CGFloat(firstLineIndent)
        style.paragraphSpacing = 8
        return NSAttributedString(string: Self.sample + "\n" + Self.sample, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .callout),
            .foregroundColor: UIColor.label,
            .paragraphStyle: style,
        ])
    }

    // MARK: Cheat Sheet

    private var cheatSheetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Which Layer Owns What", systemImage: "list.bullet.rectangle").font(.headline)

            VStack(spacing: 8) {
                CheatRow(api: ".tracking / .kerning", layer: "SwiftUI", detail: "Tracking spaces every glyph; kerning respects kern pairs")
                Divider()
                CheatRow(api: ".lineSpacing", layer: "SwiftUI", detail: "Adds fixed points between line fragments")
                Divider()
                CheatRow(api: "hyphenationFactor", layer: "TextKit", detail: "0…1 threshold for breaking words at syllables")
                Divider()
                CheatRow(api: ".justified", layer: "TextKit", detail: "NSTextAlignment — SwiftUI's TextAlignment has no justified case")
                Divider()
                CheatRow(api: "lineHeightMultiple", layer: "TextKit", detail: "Scales the line box relative to the font's natural height")
            }

            Text("SwiftUI Text renders paragraph styles it understands from AttributedString, but NSParagraphStyle lives in the UIKit attribute scope — for full paragraph control, drop to UITextView or UILabel.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Shared Controls

    private func sliderRow(title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.mono(.caption2))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.mono(.caption2))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

private struct CheatRow: View {
    let api: String
    let layer: String
    let detail: String

    var body: some View {
        HStack(alignment: .top) {
            Text(api)
                .font(.caption.monospaced())
                .foregroundStyle(layer == "SwiftUI" ? .blue : .orange)
                .frame(width: 130, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(layer).font(.subheadline).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - UITextView preview host

private struct ParagraphStylePreview: UIViewRepresentable {
    let attributed: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = attributed
    }
}

#Preview {
    NavigationStack { ParagraphLineControlView() }
}
