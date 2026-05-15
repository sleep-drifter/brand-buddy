import SwiftUI

struct DynamicTypeExploreView: View {
    @Environment(\.dynamicTypeSize) private var currentSize

    private let allSizes: [DynamicTypeSize] = [
        .xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
        .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5
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

                // MARK: - Layout tip
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Layout Tip: ViewThatFits", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                            .font(.headline)
                        Spacer()
                    }
                    ViewThatFits(in: .horizontal) {
                        // Preferred: side by side
                        HStack(spacing: 12) {
                            sampleBadge(color: .blue, label: "Compact")
                            sampleBadge(color: .purple, label: "Layout")
                        }
                        // Fallback: stacked
                        VStack(spacing: 8) {
                            sampleBadge(color: .blue, label: "Stacked")
                            sampleBadge(color: .purple, label: "Layout")
                        }
                    }
                    Text("ViewThatFits picks the first child that fits the available space — use it to swap between HStack and VStack layouts at large type sizes.")
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
