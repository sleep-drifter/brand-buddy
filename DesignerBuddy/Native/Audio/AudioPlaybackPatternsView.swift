import SwiftUI

// MARK: - Mock Data

private struct MockTrack {
    let title: String
    let artist: String
    let duration: TimeInterval
    let color: Color
}

private let mockTrack = MockTrack(
    title: "Midnight Drive",
    artist: "Synthwave Artist",
    duration: 214,
    color: .indigo
)

// MARK: - Player Style

private enum PlayerStyle: String, CaseIterable, Identifiable {
    case mini = "Mini"
    case expanded = "Expanded"
    case inline = "Inline"

    var id: Self { self }

    var explanation: String {
        switch self {
        case .mini:     return "Use at the bottom of any screen to let users control playback without leaving their current context. Common in music, podcast, and audio apps."
        case .expanded: return "Full-screen or large sheet used when the user wants full control. Typically presented over existing content via a sheet or by tapping the mini player bar."
        case .inline:   return "Compact row embedded in a list or queue. Use to show Now Playing state alongside other tracks, with minimal controls to keep the layout dense."
        }
    }
}

// MARK: - Main View

struct AudioPlaybackPatternsView: View {
    @State private var style: PlayerStyle = .mini
    @State private var isPlaying = false
    @State private var progress: Double = 0.32
    @State private var isFavorited = false
    @State private var isShuffle = false
    @State private var isRepeat = false
    @State private var volume: Double = 0.7

    private let placeholderWidths: [(CGFloat, CGFloat)] = [(128, 84), (96, 64), (136, 92)]

