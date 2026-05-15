import SwiftUI

// MARK: - Prompt Input View

struct PromptInputView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                chatInputCard
                sendButtonStatesCard
                attachmentChipsCard
            }
            .padding(16)
        }
        .navigationTitle("Prompt Input Patterns")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chatInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Grow-to-Fit Input", systemImage: "text.bubble").font(.headline)
                Spacer()
            }
            GrowingInputDemo()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var sendButtonStatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Send Button States", systemImage: "paperplane").font(.headline)
                Spacer()
            }
            SendButtonStatesDemo()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var attachmentChipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Attachment Chips", systemImage: "paperclip").font(.headline)
                Spacer()
            }
            AttachmentChipsDemo()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Growing Input Demo

private struct GrowingInputDemo: View {
    @State private var text = ""
    @State private var isSending = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                // Grow-to-fit text editor with placeholder overlay
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 36, maxHeight: 120)
                        .padding(.horizontal, 4)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)

                    if text.isEmpty {
                        Text("Message…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))

                Button {
                    send()
                } label: {
                    Image(systemName: isSending ? "stop.fill" : "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(sendButtonColor, in: Circle())
                        .animation(.spring(response: 0.25), value: isSending)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending)
            }

            Text("The TextEditor height grows up to a max — use .frame(minHeight:maxHeight:). Disable send while empty.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sendButtonColor: Color {
        if isSending { return .red }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color(.tertiaryLabel) : .blue
    }

    private func send() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSending = false
            text = ""
        }
    }
}

// MARK: - Send Button States Demo

private struct SendButtonStatesDemo: View {
    @State private var currentState: SendState = .empty

    enum SendState: String, CaseIterable, Identifiable {
        case empty = "Empty"
        case hasText = "Has text"
        case sending = "Sending"
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 14) {
            Picker("State", selection: $currentState) {
                ForEach(SendState.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                // Mock input bar
                HStack {
                    Text(currentState == .empty ? "Type a message…" : "Hello, how are you?")
                        .foregroundStyle(currentState == .empty ? .tertiary : .primary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: Capsule())

                // Send button
                ZStack {
                    Circle()
                        .fill(currentState == .empty ? Color(.tertiaryLabel) : .blue)
                        .frame(width: 34, height: 34)
                    if currentState == .sending {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.3), value: currentState)
            }

            Text(stateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var stateDescription: String {
        switch currentState {
        case .empty:   return "Button is muted — .disabled(true) when input is empty"
        case .hasText: return "Button is active — tappable when input has non-whitespace content"
        case .sending: return "ProgressView replaces the icon; button disabled during request"
        }
    }
}

// MARK: - Attachment Chips Demo

private struct AttachmentChipsDemo: View {
    @State private var attachments: [Attachment] = [
        .init(name: "photo.jpg", icon: "photo"),
        .init(name: "doc.pdf", icon: "doc.richtext"),
        .init(name: "data.csv", icon: "tablecells"),
    ]
    @State private var showAddAlert = false

    struct Attachment: Identifiable {
        let id = UUID()
        var name: String
        var icon: String
    }

    private let presets: [(String, String)] = [
        ("audio.m4a", "waveform"), ("image.png", "photo"), ("notes.txt", "doc.text"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            if attachments.isEmpty {
                Text("No attachments")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachments) { attachment in
                            AttachmentChip(attachment: attachment) {
                                withAnimation(.spring(response: 0.3)) {
                                    attachments.removeAll { $0.id == attachment.id }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack {
                Button {
                    if let preset = presets.randomElement() {
                        withAnimation(.spring(response: 0.3)) {
                            attachments.append(.init(name: preset.0, icon: preset.1))
                        }
                    }
                } label: {
                    Label("Add file", systemImage: "plus.circle")
                        .font(.subheadline)
                }

                Spacer()

                if !attachments.isEmpty {
                    Button("Clear all") {
                        withAnimation(.spring(response: 0.3)) {
                            attachments.removeAll()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }

            Text("Horizontal scroll row with remove buttons. Spring animation on add/remove.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AttachmentChip: View {
    let attachment: AttachmentChipsDemo.Attachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: attachment.icon)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(attachment.name)
                .font(.caption)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground), in: Capsule())
        .overlay(Capsule().strokeBorder(.quaternary))
    }
}

#Preview {
    NavigationStack { PromptInputView() }
}
