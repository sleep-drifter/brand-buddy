import SwiftUI
import FoundationModels

// Foundation Models — iOS 26's on-device LLM UX: availability handling,
// prompt → streamed-feeling response with stop control, tool-call
// affordances, and guided generation. When the device supports Apple
// Intelligence the responses are real (SystemLanguageModel); everywhere
// else the same UI runs on deterministic canned output, so the patterns
// always demo.

struct FoundationModelsView: View {

    private struct Preset: Identifiable, Hashable {
        let id: String
        let prompt: String
    }
    private let presets = [
        Preset(id: "haiku",  prompt: "Write a haiku about autosaving."),
        Preset(id: "name",   prompt: "Suggest three names for a design reference app."),
        Preset(id: "explain", prompt: "Explain size classes in two sentences."),
    ]
    @State private var selectedPreset = "haiku"

    @State private var output = ""
    @State private var isGenerating = false
    @State private var usedRealModel = false
    @State private var revealTask: Task<Void, Never>?

    @State private var toolStep = 0
    @State private var toolTask: Task<Void, Never>?

    private var modelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    var body: some View {
        List {

            // ── Availability ───────────────────────────────────────────────
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "apple.intelligence")
                        .font(.title3)
                        .foregroundStyle(modelAvailable ? .blue : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(modelAvailable
                             ? "On-device model available"
                             : "On-device model unavailable")
                            .font(.subheadline.weight(.semibold))
                        Text(modelAvailable
                             ? "Demos below call SystemLanguageModel for real."
                             : "Simulator or unsupported device — demos run on canned output, same UI.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                RefCaption("if case .available = SystemLanguageModel.default.availability")
                HIGNoteRow("Availability is a runtime fact, not a build-time one: Apple Intelligence can be off, the model still downloading, or the device ineligible. Design the feature so each of those degrades to something useful.")
            }

            // ── Prompt & response ──────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Prompt & Response", tag: modelAvailable ? "Live" : "Simulated")) {
                Picker("Prompt", selection: $selectedPreset) {
                    ForEach(presets) { preset in
                        Text(preset.prompt).tag(preset.id)
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 6) {
                    if output.isEmpty && !isGenerating {
                        Text("Response appears here")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(output + (isGenerating ? "▍" : ""))
                            .font(.subheadline)
                    }
                    if !output.isEmpty && !isGenerating {
                        Label(usedRealModel ? "Generated on device" : "Simulated response",
                              systemImage: "apple.intelligence")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12))

                HStack {
                    Button {
                        generate()
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                    }
                    .disabled(isGenerating)
                    Spacer()
                    if isGenerating {
                        Button(role: .destructive) {
                            stopGenerating()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                    }
                }
                RefCaption("try await LanguageModelSession().respond(to: prompt)")
                HIGNoteRow("Show partial output as it arrives and keep a visible Stop — generation that can't be interrupted feels broken at any speed. The trailing cursor says \"still thinking\" without a spinner.")
            }

            // ── Tool-call affordances ──────────────────────────────────────
            Section(header: SectionTagHeader(title: "Tool Calls", tag: "Affordance")) {
                VStack(alignment: .leading, spacing: 10) {
                    chatBubble("What's the weather for the design offsite?", user: true)
                    if toolStep >= 1 {
                        toolChip(done: toolStep >= 2)
                    }
                    if toolStep >= 3 {
                        chatBubble("Berlin is 18° and clear on Friday — light jacket weather for the rooftop session.", user: false)
                    }
                }
                .padding(.vertical, 4)
                .animation(.snappy, value: toolStep)

                Button(toolStep == 0 ? "Run tool-call sequence" : "Replay") {
                    runToolSequence()
                }
                RefCaption("Tool protocol: the model decides to call your function mid-response")
                HIGNoteRow("When the model reaches into your app's data or a service, say so in the transcript — a quiet pause reads as a hang, and an unexplained answer reads as a hallucination. Name the tool in plain words.")
            }

            // ── Guided generation ──────────────────────────────────────────
            Section(header: SectionTagHeader(title: "Guided Generation", tag: "@Generable")) {
                Text("Instead of parsing prose, declare the shape you need and the framework constrains decoding to it — fields arrive progressively, so forms can fill in as they generate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                CodeBlockRow(code: """
                    @Generable
                    struct Itinerary {
                        @Guide(description: "A short, catchy title")
                        var title: String
                        @Guide(.count(3))
                        var stops: [String]
                    }

                    let response = try await session.respond(
                        to: "Plan a studio tour in Berlin",
                        generating: Itinerary.self)
                    """)
                HIGNoteRow("Typed output turns \"chat\" into UI: each field can render the moment it finishes, instead of waiting for one blob of text to parse.")
            }

            // ── Guidance ───────────────────────────────────────────────────
            Section("HIG guidance") {
                DoDontRow(good: true,  text: "Label generated content as generated, and keep the person's own words visually distinct from the model's.")
                DoDontRow(good: true,  text: "Offer regenerate and edit next to every AI result — first drafts are the product, not final answers.")
                DoDontRow(good: false, text: "Don't dead-end when the model is unavailable; the feature should fall back, queue, or explain.")
                DoDontRow(good: false, text: "Don't present model output as authoritative fact in consequential flows without a verification step.")
            }

            // ── Code ───────────────────────────────────────────────────────
            Section("Code") {
                CodeBlockRow(code: """
                    import FoundationModels

                    guard case .available =
                        SystemLanguageModel.default.availability else {
                        return showFallback()
                    }

                    let session = LanguageModelSession(
                        instructions: "You are a concise design assistant.")
                    let response = try await session.respond(to: prompt)
                    show(response.content)
                    """)
            }
        }
        .navigationTitle("Foundation Models")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Generation

    private var currentPrompt: String {
        presets.first { $0.id == selectedPreset }?.prompt ?? ""
    }

    private func generate() {
        revealTask?.cancel()
        output = ""
        isGenerating = true
        let prompt = currentPrompt
        revealTask = Task {
            let full = await fetchResponse(for: prompt)
            guard !Task.isCancelled else { return }
            for character in full {
                if Task.isCancelled { break }
                output.append(character)
                try? await Task.sleep(nanoseconds: 14_000_000)
            }
            isGenerating = false
        }
    }

    private func stopGenerating() {
        revealTask?.cancel()
        isGenerating = false
    }

    private func fetchResponse(for prompt: String) async -> String {
        if modelAvailable {
            do {
                let session = LanguageModelSession(
                    instructions: "You are a concise assistant inside a design reference app. Answer in under 60 words.")
                let response = try await session.respond(to: prompt)
                usedRealModel = true
                return response.content
            } catch {
                usedRealModel = false
                return cannedResponse(for: selectedPreset)
            }
        }
        usedRealModel = false
        return cannedResponse(for: selectedPreset)
    }

    private func cannedResponse(for id: String) -> String {
        switch id {
        case "haiku":
            return "Keystrokes drift like snow —\nnothing asks to be remembered,\nthe draft already saved."
        case "name":
            return "1. Fieldnotes — a working designer's reference.\n2. Primitive — the parts every interface is made of.\n3. Spec Sheet — patterns you can hand to engineering."
        default:
            return "Size classes describe available width and height as just two values, compact or regular, so layouts adapt to context instead of devices. An iPad app in one-third Split View is compact — the same class as an iPhone."
        }
    }

    // MARK: - Tool sequence

    private func runToolSequence() {
        toolTask?.cancel()
        toolStep = 0
        toolTask = Task {
            for step in 1...3 {
                try? await Task.sleep(nanoseconds: 900_000_000)
                if Task.isCancelled { return }
                toolStep = step
            }
        }
    }

    // MARK: - Pieces

    private func chatBubble(_ text: String, user: Bool) -> some View {
        HStack {
            if user { Spacer(minLength: 40) }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(user ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    user ? AnyShapeStyle(.blue) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                    in: RoundedRectangle(cornerRadius: 14))
            if !user { Spacer(minLength: 40) }
        }
    }

    private func toolChip(done: Bool) -> some View {
        HStack(spacing: 8) {
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
            Text(done ? "Checked weather for Berlin" : "Checking weather…")
                .font(.caption.weight(.medium))
            Image(systemName: "cpu")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        .overlay {
            Capsule().strokeBorder(.secondary.opacity(0.25))
        }
    }
}

#Preview {
    NavigationStack { FoundationModelsView() }
}
