import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - DocumentPickerView

struct DocumentPickerView: View {
    @State private var showImporter = false
    @State private var showCustomPicker = false
    @State private var importedURL: URL?
    @State private var importError: String?
    @State private var fileInfo: FileInfo?

    struct FileInfo {
        let name: String
        let size: String
        let type: String
        let path: String
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: SwiftUI .fileImporter
                VStack(spacing: 12) {
                    HStack {
                        Label(".fileImporter (SwiftUI)", systemImage: "square.and.arrow.down")
                            .font(.headline)
                        Spacer()
                    }

                    Text("The `.fileImporter` modifier is the SwiftUI-native way to present a document picker. It wraps UIDocumentPickerViewController internally.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        importError = nil
                        showImporter = true
                    } label: {
                        Label("Open File Importer", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let error = importError {
                        HStack {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Imported file details
                if let info = fileInfo {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Imported File", systemImage: "doc.fill")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }

                        VStack(spacing: 6) {
                            detailRow(label: "Name", value: info.name)
                            detailRow(label: "Size", value: info.size)
                            detailRow(label: "Type", value: info.type)
                        }

                        infoRow(icon: "lock.shield", text: "The app received a security-scoped URL. Call startAccessingSecurityScopedResource() before reading and stopAccessingSecurityScopedResource() when done.")
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                // MARK: UIDocumentPickerViewController wrapper
                VStack(spacing: 12) {
                    HStack {
                        Label("UIDocumentPickerViewController", systemImage: "gearshape.2")
                            .font(.headline)
                        Spacer()
                    }

                    Text("For more control — multiple selection, custom UTTypes, export mode — use the UIKit wrapper directly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showCustomPicker = true
                    } label: {
                        Label("Open UIKit Picker (Multi-select)", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: UTType reference
                VStack(spacing: 12) {
                    HStack {
                        Label("Common UTTypes", systemImage: "tag")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        utypeRow(".item",         "Any file")
                        utypeRow(".data",         "Raw data / binary")
                        utypeRow(".text",         "Plain text")
                        utypeRow(".pdf",          "PDF document")
                        utypeRow(".image",        "Any image format")
                        utypeRow(".json",         "JSON data")
                        utypeRow(".zip",          "ZIP archive")
                        utypeRow(".spreadsheet",  "Spreadsheet (xlsx, csv…)")
                        utypeRow(".folder",       "Folder / directory")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: Implementation notes
                VStack(spacing: 12) {
                    HStack {
                        Label("Key Patterns", systemImage: "list.bullet.rectangle")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(spacing: 6) {
                        noteRow("Use .fileImporter for simple single-file import; UIDocumentPickerViewController for multi-select or export.")
                        noteRow("Always call startAccessingSecurityScopedResource() / stopAccessingSecurityScopedResource() on the returned URL.")
                        noteRow("For saving files from your app, use .fileExporter with a FileDocument or ReferenceFileDocument conformance.")
                        noteRow("Add NSDocumentsFolderUsageDescription to Info.plist if accessing iCloud Drive documents.")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(16)
        }
        .navigationTitle("Document Picker")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handleImport(url: url)
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .sheet(isPresented: $showCustomPicker) {
            MultiSelectDocumentPicker { urls in
                showCustomPicker = false
                if let url = urls.first { handleImport(url: url) }
            }
        }
    }

    // MARK: Import handling

    private func handleImport(url: URL) {
        importedURL = url
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let bytes = attrs?[.size] as? Int ?? 0
        let typeID = UTType(filenameExtension: url.pathExtension)?.identifier ?? url.pathExtension

        fileInfo = FileInfo(
            name: url.lastPathComponent,
            size: ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file),
            type: typeID,
            path: url.lastPathComponent
        )
    }

    // MARK: Helpers

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

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
    private func utypeRow(_ identifier: String, _ description: String) -> some View {
        HStack {
            Text(identifier)
                .font(.caption.monospaced())
                .foregroundStyle(.blue)
                .frame(width: 120, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

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

// MARK: - UIDocumentPickerViewController wrapper (multi-select)

private struct MultiSelectDocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick([])
        }
    }
}

#Preview {
    NavigationStack { DocumentPickerView() }
}
