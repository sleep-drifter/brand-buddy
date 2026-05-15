import SwiftUI

// MARK: - Image Generation View

struct ImageGenerationView: View {
    @State private var generationState: GenerationState = .idle
    @State private var shimmerOffset: CGFloat = -1
    @State private var progress: Double = 0
    @State private var generationTask: Task<Void, Never>?

    enum GenerationState: Equatable {
        case idle
        case loading(Double)
        case complete
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                demoCard
                statesCard
            }
            .padding(16)
        }
        .navigationTitle("Image Generation")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { generationTask?.cancel() }
    }

    // MARK: Demo Card

    private var demoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Pattern Demo", systemImage: "photo.badge.plus").font(.headline)
                Spacer()
            }

            // Result area
            ZStack {
                switch generationState {
                case .idle:
                    idlePlaceholder
                case .loading(let p):
                    loadingView(progress: p)
                case .complete:
                    resultView
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Controls
            HStack(spacing: 12) {
                Button {
                    generate()
                } label: {
                    Label(buttonLabel, systemImage: buttonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(generationState != .idle && generationState != .complete)

                if generationState == .complete {
                    Button("Reset") {
                        withAnimation(.spring(response: 0.4)) {
                            generationState = .idle
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .animation(.spring(response: 0.3), value: generationState)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var buttonLabel: String {
        switch generationState {
        case .idle:    return "Generate"
        case .loading: return "Generating…"
        case .complete: return "Regenerate"
        }
    }

    private var buttonIcon: String {
        switch generationState {
        case .idle:    return "sparkles"
        case .loading: return "sparkles"
        case .complete: return "arrow.clockwise"
        }
    }

    // MARK: State Views

    private var idlePlaceholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            VStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No image yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func loadingView(progress: Double) -> some View {
        ZStack {
            // Shimmer skeleton
            GeometryReader { geo in
                LinearGradient(
                    stops: [
                        .init(color: Color(.tertiarySystemBackground), location: 0),
                        .init(color: Color(.secondarySystemBackground), location: 0.3),
                        .init(color: Color(.quaternarySystemFill), location: 0.5),
                        .init(color: Color(.secondarySystemBackground), location: 0.7),
                        .init(color: Color(.tertiarySystemBackground), location: 1),
                    ],
                    startPoint: .init(x: shimmerOffset, y: 0),
                    endPoint: .init(x: shimmerOffset + 1, y: 0)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1
                    }
                }
            }

            // Progress ring overlay
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
                Text("Generating…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var resultView: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: generationState == .complete)
                Text("Image ready")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
        }
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }

    // MARK: States Reference Card

    private var statesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("UX States", systemImage: "list.number").font(.headline)
                Spacer()
            }
            VStack(spacing: 8) {
                StateRow(icon: "photo", color: .secondary, label: "Idle", detail: "Placeholder shown — no content yet")
                Divider()
                StateRow(icon: "rays", color: .blue, label: "Loading", detail: "Shimmer skeleton + progress indicator")
                Divider()
                StateRow(icon: "sparkles", color: .purple, label: "Complete", detail: "Reveal with scale + opacity transition")
                Divider()
                StateRow(icon: "exclamationmark.triangle", color: .red, label: "Error", detail: "Retry CTA, keep previous result if available")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Generation Simulation

    private func generate() {
        generationTask?.cancel()
        shimmerOffset = -1
        withAnimation(.spring(response: 0.4)) {
            generationState = .loading(0)
        }
        progress = 0

        generationTask = Task {
            let steps = 20
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: 80_000_000)
                await MainActor.run {
                    progress = Double(i) / Double(steps)
                    generationState = .loading(progress)
                }
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    generationState = .complete
                }
            }
        }
    }
}

private struct StateRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack { ImageGenerationView() }
}
