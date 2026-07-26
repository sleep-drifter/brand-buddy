import SwiftUI

// iOS 27 drag containers on iPhone: a collection's items become draggable
// without being reorderable, and a drag can carry every selected item, not
// just the one under the finger. The container closure decides the payload;
// dragPreviewsFormation(.stack) gives the multi-item drag the fanned-stack
// look. String IDs keep the drop side simple (String is Transferable).

private struct Sticker: Identifiable, Equatable {
    let id: String
    let symbol: String
    let color: Color
}

private let stickerSet: [Sticker] = [
    .init(id: "bolt",   symbol: "bolt.fill",       color: .orange),
    .init(id: "heart",  symbol: "heart.fill",      color: .pink),
    .init(id: "star",   symbol: "star.fill",       color: .yellow),
    .init(id: "bell",   symbol: "bell.fill",       color: .indigo),
    .init(id: "plane",  symbol: "paperplane.fill", color: .teal),
    .init(id: "moon",   symbol: "moon.fill",       color: .purple),
    .init(id: "leaf",   symbol: "leaf.fill",       color: .green),
    .init(id: "flame",  symbol: "flame.fill",      color: .red),
]

struct DragCollectionsView: View {
    @State private var shelf = stickerSet
    @State private var tray: [Sticker] = []
    @State private var selection = Set<String>()

    var body: some View {
        List {
            Section {
                Text("Tap stickers to select several, then drag any one of them — the whole selection comes along as a fanned stack. Drop on the tray below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Shelf — tap to select, drag to move") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(shelf) { sticker in
                        stickerView(sticker)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(.tint, lineWidth: selection.contains(sticker.id) ? 2.5 : 0)
                            )
                            .onTapGesture { toggleSelection(sticker.id) }
                            .draggable(containerItemID: sticker.id)
                    }
                }
                .dragContainer(for: String.self) { id in
                    selection.contains(id) ? Array(selection) : [id]
                }
                .dragPreviewsFormation(.stack)
                .padding(.vertical, 6)
            }

            Section("Tray — drop here") {
                trayView
                    .dropDestination(for: String.self) { ids, session in
                        receive(ids)
                    }
            }

            Section("How it works") {
                Text("`.draggable(containerItemID:)` marks each item, and `.dragContainer(for: String.self)` owns the payload: its closure receives the grabbed item's ID and returns everything that should ride along — here, the current selection. That's the multi-item drag pattern from WWDC26, newly available on iPhone and iPad.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("`dragPreviewsFormation(.stack)` styles the lifted previews as a stack. Unlike Reorder Containers, nothing here reorders — drag exists purely to move items between collections.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Drag Collections")
    }

    private var trayView: some View {
        Group {
            if tray.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Drop stickers here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 18)
            } else {
                HStack(spacing: 10) {
                    ForEach(tray) { sticker in
                        stickerView(sticker)
                            .frame(width: 44, height: 44)
                            .onTapGesture { returnToShelf(sticker) }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .contentShape(Rectangle())
    }

    private func stickerView(_ sticker: Sticker) -> some View {
        Image(systemName: sticker.symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(sticker.color.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toggleSelection(_ id: String) {
        withAnimation(.snappy(duration: 0.15)) {
            if selection.contains(id) {
                selection.remove(id)
            } else {
                selection.insert(id)
            }
        }
    }

    private func receive(_ ids: [String]) {
        withAnimation(.snappy) {
            let moving = shelf.filter { ids.contains($0.id) }
            shelf.removeAll { ids.contains($0.id) }
            tray.append(contentsOf: moving.filter { sticker in !tray.contains(sticker) })
            selection.subtract(ids)
        }
    }

    private func returnToShelf(_ sticker: Sticker) {
        withAnimation(.snappy) {
            tray.removeAll { $0.id == sticker.id }
            shelf.append(sticker)
        }
    }
}

#Preview {
    NavigationStack { DragCollectionsView() }
        .environmentObject(PinsStore())
}
