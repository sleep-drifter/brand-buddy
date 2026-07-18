import SwiftUI

struct VoiceOverLabelsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - accessibilityLabel
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Labels", systemImage: "tag")
                            .font(.headline)
                        Spacer()
                    }
                    comparisonCard(
                        beforeLabel: "Before",
                        afterLabel: "After"
                    ) {
                        // Before
                        Button {
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } after: {
                        // After — descriptive label
                        Button {
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .accessibilityLabel("Delete item")
                    }
                    Text("Without a label, VoiceOver reads \"trash\" (the symbol name). With the label \"Delete item\" it reads the intent, not the icon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - accessibilityHint
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Hints", systemImage: "questionmark.circle")
                            .font(.headline)
                        Spacer()
                    }
                    comparisonCard(beforeLabel: "Label only", afterLabel: "Label + Hint") {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "play.fill").foregroundStyle(.white))
                            .accessibilityLabel("Play")
                    } after: {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 44, height: 44)
                            .overlay(Image(systemName: "play.fill").foregroundStyle(.white))
                            .accessibilityLabel("Play")
                            .accessibilityHint("Starts playback from the beginning")
                    }
                    Text("Hints are read after a brief pause following the label. Keep hints short and start with a verb.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - accessibilityValue
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Values", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        Spacer()
                    }
                    AccessibilityValueDemo()
                    Text("Values communicate dynamic state that changes at runtime — volume level, toggle state, progress percentage, etc.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: - Grouping & hiding
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Grouping & Hiding", systemImage: "rectangle.3.group")
                            .font(.headline)
                        Spacer()
                    }
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            // Decorative image — hidden from VoiceOver
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundStyle(.teal)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo Album")
                                    .font(.subheadline.weight(.semibold))
                                Text("142 photos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityElement(children: .combine)
                    }
                    Text("Hiding removes decorative views from the VoiceOver tree. Combining merges a container's children into one focusable element that reads naturally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("VoiceOver Labels")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func comparisonCard<Before: View, After: View>(
        beforeLabel: String,
        afterLabel: String,
        @ViewBuilder before: () -> Before,
        @ViewBuilder after: () -> After
    ) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(beforeLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                before()
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

            Text("→")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            VStack(spacing: 8) {
                Text(afterLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                after()
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Isolated demo for accessibilityValue

private struct AccessibilityValueDemo: View {
    @State private var volume: Double = 0.6

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(value: $volume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Volume")
            .accessibilityValue("\(Int(volume * 100)) percent")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: volume = min(1, volume + 0.1)
                case .decrement: volume = max(0, volume - 0.1)
                @unknown default: break
                }
            }

            Text("VoiceOver reads: \"Volume, \(Int(volume * 100)) percent\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack { VoiceOverLabelsView() }
}
