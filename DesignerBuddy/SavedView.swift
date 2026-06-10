import SwiftUI

struct SavedView: View {
    @EnvironmentObject var pinsStore: PinsStore
    @Environment(\.dismiss) private var dismiss

    private var savedEntries: [AppEntry] {
        AppEntry.all.filter { pinsStore.isPinned($0) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if savedEntries.isEmpty {
                    ContentUnavailableView(
                        "Nothing saved yet",
                        systemImage: "bookmark",
                        description: Text("Swipe right or long-press any item to bookmark it.")
                    )
                } else {
                    List {
                        ForEach(savedEntries) { entry in
                            pinnableRow(entry, pinsStore: pinsStore)
                        }
                    }
                    .navigationDestination(for: AppEntry.self) { appDestination(for: $0) }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SavedView()
        .environmentObject(PinsStore())
}
