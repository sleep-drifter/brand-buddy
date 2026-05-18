import SwiftUI
import AVFoundation
import Combine

// MARK: - Recording State

enum RecordingState {
    case idle, recording, recorded
}

// MARK: - Audio Recorder

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var amplitude: Float = 0
    @Published var amplitudeHistory: [Float] = []
    @Published var duration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    @Published var isPlaying: Bool = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private(set) var recordingURL: URL?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.record()
            state = .recording
            duration = 0

            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateMeters()
                }
            }
        } catch {
            return
        }
    }

    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recorder?.stop()
        recorder = nil
        state = .recorded
    }

    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }

    func startPlayback() {
        guard let url = recordingURL else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let player = self.player else { return }
                    self.playbackProgress = player.currentTime / player.duration
                }
            }
        } catch {
            return
        }
    }

    func pausePlayback() {
        player?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func resetRecording() {
        pausePlayback()
        player = nil
        recorder = nil
        recordingURL = nil
        state = .idle
        amplitude = 0
        amplitudeHistory = []
        duration = 0
        playbackProgress = 0
    }

    private func updateMeters() {
        recorder?.updateMeters()
        duration += 0.05
        let power = recorder?.averagePower(forChannel: 0) ?? -60
        // Map dB (-60 to 0) to 0...1
        let normalized = max(0, min(1, (power + 60) / 60))
        amplitude = normalized
        amplitudeHistory.append(normalized)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        // no-op; state managed by stopRecording()
    }
}

extension AudioRecorder: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.isPlaying = false
            self?.playbackProgress = 0
            self?.playbackTimer?.invalidate()
            self?.playbackTimer = nil
        }
    }
}

// MARK: - Main View

struct AudioRecordingView: View {
    @StateObject private var recorder = AudioRecorder()
    // Use type inference — AVAudioApplication.shared.recordPermission's return type
    // isn't publicly named as a nested type in this SDK.
    @State private var micPermissionGranted: Bool? = nil  // nil = undetermined, true = granted, false = denied

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if micPermissionGranted == false {
                    permissionDeniedCard
                } else if micPermissionGranted == nil {
                    permissionRequestCard
                } else {
                    recordSection
                    if recorder.state == .recorded {
                        playbackSection
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Audio Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkPermission()
        }
    }

    // MARK: Permission Denied

    private var permissionDeniedCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Microphone Access Required")
                .font(.headline)
            Text("Open Settings to grant microphone permission so this demo can record audio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Permission Request

    private var permissionRequestCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("Microphone Access")
                .font(.headline)
            Text("This demo records audio from your microphone and shows a live waveform.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Allow Microphone") {
                requestPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Record Section

    private var recordSection: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Record", systemImage: "mic.fill")

            // Waveform canvas
            waveformCanvas
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            // Duration label when recording
            if recorder.state == .recording {
                Text(recorder.formattedDuration)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            // Record / Stop button
            recordButton

            // Confirmation
            if recorder.state == .recorded {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Recording saved — \(recorder.formattedDuration)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Reset when recorded
            if recorder.state == .recorded {
                Button("Record Again") {
                    withAnimation {
                        recorder.resetRecording()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .animation(.spring(response: 0.3), value: recorder.state)
    }

    // MARK: Waveform Canvas

    @ViewBuilder
    private var waveformCanvas: some View {
        if recorder.state == .recording {
            Canvas { context, size in
                let barCount = 40
                let history = recorder.amplitudeHistory
                let totalSpacing = size.width * 0.3
                let barWidth = (size.width - totalSpacing) / CGFloat(barCount)
                let gap = totalSpacing / CGFloat(barCount - 1)
                let midY = size.height / 2
                let maxHeight = size.height * 0.45

                for i in 0..<barCount {
                    let historyIdx = history.count - barCount + i
                    let amp: Float = historyIdx >= 0 ? history[historyIdx] : 0.0
                    let height = CGFloat(amp) * maxHeight + 2
                    let x = CGFloat(i) * (barWidth + gap)
                    let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
                    let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                    context.fill(path, with: .color(.red.opacity(historyIdx >= 0 ? 0.85 : 0.15)))
                }
            }
        } else if recorder.state == .recorded {
            Canvas { context, size in
                let barCount = 40
                let samples = sampledHistory(count: barCount)
                let totalSpacing = size.width * 0.3
                let barWidth = (size.width - totalSpacing) / CGFloat(barCount)
                let gap = totalSpacing / CGFloat(barCount - 1)
                let midY = size.height / 2

                for i in 0..<barCount {
                    let height = CGFloat(samples[i]) * size.height * 0.45 + 2
                    let x = CGFloat(i) * (barWidth + gap)
                    let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
                    let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                    context.fill(path, with: .color(.secondary.opacity(0.4)))
                }
            }
        } else {
            Canvas { context, size in
                let midY = size.height / 2
                let path = Path { p in
                    p.move(to: CGPoint(x: 16, y: midY))
                    p.addLine(to: CGPoint(x: size.width - 16, y: midY))
                }
                context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 2)
            }
        }
    }

    private func sampledHistory(count: Int) -> [Float] {
        let h = recorder.amplitudeHistory
        guard !h.isEmpty else { return Array(repeating: 0.02, count: count) }
        return (0..<count).map { i in
            let idx = Int(Double(i) / Double(count) * Double(h.count))
            return h[min(idx, h.count - 1)]
        }
    }

    // MARK: Record Button

    private var recordButton: some View {
        Button {
            withAnimation {
                if recorder.state == .recording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(recorder.state == .recording ? Color.red : Color.red)
                    .frame(width: 72, height: 72)
                    .shadow(color: .red.opacity(0.4), radius: recorder.state == .recording ? 12 : 4)

                Image(systemName: recorder.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.25), value: recorder.state)
    }

    // MARK: Playback Section

    private var playbackSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Playback", systemImage: "play.fill")

            // Static waveform with pulsing opacity
            playbackWaveform
                .frame(height: 64)
                .frame(maxWidth: .infinity)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(height: 4)
                    Capsule()
                        .fill(.blue)
                        .frame(width: geo.size.width * recorder.playbackProgress, height: 4)
                }
            }
            .frame(height: 4)

            // Time + Play/Pause
            HStack {
                Text(timeString(recorder.playbackProgress * recorder.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    recorder.togglePlayback()
                } label: {
                    Image(systemName: recorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                }
                Spacer()
                Text(recorder.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var playbackWaveform: some View {
        Canvas { context, size in
            let barCount = 40
            let samples = sampledHistory(count: barCount)
            let totalSpacing = size.width * 0.3
            let barWidth = (size.width - totalSpacing) / CGFloat(barCount)
            let gap = totalSpacing / CGFloat(barCount - 1)
            let midY = size.height / 2

            for i in 0..<barCount {
                let height = CGFloat(samples[i]) * size.height * 0.45 + 2
                let x = CGFloat(i) * (barWidth + gap)
                let rect = CGRect(x: x, y: midY - height, width: barWidth, height: height * 2)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                let played = Double(i) / Double(barCount) <= recorder.playbackProgress
                context.fill(path, with: .color(played ? .blue.opacity(0.85) : .secondary.opacity(0.25)))
            }
        }
    }

    // MARK: Helpers

    private func timeString(_ interval: TimeInterval) -> String {
        let t = max(0, interval)
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:    micPermissionGranted = true
        case .denied:     micPermissionGranted = false
        default:          micPermissionGranted = nil
        }
    }

    private func requestPermission() {
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            micPermissionGranted = granted
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
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

// MARK: - Preview

#Preview {
    NavigationStack {
        AudioRecordingView()
    }
}
