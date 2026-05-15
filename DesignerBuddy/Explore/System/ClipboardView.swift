import SwiftUI
import UIKit

// MARK: - ClipboardView

struct ClipboardView: View {
    @State private var textToCopy = "Hello from Designer Buddy!"
    @State private var pastedText = ""
    @State private var copyConfirmation = false
    @State private var clearConfirmation = false
    @State private var clipboardHasString = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Copy to clipboard
                VStack(spacing: 12) {
                    HStack {
                        Label("UIPasteboard — Copy", systemImage: "doc.on.clipboard")
                            .font(.headline)
                        Spacer()
                    }

                    TextField("Text to copy", text: $textToCopy, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = textToCopy
                            withAnimation { copyConfirmation = true }
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                await MainActor.run {
                                    withAnimation { copyConfirmation = false }
                                }
                            }
                        } label: {
                            Label(
                                copyConfirmation ? "Copied!" : "Copy to Clipboard",
                                systemImage: copyConfirmation ? "checkmark" : "doc.on.doc"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(copyConfirmation ? .green : .accentColor)
                        .animation(.default, value: copyConfirmation)

                        Button {
                            UIPasteboard.general.string = nil
                            withAnimation { clearConfirmation = true }
                            Task {
                                try? await Task.sleep(for: .seconds(1.5))
                                await MainActor.run {
                                    withAnimation { clearConfirmation = false }
                                }
                            }
                        } label: {
                            Image(systemName: clearConfirmation ? "checkmark" : "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(clearConfirmation ? .green : .red)
                    }

                    infoRow(icon: "info.circle", text: "UIPasteboard.general.string sets the clipboard. iOS 16+ shows a privacy indicator banner when an app reads from the clipboard without a user gesture.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Paste from clipboard
                VStack(spacing: 12) {
                    HStack {
                        Label("UIPasteboard — Read", systemImage: "arrow.down.doc")
                            .font(.headline)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button {
                            if let s = UIPasteboard.general.string {
                                pastedText = s
                            } else {
                                pastedText = "(clipboard is empty or contains non-text data)"
                            }
                        } label: {
                            Label("Read from Clipboard", systemImage: "doc.on.clipboard.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if !pastedText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clipboard contents:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(pastedText)
                                .font(.subheadline)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    infoRow(icon: "exclamationmark.triangle", text: "Reading UIPasteboard.general outside a paste user gesture triggers iOS 16+ privacy banner. Use PasteButton or TextField paste actions when possible.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: SwiftUI PasteButton
                VStack(spacing: 12) {
                    HStack {
                        Label("PasteButton (iOS 16+)", systemImage: "doc.on.clipboard.fill")
                            .font(.headline)
                        Spacer()
                    }

                    Text("PasteButton is user-triggered — no privacy banner. The system may show a one-time paste confirmation on first use.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        PasteButton(payloadType: String.self) { strings in
                            pastedText = strings.first ?? ""
                        }
                        Spacer()
                    }

                    if !pastedText.isEmpty {
                        Text(pastedText)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
                            .padding(12)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }

                    infoRow(icon: "info.circle", text: "PasteButton replaces .onPasteCommand on iOS. It's user-initiated, so it never triggers the privacy banner.")
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: iOS 16+ privacy notes
                VStack(spacing: 12) {
                    HStack {
                        Label("iOS 16+ Privacy Indicator", systemImage: "eye.slash")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        privacyRow(icon: "checkmark.circle.fill", color: .green,
                                   text: "User-triggered paste (Edit menu, Cmd+V, paste button) — no banner")
                        privacyRow(icon: "checkmark.circle.fill", color: .green,
                                   text: "UIPasteboard.general.hasStrings — read-availability check, no banner")
                        privacyRow(icon: "exclamationmark.circle.fill", color: .orange,
                                   text: "Programmatic read without user gesture — shows banner")
                        privacyRow(icon: "xmark.circle.fill", color: .red,
                                   text: "Reading in background / on app launch — may be rejected at review")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Clipboard")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Helpers

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func privacyRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    NavigationStack { ClipboardView() }
}
