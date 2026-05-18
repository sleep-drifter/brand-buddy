import SwiftUI
import QuickLook
import UIKit

// MARK: - QuickLookPreviewController wrapper

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .prominent,
            target: context.coordinator,
            action: #selector(Coordinator.dismiss)
        )
        context.coordinator.dismissAction = { nav.dismiss(animated: true) }
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        var dismissAction: (() -> Void)?

        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }

        @objc func dismiss() {
            dismissAction?()
        }
    }
}

// MARK: - QuickLookView

struct QuickLookView: View {
    @State private var showTextPreview = false
    @State private var showHTMLPreview = false
    @State private var textFileURL: URL?
    @State private var htmlFileURL: URL?
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Preview buttons
                VStack(spacing: 12) {
                    HStack {
                        Label("QLPreviewController", systemImage: "eye")
                            .font(.headline)
                        Spacer()
                    }

                    Text("QuickLook presents a full-screen preview of documents, images, PDFs, and more. Files are created temporarily for this demo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        Button {
                            textFileURL = makeTextFile()
                            showTextPreview = textFileURL != nil
                        } label: {
                            Label("Preview Plain Text File", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            htmlFileURL = makeHTMLFile()
                            showHTMLPreview = htmlFileURL != nil
                        } label: {
                            Label("Preview HTML File", systemImage: "doc.richtext")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Supported types
                VStack(spacing: 12) {
                    HStack {
                        Label("Supported File Types", systemImage: "doc.badge.gearshape")
                            .font(.headline)
                        Spacer()
                    }

                    let types: [(String, String)] = [
                        ("PDF", "application/pdf"),
                        ("Images", "png, jpg, heic, gif, tiff"),
                        ("Office", "docx, xlsx, pptx, pages, numbers"),
                        ("Text", "txt, rtf, html, md, csv"),
                        ("Video", "mp4, mov, m4v"),
                        ("Audio", "mp3, m4a, aif, wav"),
                        ("3D models", "usdz, reality"),
                    ]

                    VStack(spacing: 6) {
                        ForEach(types, id: \.0) { type, formats in
                            HStack {
                                Text(type)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 80, alignment: .leading)
                                Text(formats)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(8)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Implementation notes
                VStack(spacing: 12) {
                    HStack {
                        Label("Implementation Notes", systemImage: "info.circle")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        noteRow("Use QLPreviewController via UIViewControllerRepresentable — no SwiftUI-native API exists.")
                        noteRow("Files must be on disk (not in memory). Write to a temp directory if needed.")
                        noteRow("QLPreviewItem is just a protocol — NSURL conforms out of the box.")
                        noteRow("Use QLPreviewController.canPreview(_:) to check support before presenting.")
                        noteRow("For in-line previews without full-screen, consider QuickLookUI's QLPreviewView on macOS.")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Quick Look")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showTextPreview) {
            if let url = textFileURL {
                QuickLookPreview(url: url).ignoresSafeArea()
            }
        }
        .fullScreenCover(isPresented: $showHTMLPreview) {
            if let url = htmlFileURL {
                QuickLookPreview(url: url).ignoresSafeArea()
            }
        }
        .alert("Preview Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: File generation

    private func makeTextFile() -> URL? {
        let content = """
        Designer Buddy — Quick Look Demo
        =================================

        This plain text file was generated at runtime and stored in
        the system's temporary directory to demonstrate QLPreviewController.

        Quick Look supports:
        • Plain text (.txt, .md)
        • Rich text (.rtf)
        • PDF documents
        • Images (png, jpg, heic, gif)
        • Office documents (docx, xlsx, pptx)
        • Pages, Numbers, Keynote
        • Video and audio files
        • 3D models (.usdz)

        Generated: \(Date().formatted(date: .complete, time: .complete))
        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DesignerBuddy-Demo.txt")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            errorMessage = "Failed to create text file: \(error.localizedDescription)"
            return nil
        }
    }

    private func makeHTMLFile() -> URL? {
        let content = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Quick Look HTML Demo</title>
        <style>
          body { font-family: -apple-system, sans-serif; padding: 24px; color: #1c1c1e; }
          h1 { color: #007aff; }
          code { background: #f2f2f7; padding: 2px 6px; border-radius: 4px; }
        </style>
        </head>
        <body>
          <h1>Designer Buddy</h1>
          <h2>Quick Look HTML Demo</h2>
          <p>This <code>.html</code> file was generated at runtime and previewed
          using <code>QLPreviewController</code> via a <code>UIViewControllerRepresentable</code>
          wrapper.</p>
          <p>Generated at: \(Date().formatted(date: .complete, time: .complete))</p>
        </body>
        </html>
        """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DesignerBuddy-Demo.html")
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            errorMessage = "Failed to create HTML file: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func noteRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(.secondary)
                .padding(.top, 5)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack { QuickLookView() }
}
