import SwiftUI

// MARK: - Capture Selection Wrapper

private struct CaptureSelection: Identifiable {
    let id: Int
    let image: UIImage
}

// MARK: - Camera Config List View

struct CameraConfigListView: View {
    @State private var showDocumentScanner = false
    @State private var captures: [UIImage] = []
    @State private var selectedCapture: CaptureSelection? = nil

    var body: some View {
        List {
            // Captures shelf
            if !captures.isEmpty {
                Section("Captures") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(captures.indices, id: \.self) { i in
                                captureThumb(index: i)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 0))
                }
            }

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
            DocumentScannerView(captures: $captures, onDismiss: {
                showDocumentScanner = false
            })
        }
        .fullScreenCover(item: $selectedCapture) { selection in
            capturePreviewCover(selection: selection)
        }
    }

    // MARK: - Capture Thumbnail

    private func captureThumb(index: Int) -> some View {
        let image = captures[index]
        return ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture {
                    selectedCapture = CaptureSelection(id: index, image: image)
                }
        }
    }

    // MARK: - Capture Preview Cover

    private func capturePreviewCover(selection: CaptureSelection) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: selection.image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        selectedCapture = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(20)
                    }
                }
                Spacer()
                HStack(spacing: 20) {
                    Button("Remove") {
                        let idx = selection.id
                        if idx < captures.count {
                            captures.remove(at: idx)
                        }
                        selectedCapture = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())

                    Button("Close") {
                        selectedCapture = nil
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Row

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
                LiveCameraView(config: config, captures: $captures)
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
