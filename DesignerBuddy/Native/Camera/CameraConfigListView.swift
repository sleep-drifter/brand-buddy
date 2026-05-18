import SwiftUI

struct CameraConfigListView: View {
    @State private var showDocumentScanner = false

    var body: some View {
        List {
            ForEach(CameraConfigCategory.allCases, id: \.rawValue) { category in
                let items = CameraConfig.allCases.filter { $0.category == category }
                Section(category.rawValue) {
                    ForEach(items) { config in
                        row(for: config)
                    }
                }
            }
        }
        .navigationTitle("Camera")
        .sheet(isPresented: $showDocumentScanner) {
            DocumentScannerView(onCompletion: { _ in
                showDocumentScanner = false
            })
        }
    }

    @ViewBuilder
    private func row(for config: CameraConfig) -> some View {
        if config == .documentScanner {
            Button {
                showDocumentScanner = true
            } label: {
                rowLabel(config)
            }
            .foregroundStyle(.primary)
        } else {
            NavigationLink {
                LiveCameraView(config: config)
            } label: {
                rowLabel(config)
            }
        }
    }

    private func rowLabel(_ config: CameraConfig) -> some View {
        HStack(spacing: 12) {
            Image(systemName: config.icon)
                .font(.system(size: 20))
                .frame(width: 32, height: 32)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.title)
                    .font(.headline)
                Text(config.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        CameraConfigListView()
    }
}
