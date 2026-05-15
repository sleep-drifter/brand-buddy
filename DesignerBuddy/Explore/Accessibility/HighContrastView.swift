import SwiftUI

struct HighContrastView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    @State private var simulateHighContrast = false

    private var effectiveHighContrast: Bool {
        simulateHighContrast || contrast == .increased
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - System status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("System Setting", systemImage: "circle.lefthalf.filled")
                            .font(.headline)
                        Spacer()
                    }
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
                    Toggle("Simulate High Contrast for this demo", isOn: $simulateHighContrast)
                        .font(.subheadline)
                    Text("Enable via Settings → Accessibility → Display & Text Size → Increase Contrast.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Adaptive colors
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Adaptive Color Patterns", systemImage: "paintpalette")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 10) {
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
                    }
                    Text("Use @Environment(\\.colorSchemeContrast) == .increased to apply stricter color values. Semantic colors like .label and .systemBackground adapt automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Before / after button
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Button Comparison", systemImage: "button.horizontal.top.press")
                            .font(.headline)
                        Spacer()
                    }
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
                    Text("At increased contrast, use full opacity fills and add a border stroke. Avoid relying solely on opacity to distinguish interactive states.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Pattern: adaptive contrast color
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Adaptive Separator", systemImage: "line.horizontal.3")
                            .font(.headline)
                        Spacer()
                    }
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
                    Text("Increase separator opacity or thickness under high contrast so list rows are clearly bounded without relying on background fill differences.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("High Contrast")
        .navigationBarTitleDisplayMode(.inline)
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
        .padding(10)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack { HighContrastView() }
}
