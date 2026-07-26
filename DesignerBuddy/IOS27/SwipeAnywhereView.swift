import SwiftUI

// iOS 27 swipe actions outside List: mark any scrollable container with
// .swipeActionsContainer() and rows inside it can use the same
// .swipeActions(edge:) API that List rows always had. The container
// coordinates state — one open row at a time, scrolling or tapping away
// dismisses — and the new onPresentationChanged closure reports reveal state.

private struct Chore: Identifiable, Equatable {
    let id: Int
    var title: String
    var flagged = false
    var done = false
}

struct SwipeAnywhereView: View {
    @State private var chores: [Chore] = [
        .init(id: 0, title: "Water the monstera"),
        .init(id: 1, title: "Book dentist appointment"),
        .init(id: 2, title: "Refactor the sync engine"),
        .init(id: 3, title: "Reply to the design review"),
        .init(id: 4, title: "Prep Thursday's demo"),
        .init(id: 5, title: "Clear the download folder"),
    ]
    @State private var revealedID: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("These cards live in a `LazyVStack` inside a `ScrollView` — not a `List`. Swipe a row either way.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                LazyVStack(spacing: 10) {
                    ForEach(chores) { chore in
                        choreRow(chore)
                            .swipeActions(edge: .leading) {
                                Button {
                                    setDone(chore)
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    remove(chore)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    flag(chore)
                                } label: {
                                    Label("Flag", systemImage: "flag")
                                }
                                .tint(.orange)
                            } onPresentationChanged: { visible in
                                revealedID = visible ? chore.id : nil
                            }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: revealedID == nil ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                    Text(statusText)
                        .font(.mono(.caption))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                Text("`.swipeActionsContainer()` sits on the ScrollView and coordinates everything: only one row's actions stay revealed, scrolling closes them, and `onPresentationChanged` fires as actions show and hide — that's what drives the readout above. The same setup works in `LazyVGrid` and custom `Layout` types. The playful hand-rolled version of this pattern lives in Glass Morph's Swipe Actions scene; this page is the system API.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .swipeActionsContainer()
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Swipe Anywhere")
    }

    private var statusText: String {
        if let id = revealedID, let chore = chores.first(where: { $0.id == id }) {
            return "onPresentationChanged: “\(chore.title)” revealed"
        }
        return "onPresentationChanged: nothing revealed"
    }

    private func choreRow(_ chore: Chore) -> some View {
        HStack(spacing: 12) {
            Image(systemName: chore.done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(chore.done ? .green : .secondary)
            Text(chore.title)
                .strikethrough(chore.done)
                .foregroundStyle(chore.done ? .secondary : .primary)
            Spacer()
            if chore.flagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func setDone(_ chore: Chore) {
        guard let i = chores.firstIndex(of: chore) else { return }
        withAnimation(.snappy) { chores[i].done.toggle() }
    }

    private func flag(_ chore: Chore) {
        guard let i = chores.firstIndex(of: chore) else { return }
        withAnimation(.snappy) { chores[i].flagged.toggle() }
    }

    private func remove(_ chore: Chore) {
        withAnimation(.snappy) { chores.removeAll { $0.id == chore.id } }
    }
}

#Preview {
    NavigationStack { SwipeAnywhereView() }
        .environmentObject(PinsStore())
}
