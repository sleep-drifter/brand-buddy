import SwiftUI

struct HighContrastView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var simulateHighContrast = false

    private var effectiveHighContrast: Bool {
        simulateHighContrast || contrast == .increased
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    sampleCluster
                        .padding(24)
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                    Text(effectiveHighContrast ? "colorSchemeContrast: .increased" : "colorSchemeContrast: .standard")
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(duration: 0.3), value: effectiveHighContrast)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Controls") {
                Toggle("Simulate High Contrast for this demo", isOn: $simulateHighContrast)
            }

            Section("System Setting") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Increase Contrast is:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(contrast == .increased ? "On" : "Standard")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(contrast == .increased ? .orange : .primary)
                    }
                    Spacer()
                    Image(systemName: contrast == .increased ? "circle.lefthalf.filled" : "circle.lefthalf.strikethrough")
                        .font(.title)
                        .foregroundStyle(contrast == .increased ? .orange : .secondary)
                }
                Text("Enable via Settings → Accessibility → Display & Text Size → Increase Contrast.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Adaptive Color Patterns") {
                adaptiveColorRow(
                    label: "Background",
                    normalColor: Color(.systemGray6),
                    highContrastColor: Color(.systemBackground),
                    description: "Higher contrast between card and page background"
                )
                adaptiveColorRow(
                    label: "Text on color",
                    normalColor: Color.blue.opacity(0.7),
                    highContrastColor: Color.blue,
                    description: "Avoid reduced opacity text on colored backgrounds"
                )
                adaptiveColorRow(
                    label: "Border",
                    normalColor: Color.clear,
                    highContrastColor: Color.primary.opacity(0.3),
                    description: "Add a border to distinguish elements"
                )
                Text("Use @Environment(\\.colorSchemeContrast) == .increased to apply stricter color values. Semantic colors like .label and .systemBackground adapt automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Button Comparison") {
                HStack(spacing: 16) {
                    // Standard contrast button
                    VStack(spacing: 6) {
                        Text("Standard")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .frame(maxWidth: .infinity)

                    // High contrast button
                    VStack(spacing: 6) {
                        Text("High Contrast")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(effectiveHighContrast ? .primary : .secondary)
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(effectiveHighContrast ? Color.blue : Color.blue.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(effectiveHighContrast ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
                Text("At increased contrast, use full opacity fills and add a border stroke. Avoid relying solely on opacity to distinguish interactive states.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Adaptive Separator") {
                VStack(spacing: 0) {
                    ForEach(["Alpha", "Beta", "Gamma"], id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        Divider()
                            .padding(.leading, 14)
                            .overlay(
                                // Thicker, more opaque divider in high contrast
                                effectiveHighContrast
                                    ? Color.primary.opacity(0.3)
                                    : Color.clear
                            )
                    }
                }
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 4)
                Text("Increase separator opacity or thickness under high contrast so list rows are clearly bounded without relying on background fill differences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("High Contrast")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Canvas sample

    private var sampleCluster: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Storage Almost Full")
                .font(.headline)
            Text("Large attachments are taking up space. Review them to keep room for new photos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Learn more about storage")
                .font(.caption)
                .foregroundStyle(effectiveHighContrast ? Color.blue : Color.blue.opacity(0.7))
            Divider()
                .overlay(effectiveHighContrast ? Color.primary.opacity(0.3) : Color.clear)
            HStack {
                Text("128 GB of 256 GB used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {} label: {
                    Text("Review")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(effectiveHighContrast ? Color.blue : Color.blue.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(effectiveHighContrast ? Color.blue.opacity(0.6) : Color.clear, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(effectiveHighContrast ? Color(.systemBackground) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(effectiveHighContrast ? Color.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func adaptiveColorRow(
        label: String,
        normalColor: Color,
        highContrastColor: Color,
        description: String
    ) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(effectiveHighContrast ? highContrastColor : normalColor)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { HighContrastView() }
}
