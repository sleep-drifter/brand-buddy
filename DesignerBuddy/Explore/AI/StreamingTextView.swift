import SwiftUI

// MARK: - Streaming Text View

struct StreamingTextView: View {
    @State private var displayedText = ""
    @State private var isStreaming = false
    @State private var streamTask: Task<Void, Never>?
    @State private var showCursor = true
    @State private var cursorTimer: Timer?

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
                implementationCard
            }
            .padding(16)
        }
        .navigationTitle("Streaming Text")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopStreaming() }
    }

    // MARK: Streaming Card

    private var streamingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Live Demo", systemImage: "ellipsis.message").font(.headline)
                Spacer()
                if isStreaming {
                    ProgressView().scaleEffect(0.8)
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))

                Text(displayedText + (isStreaming && showCursor ? "▎" : ""))
                    .font(.body)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(nil, value: displayedText)

                if displayedText.isEmpty && !isStreaming {
                    Text("Tap Generate to see streaming text…")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(12)
                }
            }
            .frame(minHeight: 120)

            HStack(spacing: 12) {
                Button {
                    if isStreaming { stopStreaming() } else { startStreaming() }
                } label: {
                    Label(isStreaming ? "Stop" : "Generate", systemImage: isStreaming ? "stop.fill" : "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isStreaming ? .red : .blue)

                if !displayedText.isEmpty && !isStreaming {
                    Button {
                        UIPasteboard.general.string = displayedText
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .animation(.spring(response: 0.3), value: isStreaming)
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
                InfoRow(icon: "sparkles", label: "Token append", detail: "Append each token to @State var text on MainActor")
                InfoRow(icon: "timer", label: "Cursor blink", detail: "Timer toggles a Bool → appended '▎' character")
                InfoRow(icon: "stop.circle", label: "Cancellation", detail: "Task.cancel() lets you stop mid-generation cleanly")
                InfoRow(icon: "iphone", label: "Performance", detail: "SwiftUI diffs only the changed tail — no full re-render")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Streaming Logic

    private func startStreaming() {
        displayedText = ""
        isStreaming = true

        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            showCursor.toggle()
        }

        let words = sampleResponse.split(separator: " ").map(String.init)
        streamTask = Task {
            for word in words {
                guard !Task.isCancelled else { break }
                await MainActor.run { displayedText += (displayedText.isEmpty ? "" : " ") + word }
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
            await MainActor.run { finishStreaming() }
        }
    }

    private func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        finishStreaming()
    }

    private func finishStreaming() {
        isStreaming = false
        showCursor = false
        cursorTimer?.invalidate()
        cursorTimer = nil
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
