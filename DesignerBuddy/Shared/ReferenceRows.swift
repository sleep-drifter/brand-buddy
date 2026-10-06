import SwiftUI

// Shared rows for reference pages — the tagged section header, monospaced
// API caption, HIG call-out, Do/Don't row, and code block used across the
// newer catalog pages. (The Charts pages carry their own Chart-prefixed
// equivalents from before these existed.)

/// Section header with a small capsule tag.
struct SectionTagHeader: View {
    let title: String
    var tag: String? = nil
    var tagColor: Color = .blue

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            if let tag {
                Text(tag)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(tagColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(tagColor.opacity(0.12)))
            }
        }
    }
}

/// Monospaced caption under a demo — names the API that produced it.
struct RefCaption: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.mono(.caption2))
            .foregroundStyle(.secondary)
    }
}

/// A Human Interface Guidelines call-out row.
struct HIGNoteRow: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "book.closed")
                .font(.footnote)
                .foregroundStyle(.blue)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Do / Don't row for guidance lists.
struct DoDontRow: View {
    let good: Bool
    let text: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: good ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(good ? .green : .red)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

/// Inline code snippet block.
struct CodeBlockRow: View {
    let code: String
    var body: some View {
        Text(code)
            .font(.mono(.caption))
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
