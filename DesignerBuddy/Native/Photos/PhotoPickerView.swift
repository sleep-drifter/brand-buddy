import SwiftUI
import PhotosUI
import Combine

// MARK: - Photo Picker View

struct PhotoPickerView: View {
    enum SelectionMode: String, CaseIterable {
        case single = "Single"
        case multiple = "Multiple"
    }

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectionMode: SelectionMode = .single
    @State private var maxCount: Int = 3
    @State private var isLoading = false

    var body: some View {
        List {
            configurationSection
            pickerSection
            selectedPhotosSection
            apiNotesSection
        }
        .navigationTitle("Photo Picker")
        .onChange(of: selectedItems) { _, newItems in
            loadImages(from: newItems)
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        Section("Configuration") {
            Picker("Selection Mode", selection: $selectionMode) {
                ForEach(SelectionMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectionMode) { _, _ in
                selectedItems = []
                selectedImages = []
            }

            if selectionMode == .multiple {
                Stepper("Max selection: \(maxCount)", value: $maxCount, in: 1...10)
            }
        }
    }

    // MARK: - Picker Section

    private var pickerSection: some View {
        Section("Picker") {
            HStack {
                Spacer()
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: selectionMode == .single ? 1 : maxCount,
                    matching: .images
                ) {
                    Label("Choose Photos", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Selected Photos Section

    private var selectedPhotosSection: some View {
        Section {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading…")
                    Spacer()
                }
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
            } else if selectedImages.isEmpty {
                emptyPhotoState
            } else {
                photoGrid
            }
        } header: {
            HStack {
                Text("Selected Photos")
                Spacer()
                if !selectedImages.isEmpty {
                    Text("\(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
    }

    private var emptyPhotoState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No photos selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .listRowBackground(Color.clear)
    }

    private var photoGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Button {
                        removeImage(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    .padding(4)
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    // MARK: - API Notes Section

    private var apiNotesSection: some View {
        Section("API Notes") {
            VStack(alignment: .leading, spacing: 10) {
                apiRow(modifier: ".matching(.images)", note: "Filter by asset type (images, videos, livePhotos)")
                Divider()
                apiRow(modifier: "maxSelectionCount:", note: "Limit how many items can be selected at once")
                Divider()
                apiRow(modifier: ".loadTransferable(type: Data.self)", note: "Async load item content from picker handle")
                Divider()
                apiRow(modifier: "PhotosPickerItem", note: "The opaque handle for a selected photo asset")
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private func apiRow(modifier: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(modifier)
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func loadImages(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else {
            selectedImages = []
            return
        }
        isLoading = true
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            selectedImages = images
            isLoading = false
        }
    }

    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoPickerView()
    }
}
