import SwiftUI

// MARK: - Fixed waveform data (looks like a real decoded audio track)

private let staticWaveformData: [Float] = [
    0.15, 0.28, 0.45, 0.62, 0.80, 0.95, 0.88, 0.72, 0.55, 0.40,
    0.30, 0.48, 0.70, 0.92, 1.00, 0.85, 0.68, 0.50, 0.35, 0.20,
    0.38, 0.60, 0.78, 0.90, 0.75, 0.58, 0.42, 0.25, 0.18, 0.32,
    0.55, 0.82, 0.98, 0.88, 0.65, 0.48, 0.30, 0.22, 0.40, 0.65,
    0.85, 0.78, 0.55, 0.38, 0.20, 0.12, 0.28, 0.50, 0.72, 0.90,
    0.82, 0.65, 0.45, 0.25, 0.18, 0.35, 0.58, 0.80, 0.92, 0.70,
    0.50, 0.30, 0.15, 0.28, 0.52, 0.75, 0.95, 0.88, 0.62, 0.40,
    0.22, 0.18, 0.35, 0.60, 0.85, 0.78, 0.55, 0.30, 0.20, 0.42
]

// MARK: - Main View

struct AudioWaveformView: View {
    // Live animated waveform controls
    @State private var speed: Double = 1.5
    @State private var phaseSpread: Double = 0.4
    @State private var barColor: Color = .blue

    // Scrubber waveform
    @State private var scrubPosition: Double = 0.3

    // Playback state waveforms
    @State private var bufferingOpacity: Double = 0.3
    @State private var playheadOffset: Double = 0.2

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                liveAnimatedSection
                scrubberSection
                playbackStatesSection
            }
            .padding(16)
        }
        .navigationTitle("Waveform Visualization")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startBufferingAnimation()
            startPlayheadAnimation()
        }
    }

    // MARK: - Live Animated Waveform

    private var liveAnimatedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WFSectionHeader(title: "Live Animated Waveform", systemImage: "waveform")

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let barCount = 50
                    let totalGap = size.width * 0.35
                    let barWidth = (size.width - totalGap) / CGFloat(barCount)
                    let gap = totalGap / CGFloat(barCount - 1)
                    let midY = size.height / 2
                    let maxHeight = size.height * 0.45

                    for i in 0..<barCount {
                        let phase = Double(i) * phaseSpread
                        let height = CGFloat(abs(sin(time * speed + phase))) * maxHeight + 2
                        let x = CGFloat(i) * (barWidth + gap)
                        let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
                        let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                        context.fill(path, with: .color(barColor.opacity(0.85)))
                    }
                }
                .frame(height: 100)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 12) {
                LabeledSlider(label: "Speed", value: $speed, range: 0.5...4.0, format: "%.1f×")
                LabeledSlider(label: "Wave Spread", value: $phaseSpread, range: 0.1...1.0, format: "%.2f")

                HStack {
                    Text("Bar Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ColorPicker("Bar Color", selection: $barColor, supportsOpacity: false)
                        .labelsHidden()
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Scrubber Waveform

    private var scrubberSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WFSectionHeader(title: "Scrubber Waveform", systemImage: "slider.horizontal.below.sun.horizon")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Canvas { context, size in
                        let barCount = staticWaveformData.count
                        let totalGap = size.width * 0.3
                        let barWidth = (size.width - totalGap) / CGFloat(barCount)
                        let gap = totalGap / CGFloat(barCount - 1)
                        let midY = size.height / 2

                        for i in 0..<barCount {
                            let amp = CGFloat(staticWaveformData[i])
                            let height = amp * size.height * 0.45 + 2
                            let x = CGFloat(i) * (barWidth + gap)
                            let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
                            let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                            let played = Double(i) / Double(barCount) <= scrubPosition
                            context.fill(path, with: .color(played ? .blue.opacity(0.85) : .secondary.opacity(0.25)))
                        }
                    }

                    // Scrubber line
                    Rectangle()
                        .fill(.blue)
                        .frame(width: 2, height: geo.size.height)
                        .offset(x: scrubPosition * geo.size.width - 1)
                        .shadow(color: .blue.opacity(0.4), radius: 4)

                    // Drag handle
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.blue, lineWidth: 2))
                        .shadow(radius: 4)
                        .offset(x: scrubPosition * geo.size.width - 8, y: -geo.size.height / 2 + 8)
                }
                .frame(height: 80)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            scrubPosition = max(0, min(1, value.location.x / geo.size.width))
                        }
                )
            }
            .frame(height: 80)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            HStack {
                Text(mockTimeString(scrubPosition * totalDurationSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(mockTotalDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private let totalDurationSeconds: Double = 138 // 2:18
    private let mockTotalDuration = "2:18"

    private func mockTimeString(_ seconds: Double) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", Int(s) / 60, Int(s) % 60)
    }

    // MARK: - Playback States

    private var playbackStatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WFSectionHeader(title: "Playback States", systemImage: "play.circle")

            HStack(spacing: 12) {
                playingStateCard
                pausedStateCard
                bufferingStateCard
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // Playing — color bars with animated moving playhead
    private var playingStateCard: some View {
        VStack(spacing: 8) {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let playhead = (time.truncatingRemainder(dividingBy: 3.0)) / 3.0
                    drawMiniWaveform(context: context, size: size, playhead: playhead,
                                    playedColor: .blue, unplayedColor: .secondary.opacity(0.2))
                    // Playhead line
                    let x = playhead * size.width
                    let linePath = Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(linePath, with: .color(.blue), lineWidth: 1.5)
                }
                .frame(height: 48)
            }

            Text("Playing")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // Paused — gray bars, static playhead
    private var pausedStateCard: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                drawMiniWaveform(context: context, size: size, playhead: 0.45,
                                 playedColor: .secondary.opacity(0.5), unplayedColor: .secondary.opacity(0.2))
                let x = 0.45 * size.width
                let linePath = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(linePath, with: .color(.secondary.opacity(0.7)), lineWidth: 1.5)
            }
            .frame(height: 48)

            Text("Paused")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // Buffering — pulsing opacity bars
    private var bufferingStateCard: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                drawMiniWaveform(context: context, size: size, playhead: nil,
                                 playedColor: .secondary.opacity(bufferingOpacity),
                                 unplayedColor: .secondary.opacity(bufferingOpacity * 0.5))
            }
            .frame(height: 48)

            Text("Buffering")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func drawMiniWaveform(
        context: GraphicsContext,
        size: CGSize,
        playhead: Double?,
        playedColor: Color,
        unplayedColor: Color
    ) {
        let barCount = 20
        let totalGap = size.width * 0.3
        let barWidth = (size.width - totalGap) / CGFloat(barCount)
        let gap = totalGap / CGFloat(barCount - 1)
        let midY = size.height / 2

        for i in 0..<barCount {
            let idx = (i * staticWaveformData.count / barCount) % staticWaveformData.count
            let amp = CGFloat(staticWaveformData[idx])
            let height = amp * size.height * 0.45 + 2
            let x = CGFloat(i) * (barWidth + gap)
            let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
            let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
            let played = playhead.map { Double(i) / Double(barCount) <= $0 } ?? false
            context.fill(path, with: .color(played ? playedColor : unplayedColor))
        }
    }

    // MARK: - Animations

    private func startBufferingAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bufferingOpacity = 0.7
        }
    }

    private func startPlayheadAnimation() {
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            playheadOffset = 1.0
        }
    }
}

// MARK: - Subviews

private struct WFSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline)
            Spacer()
        }
    }
}

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: format, value))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioWaveformView()
    }
}
