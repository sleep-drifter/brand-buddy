import SwiftUI

// MARK: - Photo Library Patterns View

struct PhotoLibraryPatternsView: View {
    @State private var pattern: PhotoPattern = .avatar
    @State private var isPhotoSet = false
    @State private var thumbnails: [Color] = [
        .indigo, .blue, .purple, .teal
    ]
    @State private var showEditOverlay = true

    var body: some View {
        List {
            Section("Pattern") {
                PresetChipRow(
                    chips: PhotoPattern.allCases.map { option in
                        PresetChip(name: option.rawValue, detail: option.note)
                    },
                    selectedID: patternSelection
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Controls") {
                switch pattern {
                case .avatar:
                    Toggle("Photo set", isOn: $isPhotoSet)
                case .thumbnailStrip:
                    Stepper("Thumbnails: \(thumbnails.count)") {
                        withAnimation(.spring(duration: 0.3)) {
                            thumbnails.append(availableColors.randomElement() ?? .blue)
                        }
                    } onDecrement: {
                        guard !thumbnails.isEmpty else { return }
                        withAnimation(.spring(duration: 0.3)) {
                            thumbnails.removeLast(1)
                        }
                    }
                case .fullBleed:
                    Toggle("Edit overlay", isOn: $showEditOverlay)
                }
            }
        }
        .pinnedPreview(entry: "Photo Library Patterns") {
            Group {
                switch pattern {
                case .avatar:
                    AvatarPatternView(isPhotoSet: $isPhotoSet)
                case .thumbnailStrip:
                    ThumbnailStripPatternView(thumbnails: $thumbnails)
                case .fullBleed:
                    FullBleedPatternView(showEditOverlay: showEditOverlay)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 230, alignment: .top)
            .clipped()
            .buttonStyle(.borderless)
            .animation(.spring(duration: 0.3), value: canvasState)
        }
        .navigationTitle("Photo Library Patterns")
    }

    private var canvasState: [AnyHashable] {
        [pattern, isPhotoSet, thumbnails, showEditOverlay]
    }

    private var patternSelection: Binding<String?> {
        Binding(
            get: { pattern.rawValue },
            set: { name in
                guard let name, let option = PhotoPattern(rawValue: name) else { return }
                pattern = option
            }
        )
    }
}

// MARK: - Photo Pattern

private enum PhotoPattern: String, CaseIterable, Identifiable {
    case avatar = "Avatar"
    case thumbnailStrip = "Thumbnail strip"
    case fullBleed = "Full bleed"

    var id: Self { self }

    var note: String {
        switch self {
        case .avatar:         return "Use when the user has a single primary identity photo. The confirmationDialog matches native iOS Camera Roll patterns users already expect."
        case .thumbnailStrip: return "Use for multi-image content like listings, galleries, or attachments. The horizontal strip keeps images visible while allowing reorder/remove at a glance."
        case .fullBleed:      return "Use when the photo is the primary content (cover photo, hero image). Overlaid edit affordances keep the image immersive without leaving the context."
        }
    }
}

private let availableColors: [Color] = [.indigo, .blue, .purple, .teal, .green, .orange, .pink]

// MARK: - Pattern Header

struct PatternHeader: View {
    let number: Int
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.title3.weight(.bold))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Pattern 1: Avatar / Profile Photo

struct AvatarPatternView: View {
    @Binding var isPhotoSet: Bool
    @State private var showChangeDialog = false

    var body: some View {
        VStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(isPhotoSet ? Color.indigo.opacity(0.7) : Color.blue.opacity(0.25))
                    .frame(width: 80, height: 80)

                if isPhotoSet {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue.opacity(0.5))
                }
            }
            .overlay(
                Circle()
                    .strokeBorder(Color(uiColor: .separator), lineWidth: 1)
            )

            // Change photo button
            Button("Change Photo") {
                showChangeDialog = true
            }
            .font(.subheadline.weight(.medium))
            .confirmationDialog("Change Photo", isPresented: $showChangeDialog, titleVisibility: .visible) {
                Button("Take Photo") { isPhotoSet = true }
                Button("Choose from Library") { isPhotoSet = true }
                Button("Remove Photo", role: .destructive) { isPhotoSet = false }
                Button("Cancel", role: .cancel) {}
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Pattern 2: Thumbnail Strip with Replace

struct ThumbnailStripPatternView: View {
    @Binding var thumbnails: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Change cover button
            Button {
                // Simulate replacing first/featured image
                if !thumbnails.isEmpty {
                    thumbnails[0] = availableColors.randomElement() ?? .blue
                }
            } label: {
                Label("Change Cover Photo", systemImage: "photo.badge.arrow.down")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 20)

            // Horizontal thumbnail strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(thumbnails.enumerated()), id: \.offset) { (index: Int, color: Color) in
                        ZStack(alignment: .topTrailing) {
                            // Thumbnail
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.5))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .foregroundStyle(color.opacity(0.8))
                                )

                            // Featured badge on first
                            if index == 0 {
                                Text("Cover")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.black.opacity(0.6)))
                                    .padding(4)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            }

                            // Remove button
                            Button {
                                let i: Int = index
                                withAnimation { thumbnails.removeSubrange(i...i) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }
                            .padding(4)
                        }
                    }

                    // Add tile
                    Button {
                        withAnimation {
                            thumbnails.append(availableColors.randomElement() ?? .blue)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .foregroundStyle(.secondary)
                            .frame(width: 80, height: 80)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Add")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Pattern 3: Full-Bleed Preview

struct FullBleedPatternView: View {
    var showEditOverlay: Bool = true

    var body: some View {
        ZStack(alignment: .top) {
            // Hero photo placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.8), Color.purple.opacity(0.6), Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 300)
                .overlay(
                    Image(systemName: "photo.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.25))
                )
                .overlay(alignment: .bottom) {
                    bottomMetaBar
                }
                .overlay(alignment: .top) {
                    if showEditOverlay {
                        topEditBar
                    }
                }
                .overlay(alignment: .bottom) {
                    if showEditOverlay {
                        editToolbar
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var topEditBar: some View {
        HStack {
            Button {
                // Replace
            } label: {
                Text("Replace")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
            }

            Spacer()

            Button {
                // Edit
            } label: {
                Text("Edit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(12)
    }

    private var bottomMetaBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("cover_photo_final.jpg")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                Text("May 14, 2026 · 4.2 MB")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var editToolbar: some View {
        HStack(spacing: 28) {
            ForEach([
                ("crop", "Crop"),
                ("rotate.right", "Rotate"),
                ("slider.horizontal.3", "Filters")
            ], id: \.0) { (icon, label) in
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                    Text(label)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
        .clipShape(Capsule())
        .offset(y: -50)
    }
}

#Preview {
    NavigationStack {
        PhotoLibraryPatternsView()
    }
    .environmentObject(PinsStore())
}
