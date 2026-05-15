import SwiftUI

// MARK: - Writing Tools View

struct WritingToolsView: View {
    @State private var sampleText = "The quick brown fox jumps over the lazy dog. Writing tools can help you refine, rewrite, and polish this text."
    @State private var selectedBehavior: BehaviorOption = .automatic

    enum BehaviorOption: String, CaseIterable, Identifiable {
        case automatic = "automatic"
        case limited = "limited"
        var id: Self { self }

        var title: String {
            switch self {
            case .automatic: return "Automatic"
            case .limited:   return "Limited"
            }
        }

        var description: String {
            switch self {
            case .automatic:
                return "System determines when Writing Tools appear. Shows the full toolbar with rewrite, proofread, and summarize options."
            case .limited:
                return "Only inline predictions appear. No full Writing Tools panel. Useful for short inputs like search bars."
            }
        }

        var icon: String {
            switch self {
            case .automatic: return "sparkles"
            case .limited:   return "text.cursor"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                selectorCard
                editorCard
                referenceCard
            }
            .padding(16)
        }
        .navigationTitle("Writing Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Selector Card

    private var selectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Behavior Mode", systemImage: "pencil.and.sparkles").font(.headline)
                Spacer()
            }

            Picker("Behavior", selection: $selectedBehavior) {
                ForEach(BehaviorOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: selectedBehavior.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                Text(selectedBehavior.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            .animation(.spring(response: 0.3), value: selectedBehavior)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Editor Card

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Text Editor", systemImage: "doc.text").font(.headline)
                Spacer()
                Text(selectedBehavior.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.15), in: Capsule())
                    .foregroundStyle(.blue)
            }

            if #available(iOS 18, *) {
                writingToolsEditor
            } else {
                legacyEditor
            }

            Text("Long-press selected text or tap the cursor to access Writing Tools (requires iOS 18 on device).")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @available(iOS 18, *)
    private var writingToolsEditor: some View {
        TextEditor(text: $sampleText)
            .writingToolsBehavior(currentBehavior)
            .frame(minHeight: 100)
            .padding(8)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    @available(iOS 18, *)
    private var currentBehavior: WritingToolsBehavior {
        switch selectedBehavior {
        case .automatic: return .automatic
        case .limited:   return .limited
        }
    }

    private var legacyEditor: some View {
        VStack(spacing: 8) {
            TextEditor(text: $sampleText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
            Text("writingToolsBehavior requires iOS 18+")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }

    // MARK: Reference Card

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("When to Use Each", systemImage: "list.bullet.rectangle").font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                BehaviorRow(title: ".automatic", subtitle: "Long-form text", detail: "Notes, emails, documents — let the system decide")
                Divider()
                BehaviorRow(title: ".limited", subtitle: "Short inputs / sensitive fields", detail: "Search bars, code editors, passwords — most restrictive SwiftUI option")
            }

            Text("UIKit exposes UIWritingToolsBehavior.none for full opt-out; SwiftUI's WritingToolsBehavior only has .automatic and .limited.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct BehaviorRow: View {
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.monospaced())
                .foregroundStyle(.blue)
                .frame(width: 100, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle).font(.subheadline).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack { WritingToolsView() }
}
