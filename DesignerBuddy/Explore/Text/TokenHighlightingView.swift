import SwiftUI
import UIKit

// MARK: - Live Token Highlighting
//
// A UITextView whose text storage is restyled on every keystroke:
// hashtags, mentions, and URLs get colors and backgrounds as you type.
// Attribute-only edits inside beginEditing/endEditing don't disturb the
// caret, and NSTextContentStorage keeps TextKit 2 layout in sync.

struct TokenHighlightingView: View {
    @State private var text = "Drafting the #DesignSystem rollout with @riley and @sam — spec at https://example.com/tokens, launch thread tagged #shipit 🚀"
    @State private var enabledKinds: Set<TokenKind> = Set(TokenKind.allCases)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                editorCard
                tokensCard
                howItWorksCard
            }
            .padding(16)
        }
        .navigationTitle("Live Token Highlighting")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Editor Card

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Type Here", systemImage: "highlighter").font(.headline)
                Spacer()
                Text("UITextView")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }

            TokenTextView(text: $text, enabledKinds: enabledKinds)
                .frame(height: 180)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                ForEach(TokenKind.allCases) { kind in
                    let count = kind.count(in: text)
                    HStack(spacing: 4) {
                        Image(systemName: kind.icon).font(.caption2)
                        Text("\(count)").font(.mono(.caption2))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(kind.color.opacity(0.15), in: Capsule())
                    .foregroundStyle(kind.color)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Tokens Card

    private var tokensCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Token Types", systemImage: "textformat.characters.dottedunderline").font(.headline)

            ForEach(TokenKind.allCases) { kind in
                Toggle(isOn: bindingFor(kind)) {
                    HStack(spacing: 10) {
                        Image(systemName: kind.icon)
                            .foregroundStyle(kind.color)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(kind.title).font(.subheadline)
                            Text(kind.pattern)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func bindingFor(_ kind: TokenKind) -> Binding<Bool> {
        Binding(
            get: { enabledKinds.contains(kind) },
            set: { isOn in
                if isOn { enabledKinds.insert(kind) } else { enabledKinds.remove(kind) }
            }
        )
    }

    // MARK: How It Works

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How It Works", systemImage: "gearshape").font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                stepRow("1", "textViewDidChange fires after each edit and re-runs the token regexes over the full string.")
                stepRow("2", "Attributes reset to the base style, then each match gets its color — all inside beginEditing/endEditing so layout is invalidated once.")
                stepRow("3", "NSTextContentStorage mirrors those NSTextStorage edits into TextKit 2, which relays out only the affected fragments.")
            }

            Text("Attribute-only changes don't trigger textViewDidChange, so restyling inside the delegate callback can't loop.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stepRow(_ number: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(.blue.opacity(0.15), in: Circle())
                .foregroundStyle(.blue)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Token Kinds

private enum TokenKind: String, CaseIterable, Identifiable {
    case hashtag
    case mention
    case url

    var id: Self { self }

    var title: String {
        switch self {
        case .hashtag: "Hashtags"
        case .mention: "Mentions"
        case .url:     "Links"
        }
    }

    var icon: String {
        switch self {
        case .hashtag: "number"
        case .mention: "at"
        case .url:     "link"
        }
    }

    var pattern: String {
        switch self {
        case .hashtag: "#[\\p{L}\\p{N}_]+"
        case .mention: "@[A-Za-z0-9_.]+"
        case .url:     "https?://[^\\s]+"
        }
    }

    var color: Color {
        switch self {
        case .hashtag: .blue
        case .mention: .purple
        case .url:     .teal
        }
    }

    var uiColor: UIColor {
        switch self {
        case .hashtag: .systemBlue
        case .mention: .systemPurple
        case .url:     .systemTeal
        }
    }

    var regex: NSRegularExpression {
        switch self {
        case .hashtag: Self.hashtagRegex
        case .mention: Self.mentionRegex
        case .url:     Self.urlRegex
        }
    }

    var highlightAttributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: uiColor,
            .backgroundColor: uiColor.withAlphaComponent(0.12),
        ]
        if self == .url {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attributes
    }

    func count(in text: String) -> Int {
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, range: range)
    }

    private static let hashtagRegex = try! NSRegularExpression(pattern: "#[\\p{L}\\p{N}_]+")
    private static let mentionRegex = try! NSRegularExpression(pattern: "@[A-Za-z0-9_.]+")
    private static let urlRegex = try! NSRegularExpression(pattern: "https?://[^\\s]+")
}

// MARK: - UITextView wrapper

private struct TokenTextView: UIViewRepresentable {
    @Binding var text: String
    var enabledKinds: Set<TokenKind>

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        if textView.text != text {
            textView.text = text
        }
        context.coordinator.applyHighlighting(to: textView)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TokenTextView

        init(_ parent: TokenTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            applyHighlighting(to: textView)
        }

        func applyHighlighting(to textView: UITextView) {
            // Restyling mid-composition would break CJK/dictation input.
            guard textView.markedTextRange == nil else { return }
            let storage = textView.textStorage
            let fullRange = NSRange(location: 0, length: storage.length)
            let savedSelection = textView.selectedRange

            storage.beginEditing()
            storage.setAttributes([
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label,
            ], range: fullRange)

            for kind in TokenKind.allCases where parent.enabledKinds.contains(kind) {
                kind.regex.enumerateMatches(in: storage.string, range: fullRange) { match, _, _ in
                    guard let range = match?.range else { return }
                    storage.addAttributes(kind.highlightAttributes, range: range)
                }
            }
            storage.endEditing()

            textView.selectedRange = savedSelection
        }
    }
}

#Preview {
    NavigationStack { TokenHighlightingView() }
}
