import SwiftUI

struct DynamicTypeExploreView: View {
    @Environment(\.dynamicTypeSize) private var currentSize

    private let toolbarItems = [("square.and.arrow.up", "Share"), ("heart", "Like"), ("bookmark", "Save")]
    private let gridItems = ["Photos", "Videos", "Music", "Podcasts", "Books", "News"]

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