    var body: some View {
        List {
            Section("Style") {
                PresetChipRow(
                    chips: PlayerStyle.allCases.map { option in
                        PresetChip(name: option.rawValue, detail: option.explanation)
                    },
                    selectedID: styleSelection
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Playback") {
                Toggle("Playing", isOn: $isPlaying)

                LabeledContent("progress: \(progress, specifier: "%.2f")") {
                    Slider(value: $progress, in: 0...1)
                }
                .disabled(style == .inline)

                LabeledContent("volume: \(volume, specifier: "%.2f")") {
                    Slider(value: $volume, in: 0...1)
                }
                .disabled(style != .expanded)

                Toggle("Favorited", isOn: $isFavorited)
                    .disabled(style != .expanded)
                Toggle("Shuffle", isOn: $isShuffle)
                    .disabled(style != .expanded)
                Toggle("Repeat", isOn: $isRepeat)
                    .disabled(style != .expanded)
            }
        }
        .pinnedPreview(entry: "Playback UI Patterns") {
            Group {
                switch style {
                case .mini:
                    miniPlayerCanvas
                case .expanded:
                    expandedPlayerCanvas
                case .inline:
                    inlinePlayerCanvas
                }
            }
            .buttonStyle(.borderless)
            .animation(.spring(duration: 0.3), value: canvasState)
        }
        .navigationTitle("Playback UI Patterns")
    }

    private var canvasState: [AnyHashable] {
        [style, isPlaying, isFavorited, isShuffle, isRepeat]
    }

    private var styleSelection: Binding<String?> {
        Binding(
            get: { style.rawValue },
            set: { name in
                guard let name, let option = PlayerStyle(rawValue: name) else { return }
                style = option
            }
        )
    }

    // MARK: - Pattern 1: Mini Player Bar

    private var miniPlayerCanvas: some View {
        // Phone frame mockup
        RoundedRectangle(cornerRadius: 28)
            .fill(Color(.secondarySystemBackground))
            .frame(height: 240)
            .overlay(
                VStack(spacing: 0) {
                    // Placeholder content
                    VStack(spacing: 12) {
                        ForEach(0..<placeholderWidths.count, id: \.self) { i in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.quaternary)
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Capsule().fill(.quaternary).frame(width: placeholderWidths[i].0, height: 10)
                                    Capsule().fill(.quaternary.opacity(0.6)).frame(width: placeholderWidths[i].1, height: 8)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxHeight: .infinity, alignment: .top)

                    miniPlayerBar
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }

    private var miniPlayerBar: some View {
        VStack(spacing: 0) {
            // Thin progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(.quaternary).frame(height: 2)
                    Rectangle().fill(mockTrack.color).frame(width: geo.size.width * progress, height: 2)
                }
            }
            .frame(height: 2)

            HStack(spacing: 12) {
                // Album art
                RoundedRectangle(cornerRadius: 8)
                    .fill(mockTrack.color.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.caption)
                    )

                // Title + artist
                VStack(alignment: .leading, spacing: 2) {
                    Text(mockTrack.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(mockTrack.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                }

                Button {
                    // next
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }

    // MARK: - Pattern 2: Expanded Player Sheet

    private var expandedPlayerCanvas: some View {
        VStack(spacing: 10) {
            // Album art + title + favorite
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [mockTrack.color, mockTrack.color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.6))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(mockTrack.title)
                        .font(.headline)
                    Text(mockTrack.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isFavorited.toggle()
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(isFavorited ? .red : .secondary)
                }
                .animation(.spring(response: 0.2), value: isFavorited)
            }

            // Scrubber
            VStack(spacing: 4) {
                Slider(value: $progress, in: 0...1)
                    .tint(mockTrack.color)

                HStack {
                    Text(timeString(progress * mockTrack.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("-" + timeString((1 - progress) * mockTrack.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // Playback controls
            HStack(spacing: 0) {
                controlButton(systemImage: "shuffle", isActive: isShuffle, size: 18) {
                    isShuffle.toggle()
                }
                controlButton(systemImage: "backward.fill", isActive: false, size: 22) {}
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(mockTrack.color)
                }
                .frame(maxWidth: .infinity)
                controlButton(systemImage: "forward.fill", isActive: false, size: 22) {}
                controlButton(systemImage: isRepeat ? "repeat.1" : "repeat", isActive: isRepeat, size: 18) {
                    isRepeat.toggle()
                }
            }

            // Volume
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Slider(value: $volume, in: 0...1)
                    .tint(.secondary)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func controlButton(systemImage: String, isActive: Bool, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(isActive ? mockTrack.color : .secondary)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Pattern 3: Inline Player Row

    private var inlinePlayerCanvas: some View {
        VStack(spacing: 0) {
            // Now playing row
            inlinePlayerRow(
                track: mockTrack,
                isCurrentTrack: true,
                isPlayingParam: $isPlaying
            )

            Divider().padding(.leading, 64)

            // Other rows (static, not playing)
            inlineStaticRow(title: "Neon Coast", artist: "Chillwave Co.", color: .teal)

            Divider().padding(.leading, 64)

            inlineStaticRow(title: "Electric Dusk", artist: "Future Bass", color: .purple)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }

    private func inlinePlayerRow(track: MockTrack, isCurrentTrack: Bool, isPlayingParam: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            // Album art with equalizer overlay when playing
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(track.color.gradient)
                    .frame(width: 40, height: 40)

                if isCurrentTrack && isPlayingParam.wrappedValue {
                    EqualizerView()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCurrentTrack ? track.color : .primary)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    // prev
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }

                Button {
                    isPlayingParam.wrappedValue.toggle()
                } label: {
                    Image(systemName: isPlayingParam.wrappedValue ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(track.color)
                        .frame(width: 32, height: 32)
                }

                Button {
                    // next
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    private func inlineStaticRow(title: String, artist: String, color: Color) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                Text(artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    // MARK: - Helpers

    private func timeString(_ interval: TimeInterval) -> String {
        let t = max(0, interval)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Equalizer Animation

private struct EqualizerView: View {
    @State private var heights: [CGFloat] = [0.3, 0.7, 0.5]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: 20 * heights[i])
            }
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.3...0.6))
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
                ) {
                    heights[i] = CGFloat.random(in: 0.5...1.0)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioPlaybackPatternsView()
    }
    .environmentObject(PinsStore())
}
