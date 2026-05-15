import SwiftUI

struct ExploreTab: View {
    var body: some View {
        NavigationStack {
            List {
                Section("System Integrations") {
                    NavigationLink { ShareSheetView() } label: {
                        Label("Share Sheet", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink { FaceIDView() } label: {
                        Label("Face ID / Touch ID", systemImage: "faceid")
                    }
                    NavigationLink { ClipboardView() } label: {
                        Label("Clipboard", systemImage: "doc.on.clipboard")
                    }
                    NavigationLink { QuickLookView() } label: {
                        Label("Quick Look", systemImage: "eye")
                    }
                    NavigationLink { DocumentPickerView() } label: {
                        Label("Document Picker", systemImage: "folder")
                    }
                }
            }
            .navigationTitle("Explore")
        }
    }
}

#Preview {
    ExploreTab()
}
