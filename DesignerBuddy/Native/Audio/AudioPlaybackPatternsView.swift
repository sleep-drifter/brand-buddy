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

// MARK: - Main View

struct AudioPlaybackPatternsView: View {
    // Mini player
    @State private var miniIsPlaying = false
    @State private var miniProgress: Double = 0.32

    // Expanded player
    @State private var expandedIsPlaying = false
    @State private var expandedProgress: Double = 0.45
    @State private var isFavorited = false
    @State private var isShuffle = false
    @State private var isRepeat = false
    @State private var volume: Double = 0.7

    // Inline player
    @State private var inlineIsPlaying = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                miniPlayerSection
                expandedPlayerSection
                inlinePlayerSection
            }
            .padding(16)
        }
        .navigationTitle("Playback UI Patterns")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pattern 1: Mini Player Bar

    private var miniPlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AudioPatternHeader(
                number: "01",
                title: "Mini Player Bar",
                description: "Use at the bottom of any screen to let users control playback without leaving their current context. Common in music, podcast, and audio apps."
            )

            // Phone frame mockup
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 320)
                .overlay(
                    VStack(spacing: 0) {
                        // Placeholder content
                        VStack(spacing: 12) {
                            ForEach(0..<3) { i in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.quaternary)
                                        .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Capsule().fill(.quaternary).frame(width: CGFloat.random(in: 80...140), height: 10)
                                        Capsule().fill(.quaternary.opacity(0.6)).frame(width: CGFloat.random(in: 60...100), height: 8)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxHeight: .infinity, alignment: .top)

                        miniPlayerBar
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.quaternary, lineWidth: 1)
                )
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var miniPlayerBar: some View {
        VStack(spacing: 0) {
            // Thin progress line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(.quaternary).frame(height: 2)
                    Rectangle().fill(mockTrack.color).frame(width: geo.size.width * miniProgress, height: 2)
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
                    miniIsPlaying.toggle()
                } label: {
                    Image(systemName: miniIsPlaying ? "pause.fill" : "play.fill")
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

    private var expandedPlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AudioPatternHeader(
                number: "02",
                title: "Expanded Player Sheet",
                description: "Full-screen or large sheet used when the user wants full control. Typically presented over existing content via a sheet or by tapping the mini player bar."
            )

            VStack(spacing: 24) {
                // Album art
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [mockTrack.color, mockTrack.color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 64))
                            .foregroundStyle(.white.opacity(0.6))
                    )
                    .shadow(color: mockTrack.color.opacity(0.4), radius: 20, y: 8)
                    .frame(maxWidth: .infinity)

                // Title + favorite
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mockTrack.title)
                            .font(.title2.weight(.bold))
                        Text(mockTrack.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        isFavorited.toggle()
                    } label: {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isFavorited ? .red : .secondary)
                    }
                    .animation(.spring(response: 0.2), value: isFavorited)
                }

                // Scrubber
                VStack(spacing: 6) {
                    Slider(value: $expandedProgress, in: 0...1)
                        .tint(mockTrack.color)

                    HStack {
                        Text(timeString(expandedProgress * mockTrack.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("-" + timeString((1 - expandedProgress) * mockTrack.duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                // Playback controls
                HStack(spacing: 0) {
                    controlButton(systemImage: isShuffle ? "shuffle" : "shuffle", isActive: isShuffle, size: 20) {
                        isShuffle.toggle()
                    }
                    controlButton(systemImage: "backward.fill", isActive: false, size: 24) {}
                    Button {
                        expandedIsPlaying.toggle()
                    } label: {
                        Image(systemName: expandedIsPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(mockTrack.color)
                    }
                    .frame(maxWidth: .infinity)
                    controlButton(systemImage: "forward.fill", isActive: false, size: 24) {}
                    controlButton(systemImage: isRepeat ? "repeat.1" : "repeat", isActive: isRepeat, size: 20) {
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

                // AirPlay
                HStack {
                    Spacer()
                    Button {
                        // AirPlay picker would appear here
                    } label: {
                        Image(systemName: "airplay.audio")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

    private var inlinePlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AudioPatternHeader(
                number: "03",
                title: "Inline Player Row",
                description: "Compact row embedded in a list or queue. Use to show Now Playing state alongside other tracks, with minimal controls to keep the layout dense."
            )

            VStack(spacing: 0) {
                // Now playing row
                inlinePlayerRow(
                    track: mockTrack,
                    isCurrentTrack: true,
                    isPlayingParam: $inlineIsPlaying
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
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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

// MARK: - Pattern Header

private struct AudioPatternHeader: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(number)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioPlaybackPatternsView()
    }
}
