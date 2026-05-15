import SwiftUI
import Combine

// MARK: - Streaming State

private enum StreamingState: Equatable {
    case idle
    case thinking
    case streaming
    case complete
    case cancelled
}

// MARK: - Streaming Text View

struct StreamingTextView: View {
    @State private var streamingState: StreamingState = .idle
    @State private var displayedText = ""
    @State private var streamTask: Task<Void, Never>?
    @State private var showCursor = true
    @State private var cursorTimer: Timer?
    @State private var thinkingSeconds = 0
    @State private var thinkingTimer: Timer?
    @State private var shimmerOffset: CGFloat = -1
    @State private var speed: StreamSpeed = .normal
    @State private var skeletonPhase: CGFloat = -0.4

    private let sampleResponse = """
    SwiftUI makes it remarkably easy to build streaming text interfaces. \
    As tokens arrive from a language model, you append them to a @State string \
    and SwiftUI handles the incremental re-renders efficiently. \
    The key is to update on the MainActor so the UI stays responsive. \
    You can add a blinking cursor by toggling a Bool on a Timer and appending \
    a pipe character to the displayed text. When generation stops, hide the cursor \
    and reveal action buttons like copy or regenerate.
    """

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                streamingCard
                speedCard
                skeletonShimmerCard
                implementationCard
            }
            .padding(16)
        }
        .navigationTitle("Streaming Text")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { cancelAll() }
    }

    // MARK: Streaming Card

    private var streamingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Live Demo", systemImage: "ellipsis.message").font(.headline)
                Spacer()
                if streamingState == .streaming {
                    ProgressView().scaleEffect(0.8)
                }
            }

            textArea

            controlRow
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var textArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

            switch streamingState {
            case .idle:
                Text("Tap Generate to see streaming text…")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(12)

            case .thinking:
                thinkingView

            case .streaming:
                Text(displayedText + (showCursor ? "▎" : ""))
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(nil, value: displayedText)

            case .complete:
                Text(displayedText)
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)

            case .cancelled:
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayedText)
                        .font(.body)
                    Text("Generation stopped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 120)
    }

    private var thinkingView: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, isActive: true)
            Text("Thinking… \(thinkingSeconds)s")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .transition(.opacity)
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button {
                switch streamingState {
                case .idle, .complete, .cancelled:
                    startGeneration()
                case .thinking, .streaming:
                    cancelGeneration()
                }
            } label: {
                Label(
                    streamingState == .thinking || streamingState == .streaming ? "Stop" : "Generate",
                    systemImage: streamingState == .thinking || streamingState == .streaming ? "stop.fill" : "sparkles"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(streamingState == .thinking || streamingState == .streaming ? .red : .blue)

            if streamingState == .complete, !displayedText.isEmpty {
                Button {
                    UIPasteboard.general.string = displayedText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: streamingState)
    }

    // MARK: Skeleton Shimmer Card

    private var skeletonShimmerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Skeleton Shimmer", systemImage: "rays").font(.headline)
                Spacer()
            }

            Text("Looping greyscale gradient used by AI agents to indicate pending content. A highlight sweeps left-to-right across placeholder lines in a continuous loop.")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 10) {
                    skeletonLine(width: geo.size.width * 0.92)
                    skeletonLine(width: geo.size.width * 0.78)
                    skeletonLine(width: geo.size.width * 0.85)
                    skeletonLine(width: geo.size.width * 0.55)
                    skeletonLine(width: geo.size.width * 0.70)
                }
            }
            .frame(height: 5 * 14 + 4 * 10)
            .onAppear {
                skeletonPhase = -0.4
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    skeletonPhase = 1.4
                }
            }

            Text(".fill(LinearGradient) with animated UnitPoint(x: phase ± 0.4)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func skeletonLine(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGray5),
                        Color(uiColor: .systemGray3),
                        Color(uiColor: .systemGray5),
                    ],
                    startPoint: UnitPoint(x: skeletonPhase - 0.4, y: 0.5),
                    endPoint: UnitPoint(x: skeletonPhase + 0.4, y: 0.5)
                )
            )
            .frame(width: width, height: 14)
    }

    // MARK: Speed Card

    private var speedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Speed", systemImage: "gauge.medium").font(.headline)
                Spacer()
            }
            Picker("Speed", selection: $speed) {
                ForEach(StreamSpeed.allCases, id: \.self) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            Text("Adjusts token append interval: \(speed.description)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Implementation Card

    private var implementationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("How It Works", systemImage: "info.circle").font(.headline)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "sparkles", label: "Thinking state", detail: "Pre-stream phase with live elapsed timer + pulse icon")
                InfoRow(icon: "text.append", label: "Token append", detail: "Append each token to @State var on MainActor")
                InfoRow(icon: "timer", label: "Cursor blink", detail: "Timer toggles Bool → appended '▎' character")
                InfoRow(icon: "stop.circle", label: "Cancellation", detail: "Task.cancel() stops mid-generation cleanly")
                InfoRow(icon: "gauge.medium", label: "Speed control", detail: "Segmented picker adjusts the per-token sleep interval")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Generation Logic

    private func startGeneration() {
        displayedText = ""
        streamingState = .thinking
        thinkingSeconds = 0

        thinkingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            thinkingSeconds += 1
        }

        streamTask = Task {
            // Thinking phase: wait 1.5s
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else {
                await MainActor.run { finishCancelled() }
                return
            }

            await MainActor.run {
                stopThinkingTimer()
                streamingState = .streaming
                cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    showCursor.toggle()
                }
            }

            let words = sampleResponse.split(separator: " ").map(String.init)
            for word in words {
                guard !Task.isCancelled else {
                    await MainActor.run { finishCancelled() }
                    return
                }
                await MainActor.run {
                    displayedText += (displayedText.isEmpty ? "" : " ") + word
                }
                try? await Task.sleep(nanoseconds: speed.nanoseconds)
            }
            await MainActor.run { finishComplete() }
        }
    }

    private func cancelGeneration() {
        streamTask?.cancel()
        streamTask = nil
        finishCancelled()
    }

    private func finishComplete() {
        stopCursorTimer()
        stopThinkingTimer()
        streamingState = .complete
    }

    private func finishCancelled() {
        stopCursorTimer()
        stopThinkingTimer()
        streamingState = .cancelled
    }

    private func cancelAll() {
        streamTask?.cancel()
        stopCursorTimer()
        stopThinkingTimer()
    }

    private func stopCursorTimer() {
        cursorTimer?.invalidate()
        cursorTimer = nil
        showCursor = false
    }

    private func stopThinkingTimer() {
        thinkingTimer?.invalidate()
        thinkingTimer = nil
    }
}

// MARK: - Stream Speed

private enum StreamSpeed: CaseIterable {
    case slow, normal, fast

    var label: String {
        switch self {
        case .slow:   return "Slow"
        case .normal: return "Normal"
        case .fast:   return "Fast"
        }
    }

    var description: String {
        switch self {
        case .slow:   return "0.1s per token"
        case .normal: return "0.05s per token"
        case .fast:   return "0.01s per token"
        }
    }

    var nanoseconds: UInt64 {
        switch self {
        case .slow:   return 100_000_000
        case .normal: return 50_000_000
        case .fast:   return 10_000_000
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let label: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack { StreamingTextView() }
}
